variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "enable_all_vpc_endpoints" {
  description = "Enable all VPC interface endpoints (set false for dev to save costs)"
  type        = bool
  default     = true
}

variable "enable_flow_log" {
  description = "Enable VPC flow logs"
  type        = bool
  default     = true
}

variable "enable_ecr_vpc_endpoints" {
  description = "Enable ECR VPC interface endpoints (ecr.dkr and ecr.api)"
  type        = bool
  default     = true
}
