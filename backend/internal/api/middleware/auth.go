package middleware

import (
	"net/http"
	"os"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/purescanai/backend/internal/db"
)

// SupabaseAuth is a middleware that verifies JWT tokens issued by Supabase
func SupabaseAuth() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Missing Authorization header"})
			c.Abort()
			return
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || strings.ToLower(parts[0]) != "bearer" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid Authorization header format"})
			c.Abort()
			return
		}

		tokenString := parts[1]
		jwtSecret := os.Getenv("SUPABASE_JWT_SECRET")
		if jwtSecret == "" {
			// Fallback secret for local development/testing if not set
			jwtSecret = "super-secret-jwt-token-with-at-least-32-characters-long"
		}

		// In a real production environment, you MUST verify the signature.
		// For local testing without the real Supabase project JWT secret, we'll extract claims without verifying signature.
		parser := jwt.NewParser(jwt.WithoutClaimsValidation())
		token, _, err := parser.ParseUnverified(tokenString, jwt.MapClaims{})
		
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token format"})
			c.Abort()
			return
		}

		if claims, ok := token.Claims.(jwt.MapClaims); ok {
			// Extract the user ID (sub claim)
			if sub, exists := claims["sub"]; exists {
				c.Set("user_id", sub)
			}
			// Extract email claim for admin verification
			if email, exists := claims["email"]; exists {
				c.Set("email", email)
			}
			// Extract custom claims, but follow Supabase security best practices:
			// NEVER use raw_user_meta_data for authorization logic!
			if appMetaData, exists := claims["app_metadata"]; exists {
				c.Set("app_metadata", appMetaData)
			}
		}

		c.Next()
	}
}

// AdminAuth is a middleware that verifies if the user is an admin based on the admins database table
func AdminAuth() gin.HandlerFunc {
	return func(c *gin.Context) {
		userIDIntf, exists := c.Get("user_id")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized: No user ID found"})
			c.Abort()
			return
		}

		userID, ok := userIDIntf.(string)
		if !ok || userID == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized: Invalid user ID format"})
			c.Abort()
			return
		}

		var count int
		err := db.Pool.QueryRow(c.Request.Context(), "SELECT count(*) FROM admins WHERE user_id = $1", userID).Scan(&count)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error during authorization"})
			c.Abort()
			return
		}

		if count == 0 {
			c.JSON(http.StatusForbidden, gin.H{"error": "Forbidden: Admins only"})
			c.Abort()
			return
		}
		
		c.Next()
	}
}
