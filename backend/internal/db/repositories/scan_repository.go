package repositories

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/purescanai/backend/internal/ai"
	"github.com/purescanai/backend/internal/db"
	"github.com/purescanai/backend/internal/engine"
)

// GetCachedScan looks up a previously analyzed ingredient text to return consistent results
func GetCachedScan(ctx context.Context, rawText string) (*ai.ParsedIngredients, *engine.TrustScoreReport, error) {
	if db.Pool == nil {
		return nil, nil, fmt.Errorf("database pool not initialized")
	}

	var parsedJSON, reportJSON []byte
	err := db.Pool.QueryRow(ctx, `
		SELECT parsed_json, trust_score_report FROM public.ingredients WHERE raw_text = $1
	`, rawText).Scan(&parsedJSON, &reportJSON)

	if err != nil {
		// No cache hit - caller should re-analyze
		return nil, nil, nil
	}

	var parsed ai.ParsedIngredients
	var report engine.TrustScoreReport

	if err := json.Unmarshal(parsedJSON, &parsed); err != nil {
		return nil, nil, nil // If corrupt, re-analyze
	}
	if err := json.Unmarshal(reportJSON, &report); err != nil {
		return nil, nil, nil // If corrupt, re-analyze
	}

	return &parsed, &report, nil
}

func SaveIngredientScan(ctx context.Context, userID string, rawText string, parsed *ai.ParsedIngredients, report *engine.TrustScoreReport) error {
	if db.Pool == nil {
		return fmt.Errorf("database pool not initialized")
	}

	parsedBytes, _ := json.Marshal(parsed)
	reportBytes, _ := json.Marshal(report)

	// 1. Upsert into ingredients cache
	var ingredientID string
	err := db.Pool.QueryRow(ctx, `
		INSERT INTO public.ingredients (raw_text, parsed_json, trust_score_report)
		VALUES ($1, $2, $3)
		ON CONFLICT (raw_text) DO UPDATE 
		SET parsed_json = $2, trust_score_report = $3
		RETURNING id
	`, rawText, string(parsedBytes), string(reportBytes)).Scan(&ingredientID)
	
	if err != nil {
		return fmt.Errorf("failed to insert ingredient: %v", err)
	}

	// 2. Insert into scan history
	_, err = db.Pool.Exec(ctx, `
		INSERT INTO public.scan_history (user_id, scan_type, ingredient_id, report_json)
		VALUES ($1, 'ocr', $2, $3)
	`, userID, ingredientID, string(reportBytes))
	
	if err != nil {
		return fmt.Errorf("failed to insert scan history: %v", err)
	}

	return nil
}
