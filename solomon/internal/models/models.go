package models

import (
	"time"

	"github.com/google/uuid"
)

// Service represents an application in the catalog
type Service struct {
	ID          uuid.UUID         `json:"id" db:"id"`
	Name        string            `json:"name" db:"name"`
	DisplayName string            `json:"displayName" db:"display_name"`
	Description string            `json:"description" db:"description"`
	Repository  string            `json:"repository" db:"repository"`
	Team        string            `json:"team" db:"team"`
	Tier        string            `json:"tier" db:"tier"`
	Language    string            `json:"language" db:"language"`
	Framework   string            `json:"framework" db:"framework"`
	Metadata    map[string]any    `json:"metadata" db:"metadata"`
	CreatedAt   time.Time         `json:"createdAt" db:"created_at"`
	UpdatedAt   time.Time         `json:"updatedAt" db:"updated_at"`

	// Loaded via joins
	Environments []Environment `json:"environments,omitempty"`
	Dependencies []Dependency  `json:"dependencies,omitempty"`
	Runbooks     []Runbook     `json:"runbooks,omitempty"`
	HealthStatus string        `json:"healthStatus,omitempty"`
}

// Environment represents a deployment environment for a service
type Environment struct {
	ID        uuid.UUID      `json:"id" db:"id"`
	ServiceID uuid.UUID      `json:"serviceId" db:"service_id"`
	Name      string         `json:"name" db:"name"`
	Cluster   string         `json:"cluster" db:"cluster"`
	Namespace string         `json:"namespace" db:"namespace"`
	Config    map[string]any `json:"config" db:"config"`
	CreatedAt time.Time      `json:"createdAt" db:"created_at"`
	UpdatedAt time.Time      `json:"updatedAt" db:"updated_at"`

	// Runtime info (populated dynamically)
	Deployment *DeploymentInfo `json:"deployment,omitempty"`
	Endpoints  *Endpoints      `json:"endpoints,omitempty"`
	Resources  *Resources      `json:"resources,omitempty"`
}

type DeploymentInfo struct {
	ImageTag       string    `json:"imageTag"`
	Replicas       int       `json:"replicas"`
	ReadyReplicas  int       `json:"readyReplicas"`
	LastDeployedAt time.Time `json:"lastDeployedAt"`
	LastDeployedBy string    `json:"lastDeployedBy"`
	GitCommit      string    `json:"gitCommit"`
}

type Endpoints struct {
	Internal    string `json:"internal"`
	External    string `json:"external,omitempty"`
	HealthCheck string `json:"healthCheck"`
}

type Resources struct {
	CPURequest    string `json:"cpuRequest"`
	CPULimit      string `json:"cpuLimit"`
	MemoryRequest string `json:"memoryRequest"`
	MemoryLimit   string `json:"memoryLimit"`
}

// Dependency represents a service dependency
type Dependency struct {
	ID          uuid.UUID `json:"id" db:"id"`
	ServiceID   uuid.UUID `json:"serviceId" db:"service_id"`
	DependsOnID uuid.UUID `json:"dependsOnId" db:"depends_on_id"`
	Type        string    `json:"type" db:"type"` // runtime, build, optional
	Description string    `json:"description" db:"description"`

	// Loaded via join
	DependsOn *Service `json:"dependsOn,omitempty"`
}

// Runbook represents operational documentation
type Runbook struct {
	ID          uuid.UUID `json:"id" db:"id"`
	ServiceID   uuid.UUID `json:"serviceId" db:"service_id"`
	Title       string    `json:"title" db:"title"`
	Trigger     string    `json:"trigger" db:"trigger"`
	Content     string    `json:"content" db:"content"`
	Automatable bool      `json:"automatable" db:"automatable"`
	AIPrompt    string    `json:"aiPrompt,omitempty" db:"ai_prompt"`
	CreatedAt   time.Time `json:"createdAt" db:"created_at"`
	UpdatedAt   time.Time `json:"updatedAt" db:"updated_at"`
}

