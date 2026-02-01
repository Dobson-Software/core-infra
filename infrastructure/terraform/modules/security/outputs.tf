output "kms_rds_key_arn" {
  description = "ARN of the KMS key for RDS encryption"
  value       = aws_kms_key.rds.arn
}

output "kms_s3_key_arn" {
  description = "ARN of the KMS key for S3 encryption"
  value       = aws_kms_key.s3.arn
}

output "kms_secrets_key_arn" {
  description = "ARN of the KMS key for Secrets Manager"
  value       = aws_kms_key.secrets.arn
}

output "kms_eks_key_arn" {
  description = "ARN of the KMS key for EKS envelope encryption"
  value       = aws_kms_key.eks.arn
}

output "cloudtrail_bucket" {
  description = "Name of the CloudTrail S3 bucket"
  value       = aws_s3_bucket.cloudtrail.bucket
}

output "guardduty_detector_id" {
  description = "ID of the GuardDuty detector"
  value       = var.enable_guardduty ? aws_guardduty_detector.main[0].id : ""
}

output "config_recorder_id" {
  description = "ID of the AWS Config configuration recorder"
  value       = aws_config_configuration_recorder.main.id
}

output "secrets_access_policy_arn" {
  description = "ARN of the Secrets Manager access IAM policy for ESO IRSA"
  value       = aws_iam_policy.secrets_access.arn
}
