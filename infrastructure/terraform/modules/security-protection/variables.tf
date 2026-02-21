variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
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

variable "project_name" {
  description = "Project name used for WAF resource naming"
  type        = string
  default     = "cobalt"
}

variable "enable_waf" {
  description = "Enable WAF v2 WebACL for ALB protection"
  type        = bool
  default     = false
}
