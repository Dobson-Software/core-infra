package api

import (
	"context"
	"net/http"

	"github.com/cobalt/solomon/internal/api/handlers"
	"github.com/cobalt/solomon/internal/api/middleware"
	"github.com/cobalt/solomon/internal/config"
	"github.com/cobalt/solomon/internal/services/ai"
	"github.com/cobalt/solomon/internal/services/catalog"
	"github.com/cobalt/solomon/internal/services/costs"
	"github.com/cobalt/solomon/internal/services/deploy"
	"github.com/cobalt/solomon/internal/services/incidents"
	"github.com/cobalt/solomon/internal/services/logs"
	"github.com/cobalt/solomon/internal/services/secrets"
	"github.com/go-chi/chi/v5"
	chimiddleware "github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"
)

type Server struct {
	cfg    *config.Config
	router *chi.Mux
	db     *pgxpool.Pool
	redis  *redis.Client

	// Services
	catalogSvc   *catalog.Service
	deploySvc    *deploy.Service
	secretsSvc   *secrets.Service
	costsSvc     *costs.Service
	incidentsSvc *incidents.Service
	logsSvc      *logs.Service
	aiSvc        *ai.Service

	// Handlers
	catalogHandler   *handlers.CatalogHandler
	deployHandler    *handlers.DeployHandler
	secretsHandler   *handlers.SecretsHandler
	costsHandler     *handlers.CostsHandler
	incidentsHandler *handlers.IncidentsHandler
	logsHandler      *handlers.LogsHandler
	aiHandler        *handlers.AIHandler
}

func NewServer(cfg *config.Config) (*Server, error) {
	// Initialize database connection
	dbPool, err := pgxpool.New(context.Background(), cfg.Database.DSN())
	if err != nil {
		return nil, err
	}

	// Initialize Redis connection
	rdb := redis.NewClient(&redis.Options{
		Addr:     cfg.Redis.Addr(),
		Password: cfg.Redis.Password,
		DB:       cfg.Redis.DB,
	})

	// Initialize services
	catalogSvc := catalog.NewService(dbPool, rdb)
	deploySvc := deploy.NewService(dbPool, cfg)
	secretsSvc := secrets.NewService(cfg)
	costsSvc := costs.NewService(dbPool, cfg)
	incidentsSvc := incidents.NewService(dbPool, cfg)
	logsSvc := logs.NewService(cfg)
	aiSvc := ai.NewService(dbPool, cfg, catalogSvc, deploySvc, logsSvc, incidentsSvc)

	// Initialize handlers
	catalogHandler := handlers.NewCatalogHandler(catalogSvc)
	deployHandler := handlers.NewDeployHandler(deploySvc)
	secretsHandler := handlers.NewSecretsHandler(secretsSvc)
	costsHandler := handlers.NewCostsHandler(costsSvc)
	incidentsHandler := handlers.NewIncidentsHandler(incidentsSvc)
	logsHandler := handlers.NewLogsHandler(logsSvc)
	aiHandler := handlers.NewAIHandler(aiSvc)

	s := &Server{
		cfg:              cfg,
		db:               dbPool,
		redis:            rdb,
		catalogSvc:       catalogSvc,
		deploySvc:        deploySvc,
		secretsSvc:       secretsSvc,
		costsSvc:         costsSvc,
		incidentsSvc:     incidentsSvc,
		logsSvc:          logsSvc,
		aiSvc:            aiSvc,
		catalogHandler:   catalogHandler,
		deployHandler:    deployHandler,
		secretsHandler:   secretsHandler,
		costsHandler:     costsHandler,
		incidentsHandler: incidentsHandler,
		logsHandler:      logsHandler,
		aiHandler:        aiHandler,
	}

	s.setupRouter()
	return s, nil
}

