package ai

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/cobalt/solomon/internal/models"
	"github.com/google/uuid"
)

type Session struct {
	ID          uuid.UUID
	UserID      string
	ContextType string
	ContextID   *uuid.UUID
	Model       string
	Status      string
	StartedAt   time.Time
	EndedAt     *time.Time

	svc     *Service
	context *SessionContext

	mu          sync.RWMutex
	messages    []Message
	tools       []Tool
	actions     []models.AIAction
	subscribers []chan StreamEvent
}

type Message struct {
	Role      string    `json:"role"` // user, assistant, system
	Content   string    `json:"content"`
	Timestamp time.Time `json:"timestamp"`
}

type SessionContext struct {
	User         UserContext         `json:"user"`
	Target       *TargetContext      `json:"target,omitempty"`
	Runbooks     []models.Runbook    `json:"runbooks,omitempty"`
	RecentEvents RecentEvents        `json:"recentEvents"`
	Tools        ToolConfig          `json:"tools"`
}

type UserContext struct {
	ID          string   `json:"id"`
	Email       string   `json:"email"`
	Roles       []string `json:"roles"`
	Permissions []string `json:"permissions"`
}

type TargetContext struct {
	Type        string              `json:"type"` // service, environment, incident
	Service     *models.Service     `json:"service,omitempty"`
	Environment *models.Environment `json:"environment,omitempty"`
	Incident    *models.Incident    `json:"incident,omitempty"`
}

type RecentEvents struct {
	Deployments []models.Deployment `json:"deployments"`
	Incidents   []models.Incident   `json:"incidents"`
}

type ToolConfig struct {
	Kubectl KubectlConfig `json:"kubectl"`
	AWS     AWSConfig     `json:"aws"`
	GitHub  GitHubConfig  `json:"github"`
}

type KubectlConfig struct {
	Contexts   []string `json:"contexts"`
	Namespaces []string `json:"namespaces"`
}

type AWSConfig struct {
	Role    string   `json:"role"`
	Regions []string `json:"regions"`
}

type GitHubConfig struct {
	Repos       []string `json:"repos"`
	Permissions []string `json:"permissions"`
}

func (s *Session) buildContext(ctx context.Context) error {
	s.context = &SessionContext{
		User: UserContext{
			ID:    s.UserID,
			Email: s.UserID, // TODO: Get from user service
			Roles: []string{"admin"},
		},
		Tools: ToolConfig{
			Kubectl: KubectlConfig{
				Contexts:   []string{"prod", "staging", "dev"},
				Namespaces: []string{"cobalt-services", "monitoring"},
			},
			AWS: AWSConfig{
				Role:    "SolomonAgentRole",
				Regions: []string{"us-east-1"},
			},
			GitHub: GitHubConfig{
				Repos:       []string{"cobalt/*"},
				Permissions: []string{"read", "write:pr"},
			},
		},
	}

	// Load target context if specified
	if s.ContextID != nil {
		switch s.ContextType {
		case "service":
			svc, err := s.svc.catalogSvc.Get(ctx, *s.ContextID)
			if err != nil {
				return err
			}
			s.context.Target = &TargetContext{
				Type:    "service",
				Service: svc,
			}
			// Load runbooks for this service
			runbooks, _ := s.svc.catalogSvc.ListRunbooks(ctx, *s.ContextID)
			s.context.Runbooks = runbooks

		case "incident":
			incident, err := s.svc.incidentsSvc.Get(ctx, *s.ContextID)
			if err != nil {
				return err
			}
			s.context.Target = &TargetContext{
				Type:     "incident",
				Incident: incident,
			}
		}
	}

	// Add system message with context
	s.messages = append(s.messages, Message{
		Role:      "system",
		Content:   s.buildSystemPrompt(),
		Timestamp: time.Now(),
	})

	return nil
}

