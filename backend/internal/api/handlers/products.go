package handlers

import (
	"context"
	"net/http"
	"regexp"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/purescanai/backend/internal/db"
)

type UpsertProductRequest struct {
	Barcode         string `json:"barcode"`
	ProductName     string `json:"product_name" binding:"required"`
	BrandName       string `json:"brand_name"`
	IngredientsText string `json:"ingredients_text"`
	ReportJSON      string `json:"report_json"`
}

func normalize(input string) string {
	input = strings.ToLower(strings.TrimSpace(input))
	re := regexp.MustCompile(`\s+`)
	input = re.ReplaceAllString(input, " ")
	input = strings.ReplaceAll(input, "'", "")
	input = strings.ReplaceAll(input, ",", "")
	return input
}

// UpsertProduct creates or updates a product
func UpsertProduct(c *gin.Context) {
	var req UpsertProductRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request payload"})
		return
	}

	var fingerprint string
	if req.Barcode != "" && !strings.HasPrefix(req.Barcode, "manual_") {
		fingerprint = req.Barcode
	} else {
		fingerprint = normalize(req.BrandName) + "|" + normalize(req.ProductName)
	}

	// Make sure barcode isn't completely empty when inserting to db
	barcode := req.Barcode
	if barcode == "" {
		barcode = "manual_" + uuid.New().String()
	}

	var productID string
	var created bool
	
	ctx := context.Background()
	
	// Ensure brand exists if provided
	var brandID *string
	if req.BrandName != "" {
		var id string
		err := db.Pool.QueryRow(ctx, 
			`INSERT INTO brands (id, name) VALUES ($1, $2) ON CONFLICT (name) DO UPDATE SET name = EXCLUDED.name RETURNING id`, 
			uuid.New().String(), req.BrandName).Scan(&id)
		if err == nil {
			brandID = &id
		}
	}

	// Try to insert or update
	err := db.Pool.QueryRow(ctx, `
		INSERT INTO products (id, barcode, name, brand_id, fingerprint, ingredients_text, trust_score)
		VALUES ($1, $2, $3, $4, $5, $6, 50)
		ON CONFLICT (fingerprint) DO UPDATE 
		SET name = EXCLUDED.name, ingredients_text = EXCLUDED.ingredients_text
		RETURNING id, (xmax = 0) AS inserted
	`, uuid.New().String(), barcode, req.ProductName, brandID, fingerprint, req.IngredientsText).Scan(&productID, &created)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error", "details": err.Error()})
		return
	}

	// Push to meilisearch if it's available
	if db.MeiliClient != nil {
		doc := map[string]interface{}{
			"id":      productID,
			"name":    req.ProductName,
			"barcode": barcode,
		}
		_, _ = db.MeiliClient.Index("products").AddDocuments([]map[string]interface{}{doc}, nil)
	}

	c.JSON(http.StatusOK, gin.H{
		"product_id": productID,
		"created":    created,
		"existing":   !created,
	})
}

// GetCommunityProducts returns a paginated list of products for the community hub
func GetCommunityProducts(c *gin.Context) {
	pageStr := c.DefaultQuery("page", "1")
	limitStr := c.DefaultQuery("limit", "20")

	page, _ := strconv.Atoi(pageStr)
	limit, _ := strconv.Atoi(limitStr)
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 50 {
		limit = 20
	}
	offset := (page - 1) * limit

	ctx := context.Background()
	rows, err := db.Pool.Query(ctx, `
		SELECT p.id, p.barcode, p.name, p.trust_score, p.ingredients_text, b.name as brand_name
		FROM products p
		LEFT JOIN brands b ON p.brand_id = b.id
		ORDER BY p.created_at DESC
		LIMIT $1 OFFSET $2
	`, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch products"})
		return
	}
	defer rows.Close()

	var results []map[string]interface{}
	for rows.Next() {
		var id, barcode, name, ingredientsText string
		var trustScore int
		var brandName *string

		if err := rows.Scan(&id, &barcode, &name, &trustScore, &ingredientsText, &brandName); err != nil {
			continue
		}
		
		item := map[string]interface{}{
			"id": id,
			"barcode": barcode,
			"name": name,
			"trust_score": trustScore,
			"ingredients_text": ingredientsText,
		}
		if brandName != nil {
			item["brand_name"] = *brandName
		}
		results = append(results, item)
	}
	if results == nil {
		results = make([]map[string]interface{}, 0)
	}

	c.JSON(http.StatusOK, gin.H{
		"data":  results,
		"page":  page,
		"limit": limit,
	})
}
