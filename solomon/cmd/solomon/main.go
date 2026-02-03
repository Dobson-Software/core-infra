package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/cobalt/solomon/internal/api"
	"github.com/cobalt/solomon/internal/config"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
)

var (
	version   = "dev"
	commit    = "unknown"
	buildTime = "unknown"
)

func main() {
	// Initialize logger
	zerolog.TimeFieldFormat = zerolog.TimeFormatUnix
	if os.Getenv("SOLOMON_ENV") != "production" {
		log.Logger = log.Output(zerolog.ConsoleWriter{Out: os.Stderr})
	}

	log.Info().
		Str("version", version).
		Str("commit", commit).
		Str("build_time", buildTime).
		Msg("Starting Solomon Platform Control Plane")

	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		log.Fatal().Err(err).Msg("Failed to load configuration")
	}

	// Initialize API server
	server, err := api.NewServer(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("Failed to initialize API server")
	}

	// Create HTTP server
	httpServer := &http.Server{
		Addr:         fmt.Sprintf(":%d", cfg.Server.Port),
		Handler:      server.Router(),
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Start server in goroutine
	go func() {
		log.Info().Int("port", cfg.Server.Port).Msg("Starting HTTP server")
		if err := httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal().Err(err).Msg("HTTP server failed")
		}
	}()

	// Wait for interrupt signal
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Info().Msg("Shutting down server...")

	// Graceful shutdown with timeout
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := httpServer.Shutdown(ctx); err != nil {
		log.Error().Err(err).Msg("Server forced to shutdown")
	}

	// Cleanup resources
	if err := server.Close(); err != nil {
		log.Error().Err(err).Msg("Error closing server resources")
	}

	log.Info().Msg("Server stopped")
}
