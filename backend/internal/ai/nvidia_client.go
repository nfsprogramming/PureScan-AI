package ai

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
)

// ParsedIngredients represents the structured output we want from the AI.
type ParsedIngredients struct {
	NaturalIngredients   []string `json:"natural_ingredients"`
	WholeFoodIngredients []string `json:"whole_food_ingredients"`
	Additives            []string `json:"additives"`
	ArtificialColors     []string `json:"artificial_colors"`
	ArtificialSweeteners []string `json:"artificial_sweeteners"`
	Preservatives        []string `json:"preservatives"`
	HighRiskIngredients  []string `json:"high_risk_ingredients"`
	ProductClaims        []string `json:"product_claims"`
	SugarLevel           string   `json:"sugar_level"`   // "Very Low", "Low", "Moderate", "High"
	SodiumLevel          string   `json:"sodium_level"`  // "Low", "Moderate", "High"
	ProteinLevel         string   `json:"protein_level"` // "Low", "Moderate", "High"
	AlternativeProducts  []string `json:"alternative_products"`
	RedAlerts            []string `json:"red_alerts"`
}

// NIMClient handles communication with NVIDIA NIM APIs
type NIMClient struct {
	APIKey string
	Model  string
	Client *http.Client
}

func NewNIMClient() *NIMClient {
	return &NIMClient{
		APIKey: os.Getenv("NVIDIA_NIM_API_KEY"),
		Model:  "meta/llama-3.1-70b-instruct",
		Client: &http.Client{},
	}
}

