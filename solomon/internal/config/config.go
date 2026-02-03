package config

import (
	"fmt"
	"strings"

	"github.com/spf13/viper"
)

type Config struct {
	Server    ServerConfig    `mapstructure:"server"`
	Database  DatabaseConfig  `mapstructure:"database"`
	Redis     RedisConfig     `mapstructure:"redis"`
	Auth      AuthConfig      `mapstructure:"auth"`
	AWS       AWSConfig       `mapstructure:"aws"`
	GitHub    GitHubConfig    `mapstructure:"github"`
	Anthropic AnthropicConfig `mapstructure:"anthropic"`
	ArgoCD    ArgoCDConfig    `mapstructure:"argocd"`
	PagerDuty PagerDutyConfig `mapstructure:"pagerduty"`
	Axiom     AxiomConfig     `mapstructure:"axiom"`
}

type ServerConfig struct {
	Port            int    `mapstructure:"port"`
	Environment     string `mapstructure:"environment"`
	ShutdownTimeout int    `mapstructure:"shutdown_timeout"`
}

type DatabaseConfig struct {
	Host     string `mapstructure:"host"`
	Port     int    `mapstructure:"port"`
	User     string `mapstructure:"user"`
	Password string `mapstructure:"password"`
	Database string `mapstructure:"database"`
	SSLMode  string `mapstructure:"ssl_mode"`
	MaxConns int    `mapstructure:"max_conns"`
	MinConns int    `mapstructure:"min_conns"`
}

func (d DatabaseConfig) DSN() string {
	return fmt.Sprintf(
		"postgres://%s:%s@%s:%d/%s?sslmode=%s",
		d.User, d.Password, d.Host, d.Port, d.Database, d.SSLMode,
	)
}

type RedisConfig struct {
	Host     string `mapstructure:"host"`
	Port     int    `mapstructure:"port"`
	Password string `mapstructure:"password"`
	DB       int    `mapstructure:"db"`
}

func (r RedisConfig) Addr() string {
	return fmt.Sprintf("%s:%d", r.Host, r.Port)
}

type AuthConfig struct {
	JWTSecret     string   `mapstructure:"jwt_secret"`
	OIDCIssuer    string   `mapstructure:"oidc_issuer"`
	OIDCClientID  string   `mapstructure:"oidc_client_id"`
	AllowedEmails []string `mapstructure:"allowed_emails"`
}

type AWSConfig struct {
	Region          string `mapstructure:"region"`
	SecretsPrefix   string `mapstructure:"secrets_prefix"`
	CostExplorerOn  bool   `mapstructure:"cost_explorer_enabled"`
	AssumeRoleARN   string `mapstructure:"assume_role_arn"`
}

type GitHubConfig struct {
	AppID          int64  `mapstructure:"app_id"`
	InstallationID int64  `mapstructure:"installation_id"`
	PrivateKeyPath string `mapstructure:"private_key_path"`
	WebhookSecret  string `mapstructure:"webhook_secret"`
}

type AnthropicConfig struct {
	APIKey       string `mapstructure:"api_key"`
	DefaultModel string `mapstructure:"default_model"`
	MaxTokens    int    `mapstructure:"max_tokens"`
}

type ArgoCDConfig struct {
	ServerURL string `mapstructure:"server_url"`
	AuthToken string `mapstructure:"auth_token"`
	Insecure  bool   `mapstructure:"insecure"`
}

type PagerDutyConfig struct {
	APIKey         string `mapstructure:"api_key"`
	ServiceID      string `mapstructure:"service_id"`
	WebhookSecret  string `mapstructure:"webhook_secret"`
}

type AxiomConfig struct {
	APIToken string `mapstructure:"api_token"`
	OrgID    string `mapstructure:"org_id"`
	Dataset  string `mapstructure:"dataset"`
}

func Load() (*Config, error) {
	viper.SetConfigName("config")
	viper.SetConfigType("yaml")
	viper.AddConfigPath(".")
	viper.AddConfigPath("/etc/solomon")
	viper.AddConfigPath("$HOME/.solomon")

	// Environment variable overrides
	viper.SetEnvPrefix("SOLOMON")
	viper.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
	viper.AutomaticEnv()

	// Defaults
	viper.SetDefault("server.port", 8080)
	viper.SetDefault("server.environment", "development")
	viper.SetDefault("server.shutdown_timeout", 30)
	viper.SetDefault("database.host", "localhost")
	viper.SetDefault("database.port", 5432)
	viper.SetDefault("database.database", "solomon")
	viper.SetDefault("database.ssl_mode", "disable")
	viper.SetDefault("database.max_conns", 25)
	viper.SetDefault("database.min_conns", 5)
	viper.SetDefault("redis.host", "localhost")
	viper.SetDefault("redis.port", 6379)
	viper.SetDefault("redis.db", 0)
	viper.SetDefault("anthropic.default_model", "claude-sonnet-4-20250514")
	viper.SetDefault("anthropic.max_tokens", 4096)
	viper.SetDefault("aws.region", "us-east-1")
	viper.SetDefault("aws.secrets_prefix", "solomon")
	viper.SetDefault("aws.cost_explorer_enabled", true)

	// Read config file (optional)
	if err := viper.ReadInConfig(); err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
			return nil, fmt.Errorf("reading config file: %w", err)
		}
		// Config file not found is OK - we use env vars
	}

	var cfg Config
	if err := viper.Unmarshal(&cfg); err != nil {
		return nil, fmt.Errorf("unmarshaling config: %w", err)
	}

	return &cfg, nil
}
