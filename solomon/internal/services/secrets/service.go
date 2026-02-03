package secrets

import (
	"context"

	"github.com/cobalt/solomon/internal/config"
	"github.com/cobalt/solomon/internal/models"
)

type Service struct {
	cfg *config.Config
}

func NewService(cfg *config.Config) *Service {
	return &Service{cfg: cfg}
}

func (s *Service) List(ctx context.Context, environment string) ([]models.Secret, error) {
	// TODO: List secrets from AWS Secrets Manager (metadata only)
	return nil, nil
}

func (s *Service) Get(ctx context.Context, path string) (*models.Secret, error) {
	// TODO: Get secret metadata
	return nil, nil
}

func (s *Service) GetValue(ctx context.Context, path string) (string, error) {
	// TODO: Get actual secret value (requires elevated permissions)
	// This should be heavily audited
	return "", nil
}

func (s *Service) Create(ctx context.Context, req CreateSecretRequest) (*models.Secret, error) {
	// TODO: Create secret in AWS Secrets Manager
	return nil, nil
}

func (s *Service) Update(ctx context.Context, path string, value string) error {
	// TODO: Update secret value
	return nil
}

func (s *Service) Delete(ctx context.Context, path string) error {
	// TODO: Delete secret (with soft-delete period)
	return nil
}

func (s *Service) Rotate(ctx context.Context, path string) error {
	// TODO: Trigger rotation workflow
	return nil
}

func (s *Service) History(ctx context.Context, path string) ([]SecretVersion, error) {
	// TODO: Get version history
	return nil, nil
}

func (s *Service) Rollback(ctx context.Context, path string, versionID string) error {
	// TODO: Rollback to previous version
	return nil
}

func (s *Service) ListExpiring(ctx context.Context, days int) ([]models.Secret, error) {
	// TODO: List secrets expiring within N days
	return nil, nil
}

func (s *Service) AuditLog(ctx context.Context, path string, limit int) ([]models.AuditLog, error) {
	// TODO: Get access audit log for a secret
	return nil, nil
}

type CreateSecretRequest struct {
	Path         string `json:"path"`
	Value        string `json:"value"`
	Description  string `json:"description,omitempty"`
	Environment  string `json:"environment"`
	Category     string `json:"category"`
	RotationDays int    `json:"rotationDays,omitempty"`
}

type SecretVersion struct {
	VersionID string `json:"versionId"`
	CreatedAt string `json:"createdAt"`
	CreatedBy string `json:"createdBy"`
	Current   bool   `json:"current"`
}
