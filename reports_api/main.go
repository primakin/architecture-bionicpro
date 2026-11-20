package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/ClickHouse/clickhouse-go/v2"
	"github.com/ClickHouse/clickhouse-go/v2/lib/driver"
	"github.com/MicahParks/keyfunc/v3"
	"github.com/golang-jwt/jwt/v5"
)

// Event — структура события из ClickHouse
type Event struct {
	UserID      uint64    `json:"user_id"`
	TelemetryID uint64    `json:"telemetry_id"`
	DeviceID    uint64    `json:"device_id"`
	Username    string    `json:"username"`
	FullName    string    `json:"full_name"`
	Email       string    `json:"email"`
	Phone       string    `json:"phone"`
	EventTime   time.Time `json:"event_time"`
	Payload     string    `json:"payload"`
}

// KeycloakClaims — claims, которые нас интересуют в токене
type KeycloakClaims struct {
	Sub               string `json:"sub"`
	PreferredUsername string `json:"preferred_username"`
	Email             string `json:"email"`
	jwt.RegisteredClaims
}

type Config struct {
	KeycloakURL    string
	KeycloakRealm  string
	ClientID       string
	ClickHouseAddr string
	ClickHouseDB   string
	ClickHouseUser string
	ClickHousePass string
	AllowedOrigins string
}

func main() {
	cfg := Config{
		KeycloakURL:    getEnv("KEYCLOAK_URL", "http://keycloak:8080"),
		KeycloakRealm:  getEnv("KEYCLOAK_REALM", "reports-realm"),
		ClientID:       getEnv("KEYCLOAK_CLIENT_ID", "reports-api"),
		ClickHouseAddr: getEnv("CLICKHOUSE_ADDR", "reports_db:9000"),
		ClickHouseDB:   getEnv("CLICKHOUSE_DB", "report_db"),
		ClickHouseUser: getEnv("CLICKHOUSE_USER", "report_user"),
		ClickHousePass: getEnv("CLICKHOUSE_PASS", "report_password"),
		AllowedOrigins: getEnv("CORS_ALLOWED_ORIGINS", "*"),
	}

	// ---- Инициализация JWKS ----
	jwksURL := fmt.Sprintf("%s/realms/%s/protocol/openid-connect/certs",
		strings.TrimRight(cfg.KeycloakURL, "/"), cfg.KeycloakRealm)
	log.Printf("Loading JWKS from: %s", jwksURL)

	jwks, err := keyfunc.NewDefaultCtx(context.Background(), []string{jwksURL})
	if err != nil {
		log.Fatalf("Failed to create JWKS keyfunc: %v", err)
	}

	// ---- ClickHouse ----
	chConn, err := clickhouse.Open(&clickhouse.Options{
		Addr: []string{cfg.ClickHouseAddr},
		Auth: clickhouse.Auth{
			Database: cfg.ClickHouseDB,
			Username: cfg.ClickHouseUser,
			Password: cfg.ClickHousePass,
		},
		Settings: clickhouse.Settings{
			"output_format_native_write_json_as_string": 1,
		},
	})
	if err != nil {
		log.Fatalf("Failed to connect to ClickHouse: %v", err)
	}
	defer chConn.Close()

	// ---- HTTP ----
	mux := http.NewServeMux()
	mux.HandleFunc("/reports", func(w http.ResponseWriter, r *http.Request) {
		origin := r.Header.Get("Origin")
		if origin != "" && isOriginAllowed(origin, cfg.AllowedOrigins) {
			setCORSHeaders(w, origin)
		}

		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}

		if r.Method != http.MethodGet {
			w.Header().Set("Allow", "GET, OPTIONS")
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}

		authHeader := r.Header.Get("Authorization")
		if !strings.HasPrefix(authHeader, "Bearer ") {
			http.Error(w, "Missing or invalid Authorization header", http.StatusUnauthorized)
			return
		}
		tokenString := strings.TrimSpace(strings.TrimPrefix(authHeader, "Bearer "))

		// ---- Локальная валидация JWT через JWKS ----
		claims := &KeycloakClaims{}
		token, err := jwt.ParseWithClaims(tokenString, claims, jwks.Keyfunc,
			jwt.WithExpirationRequired(),
		)
		if err != nil || !token.Valid {
			log.Printf("JWT signature validation failed: %v", err)
			http.Error(w, "Unauthorized", http.StatusUnauthorized)
			return
		}

		userID := claims.PreferredUsername
		if userID == "" {
			http.Error(w, "Invalid token: missing PreferredUsername claim", http.StatusUnauthorized)
			return
		}

		events, err := getUserEvents(r.Context(), chConn, userID)
		if err != nil {
			log.Printf("ClickHouse query error: %v", err)
			http.Error(w, "Internal server error", http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(events)
	})

	log.Println("Reports service listening on :8000")
	if err := http.ListenAndServe(":8000", mux); err != nil {
		log.Fatal(err)
	}
}

func setCORSHeaders(w http.ResponseWriter, origin string) {
	w.Header().Set("Access-Control-Allow-Origin", origin)
	w.Header().Set("Vary", "Origin")
	w.Header().Set("Access-Control-Allow-Methods", "GET, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Authorization, Content-Type")
	w.Header().Set("Access-Control-Max-Age", "86400")
}

func isOriginAllowed(origin, allowed string) bool {
	if allowed == "*" {
		return true
	}
	for _, o := range strings.Split(allowed, ",") {
		if strings.TrimSpace(o) == origin {
			return true
		}
	}
	return false
}

func getUserEvents(ctx context.Context, conn driver.Conn, userID string) ([]Event, error) {
	log.Printf("getUserEvents for %s", userID)

	query := `
		SELECT user_id, telemetry_id, device_id, username, full_name, email, phone, event_time, payload
		FROM user_events FINAL
		WHERE username = @username
		ORDER BY event_time DESC
		LIMIT 100
	`
	rows, err := conn.Query(ctx, query, clickhouse.Named("username", userID))

	if err != nil {
		log.Println(err.Error())
		log.Println(err)
		return nil, err
	}
	defer rows.Close()

	var events []Event
	for rows.Next() {
		var e Event
		if err := rows.Scan(
			&e.UserID,
			&e.TelemetryID,
			&e.DeviceID,
			&e.Username,
			&e.FullName,
			&e.Email,
			&e.Phone,
			&e.EventTime,
			&e.Payload); err != nil {
			return nil, err
		}
		events = append(events, e)
		log.Println(e)
	}
	return events, rows.Err()
}

func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}
