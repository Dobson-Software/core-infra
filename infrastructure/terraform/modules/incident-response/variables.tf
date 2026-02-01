variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "enable_incident_response" {
  description = "Enable the AI incident response pipeline"
  type        = bool
  default     = false
}

variable "sns_alert_topic_arn" {
  description = "ARN of the SNS topic that receives CloudWatch alarm notifications"
  type        = string
}

variable "secrets_manager_secret_id" {
  description = "Secrets Manager secret ID containing API keys (anthropic_api_key, axiom_api_token, github_token, slack_webhook_url)"
  type        = string
  default     = ""
}

variable "secrets_manager_secret_arn" {
  description = "Secrets Manager secret ARN for IAM policy"
  type        = string
  default     = ""
}

variable "github_repo" {
  description = "GitHub repo in owner/repo format for creating incident issues"
  type        = string
  default     = ""
}
