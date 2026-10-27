package services

import (
	"context"
	"fmt"
	"log"
	"os"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"google.golang.org/api/option"
	"github.com/purescanai/backend/internal/db"
)

var fcmClient *messaging.Client

// InitFirebase initializes the Firebase Admin SDK
func InitFirebase() {
	var opt option.ClientOption

	credentialsPath := os.Getenv("FIREBASE_CREDENTIALS_PATH")
	credentialsJSON := os.Getenv("FIREBASE_SERVICE_ACCOUNT_JSON")

	if credentialsPath != "" {
		opt = option.WithCredentialsFile(credentialsPath)
	} else if credentialsJSON != "" {
		opt = option.WithCredentialsJSON([]byte(credentialsJSON))
	} else {
		log.Println("Neither FIREBASE_CREDENTIALS_PATH nor FIREBASE_SERVICE_ACCOUNT_JSON is set. Push notifications will be disabled.")
		return
	}
	app, err := firebase.NewApp(context.Background(), nil, opt)
	if err != nil {
		log.Printf("Error initializing Firebase app: %v\n", err)
		return
	}

	client, err := app.Messaging(context.Background())
	if err != nil {
		log.Printf("Error getting Firebase Messaging client: %v\n", err)
		return
	}

	fcmClient = client
	log.Println("Successfully initialized Firebase Cloud Messaging!")
}

// SendRealTimeAlert checks if the user has alerts enabled and sends an FCM push
func SendRealTimeAlert(ctx context.Context, userID string, productName string, risks []string) {
	if fcmClient == nil {
		return
	}

	// Fetch user preferences and token
	var alertsEnabled bool
	var fcmToken *string
	
	err := db.Pool.QueryRow(ctx, `
		SELECT up.alerts_enabled, u.fcm_token 
		FROM public.user_preferences up
		JOIN public.users u ON up.user_id = u.id
		WHERE up.user_id = $1
	`, userID).Scan(&alertsEnabled, &fcmToken)

	if err != nil || !alertsEnabled || fcmToken == nil || *fcmToken == "" {
		return
	}

	// Prepare message
	body := fmt.Sprintf("We detected health risks in %s.", productName)
	if len(risks) > 0 {
		body = fmt.Sprintf("Warning! %s contains: %s", productName, risks[0])
	}

	message := &messaging.Message{
		Notification: &messaging.Notification{
			Title: "Critical Ingredient Alert 🚨",
			Body:  body,
		},
		Token: *fcmToken,
	}

	_, err = fcmClient.Send(ctx, message)
	if err != nil {
		log.Printf("Failed to send real-time alert to user %s: %v", userID, err)
	} else {
		log.Printf("Sent real-time alert to user %s", userID)
	}
}

// SendAdminCommunityRequestNotification sends an FCM message to all admins when a new community request is submitted
func SendAdminCommunityRequestNotification(ctx context.Context, requestID, userName, productName, barcode, userID string) {
	if fcmClient == nil {
		return
	}

	rows, err := db.Pool.Query(ctx, "SELECT u.fcm_token FROM users u JOIN admins a ON u.id = a.user_id WHERE u.fcm_token IS NOT NULL AND u.fcm_token != ''")
	if err != nil {
		log.Println("Error fetching admin fcm tokens:", err)
		return
	}
	defer rows.Close()

	var tokens []string
	for rows.Next() {
		var token string
		if err := rows.Scan(&token); err == nil && token != "" {
			tokens = append(tokens, token)
		}
	}

	if len(tokens) == 0 {
		return
	}

	message := &messaging.MulticastMessage{
		Notification: &messaging.Notification{
			Title: "New Database Request",
			Body:  fmt.Sprintf("%s submitted a request for %s.", userName, productName),
		},
		Data: map[string]string{
			"notificationType": "COMMUNITY_REQUEST",
			"requestId":        requestID,
			"productName":      productName,
			"barcode":          barcode,
			"userId":           userID,
			"route":            "/admin?requestId=" + requestID,
		},
		Tokens: tokens,
	}

	response, err := fcmClient.SendEachForMulticast(ctx, message)
	if err != nil {
		log.Printf("Failed to send admin notification: %v\n", err)
	} else {
		log.Printf("Sent admin notifications. Success: %d, Failures: %d\n", response.SuccessCount, response.FailureCount)
	}
}
