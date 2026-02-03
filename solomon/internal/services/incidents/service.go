package incidents

import (
	"context"

	"github.com/cobalt/solomon/internal/config"
	"github.com/cobalt/solomon/internal/models"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Service struct {
	db  *pgxpool.Pool
	cfg *config.Config
}

func NewService(db *pgxpool.Pool, cfg *config.Config) *Service {
	return &Service{db: db, cfg: cfg}
}

func (s *Service) List(ctx context.Context, filters ListFilters) ([]models.Incident, error) {
	// TODO: Implement
	return nil, nil
}

func (s *Service) Get(ctx context.Context, id uuid.UUID) (*models.Incident, error) {
	// TODO: Implement with timeline
	return nil, nil
}

func (s *Service) Create(ctx context.Context, req CreateIncidentRequest) (*models.Incident, error) {
	// TODO: Create incident and notify
	return nil, nil
}

func (s *Service) Update(ctx context.Context, id uuid.UUID, req UpdateIncidentRequest) error {
	// TODO: Update incident and add timeline entry
	return nil
}

func (s *Service) Acknowledge(ctx context.Context, id uuid.UUID, user string) error {
	// TODO: Mark acknowledged and notify PagerDuty
	return nil
}

func (s *Service) Resolve(ctx context.Context, id uuid.UUID, user string, resolution string) error {
	// TODO: Mark resolved and add timeline entry
	return nil
}

func (s *Service) AddTimelineEntry(ctx context.Context, id uuid.UUID, entry models.TimelineEvent) error {
	// TODO: Add timeline entry
	return nil
}

func (s *Service) GetRunbook(ctx context.Context, id uuid.UUID) (*models.Runbook, error) {
	// TODO: Find matching runbook based on incident type/affected services
	return nil, nil
}

func (s *Service) GeneratePostmortem(ctx context.Context, id uuid.UUID) (*models.Postmortem, error) {
	// TODO: Use AI to generate postmortem from timeline and logs
	return nil, nil
}

func (s *Service) HandlePagerDutyWebhook(ctx context.Context, payload []byte) error {
	// TODO: Create/update incident from PagerDuty webhook
	return nil
}

type ListFilters struct {
	Status           string
	Severity         string
	AffectedService  *uuid.UUID
	IncludeResolved  bool
	Limit            int
	Offset           int
}

type CreateIncidentRequest struct {
	Title                string      `json:"title"`
	Description          string      `json:"description"`
	Severity             string      `json:"severity"`
	AffectedServices     []uuid.UUID `json:"affectedServices"`
	AffectedEnvironments []string    `json:"affectedEnvironments"`
	SourceType           string      `json:"sourceType"`
	SourceAlertID        string      `json:"sourceAlertId,omitempty"`
}

type UpdateIncidentRequest struct {
	Title       string `json:"title,omitempty"`
	Description string `json:"description,omitempty"`
	Severity    string `json:"severity,omitempty"`
	Status      string `json:"status,omitempty"`
	Assignee    string `json:"assignee,omitempty"`
}
