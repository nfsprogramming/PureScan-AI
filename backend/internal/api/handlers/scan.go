package handlers

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/purescanai/backend/internal/ai"
	"github.com/purescanai/backend/internal/db"
	"github.com/purescanai/backend/internal/db/repositories"
	"github.com/purescanai/backend/internal/engine"
	"github.com/purescanai/backend/internal/services"
)

type BarcodeScanRequest struct {
	Barcode string `json:"barcode" binding:"required"`
}

type UserProfile struct {
	Age               int      `json:"age"`
	Diets             []string `json:"diets"`
	Allergies         []string `json:"allergies"`
	ClinicalThreshold string   `json:"clinical_threshold"`
}

type OcrScanRequest struct {
	ExtractedText   string       `json:"extracted_text" binding:"required"`
	UserProfile     *UserProfile `json:"user_profile,omitempty"`
	CommunityRating float64      `json:"community_rating"`
}

// HandleBarcodeScan checks if a scanned barcode exists in the database
func HandleBarcodeScan(c *gin.Context) {
	var req BarcodeScanRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request payload"})
		return
	}

	userID, _ := c.Get("user_id")
	log.Printf("User %v scanned barcode: %s", userID, req.Barcode)

	// Check if product exists in the DB
	var id, name string
	var trustScore int
	err := db.Pool.QueryRow(c.Request.Context(), 
		"SELECT id, name, trust_score FROM products WHERE barcode = $1", req.Barcode).Scan(&id, &name, &trustScore)
	
	if err != nil {
		// Not found
		c.JSON(http.StatusOK, gin.H{
			"status":  "not_found",
			"barcode": req.Barcode,
			"message": "Product not found. Prompt user to contribute.",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "found",
		"barcode": req.Barcode,
		"product": gin.H{
			"id": id,
			"name": name,
			"trust_score": trustScore,
		},
	})
}

