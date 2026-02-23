variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "secrets_access_policy_arn" {
  description = "ARN of the Secrets Manager access IAM policy for ESO IRSA"
  type        = string
}

variable "allowed_api_cidrs" {
  description = "CIDR blocks allowed to access the EKS API endpoint"
  type        = list(string)

  validation {
    condition     = length(var.allowed_api_cidrs) > 0 && !contains(var.allowed_api_cidrs, "0.0.0.0/0")
    error_message = "allowed_api_cidrs must be set and must not contain 0.0.0.0/0 for security."
  }
}

variable "eks_kms_key_arn" {
  description = "KMS key ARN for EKS secrets encryption"
  type        = string
  default     = ""
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.31"
}

variable "node_instance_types" {
  description = "EC2 instance types for EKS managed node group"
  type        = list(string)
  default     = null
}

variable "capacity_type" {
  description = "Capacity type for EKS managed node group (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.capacity_type)
    error_message = "capacity_type must be either ON_DEMAND or SPOT."
  }
}

variable "node_min_size" {
  description = "Minimum number of nodes in the EKS managed node group"
  type        = number
  default     = null
}

variable "node_max_size" {
  description = "Maximum number of nodes in the EKS managed node group"
  type        = number
  default     = null
}

variable "node_desired_size" {
  description = "Desired number of nodes in the EKS managed node group"
  type        = number
  default     = null
}