// Deployment represents a deployment operation
type Deployment struct {
	ID            uuid.UUID      `json:"id" db:"id"`
	ServiceID     uuid.UUID      `json:"serviceId" db:"service_id"`
	EnvironmentID uuid.UUID      `json:"environmentId" db:"environment_id"`
	ImageTag      string         `json:"imageTag" db:"image_tag"`
	GitCommit     string         `json:"gitCommit" db:"git_commit"`
	Status        string         `json:"status" db:"status"` // pending, in_progress, completed, failed, cancelled
	InitiatedBy   string         `json:"initiatedBy" db:"initiated_by"`
	InitiatedVia  string         `json:"initiatedVia" db:"initiated_via"` // ui, api, ai, gitops
	StartedAt     time.Time      `json:"startedAt" db:"started_at"`
	CompletedAt   *time.Time     `json:"completedAt,omitempty" db:"completed_at"`
	Metadata      map[string]any `json:"metadata" db:"metadata"`

	// Loaded via joins
	Service     *Service     `json:"service,omitempty"`
	Environment *Environment `json:"environment,omitempty"`
}

// Incident represents a production incident
type Incident struct {
	ID                   uuid.UUID       `json:"id" db:"id"`
	Title                string          `json:"title" db:"title"`
	Description          string          `json:"description" db:"description"`
	Severity             string          `json:"severity" db:"severity"` // critical, high, medium, low
	Status               string          `json:"status" db:"status"`     // triggered, acknowledged, investigating, resolved
	SourceType           string          `json:"sourceType" db:"source_type"`
	SourceAlertID        string          `json:"sourceAlertId,omitempty" db:"source_alert_id"`
	AffectedServices     []uuid.UUID     `json:"affectedServices" db:"affected_services"`
	AffectedEnvironments []string        `json:"affectedEnvironments" db:"affected_environments"`
	Assignee             string          `json:"assignee,omitempty" db:"assignee"`
	AcknowledgedAt       *time.Time      `json:"acknowledgedAt,omitempty" db:"acknowledged_at"`
	ResolvedAt           *time.Time      `json:"resolvedAt,omitempty" db:"resolved_at"`
	Postmortem           *Postmortem     `json:"postmortem,omitempty" db:"postmortem"`
	CreatedAt            time.Time       `json:"createdAt" db:"created_at"`
	UpdatedAt            time.Time       `json:"updatedAt" db:"updated_at"`

	// Loaded separately
	Timeline   []TimelineEvent `json:"timeline,omitempty"`
	AISessions []AISession     `json:"aiSessions,omitempty"`
}

type Postmortem struct {
	Summary       string       `json:"summary"`
	RootCause     string       `json:"rootCause"`
	ActionItems   []ActionItem `json:"actionItems"`
	GeneratedByAI bool         `json:"generatedByAI"`
}

type ActionItem struct {
	Description string     `json:"description"`
	Assignee    string     `json:"assignee"`
	DueDate     *time.Time `json:"dueDate,omitempty"`
	Status      string     `json:"status"` // open, in_progress, completed
}

type TimelineEvent struct {
	ID        uuid.UUID      `json:"id" db:"id"`
	IncidentID uuid.UUID     `json:"incidentId" db:"incident_id"`
	EventType string         `json:"eventType" db:"event_type"` // alert, status_change, comment, action, ai_action
	Actor     string         `json:"actor" db:"actor"`
	Content   string         `json:"content" db:"content"`
	Metadata  map[string]any `json:"metadata,omitempty" db:"metadata"`
	CreatedAt time.Time      `json:"createdAt" db:"created_at"`
}