func (s *Server) setupRouter() {
	r := chi.NewRouter()

	// Global middleware
	r.Use(chimiddleware.RequestID)
	r.Use(chimiddleware.RealIP)
	r.Use(middleware.Logger)
	r.Use(chimiddleware.Recoverer)
	r.Use(chimiddleware.Compress(5))

	// CORS
	r.Use(cors.Handler(cors.Options{
		AllowedOrigins:   []string{"http://localhost:*", "https://*.cobaltplatform.com"},
		AllowedMethods:   []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type", "X-Request-ID"},
		ExposedHeaders:   []string{"X-Request-ID"},
		AllowCredentials: true,
		MaxAge:           300,
	}))

	// Health check (unauthenticated)
	r.Get("/health", s.healthCheck)
	r.Get("/ready", s.readinessCheck)

	// API routes
	r.Route("/api/v1", func(r chi.Router) {
		// Authentication middleware
		r.Use(middleware.Auth(s.cfg.Auth))

		// Service Catalog
		r.Route("/services", func(r chi.Router) {
			r.Get("/", s.catalogHandler.List)
			r.Post("/", s.catalogHandler.Create)
			r.Get("/{serviceID}", s.catalogHandler.Get)
			r.Put("/{serviceID}", s.catalogHandler.Update)
			r.Delete("/{serviceID}", s.catalogHandler.Delete)
			r.Get("/{serviceID}/environments", s.catalogHandler.ListEnvironments)
			r.Get("/{serviceID}/dependencies", s.catalogHandler.GetDependencies)
			r.Get("/{serviceID}/runbooks", s.catalogHandler.ListRunbooks)
			r.Get("/{serviceID}/health", s.catalogHandler.GetHealth)
		})

		// Deployments
		r.Route("/deployments", func(r chi.Router) {
			r.Get("/", s.deployHandler.List)
			r.Post("/", s.deployHandler.Create)
			r.Get("/{deploymentID}", s.deployHandler.Get)
			r.Post("/{deploymentID}/cancel", s.deployHandler.Cancel)
			r.Get("/history", s.deployHandler.History)
		})

		// Service operations
		r.Post("/services/{serviceID}/rollback", s.deployHandler.Rollback)
		r.Post("/services/{serviceID}/promote", s.deployHandler.Promote)
		r.Post("/services/{serviceID}/scale", s.deployHandler.Scale)
		r.Post("/services/{serviceID}/restart", s.deployHandler.Restart)

		// Secrets
		r.Route("/secrets", func(r chi.Router) {
			r.Use(middleware.RequireRole("operator", "admin"))
			r.Get("/", s.secretsHandler.List)
			r.Get("/expiring", s.secretsHandler.ListExpiring)
			r.Get("/audit", s.secretsHandler.AuditLog)
			r.Route("/{path}", func(r chi.Router) {
				r.Get("/", s.secretsHandler.Get)
				r.Post("/", s.secretsHandler.Create)
				r.Put("/", s.secretsHandler.Update)
				r.Delete("/", s.secretsHandler.Delete)
				r.Post("/rotate", s.secretsHandler.Rotate)
				r.Get("/history", s.secretsHandler.History)
				r.Post("/rollback", s.secretsHandler.Rollback)
			})
		})

		// Costs
		r.Route("/costs", func(r chi.Router) {
			r.Get("/summary", s.costsHandler.Summary)
			r.Get("/environments/{env}", s.costsHandler.ByEnvironment)
			r.Get("/services/{serviceID}", s.costsHandler.ByService)
			r.Get("/forecast", s.costsHandler.Forecast)
			r.Get("/anomalies", s.costsHandler.Anomalies)
			r.Get("/recommendations", s.costsHandler.Recommendations)
			r.Post("/budgets", s.costsHandler.SetBudget)
		})

		// Incidents
		r.Route("/incidents", func(r chi.Router) {
			r.Get("/", s.incidentsHandler.List)
			r.Post("/", s.incidentsHandler.Create)
			r.Get("/{incidentID}", s.incidentsHandler.Get)
			r.Put("/{incidentID}", s.incidentsHandler.Update)
			r.Post("/{incidentID}/acknowledge", s.incidentsHandler.Acknowledge)
			r.Post("/{incidentID}/resolve", s.incidentsHandler.Resolve)
			r.Post("/{incidentID}/timeline", s.incidentsHandler.AddTimelineEntry)
			r.Post("/{incidentID}/ai-session", s.incidentsHandler.StartAISession)
			r.Get("/{incidentID}/runbook", s.incidentsHandler.GetRunbook)
			r.Post("/{incidentID}/postmortem", s.incidentsHandler.GeneratePostmortem)
		})

		// Logs
		r.Route("/logs", func(r chi.Router) {
			r.Post("/query", s.logsHandler.Query)
			r.Get("/services/{serviceID}", s.logsHandler.ByService)
			r.Get("/trace/{traceID}", s.logsHandler.GetTrace)
		})

		// Metrics
		r.Route("/metrics", func(r chi.Router) {
			r.Get("/services/{serviceID}", s.logsHandler.ServiceMetrics)
			r.Post("/query", s.logsHandler.MetricsQuery)
		})

		// Observability deep links
		r.Get("/observability/deeplink", s.logsHandler.GenerateDeepLink)

		// AI Operations Console
		r.Route("/ai", func(r chi.Router) {
			r.Post("/sessions", s.aiHandler.CreateSession)
			r.Get("/sessions", s.aiHandler.ListSessions)
			r.Get("/sessions/active", s.aiHandler.ListActiveSessions)
			r.Get("/sessions/{sessionID}", s.aiHandler.GetSession)
			r.Delete("/sessions/{sessionID}", s.aiHandler.TerminateSession)
			r.Post("/sessions/{sessionID}/message", s.aiHandler.SendMessage)
			r.Post("/sessions/{sessionID}/approve", s.aiHandler.ApproveAction)
			r.Post("/sessions/{sessionID}/reject", s.aiHandler.RejectAction)
			r.Get("/audit", s.aiHandler.AuditLog)
		})

		// WebSocket for AI streaming
		r.Get("/ai/sessions/{sessionID}/stream", s.aiHandler.Stream)

		// Webhooks (different auth)
		r.Route("/webhooks", func(r chi.Router) {
			r.Use(middleware.WebhookAuth(s.cfg))
			r.Post("/github", s.catalogHandler.GitHubWebhook)
			r.Post("/pagerduty", s.incidentsHandler.PagerDutyWebhook)
			r.Post("/argocd", s.deployHandler.ArgoCDWebhook)
		})
	})

	s.router = r
}

func (s *Server) Router() http.Handler {
	return s.router
}

func (s *Server) Close() error {
	s.db.Close()
	return s.redis.Close()
}

func (s *Server) healthCheck(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`{"status":"healthy"}`))
}

func (s *Server) readinessCheck(w http.ResponseWriter, r *http.Request) {
	// Check database
	if err := s.db.Ping(r.Context()); err != nil {
		http.Error(w, `{"status":"not ready","reason":"database"}`, http.StatusServiceUnavailable)
		return
	}

	// Check Redis
	if err := s.redis.Ping(r.Context()).Err(); err != nil {
		http.Error(w, `{"status":"not ready","reason":"redis"}`, http.StatusServiceUnavailable)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`{"status":"ready"}`))
}
