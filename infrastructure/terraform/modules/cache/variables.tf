variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for ElastiCache"
  type        = list(string)
}

variable "allowed_security_groups" {
  description = "List of security group IDs allowed to access Redis"
  type        = list(string)
}

variable "kms_key_id" {
  description = "KMS key ARN for ElastiCache at-rest encryption with customer-managed key"
  type        = string
}

variable "enable_cache" {
  description = "Enable ElastiCache cluster (set false to skip for cost savings)"
  type        = bool
  default     = true
}

variable "node_type" {
  description = "Override ElastiCache node type. If null, defaults to cache.r6g.large (prod) or cache.t4g.medium (non-prod)."
  type        = string
  default     = null
}

variable "enable_secret_rotation" {
  description = "Enable automatic rotation of the Redis auth token via Secrets Manager. Requires rotation_lambda_arn to be set."
  type        = bool
  default     = false
}

variable "rotation_lambda_arn" {
  description = "ARN of the Lambda function that handles Redis auth token rotation. Required when enable_secret_rotation = true."
  type        = string
  default     = ""
}

variable "rotation_days" {
  description = "Number of days between automatic secret rotations"
  type        = number
  default     = 90
}