func (s *Session) buildSystemPrompt() string {
	prompt := `You are Solomon, an AI operations assistant for infrastructure and application management.
You help engineers debug issues, perform deployments, and maintain infrastructure.

## Guidelines
1. Always explain what you're about to do before doing it
2. For destructive operations, request approval through the approval flow
3. Log all actions to the audit trail
4. If you're unsure, ask clarifying questions
5. Prefer safe, reversible operations
6. For production issues, prioritize mitigation over root cause analysis
7. Be concise but thorough in your analysis

## Available Tools
`

	for _, tool := range s.tools {
		approval := "No"
		if tool.RequiresApproval {
			approval = "Yes"
		}
		prompt += fmt.Sprintf("- %s: %s (Approval: %s)\n", tool.Name, tool.Description, approval)
	}

	if s.context.Target != nil {
		prompt += "\n## Current Context\n"
		if s.context.Target.Service != nil {
			prompt += fmt.Sprintf("Target Service: %s (%s)\n", s.context.Target.Service.DisplayName, s.context.Target.Service.Name)
		}
		if s.context.Target.Incident != nil {
			prompt += fmt.Sprintf("Active Incident: %s (Severity: %s)\n", s.context.Target.Incident.Title, s.context.Target.Incident.Severity)
		}
	}

	if len(s.context.Runbooks) > 0 {
		prompt += "\n## Relevant Runbooks\n"
		for _, rb := range s.context.Runbooks {
			prompt += fmt.Sprintf("### %s\nTrigger: %s\n%s\n\n", rb.Title, rb.Trigger, rb.Content)
		}
	}

	return prompt
}

func (s *Session) SendMessage(ctx context.Context, content string) error {
	s.mu.Lock()
	s.messages = append(s.messages, Message{
		Role:      "user",
		Content:   content,
		Timestamp: time.Now(),
	})
	s.mu.Unlock()

	// Broadcast that we received the message
	s.broadcast(StreamEvent{Type: "message", Content: content})

	// Call Claude API
	go s.processWithClaude(ctx)

	return nil
}

func (s *Session) processWithClaude(ctx context.Context) {
	// TODO: Implement actual Claude API call
	// This is where we'd:
	// 1. Send messages to Claude API
	// 2. Stream responses back via subscribers
	// 3. Handle tool calls
	// 4. Request approval for dangerous operations
	// 5. Execute approved tools
	// 6. Log all actions to audit trail

	// For now, send a placeholder response
	s.broadcast(StreamEvent{
		Type:    "message",
		Content: "I'm analyzing your request. This is a placeholder - Claude API integration coming soon.",
	})
	s.broadcast(StreamEvent{Type: "done"})
}

func (s *Session) ApproveAction(ctx context.Context, actionID uuid.UUID, approver string) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	for i := range s.actions {
		if s.actions[i].ID == actionID && s.actions[i].Status == "pending" {
			now := time.Now()
			s.actions[i].Status = "approved"
			s.actions[i].ApprovedBy = approver
			s.actions[i].ApprovedAt = &now

			// Execute the action
			go s.executeAction(ctx, &s.actions[i])
			return nil
		}
	}
	return fmt.Errorf("action not found or not pending")
}

func (s *Session) RejectAction(ctx context.Context, actionID uuid.UUID, reason string) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	for i := range s.actions {
		if s.actions[i].ID == actionID && s.actions[i].Status == "pending" {
			s.actions[i].Status = "rejected"
			s.actions[i].Output = map[string]any{"rejection_reason": reason}

			s.broadcast(StreamEvent{
				Type:    "tool_result",
				Tool:    s.actions[i].ToolName,
				Content: fmt.Sprintf("Action rejected: %s", reason),
			})
			return nil
		}
	}
	return fmt.Errorf("action not found or not pending")
}

func (s *Session) executeAction(ctx context.Context, action *models.AIAction) {
	// TODO: Execute the tool based on action.ToolName and action.Input
	now := time.Now()
	action.ExecutedAt = &now
	action.Status = "executed"
	action.Output = map[string]any{"result": "placeholder"}

	s.broadcast(StreamEvent{
		Type:    "tool_result",
		Tool:    action.ToolName,
		Content: "Action executed successfully (placeholder)",
	})
}

func (s *Session) Subscribe() <-chan StreamEvent {
	ch := make(chan StreamEvent, 100)
	s.mu.Lock()
	s.subscribers = append(s.subscribers, ch)
	s.mu.Unlock()
	return ch
}

func (s *Session) broadcast(event StreamEvent) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	for _, ch := range s.subscribers {
		select {
		case ch <- event:
		default:
			// Channel full, skip
		}
	}
}

func (s *Session) closeSubscribers() {
	s.mu.Lock()
	defer s.mu.Unlock()

	for _, ch := range s.subscribers {
		close(ch)
	}
	s.subscribers = nil
}

func (s *Session) ToModel() models.AISession {
	return models.AISession{
		ID:          s.ID,
		UserID:      s.UserID,
		ContextType: s.ContextType,
		ContextID:   s.ContextID,
		Status:      s.Status,
		Model:       s.Model,
		StartedAt:   s.StartedAt,
		EndedAt:     s.EndedAt,
	}
}
