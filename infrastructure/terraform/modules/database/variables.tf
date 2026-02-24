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

# DEPRECATED: Password is now managed by RDS via Secrets Manager (manage_master_user_password = true).
# Retained for backward compatibility during migration.
variable "db_password" {
  description = "DEPRECATED: RDS password is now managed by Secrets Manager. Retained for backward compatibility."
  type        = string
  sensitive   = true
  default     = ""
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

variable "preferred_backup_window" {
  description = "Daily time range for automated backups (UTC). Format: hh24:mi-hh24:mi"
  type        = string
  default     = "03:00-04:00"
}

variable "instance_class" {
  description = "Override RDS instance class. If null, defaults to db.r6g.large (prod) or db.t4g.micro (non-prod)."
  type        = string
  default     = null
}
