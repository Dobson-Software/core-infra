variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "alert_email" {
  description = "Email address for security alert notifications"
  type        = string
  default     = ""
}

variable "enable_guardduty" {
  description = "Enable GuardDuty threat detection"
  type        = bool
  default     = true
}

variable "enable_shield_advanced" {
  description = "Enable AWS Shield Advanced for DDoS protection"
  type        = bool
  default     = false
}

variable "alb_arn" {
  description = "ARN of the ALB to protect with Shield Advanced"
  type        = string
  default     = ""
}

variable "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution to protect with Shield Advanced"
  type        = string
  default     = ""
}

variable "enable_secret_rotation" {
  description = "Enable secret rotation for DB password (requires rotation Lambda to be deployed)"
  type        = bool
  default     = false
}
