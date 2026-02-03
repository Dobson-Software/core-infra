package ai

import (
	"context"
	"sync"

	"github.com/cobalt/solomon/internal/config"
	"github.com/cobalt/solomon/internal/models"
	"github.com/cobalt/solomon/internal/services/catalog"
	"github.com/cobalt/solomon/internal/services/deploy"
	"github.com/cobalt/solomon/internal/services/incidents"
	"github.com/cobalt/solomon/internal/services/logs"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Service struct {
	db  *pgxpool.Pool
	cfg *config.Config

	// Dependencies for AI tools
	catalogSvc   *catalog.Service
	deploySvc    *deploy.Service
	logsSvc      *logs.Service
	incidentsSvc *incidents.Service

	// Active sessions
	sessions sync.Map // map[uuid.UUID]*Session
}

func NewService(
	db *pgxpool.Pool,
	cfg *config.Config,
	catalogSvc *catalog.Service,
	deploySvc *deploy.Service,
	logsSvc *logs.Service,
	incidentsSvc *incidents.Service,
) *Service {
	return &Service{
		db:           db,
		cfg:          cfg,
		catalogSvc:   catalogSvc,
		deploySvc:    deploySvc,
		logsSvc:      logsSvc,
		incidentsSvc: incidentsSvc,
	}
}

func (s *Service) CreateSession(ctx context.Context, req CreateSessionRequest) (*Session, error) {
	session := &Session{
		ID:          uuid.New(),
		UserID:      req.UserID,
		ContextType: req.ContextType,
		ContextID:   req.ContextID,
		Model:       s.cfg.Anthropic.DefaultModel,
		Status:      "active",

		svc:         s,
		messages:    make([]Message, 0),
		tools:       s.buildToolSet(req),
		subscribers: make([]chan StreamEvent, 0),
	}

	// Build initial context
	if err := session.buildContext(ctx); err != nil {
		return nil, err
	}

	// Store session
	s.sessions.Store(session.ID, session)

	// Persist to database
	if err := s.persistSession(ctx, session); err != nil {
		return nil, err
	}

	return session, nil
}

func (s *Service) GetSession(ctx context.Context, id uuid.UUID) (*Session, error) {
	if session, ok := s.sessions.Load(id); ok {
		return session.(*Session), nil
	}

	// Try to load from database
	return s.loadSession(ctx, id)
}

func (s *Service) ListSessions(ctx context.Context, userID string, limit int) ([]models.AISession, error) {
	// TODO: Query database
	return nil, nil
}

func (s *Service) ListActiveSessions(ctx context.Context) ([]models.AISession, error) {
	var active []models.AISession
	s.sessions.Range(func(key, value any) bool {
		session := value.(*Session)
		active = append(active, session.ToModel())
		return true
	})
	return active, nil
}

func (s *Service) TerminateSession(ctx context.Context, id uuid.UUID) error {
	if session, ok := s.sessions.Load(id); ok {
		sess := session.(*Session)
		sess.Status = "terminated"
		sess.closeSubscribers()
		s.sessions.Delete(id)
		return s.updateSessionStatus(ctx, id, "terminated")
	}
	return nil
}

func (s *Service) SendMessage(ctx context.Context, sessionID uuid.UUID, content string) error {
	session, err := s.GetSession(ctx, sessionID)
	if err != nil {
		return err
	}
	return session.SendMessage(ctx, content)
}

func (s *Service) ApproveAction(ctx context.Context, sessionID uuid.UUID, actionID uuid.UUID, approver string) error {
	session, err := s.GetSession(ctx, sessionID)
	if err != nil {
		return err
	}
	return session.ApproveAction(ctx, actionID, approver)
}

func (s *Service) RejectAction(ctx context.Context, sessionID uuid.UUID, actionID uuid.UUID, reason string) error {
	session, err := s.GetSession(ctx, sessionID)
	if err != nil {
		return err
	}
	return session.RejectAction(ctx, actionID, reason)
}

func (s *Service) Subscribe(ctx context.Context, sessionID uuid.UUID) (<-chan StreamEvent, error) {
	session, err := s.GetSession(ctx, sessionID)
	if err != nil {
		return nil, err
	}
	return session.Subscribe(), nil
}

func (s *Service) AuditLog(ctx context.Context, filters AuditFilters) ([]models.AuditLog, error) {
	// TODO: Query audit log
	return nil, nil
}

func (s *Service) buildToolSet(req CreateSessionRequest) []Tool {
	tools := []Tool{
		// Read-only tools (always available)
		{Name: "get_service", Description: "Get service details", RequiresApproval: false},
		{Name: "list_services", Description: "List all services", RequiresApproval: false},
		{Name: "get_health", Description: "Get service health status", RequiresApproval: false},
		{Name: "query_logs", Description: "Query application logs", RequiresApproval: false},
		{Name: "query_metrics", Description: "Query metrics (PromQL)", RequiresApproval: false},
		{Name: "get_deployments", Description: "Get deployment history", RequiresApproval: false},
		{Name: "get_incidents", Description: "Get incident details", RequiresApproval: false},
		{Name: "get_costs", Description: "Get cost information", RequiresApproval: false},
		{Name: "analyze_logs", Description: "AI analysis of recent logs", RequiresApproval: false},

		// Safe mutations (no approval for non-prod)
		{Name: "scale_service", Description: "Scale service replicas", RequiresApproval: true, ApprovalEnvs: []string{"prod"}},
		{Name: "restart_service", Description: "Rolling restart", RequiresApproval: true, ApprovalEnvs: []string{"prod"}},
		{Name: "create_pr", Description: "Create GitHub PR", RequiresApproval: false},

		// Dangerous operations (always require approval)
		{Name: "deploy", Description: "Deploy new version", RequiresApproval: true},
		{Name: "rollback", Description: "Rollback to previous version", RequiresApproval: true},
		{Name: "update_secret", Description: "Update secret value", RequiresApproval: true},

		// Kubernetes operations
		{Name: "kubectl_get", Description: "kubectl get resources", RequiresApproval: false},
		{Name: "kubectl_describe", Description: "kubectl describe resource", RequiresApproval: false},
		{Name: "kubectl_logs", Description: "kubectl logs", RequiresApproval: false},
		{Name: "kubectl_exec", Description: "kubectl exec (debug)", RequiresApproval: true},
	}

	return tools
}

func (s *Service) persistSession(ctx context.Context, session *Session) error {
	// TODO: Insert into ai_sessions table
	return nil
}

func (s *Service) loadSession(ctx context.Context, id uuid.UUID) (*Session, error) {
	// TODO: Load from database and reconstruct
	return nil, nil
}

func (s *Service) updateSessionStatus(ctx context.Context, id uuid.UUID, status string) error {
	// TODO: Update database
	return nil
}

type CreateSessionRequest struct {
	UserID      string     `json:"userId"`
	ContextType string     `json:"contextType,omitempty"` // service, environment, incident
	ContextID   *uuid.UUID `json:"contextId,omitempty"`
	Prompt      string     `json:"prompt,omitempty"`
}

type AuditFilters struct {
	SessionID *uuid.UUID
	UserID    string
	Action    string
	Limit     int
	Offset    int
}

type Tool struct {
	Name             string
	Description      string
	RequiresApproval bool
	ApprovalEnvs     []string // Environments where approval is required
}

type StreamEvent struct {
	Type    string `json:"type"` // message, tool_use, tool_result, approval_required, error, done
	Content string `json:"content,omitempty"`
	Tool    string `json:"tool,omitempty"`
	Action  *models.AIAction `json:"action,omitempty"`
	Error   string `json:"error,omitempty"`
}
