variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "rds_instance_id" {
  description = "Identifier of the RDS instance"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the ALB (for CloudWatch dimensions)"
  type        = string
}

variable "elasticache_id" {
  description = "ID of the ElastiCache replication group"
  type        = string
}

variable "alert_email" {
  description = "Email address for alarm notifications"
  type        = string
}

variable "vpc_flow_log_group_name" {
  description = "Name of the VPC flow log CloudWatch log group"
  type        = string
  default     = ""
}

variable "sns_kms_key_id" {
  description = "KMS key ID or ARN for encrypting SNS topic messages"
  type        = string
}
