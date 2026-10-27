package handlers

import (
	"context"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/purescanai/backend/internal/db"
	"github.com/purescanai/backend/internal/services"
)

type ContributionRequest struct {
	Barcode         string `json:"barcode" binding:"required"`
	ProductName     string `json:"product_name" binding:"required"`
	BrandName       string `json:"brand_name"`
	IngredientsText string `json:"ingredients_text"`
	ReportJSON      string `json:"report_json"`
}

// SubmitContribution allows a consumer to submit an unknown product
func SubmitContribution(c *gin.Context) {
	var req ContributionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request format"})
		return
	}

	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}
	userIDStr, ok := userID.(string)
	if !ok {
		userIDStr = "unknown"
	}

	ctx := context.Background()

	// Check if user is admin
	var count int
	_ = db.Pool.QueryRow(ctx, "SELECT count(*) FROM admins WHERE user_id = $1", userIDStr).Scan(&count)
	isAdmin := count > 0

	// Normal User Flow
	if !isAdmin {
		var requestID string
		err := db.Pool.QueryRow(ctx,
			`INSERT INTO product_submissions (barcode, product_name, brand_name, ingredients_text, report_json, user_id, status)
			 VALUES ($1, $2, $3, $4, $5, $6, 'pending') RETURNING id`,
			req.Barcode, req.ProductName, req.BrandName, req.IngredientsText, req.ReportJSON, userIDStr,
		).Scan(&requestID)

		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to submit contribution"})
			return
		}

		var userName string
		_ = db.Pool.QueryRow(ctx, "SELECT full_name FROM users WHERE id = $1", userIDStr).Scan(&userName)
		if userName == "" {
			userName = "A user"
		}

		go services.SendAdminCommunityRequestNotification(context.Background(), requestID, userName, req.ProductName, req.Barcode, userIDStr)

		c.JSON(http.StatusCreated, gin.H{
			"message": "Request sent for admin review.",
			"is_admin": false,
		})
		return
	}

	// Admin User Flow (Direct Publish)
	// Make sure barcode isn't completely empty
	barcode := req.Barcode
	if barcode == "" {
		barcode = "manual_" + uuid.New().String()
	}

	fingerprint := barcode

	// Try to insert brand if provided
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

	var productID string
	err := db.Pool.QueryRow(ctx, `
		INSERT INTO products (id, barcode, name, brand_id, fingerprint, ingredients_text, trust_score)
		VALUES ($1, $2, $3, $4, $5, $6, 50)
		ON CONFLICT (fingerprint) DO UPDATE 
		SET name = EXCLUDED.name, ingredients_text = EXCLUDED.ingredients_text
		RETURNING id
	`, uuid.New().String(), barcode, req.ProductName, brandID, fingerprint, req.IngredientsText).Scan(&productID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error", "details": err.Error()})
		return
	}

	// Log audit
	_, _ = db.Pool.Exec(ctx, `
		INSERT INTO audit_logs (action, entity_id, performed_by, performed_by_role)
		VALUES ('DIRECT_PUBLISH', $1, $2, 'admin')
	`, productID, userIDStr)

	// Push to meilisearch if available
	if db.MeiliClient != nil {
		doc := map[string]interface{}{
			"id":      productID,
			"name":    req.ProductName,
			"barcode": barcode,
		}
		_, _ = db.MeiliClient.Index("products").AddDocuments([]map[string]interface{}{doc}, nil)
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Product published directly to community database.",
		"is_admin": true,
		"product_id": productID,
	})
}
