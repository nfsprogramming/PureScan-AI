package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/meilisearch/meilisearch-go"
	"github.com/purescanai/backend/internal/db"
)

// SearchProducts queries Meilisearch for matching products
func SearchProducts(c *gin.Context) {
	query := c.Query("q")
	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Missing search query 'q'"})
		return
	}

	if db.MeiliClient == nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Search engine not configured"})
		return
	}

	searchRes, err := db.MeiliClient.Index("products").Search(query, &meilisearch.SearchRequest{
		Limit: 20,
	})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to query search engine"})
		return
	}

	// Option B: Proxy Search
	// Instead of just returning IDs, we can just return the Meilisearch hits directly
	// because they already contain "id", "name", and "barcode". The mobile app can use this
	// to display the search results list, and then query Supabase by ID when the user clicks a specific product.
	
	c.JSON(http.StatusOK, searchRes.Hits)
}
