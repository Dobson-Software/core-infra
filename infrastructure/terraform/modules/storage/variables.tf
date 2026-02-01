variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for S3/ECR encryption"
  type        = string
}
