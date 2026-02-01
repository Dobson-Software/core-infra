variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of database subnet IDs"
  type        = list(string)
}

variable "allowed_security_groups" {
  description = "List of security group IDs allowed to access RDS"
  type        = list(string)
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for RDS encryption"
  type        = string
}

variable "enable_multi_az" {
  description = "Enable Multi-AZ deployment for RDS"
  type        = bool
  default     = null
}

variable "enable_read_replica" {
  description = "Enable read replica for RDS"
  type        = bool
  default     = null
}