// AISession represents an AI operations session
type AISession struct {
	ID          uuid.UUID      `json:"id" db:"id"`
	UserID      string         `json:"userId" db:"user_id"`
	ContextType string         `json:"contextType,omitempty" db:"context_type"` // service, environment, incident
	ContextID   *uuid.UUID     `json:"contextId,omitempty" db:"context_id"`
	Status      string         `json:"status" db:"status"` // active, completed, terminated
	Model       string         `json:"model" db:"model"`
	StartedAt   time.Time      `json:"startedAt" db:"started_at"`
	EndedAt     *time.Time     `json:"endedAt,omitempty" db:"ended_at"`
	Metadata    map[string]any `json:"metadata,omitempty" db:"metadata"`

	// Loaded separately
	Actions []AIAction `json:"actions,omitempty"`
}

type AIAction struct {
	ID               uuid.UUID      `json:"id" db:"id"`
	SessionID        uuid.UUID      `json:"sessionId" db:"session_id"`
	ActionType       string         `json:"actionType" db:"action_type"`
	ToolName         string         `json:"toolName" db:"tool_name"`
	Input            map[string]any `json:"input" db:"input"`
	Output           map[string]any `json:"output,omitempty" db:"output"`
	Status           string         `json:"status" db:"status"` // pending, approved, rejected, executed, failed
	RequiresApproval bool           `json:"requiresApproval" db:"requires_approval"`
	ApprovedBy       string         `json:"approvedBy,omitempty" db:"approved_by"`
	ApprovedAt       *time.Time     `json:"approvedAt,omitempty" db:"approved_at"`
	ExecutedAt       *time.Time     `json:"executedAt,omitempty" db:"executed_at"`
	CreatedAt        time.Time      `json:"createdAt" db:"created_at"`
}

// AuditLog represents an audit trail entry
type AuditLog struct {
	ID           uuid.UUID      `json:"id" db:"id"`
	Actor        string         `json:"actor" db:"actor"`
	ActorType    string         `json:"actorType" db:"actor_type"` // user, ai, system
	Action       string         `json:"action" db:"action"`
	ResourceType string         `json:"resourceType" db:"resource_type"`
	ResourceID   string         `json:"resourceId,omitempty" db:"resource_id"`
	Details      map[string]any `json:"details,omitempty" db:"details"`
	IPAddress    string         `json:"ipAddress,omitempty" db:"ip_address"`
	UserAgent    string         `json:"userAgent,omitempty" db:"user_agent"`
	CreatedAt    time.Time      `json:"createdAt" db:"created_at"`
}

// CostRecord represents cost data
type CostRecord struct {
	ID            uuid.UUID      `json:"id" db:"id"`
	Date          time.Time      `json:"date" db:"date"`
	Environment   string         `json:"environment" db:"environment"`
	ServiceID     *uuid.UUID     `json:"serviceId,omitempty" db:"service_id"`
	ResourceType  string         `json:"resourceType" db:"resource_type"`
	ResourceID    string         `json:"resourceId,omitempty" db:"resource_id"`
	CostUSD       float64        `json:"costUsd" db:"cost_usd"`
	UsageQuantity float64        `json:"usageQuantity,omitempty" db:"usage_quantity"`
	UsageUnit     string         `json:"usageUnit,omitempty" db:"usage_unit"`
	Metadata      map[string]any `json:"metadata,omitempty" db:"metadata"`
}

// Secret represents secret metadata (never the actual value)
type Secret struct {
	Path         string         `json:"path"`
	Name         string         `json:"name"`
	Description  string         `json:"description,omitempty"`
	Environment  string         `json:"environment"`
	Category     string         `json:"category"` // database, api_key, oauth, internal, certificate
	LastRotated  *time.Time     `json:"lastRotated,omitempty"`
	ExpiresAt    *time.Time     `json:"expiresAt,omitempty"`
	RotationDays int            `json:"rotationDays,omitempty"`
	CreatedAt    time.Time      `json:"createdAt"`
	UpdatedAt    time.Time      `json:"updatedAt"`
	Metadata     map[string]any `json:"metadata,omitempty"`
}
