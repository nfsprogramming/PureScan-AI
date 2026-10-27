package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/purescanai/backend/internal/db"
)

type DietaryPreferences struct {
	Allergies []string `json:"allergies"`
	Diets     []string `json:"diets"`
}

func GetDietaryPreferences(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var prefs DietaryPreferences
	err := db.Pool.QueryRow(
		c.Request.Context(),
		"SELECT allergies, diets FROM user_profiles WHERE user_id = $1",
		userID,
	).Scan(&prefs.Allergies, &prefs.Diets)

	if err != nil {
		// If no profile exists yet, return empty defaults
		prefs = DietaryPreferences{
			Allergies: []string{},
			Diets:     []string{},
		}
	}

	c.JSON(http.StatusOK, prefs)
}

func UpdateDietaryPreferences(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var prefs DietaryPreferences
	if err := c.ShouldBindJSON(&prefs); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	if prefs.Allergies == nil {
		prefs.Allergies = []string{}
	}
	if prefs.Diets == nil {
		prefs.Diets = []string{}
	}

	_, err := db.Pool.Exec(
		c.Request.Context(),
		`INSERT INTO user_profiles (user_id, allergies, diets) 
		 VALUES ($1, $2, $3) 
		 ON CONFLICT (user_id) DO UPDATE 
		 SET allergies = EXCLUDED.allergies, diets = EXCLUDED.diets, updated_at = now()`,
		userID, prefs.Allergies, prefs.Diets,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update preferences"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Preferences updated successfully"})
}
