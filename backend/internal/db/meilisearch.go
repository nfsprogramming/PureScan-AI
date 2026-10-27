package db

import (
	"log"
	"os"

	"github.com/meilisearch/meilisearch-go"
)

var MeiliClient meilisearch.ServiceManager

func InitMeilisearch() {
	host := os.Getenv("MEILI_HOST")
	if host == "" {
		host = "http://localhost:7700"
	}

	key := os.Getenv("MEILI_MASTER_KEY")
	if key == "" {
		key = "purescan_super_secret_master_key"
	}

	MeiliClient = meilisearch.New(host, meilisearch.WithAPIKey(key))

	// Ensure the products index exists
	_, err := MeiliClient.GetIndex("products")
	if err != nil {
		// Index doesn't exist, create it
		_, err = MeiliClient.CreateIndex(&meilisearch.IndexConfig{
			Uid:        "products",
			PrimaryKey: "id",
		})
		if err != nil {
			log.Printf("Failed to create Meilisearch index: %v", err)
			return
		}
	}

	// Make name, brand, barcode searchable
	_, err = MeiliClient.Index("products").UpdateSearchableAttributes(&[]string{
		"name",
		"brand",
		"barcode",
	})
	if err != nil {
		log.Printf("Failed to update searchable attributes: %v", err)
	}

	log.Println("Meilisearch client initialized")
}
