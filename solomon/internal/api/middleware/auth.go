package middleware

import (
	"context"
	"net/http"
	"strings"

	"github.com/cobalt/solomon/internal/config"
	"github.com/rs/zerolog/log"
)

type contextKey string

const (
	UserContextKey contextKey = "user"
)

type User struct {
	ID          string   `json:"id"`
	Email       string   `json:"email"`
	Name        string   `json:"name"`
	Roles       []string `json:"roles"`
	Permissions []string `json:"permissions"`
}

func Auth(cfg config.AuthConfig) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			authHeader := r.Header.Get("Authorization")
			if authHeader == "" {
				http.Error(w, `{"error":"missing authorization header"}`, http.StatusUnauthorized)
				return
			}

			parts := strings.SplitN(authHeader, " ", 2)
			if len(parts) != 2 || parts[0] != "Bearer" {
				http.Error(w, `{"error":"invalid authorization header"}`, http.StatusUnauthorized)
				return
			}

			token := parts[1]

			// TODO: Implement proper JWT/OIDC validation
			// For now, accept any token in development
			user, err := validateToken(token, cfg)
			if err != nil {
				log.Warn().Err(err).Msg("Token validation failed")
				http.Error(w, `{"error":"invalid token"}`, http.StatusUnauthorized)
				return
			}

			// Add user to context
			ctx := context.WithValue(r.Context(), UserContextKey, user)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

func validateToken(token string, cfg config.AuthConfig) (*User, error) {
	// TODO: Implement proper OIDC token validation
	// This is a placeholder for development
	return &User{
		ID:          "dev-user",
		Email:       "dev@cobaltplatform.com",
		Name:        "Dev User",
		Roles:       []string{"admin"},
		Permissions: []string{"*"},
	}, nil
}

func RequireRole(roles ...string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			user, ok := r.Context().Value(UserContextKey).(*User)
			if !ok {
				http.Error(w, `{"error":"unauthorized"}`, http.StatusUnauthorized)
				return
			}

			hasRole := false
			for _, required := range roles {
				for _, userRole := range user.Roles {
					if userRole == required || userRole == "admin" {
						hasRole = true
						break
					}
				}
				if hasRole {
					break
				}
			}

			if !hasRole {
				http.Error(w, `{"error":"forbidden"}`, http.StatusForbidden)
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}

func GetUser(ctx context.Context) *User {
	user, _ := ctx.Value(UserContextKey).(*User)
	return user
}

func WebhookAuth(cfg *config.Config) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			// Webhook authentication varies by source
			// GitHub uses X-Hub-Signature-256
			// PagerDuty uses webhook secret in body
			// ArgoCD uses bearer token

			// TODO: Implement proper webhook signature verification
			next.ServeHTTP(w, r)
		})
	}
}
