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

variable "enable_config" {
  description = "Enable AWS Config recorder and rules"
  type        = bool
  default     = true
}

variable "enable_cmk_keys" {
  description = "Enable Customer Managed KMS keys (when false, outputs empty strings and uses AWS managed keys)"
  type        = bool
  default     = true
}

variable "enable_secret_rotation" {
  description = "Enable automatic secret rotation. PREREQUISITE: The rotation Lambda function (cobalt-<env>-secret-rotation) must be deployed before enabling this."
  type        = bool
  default     = false
}