// HandleOcrScan receives extracted text from ML Kit and processes it via NVIDIA AI
func HandleOcrScan(c *gin.Context) {
	var req OcrScanRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request payload"})
		return
	}

	userIDInterface, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}
	userID := userIDInterface.(string)
	
	log.Printf("User %v uploaded OCR text length: %d", userID, len(req.ExtractedText))

	// 1. Check ingredient cache first (prevents score variation on rescan)
	parsedIngredients, report, _ := repositories.GetCachedScan(c.Request.Context(), req.ExtractedText)

	if parsedIngredients == nil {
		// Cache miss — build profile prompt then call AI
		profilePrompt := ""
		
		// Fetch user profile from DB
		var dbAllergies, dbDiets []string
		err := db.Pool.QueryRow(
			c.Request.Context(),
			"SELECT allergies, diets FROM user_profiles WHERE user_id = $1",
			userID,
		).Scan(&dbAllergies, &dbDiets)
		
		if err == nil && (len(dbAllergies) > 0 || len(dbDiets) > 0) {
			profilePrompt = "The user scanning this product has the following Dietary Profile:\n"
			if len(dbDiets) > 0 {
				profilePrompt += "- Diets: " + strings.Join(dbDiets, ", ") + "\n"
			}
			if len(dbAllergies) > 0 {
				profilePrompt += "- Allergies: " + strings.Join(dbAllergies, ", ") + "\n"
			}
			profilePrompt += "\nCRITICAL INSTRUCTION: If any ingredients (or hidden derivatives) violate their diet or trigger their allergies, you MUST flag them in the `red_alerts` array AND `high_risk_ingredients` array!"
		} else if req.UserProfile != nil {
			// Fallback to request payload
			profilePrompt = "The user scanning this product has the following Demographic and Dietary Profile:\n"
			
			if req.UserProfile.Age > 0 {
				age := req.UserProfile.Age
				demographic := "Adult"
				safetyRule := ""

				if age <= 3 {
					demographic = "Toddler/Infant"
					safetyRule = "CRITICAL: The consumer is a TODDLER. You MUST aggressively flag choking hazards (whole nuts, hard pieces), excessive sodium, caffeine, artificial dyes, and high sugar. In alternative_products, ONLY suggest baby/toddler-safe healthy alternatives!"
				} else if age <= 12 {
					demographic = "Child"
					safetyRule = "CRITICAL: The consumer is a CHILD. You MUST flag artificial colors (like Red 40), high fructose corn syrup, and excessive caffeine. In alternative_products, suggest kid-friendly healthy snacks!"
				} else if age <= 17 {
					demographic = "Teenager"
					safetyRule = "CRITICAL: The consumer is a TEEN. Keep an eye out for extreme caffeine or unhealthy energy drink additives."
				} else if age >= 65 {
					demographic = "Senior"
					safetyRule = "CRITICAL: The consumer is a SENIOR. You MUST flag high sodium, trans fats, and hard-to-digest heavy processed ingredients. Suggest heart-healthy alternatives!"
				}

				profilePrompt += "- Age Demographic: " + demographic + " (" + fmt.Sprintf("%d", age) + " years old)\n"
				profilePrompt += safetyRule + "\n"
			}

			if len(req.UserProfile.Diets) > 0 {
				profilePrompt += "- Diets: " + strings.Join(req.UserProfile.Diets, ", ") + "\n"
			}
			if len(req.UserProfile.Allergies) > 0 {
				profilePrompt += "- Allergies: " + strings.Join(req.UserProfile.Allergies, ", ") + "\n"
			}
			profilePrompt += "\nCRITICAL INSTRUCTION: If any ingredients (or hidden derivatives) violate their diet or trigger their allergies, you MUST flag them in the `red_alerts` array AND `high_risk_ingredients` array!"
		}

		// Call NVIDIA AI
		client := ai.NewNIMClient()
		parsedIngredients, err = client.ClassifyIngredients(req.ExtractedText, profilePrompt)
		if err != nil {
			log.Printf("NVIDIA AI Error: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to analyze ingredients"})
			return
		}

		// Build ingredient dictionary from DB
		allNames := []string{}
		allNames = append(allNames, parsedIngredients.NaturalIngredients...)
		allNames = append(allNames, parsedIngredients.WholeFoodIngredients...)
		allNames = append(allNames, parsedIngredients.Additives...)
		allNames = append(allNames, parsedIngredients.ArtificialColors...)
		allNames = append(allNames, parsedIngredients.ArtificialSweeteners...)
		allNames = append(allNames, parsedIngredients.Preservatives...)
		allNames = append(allNames, parsedIngredients.HighRiskIngredients...)

		dictionary, dictErr := repositories.GetIngredientsByNames(c.Request.Context(), allNames)
		if dictErr != nil {
			log.Printf("Database Dictionary Error: %v", dictErr)
			dictionary = make(map[string]repositories.Ingredient)
		}

		engineDict := make(map[string]engine.IngredientProfile)
		for k, v := range dictionary {
			engineDict[k] = engine.IngredientProfile{
				Name:              v.Name,
				RiskScore:         v.RiskScore,
				RiskLevel:         v.RiskLevel,
				EatRecommendation: v.EatRecommendation,
				ConsumerSummary:   v.ConsumerSummary,
				Allergen:          v.Allergen,
			}
		}

		// Extract clinical threshold with fallback
		threshold := "Medium"
		if req.UserProfile != nil && req.UserProfile.ClinicalThreshold != "" {
			threshold = req.UserProfile.ClinicalThreshold
		}

		// Calculate Trust Score
		report = engine.CalculateScore(parsedIngredients, engineDict, req.CommunityRating, threshold)

		// Save to cache + scan history
		if saveErr := repositories.SaveIngredientScan(c.Request.Context(), userID, req.ExtractedText, parsedIngredients, report); saveErr != nil {
			log.Printf("Database Save Error: %v", saveErr)
		}
	} else {
		// Cache hit — still save to scan_history so the scan appears in history
		log.Printf("Cache hit for user %v, returning cached result", userID)
		if saveErr := repositories.SaveIngredientScan(c.Request.Context(), userID, req.ExtractedText, parsedIngredients, report); saveErr != nil {
			log.Printf("Database Save Error (cache hit path): %v", saveErr)
		}
	}

	// Trigger real-time alert if there are flagged issues
	if len(report.FlaggedIssues) > 0 {
		go services.SendRealTimeAlert(context.Background(), userID, "Scanned Product", report.FlaggedIssues)
	}

	c.JSON(http.StatusOK, gin.H{
		"message":           "Analysis complete",
		"parsed_data":       parsedIngredients,
		"trust_score_report": report,
	})
}