func (n *NIMClient) ClassifyIngredients(rawText string, profilePrompt string) (*ParsedIngredients, error) {
	url := "https://integrate.api.nvidia.com/v1/chat/completions"

	systemPrompt := `You are an expert food scientist and toxicologist. 
Your job is to read raw, messy OCR text from a food ingredient label, fix any OCR spelling mistakes (e.g., "Citrc Acld" -> "Citric Acid"), and classify every ingredient strictly into the provided JSON schema.
CRITICAL INSTRUCTION: DO NOT HALLUCINATE INGREDIENTS. If an ingredient is not explicitly listed in the raw OCR text, DO NOT add it to the JSON output.
PARENTHETICAL RULE: When an ingredient lists sub-types in parentheses (e.g., "VEGETABLE OIL (CANOLA, CORN, SOYBEAN, AND/OR SUNFLOWER OIL)"), treat the WHOLE thing as ONE ingredient ("Vegetable Oil"). Do NOT list the sub-types as separate ingredients.
Do NOT output any markdown, conversational text, or explanations. ONLY output raw, valid JSON.

CLASSIFICATION RULES:
1. natural_ingredients: Basic culinary ingredients (e.g., salt, water, yeast, spices, natural flavors).
2. whole_food_ingredients: Unprocessed or minimally processed whole foods (e.g., whole wheat flour, oats, milk, eggs, apples).
3. additives: Emulsifiers, thickeners, stabilizers, and texturizers (e.g., soy lecithin, xanthan gum, guar gum, carrageenan).
4. artificial_colors: Synthetic dyes (e.g., Red 40, Yellow 5, Blue 1).
5. artificial_sweeteners: Synthetic zero-calorie sweeteners (e.g., aspartame, sucralose, acesulfame potassium, saccharin).
6. preservatives: Chemicals added to extend shelf life (e.g., sodium benzoate, potassium sorbate, BHT, calcium propionate).
7. high_risk_ingredients: Ingredients known to have severe health concerns or heavy processing. IMPORTANT: Standard cooking oils (vegetable oil, canola oil, corn oil, sunflower oil, soybean oil, coconut oil, olive oil) are NOT high risk — put them in natural_ingredients. Only flag as high_risk if truly dangerous: partially hydrogenated oils, high fructose corn syrup, titanium dioxide, artificial flavors, brominated vegetable oil.
8. product_claims: Extract any marketing or health claims printed on the label (e.g., "Gluten Free", "Non-GMO", "Vegan", "Organic", "No added sugar", "Zero Trans Fat", "Keto Friendly"). If none found, return empty array [].
9. alternative_products: Suggest 3 specific healthier generic or brand-name product alternatives to whatever food product these ingredients likely belong to. Ensure these alternatives align with the user's dietary profile (if provided). Strongly prioritize healthy, natural alternatives, and specifically recommend well-known healthier Indian products or traditional natural Indian substitutes where applicable.
10. red_alerts: If the user provided a Dietary Profile and an ingredient violates their diet or triggers an allergy, add a prominent warning here (e.g. 'Contains Lactose - Conflicts with Dairy Allergy'). If no conflict, return empty array [].

NUTRITION LEVEL RULES (Based on ingredient order, as ingredients are listed by weight):
- SugarLevel ("Very Low", "Low", "Moderate", "High"): If sugar, corn syrup, or cane juice is in the top 3 ingredients, return "High". If in the top 6, return "Moderate". Otherwise "Low" or "Very Low".
- SodiumLevel ("Low", "Moderate", "High"): If salt/sodium is in the top 5, return "High". If further down, return "Moderate" or "Low".
- ProteinLevel ("Low", "Moderate", "High"): If meat, nuts, whey, or soy protein isolate are in the top 3, return "High".

Schema:
{
  "natural_ingredients": [],
  "whole_food_ingredients": [],
  "additives": [],
  "artificial_colors": [],
  "artificial_sweeteners": [],
  "preservatives": [],
  "high_risk_ingredients": [],
  "product_claims": [],
  "alternative_products": [],
  "red_alerts": [],
  "sugar_level": "Moderate",
  "sodium_level": "Moderate",
  "protein_level": "Moderate"
}`

	if profilePrompt != "" {
		systemPrompt += "\n\n" + profilePrompt
	}

	payload := map[string]interface{}{
		"model": n.Model,
		"messages": []map[string]string{
			{"role": "system", "content": systemPrompt},
			{"role": "user", "content": rawText},
		},
		"temperature": 0.0,
		"max_tokens":  1024,
		"top_p":       0.1,
		"stream":      false,
	}

	jsonPayload, err := json.Marshal(payload)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal payload: %w", err)
	}

	req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonPayload))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Authorization", "Bearer "+n.APIKey)
	req.Header.Set("Accept", "application/json")
	req.Header.Set("Content-Type", "application/json")

	resp, err := n.Client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		bodyBytes, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("API error %d: %s", resp.StatusCode, string(bodyBytes))
	}

	var result struct {
		Choices []struct {
			Message struct {
				Content string `json:"content"`
			} `json:"message"`
		} `json:"choices"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	if len(result.Choices) == 0 {
		return nil, fmt.Errorf("no choices returned from API")
	}

	rawJSONContent := result.Choices[0].Message.Content

	var parsed ParsedIngredients
	if err := json.Unmarshal([]byte(rawJSONContent), &parsed); err != nil {
		return nil, fmt.Errorf("failed to parse AI JSON output: %w. Raw text: %s", err, rawJSONContent)
	}

	return &parsed, nil
}

func (n *NIMClient) AnalyzeText(prompt string) (string, error) {
	url := "https://integrate.api.nvidia.com/v1/chat/completions"

	payload := map[string]interface{}{
		"model": n.Model,
		"messages": []map[string]string{
			{"role": "user", "content": prompt},
		},
		"temperature": 0.7,
		"max_tokens":  150,
		"top_p":       0.9,
		"stream":      false,
	}

	jsonPayload, err := json.Marshal(payload)
	if err != nil {
		return "", fmt.Errorf("failed to marshal payload: %w", err)
	}

	req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonPayload))
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Authorization", "Bearer "+n.APIKey)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "application/json")

	resp, err := n.Client.Do(req)
	if err != nil {
		return "", fmt.Errorf("API request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		bodyBytes, _ := io.ReadAll(resp.Body)
		return "", fmt.Errorf("NVIDIA API returned status: %d, body: %s", resp.StatusCode, string(bodyBytes))
	}

	var result struct {
		Choices []struct {
			Message struct {
				Content string `json:"content"`
			} `json:"message"`
		} `json:"choices"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return "", fmt.Errorf("failed to decode response: %w", err)
	}

	if len(result.Choices) == 0 {
		return "", fmt.Errorf("no choices returned from API")
	}

	return result.Choices[0].Message.Content, nil
}
