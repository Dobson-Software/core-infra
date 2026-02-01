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
