output "uploads_bucket" {
  description = "Name of the uploads S3 bucket"
  value       = aws_s3_bucket.uploads.bucket
}

output "frontend_bucket" {
  description = "Name of the frontend assets S3 bucket"
  value       = aws_s3_bucket.frontend.bucket
}

output "frontend_bucket_id" {
  description = "ID of the frontend assets S3 bucket"
  value       = aws_s3_bucket.frontend.id
}

output "frontend_bucket_domain" {
  description = "Regional domain name of the frontend bucket"
  value       = aws_s3_bucket.frontend.bucket_regional_domain_name
}

output "log_bucket_name" {
  description = "Name of the ALB access logs S3 bucket"
  value       = aws_s3_bucket.alb_logs.bucket
}

output "ecr_repository_urls" {
  description = "Map of ECR repository URLs"
  value       = { for k, v in aws_ecr_repository.services : k => v.repository_url }
}
