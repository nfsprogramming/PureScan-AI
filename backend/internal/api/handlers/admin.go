package handlers

import (
	"context"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/purescanai/backend/internal/db"
)

type Submission struct {
	ID          string `json:"id"`
	Barcode     string `json:"barcode"`
	ProductName string `json:"product_name"`
	Status      string `json:"status"`
	CreatedAt   string `json:"created_at"`
}

// GetSubmissions returns all pending product submissions (Admin only)
func GetSubmissions(c *gin.Context) {
	rows, err := db.Pool.Query(context.Background(),
		`SELECT id, barcode, product_name, status, created_at
		 FROM product_submissions
		 WHERE status = 'pending'
		 ORDER BY created_at DESC`,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch submissions"})
		return
	}
	defer rows.Close()

	submissions := []Submission{}
	for rows.Next() {
		var s Submission
		var createdAtRaw interface{}
		if err := rows.Scan(&s.ID, &s.Barcode, &s.ProductName, &s.Status, &createdAtRaw); err != nil {
			continue
		}
		// Basic parsing or leave it
		s.CreatedAt = "recently"
		submissions = append(submissions, s)
	}

	c.JSON(http.StatusOK, submissions)
}

type ApproveSubmissionReq struct {
	ProductName string `json:"product_name"` // Allowed to be edited
}

// ApproveSubmission officially adds the product to the database
func ApproveSubmission(c *gin.Context) {
	id := c.Param("id")

	var req ApproveSubmissionReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request format"})
		return
	}

	// Begin transaction
	ctx := context.Background()
	tx, err := db.Pool.Begin(ctx)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}
	defer tx.Rollback(ctx)

	// Fetch barcode and ingredients_text from submission
	var barcode string
	var ingredientsText *string
	err = tx.QueryRow(ctx, "SELECT barcode, ingredients_text FROM product_submissions WHERE id = $1 AND status = 'pending'", id).Scan(&barcode, &ingredientsText)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Submission not found or already processed"})
		return
	}

	// Mark as approved
	_, err = tx.Exec(ctx, "UPDATE product_submissions SET status = 'approved', product_name = $1 WHERE id = $2", req.ProductName, id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update submission"})
		return
	}

	// Insert into official products table
	// We'll give it a default Trust Score of 50 until analyzed
	var newProductID string
	err = tx.QueryRow(ctx,
		`INSERT INTO products (barcode, name, trust_score, ingredients_text)
		 VALUES ($1, $2, 50, $3)
		 ON CONFLICT (barcode) DO UPDATE SET name = EXCLUDED.name, ingredients_text = EXCLUDED.ingredients_text
		 RETURNING id`,
		barcode, req.ProductName, ingredientsText,
	).Scan(&newProductID)
	
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to add product"})
		return
	}

	tx.Commit(ctx)

	// Sync to Meilisearch
	if db.MeiliClient != nil {
		doc := map[string]interface{}{
			"id":      newProductID,
			"name":    req.ProductName,
			"barcode": barcode,
		}
		_, meiliErr := db.MeiliClient.Index("products").AddDocuments(doc, nil)
		if meiliErr != nil {
			// Just log the error, don't fail the API request
			c.Error(meiliErr)
		}
	}

	c.JSON(http.StatusOK, gin.H{"message": "Submission approved and product added"})
}

// RejectSubmission rejects a contribution
func RejectSubmission(c *gin.Context) {
	id := c.Param("id")

	_, err := db.Pool.Exec(context.Background(),
		"UPDATE product_submissions SET status = 'rejected' WHERE id = $1", id,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to reject submission"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Submission rejected"})
}

type DashboardStats struct {
	TotalProducts      int `json:"total_products"`
	TotalScans         int `json:"total_scans"`
	PendingSubmissions int `json:"pending_submissions"`
	ApprovedProducts   int `json:"approved_products"`
	RejectedProducts   int `json:"rejected_products"`
}

func GetDashboardStats(c *gin.Context) {
	ctx := context.Background()
	var stats DashboardStats

	if err := db.Pool.QueryRow(ctx, "SELECT count(*) FROM products").Scan(&stats.TotalProducts); err != nil {
		log.Printf("Error fetching products count: %v", err)
	}
	if err := db.Pool.QueryRow(ctx, "SELECT count(*) FROM scan_history").Scan(&stats.TotalScans); err != nil {
		log.Printf("Error fetching scan history count: %v", err)
	}
	if err := db.Pool.QueryRow(ctx, "SELECT count(*) FROM product_submissions WHERE status = 'pending'").Scan(&stats.PendingSubmissions); err != nil {
		log.Printf("Error fetching pending submissions count: %v", err)
	}
	if err := db.Pool.QueryRow(ctx, "SELECT count(*) FROM product_submissions WHERE status = 'approved'").Scan(&stats.ApprovedProducts); err != nil {
		log.Printf("Error fetching approved submissions count: %v", err)
	}
	if err := db.Pool.QueryRow(ctx, "SELECT count(*) FROM product_submissions WHERE status = 'rejected'").Scan(&stats.RejectedProducts); err != nil {
		log.Printf("Error fetching rejected submissions count: %v", err)
	}

	c.JSON(http.StatusOK, stats)
}
