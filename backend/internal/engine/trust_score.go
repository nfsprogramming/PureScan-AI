package engine

import (
	"fmt"
	"math"
	"strings"

	"github.com/purescanai/backend/internal/ai"
)

// IngredientProfile represents the risk profile of an ingredient for engine calculation
type IngredientProfile struct {
	Name              string
	RiskScore         int
	RiskLevel         string
	EatRecommendation string
	ConsumerSummary   string
	Allergen          bool
}

type TrustScoreReport struct {
	FinalScore             int      `json:"final_score"`
	CombinedScore          int      `json:"combined_score"`
	CommunityRating        float64  `json:"community_rating"`
	Rating                 string   `json:"rating"`
	Description            string   `json:"description"`
	IngredientQualityScore int      `json:"ingredient_quality_score"`
	NutritionScore         int      `json:"nutrition_score"`
	RiskPenalty            int      `json:"risk_penalty"`
	AdditivesScore         int      `json:"additives_score"`
	TransparencyScore      int      `json:"transparency_score"`
	FlaggedIssues          []string `json:"flagged_issues"`
	AlternativeProducts    []string `json:"alternative_products"`
}

// CalculateScore calculates the real trust score based on AI output and database risk scores
func CalculateScore(parsed *ai.ParsedIngredients, dictionary map[string]IngredientProfile, averageCommunityRating float64, threshold string) *TrustScoreReport {
	report := &TrustScoreReport{
		FlaggedIssues:   []string{},
		CommunityRating: averageCommunityRating,
	}

	// 1. Ingredient Quality Score (Max 40)
	ingQuality := 0
	naturalCount := len(parsed.NaturalIngredients)
	wholeCount := len(parsed.WholeFoodIngredients)
	totalIngredients := naturalCount + wholeCount + len(parsed.Additives) + len(parsed.ArtificialColors) + len(parsed.ArtificialSweeteners) + len(parsed.Preservatives) + len(parsed.HighRiskIngredients)

	if totalIngredients > 0 {
		goodCount := naturalCount + wholeCount
		ratio := float64(goodCount) / float64(totalIngredients)
		ingQuality = int(ratio * 40.0)

		// Small boost for very clean lists, but capped at 35 (not 40) for non-whole-food-dominant products
		if totalIngredients <= 5 && ratio >= 1.0 && wholeCount >= naturalCount {
			ingQuality = 38 // All ingredients are whole/natural — nearly perfect
		} else if totalIngredients <= 5 && ratio > 0.8 {
			ingQuality = 30 // Simple but still contains oils/salts processed
		}
	}
	report.IngredientQualityScore = min(ingQuality, 40)

	// 2. Nutrition Score (Max 25 — reduced from 30 for realism)
	nutrition := 0

	switch parsed.SugarLevel {
	case "Very Low":
		nutrition += 10
	case "Low":
		nutrition += 8
	case "Moderate":
		nutrition += 4
	// High sugar = 0 points
	}

	switch parsed.SodiumLevel {
	case "Very Low":
		nutrition += 10
	case "Low":
		nutrition += 7
	case "Moderate":
		nutrition += 3
	// High sodium = 0 points
	}

	switch parsed.ProteinLevel {
	case "High":
		nutrition += 5
	case "Moderate":
		nutrition += 3
	}
	report.NutritionScore = min(nutrition, 25)

	// 3. Snack/Frying penalty — oils in natural ingredients signal a fried snack
	fryingPenalty := 0
	for _, ing := range parsed.NaturalIngredients {
		lower := strings.ToLower(ing)
		if strings.Contains(lower, "vegetable oil") || strings.Contains(lower, "canola oil") ||
			strings.Contains(lower, "palm oil") || strings.Contains(lower, "sunflower oil") ||
			strings.Contains(lower, "soybean oil") || strings.Contains(lower, "corn oil") {
			// Oils in the ingredient list are fine, but indicate processed/fried food
			// Apply a modest penalty to prevent perfect scores for fried snacks
			fryingPenalty = 8
			break
		}
	}

	// 4. Risk Penalties & Flagged Issues from Database
	penalty := 0

	// Map thresholds
	lowerThreshold := strings.ToLower(threshold)
	minRiskToFlag := 4 // Medium (moderate and above)
	if lowerThreshold == "high" {
		minRiskToFlag = 2 // High sensitivity (low, moderate, high, severe)
	} else if lowerThreshold == "low" {
		minRiskToFlag = 7 // Low sensitivity (only severe)
	}

	processIngredients := func(ingredients []string) {
		for _, name := range ingredients {
			if name == "" {
				continue
			}
			lowerName := strings.ToLower(name)
			if ing, exists := dictionary[lowerName]; exists {
				if ing.RiskScore >= 7 && ing.RiskScore >= minRiskToFlag {
					penalty += 15
					report.FlaggedIssues = append(report.FlaggedIssues, fmt.Sprintf("%s (%s): %s", ing.Name, ing.RiskLevel, ing.ConsumerSummary))
				} else if ing.RiskScore >= 4 && ing.RiskScore >= minRiskToFlag {
					penalty += 5
					report.FlaggedIssues = append(report.FlaggedIssues, fmt.Sprintf("%s: %s", ing.Name, ing.EatRecommendation))
				} else if ing.RiskScore >= 2 && ing.RiskScore >= minRiskToFlag {
					penalty += 2
					report.FlaggedIssues = append(report.FlaggedIssues, fmt.Sprintf("%s: Low-risk potential concern.", ing.Name))
				} else if ing.Allergen {
					report.FlaggedIssues = append(report.FlaggedIssues, fmt.Sprintf("Allergen Warning: %s", ing.Name))
				}
			}
		}
	}

	processIngredients(parsed.NaturalIngredients)
	processIngredients(parsed.WholeFoodIngredients)
	processIngredients(parsed.Additives)
	processIngredients(parsed.ArtificialColors)
	processIngredients(parsed.ArtificialSweeteners)
	processIngredients(parsed.Preservatives)
	processIngredients(parsed.HighRiskIngredients)

	// Penalty for artificial additives count
	artificialPenalty := len(parsed.ArtificialColors)*8 + len(parsed.ArtificialSweeteners)*6 + len(parsed.Preservatives)*4
	report.RiskPenalty = penalty + artificialPenalty
	if report.RiskPenalty > 20 {
		report.RiskPenalty = 20
	}

	// Additives Score
	additivesScore := 100 - penalty
	if len(parsed.Additives) > 0 {
		additivesScore -= len(parsed.Additives) * 5
	}
	if additivesScore < 0 {
		additivesScore = 0
	}
	report.AdditivesScore = additivesScore

	// Transparency Score
	transparencyScore := 80
	transparencyScore += naturalCount * 2
	transparencyScore += wholeCount * 3
	transparencyScore -= len(parsed.ArtificialColors) * 5
	transparencyScore -= len(parsed.ArtificialSweeteners) * 5
	if transparencyScore > 100 {
		transparencyScore = 100
	} else if transparencyScore < 0 {
		transparencyScore = 0
	}
	report.TransparencyScore = transparencyScore

	// Calculate Final Score
	// Base is 25 + Quality(0-40) + Nutrition(0-25) - Penalties
	rawScore := 25 + report.IngredientQualityScore + report.NutritionScore - report.RiskPenalty - fryingPenalty

	report.FinalScore = int(math.Max(0, math.Min(100, float64(rawScore))))

	// Combine AI Score with Community Rating (70% AI / 30% Community)
	report.CombinedScore = report.FinalScore
	if averageCommunityRating > 0 {
		// Convert 1-5 rating to 0-100 scale (e.g., 5 = 100, 1 = 20)
		communityScore := (averageCommunityRating / 5.0) * 100.0
		combinedFloat := (float64(report.FinalScore) * 0.70) + (communityScore * 0.30)
		report.CombinedScore = int(math.Max(0, math.Min(100, combinedFloat)))
	}

	// Rating & Description
	if report.CombinedScore >= 80 {
		report.Rating = "Excellent"
		report.Description = "This product contains primarily whole foods and safe ingredients."
	} else if report.CombinedScore >= 60 {
		report.Rating = "Good"
		report.Description = "Generally safe for consumption, but may contain some processed ingredients."
	} else if report.CombinedScore >= 40 {
		report.Rating = "Moderate"
		
		var issues []string
		if len(parsed.Additives) > 0 {
			issues = append(issues, "additives")
		}
		if parsed.SugarLevel == "High" {
			issues = append(issues, "high sugar")
		}
		if parsed.SodiumLevel == "High" {
			issues = append(issues, "high sodium")
		}

		if len(issues) > 0 {
			report.Description = fmt.Sprintf("Contains %s. Consume in moderation.", strings.Join(issues, ", "))
		} else {
			report.Description = "A moderately processed item. Consume in moderation."
		}
	} else {
		report.Rating = "High Risk"
		report.Description = "Contains highly processed or potentially harmful ingredients. Avoid frequent consumption."
	}

	report.AlternativeProducts = parsed.AlternativeProducts

	return report
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
