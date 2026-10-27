package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/purescanai/backend/internal/ai"
	"github.com/purescanai/backend/internal/db"
)

type WeeklySummaryResponse struct {
	AverageScore int    `json:"average_score"`
	TierLabel    string `json:"tier_label"`
	Insight      string `json:"insight"`
	TotalScans   int    `json:"total_scans"`
}

type ScanReport struct {
	Score               int      `json:"score"`
	HighRiskIngredients []string `json:"high_risk_ingredients,omitempty"`
}

// GetWeeklySummary calculates the user's scanning habits for the last 7 days
func GetWeeklySummary(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	// Query scan history for the last 7 days
	rows, err := db.Pool.Query(context.Background(),
		`SELECT report_json 
		 FROM scan_history 
		 WHERE user_id = $1 AND created_at >= NOW() - INTERVAL '7 days'`,
		userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch scan history"})
		return
	}
	defer rows.Close()

	var totalScore int
	var scanCount int
	var allHighRisk []string

	for rows.Next() {
		var reportJSON []byte
		if err := rows.Scan(&reportJSON); err != nil {
			continue
		}

		if len(reportJSON) == 0 {
			continue
		}

		var report ScanReport
		if err := json.Unmarshal(reportJSON, &report); err == nil {
			totalScore += report.Score
			scanCount++
			allHighRisk = append(allHighRisk, report.HighRiskIngredients...)
		}
	}

	if scanCount == 0 {
		c.JSON(http.StatusOK, WeeklySummaryResponse{
			AverageScore: 0,
			TierLabel:    "No Scans Yet",
			Insight:      "Scan your first product this week to get your personalized health insight!",
			TotalScans:   0,
		})
		return
	}

	averageScore := totalScore / scanCount
	tierLabel := "Needs Improvement"
	if averageScore >= 80 {
		tierLabel = "Clean Eating"
	} else if averageScore >= 50 {
		tierLabel = "Balanced Diet"
	}

	// Deduplicate high risk ingredients
	uniqueHighRisk := make(map[string]bool)
	var finalHighRisk []string
	for _, ing := range allHighRisk {
		if !uniqueHighRisk[ing] {
			uniqueHighRisk[ing] = true
			finalHighRisk = append(finalHighRisk, ing)
		}
	}

	insight := "You are making excellent choices. Keep up the great work!"
	if len(finalHighRisk) > 0 {
		// Use AI to generate a custom 1-sentence insight
		prompt := fmt.Sprintf(
			"The user scanned %d products this week. Their average health score is %d/100. " +
			"They encountered these high risk ingredients: %s. " +
			"Write exactly ONE short, encouraging sentence advising them on their diet. Be concise, direct, and conversational.",
			scanCount, averageScore, strings.Join(finalHighRisk, ", "))
		
		nimClient := ai.NewNIMClient()
		aiInsight, err := nimClient.AnalyzeText(prompt)
		if err == nil && aiInsight != "" {
			// Try to clean up quotes or markdown if the AI added any
			insight = strings.Trim(aiInsight, "\"'\n")
		} else {
			// Fallback if AI fails
			insight = fmt.Sprintf("You scanned products containing %d different high-risk ingredients. Try to minimize these next week!", len(finalHighRisk))
		}
	} else if averageScore < 80 {
		insight = "Your ingredients are mostly safe, but you can still aim for healthier, less processed options!"
	}

	c.JSON(http.StatusOK, WeeklySummaryResponse{
		AverageScore: averageScore,
		TierLabel:    tierLabel,
		Insight:      insight,
		TotalScans:   scanCount,
	})
}
