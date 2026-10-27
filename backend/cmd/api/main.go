package main

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"github.com/purescanai/backend/internal/api/handlers"
	"github.com/purescanai/backend/internal/api/middleware"
	"github.com/purescanai/backend/internal/db"
	"github.com/purescanai/backend/internal/services"
)

func main() {
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using environment variables")
	}

	db.InitDB()
	defer db.CloseDB()

	db.InitMeilisearch()
	services.InitFirebase()

	r := gin.Default()

	// Public routes
	r.GET("/", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"message": "Welcome to PureScan AI API",
			"docs":    "Visit /health for status",
		})
	})

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "healthy",
			"message": "PureScan AI backend is running",
		})
	})
	r.GET("/api/v1/search", handlers.SearchProducts)

	// Protected routes (require Supabase JWT)
	api := r.Group("/api/v1")
	api.Use(middleware.SupabaseAuth())
	{
		api.GET("/profile", func(c *gin.Context) {
			userID, _ := c.Get("user_id")

			var count int
			_ = db.Pool.QueryRow(c.Request.Context(), "SELECT count(*) FROM admins WHERE user_id = $1", userID).Scan(&count)
			isAdmin := count > 0

			c.JSON(http.StatusOK, gin.H{
				"message": "This is a protected route!",
				"user_id": userID,
				"is_admin": isAdmin,
			})
		})

		// Profile Preferences
		api.GET("/profile/preferences", handlers.GetDietaryPreferences)
		api.PUT("/profile/preferences", handlers.UpdateDietaryPreferences)
		
		api.GET("/user/summary/weekly", handlers.GetWeeklySummary)

		// Scanner endpoints
		scanGroup := api.Group("/scan")
		{
			scanGroup.POST("/barcode", handlers.HandleBarcodeScan)
			scanGroup.POST("/ocr", handlers.HandleOcrScan)
		}

		// Contribution
		api.POST("/contribute", handlers.SubmitContribution)

		// Products API (Public Read / Admin Write)
		// Removed public UpsertProduct
		
		api.GET("/community/products", handlers.GetCommunityProducts)

		// Admin routes
		adminGroup := api.Group("/admin")
		adminGroup.Use(middleware.SupabaseAuth(), middleware.AdminAuth())
		{
			adminGroup.GET("/stats", handlers.GetDashboardStats)
			adminGroup.GET("/submissions", handlers.GetSubmissions)
			adminGroup.POST("/submissions/:id/approve", handlers.ApproveSubmission)
			adminGroup.POST("/submissions/:id/reject", handlers.RejectSubmission)
			adminGroup.POST("/products", handlers.UpsertProduct)
		}
	}

	log.Println("Starting PureScan AI backend on :8080")
	if err := r.Run(":8080"); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
