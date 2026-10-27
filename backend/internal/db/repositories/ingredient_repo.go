package repositories

import (
	"context"
	"strings"

	"github.com/purescanai/backend/internal/db"
)

type Ingredient struct {
	Name              string
	Category          string
	InsNumber         string
	RiskScore         int
	RiskLevel         string
	FssaiStatus       string
	FdaStatus         string
	EfsaStatus        string
	Allergen          bool
	ConsumerSummary   string
	EatRecommendation string
}

// GetIngredientsByNames queries the database for matching ingredients (case-insensitive).
func GetIngredientsByNames(ctx context.Context, names []string) (map[string]Ingredient, error) {
	result := make(map[string]Ingredient)
	if len(names) == 0 {
		return result, nil
	}

	// We'll normalize the input names to lowercase for comparison, but PostgreSQL
	// allows us to use ILIKE or LOWER() in the query.
	var lowerNames []string
	for _, n := range names {
		lowerNames = append(lowerNames, strings.ToLower(n))
	}

	// pgx allows using ANY($1) for slice queries!
	query := `
		SELECT name, category, ins_number, risk_score, risk_level, 
		       fssai_status, fda_status, efsa_status, allergen, 
		       consumer_summary, eat_recommendation 
		FROM ingredient_dictionary 
		WHERE LOWER(name) = ANY($1)
	`

	rows, err := db.Pool.Query(ctx, query, lowerNames)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var ing Ingredient
		var insNumber, consumerSummary, eatRecommendation *string

		err := rows.Scan(
			&ing.Name, &ing.Category, &insNumber, &ing.RiskScore, &ing.RiskLevel,
			&ing.FssaiStatus, &ing.FdaStatus, &ing.EfsaStatus, &ing.Allergen,
			&consumerSummary, &eatRecommendation,
		)
		if err != nil {
			return nil, err
		}

		if insNumber != nil {
			ing.InsNumber = *insNumber
		}
		if consumerSummary != nil {
			ing.ConsumerSummary = *consumerSummary
		}
		if eatRecommendation != nil {
			ing.EatRecommendation = *eatRecommendation
		}

		// Store in map with lowercase name as key for easy lookup later
		result[strings.ToLower(ing.Name)] = ing
	}

	return result, nil
}
