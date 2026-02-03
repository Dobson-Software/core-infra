package costs

import (
	"context"
	"time"

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

func (s *Service) Summary(ctx context.Context, period string) (*CostSummary, error) {
	// TODO: Aggregate costs across all services/environments
	return nil, nil
}

func (s *Service) ByEnvironment(ctx context.Context, env string, start, end time.Time) (*EnvironmentCosts, error) {
	// TODO: Get costs for specific environment
	return nil, nil
}

func (s *Service) ByService(ctx context.Context, serviceID uuid.UUID, start, end time.Time) (*ServiceCosts, error) {
	// TODO: Get costs for specific service across all environments
	return nil, nil
}

func (s *Service) Forecast(ctx context.Context, months int) (*CostForecast, error) {
	// TODO: Project future costs based on trends
	return nil, nil
}

func (s *Service) Anomalies(ctx context.Context) ([]CostAnomaly, error) {
	// TODO: Detect cost anomalies using ML/statistical analysis
	return nil, nil
}

func (s *Service) Recommendations(ctx context.Context) ([]CostRecommendation, error) {
	// TODO: Generate cost optimization recommendations
	// - Right-sizing
	// - Spot opportunities
	// - RI recommendations
	// - Idle resources
	return nil, nil
}

func (s *Service) SetBudget(ctx context.Context, req SetBudgetRequest) error {
	// TODO: Set budget alert thresholds
	return nil
}

func (s *Service) SyncFromAWS(ctx context.Context) error {
	// TODO: Pull cost data from AWS Cost Explorer
	return nil
}

func (s *Service) SyncFromKubecost(ctx context.Context) error {
	// TODO: Pull pod-level costs from Kubecost
	return nil
}

type CostSummary struct {
	TotalCost       float64               `json:"totalCost"`
	PreviousPeriod  float64               `json:"previousPeriod"`
	ChangePercent   float64               `json:"changePercent"`
	ByEnvironment   map[string]float64    `json:"byEnvironment"`
	ByResourceType  map[string]float64    `json:"byResourceType"`
	TopServices     []ServiceCostSummary  `json:"topServices"`
}

type ServiceCostSummary struct {
	ServiceID   uuid.UUID `json:"serviceId"`
	ServiceName string    `json:"serviceName"`
	Cost        float64   `json:"cost"`
	Change      float64   `json:"change"`
}

type EnvironmentCosts struct {
	Environment    string                   `json:"environment"`
	TotalCost      float64                  `json:"totalCost"`
	ByService      map[string]float64       `json:"byService"`
	ByResourceType map[string]float64       `json:"byResourceType"`
	DailyCosts     []DailyCost              `json:"dailyCosts"`
}

type ServiceCosts struct {
	ServiceID     uuid.UUID          `json:"serviceId"`
	TotalCost     float64            `json:"totalCost"`
	ByEnvironment map[string]float64 `json:"byEnvironment"`
	DailyCosts    []DailyCost        `json:"dailyCosts"`
	Records       []models.CostRecord `json:"records"`
}

type DailyCost struct {
	Date time.Time `json:"date"`
	Cost float64   `json:"cost"`
}

type CostForecast struct {
	CurrentMonthEstimate float64       `json:"currentMonthEstimate"`
	NextMonthEstimate    float64       `json:"nextMonthEstimate"`
	MonthlyForecasts     []MonthlyCost `json:"monthlyForecasts"`
}

type MonthlyCost struct {
	Month    string  `json:"month"`
	Estimate float64 `json:"estimate"`
}

type CostAnomaly struct {
	ID           string    `json:"id"`
	ResourceType string    `json:"resourceType"`
	ResourceID   string    `json:"resourceId"`
	Environment  string    `json:"environment"`
	ExpectedCost float64   `json:"expectedCost"`
	ActualCost   float64   `json:"actualCost"`
	Deviation    float64   `json:"deviation"`
	DetectedAt   time.Time `json:"detectedAt"`
}

type CostRecommendation struct {
	ID              string  `json:"id"`
	Type            string  `json:"type"` // right_sizing, spot, reserved_instance, idle
	ResourceType    string  `json:"resourceType"`
	ResourceID      string  `json:"resourceId"`
	Description     string  `json:"description"`
	EstimatedSaving float64 `json:"estimatedSaving"`
	Confidence      float64 `json:"confidence"`
}

type SetBudgetRequest struct {
	Environment    string  `json:"environment,omitempty"`
	ServiceID      string  `json:"serviceId,omitempty"`
	MonthlyBudget  float64 `json:"monthlyBudget"`
	AlertThreshold float64 `json:"alertThreshold"` // Percentage (0.8 = 80%)
}
