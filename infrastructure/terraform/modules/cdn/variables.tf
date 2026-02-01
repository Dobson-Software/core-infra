variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "frontend_bucket_id" {
  description = "ID of the frontend S3 bucket"
  type        = string
}

variable "frontend_bucket_domain" {
  description = "Regional domain name of the frontend S3 bucket"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the ALB for API origin"
  type        = string
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate (must be in us-east-1 for CloudFront)"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the CloudFront distribution"
  type        = string
}

variable "log_bucket_domain_name" {
  description = "Domain name of the S3 bucket for CloudFront access logs (e.g. my-bucket.s3.amazonaws.com)"
  type        = string
}
