variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the ALB"
  type        = list(string)
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block for ALB egress targeting"
  type        = string
}

variable "log_bucket_name" {
  description = "Name of the S3 bucket for ALB access logs"
  type        = string
}
