package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/joho/godotenv"
	"google.golang.org/api/option"
)

func main() {
	err := godotenv.Load("../../.env")
	if err != nil {
		log.Println("No .env file found, relying on environment variables")
	}

	dbUrl := os.Getenv("DATABASE_URL")
	if dbUrl == "" {
		log.Fatal("DATABASE_URL is not set")
	}

	ctx := context.Background()
	
	// Init DB Pool
	pool, err := pgxpool.New(ctx, dbUrl)
	if err != nil {
		log.Fatalf("Unable to connect to database: %v\n", err)
	}
	defer pool.Close()

	// Init Firebase
	credentialsJSON := os.Getenv("FIREBASE_SERVICE_ACCOUNT_JSON")
	if credentialsJSON == "" {
		log.Fatal("FIREBASE_SERVICE_ACCOUNT_JSON is not set.")
	}
	opt := option.WithCredentialsJSON([]byte(credentialsJSON))
	app, err := firebase.NewApp(ctx, nil, opt)
	if err != nil {
		log.Fatalf("Error initializing Firebase app: %v\n", err)
	}
	fcmClient, err := app.Messaging(ctx)
	if err != nil {
		log.Fatalf("Error getting Firebase Messaging client: %v\n", err)
	}

	log.Println("Starting Daily Digest Process...")

	// Find users with daily_digest_enabled = true and a valid fcm_token
	rows, err := pool.Query(ctx, `
		SELECT up.user_id, u.fcm_token
		FROM public.user_preferences up
		JOIN public.users u ON up.user_id = u.id
		WHERE up.daily_digest_enabled = true 
		AND u.fcm_token IS NOT NULL 
		AND u.fcm_token != ''
	`)
	if err != nil {
		log.Fatalf("Query error: %v", err)
	}
	defer rows.Close()

	now := time.Now()
	yesterday := now.AddDate(0, 0, -1)

	userCount := 0
	for rows.Next() {
		var userID string
		var fcmToken string
		if err := rows.Scan(&userID, &fcmToken); err != nil {
			log.Printf("Row scan error: %v", err)
			continue
		}

		// Count user's scans in the last 24 hours
		var scanCount int
		err = pool.QueryRow(ctx, `
			SELECT COUNT(*) 
			FROM public.scan_history 
			WHERE user_id = $1 AND scanned_at >= $2
		`, userID, yesterday).Scan(&scanCount)

		if err != nil {
			log.Printf("Failed to fetch scans for user %s: %v", userID, err)
			continue
		}

		// Skip users who didn't scan anything
		if scanCount == 0 {
			continue
		}

		// Send FCM Push
		body := fmt.Sprintf("You analyzed %d products yesterday. Tap to see your insights!", scanCount)
		message := &messaging.Message{
			Notification: &messaging.Notification{
				Title: "Your Daily Digest is Ready 📊",
				Body:  body,
			},
			Data: map[string]string{
				"route": "/daily-digest",
			},
			Token: fcmToken,
		}

		_, err = fcmClient.Send(ctx, message)
		if err != nil {
			log.Printf("Failed to send daily digest to user %s: %v", userID, err)
		} else {
			log.Printf("Sent daily digest to user %s", userID)
		}
		userCount++
	}

	log.Printf("Daily digest processing complete. Sent %d notifications.", userCount)
}
