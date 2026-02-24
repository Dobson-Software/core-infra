################################################################################
# Cobalt Platform — Staging Environment
#
# Intermediate environment between dev and prod for integration/load testing.
# Security matches prod (CMK, GuardDuty, Config). Compute is scaled down.
################################################################################

terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "cobalt-terraform-state"
    key            = "environments/staging/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "cobalt-terraform-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "cobalt"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

provider "aws" {
  alias  = "us_west_2"
  region = "us-west-2"

  default_tags {
    tags = {
      Project     = "cobalt"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

data "aws_eks_cluster" "this" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

################################################################################
# Variables
################################################################################

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.2.0.0/16"
}

variable "domain_name" {
  description = "Domain name for the environment"
  type        = string
}

variable "alert_email" {
  description = "Email for alarm notifications"
  type        = string
}

variable "allowed_api_cidrs" {
  description = "CIDRs allowed to access the EKS API server (e.g., office/VPN IPs)"
  type        = list(string)

  validation {
    condition     = length(var.allowed_api_cidrs) > 0
    error_message = "allowed_api_cidrs must be explicitly set — do not use a broad CIDR like 10.0.0.0/8."
  }

  validation {
    condition     = !contains(var.allowed_api_cidrs, "10.0.0.0/8") && !contains(var.allowed_api_cidrs, "0.0.0.0/0")
    error_message = "allowed_api_cidrs must not contain overly broad CIDRs (10.0.0.0/8 or 0.0.0.0/0)."
  }
}

variable "db_password" {
  description = "DEPRECATED: RDS password is now managed by Secrets Manager. Retained for backward compatibility."
  type        = string
  sensitive   = true
  default     = ""
}

variable "enable_secret_rotation" {
  description = "Enable automatic secret rotation (requires pg8000 Lambda layer)"
  type        = bool
  default     = false
}

################################################################################
# Security Base (must come first — provides KMS keys)
################################################################################

module "security_base" {
  source = "../../modules/security-base"

  environment            = var.environment
  alert_email            = var.alert_email
  enable_guardduty       = true
  enable_config          = true
  enable_cmk_keys        = true
  enable_secret_rotation = var.enable_secret_rotation
}

################################################################################
# Security Protection (Shield Advanced — depends on ALB/CDN)
################################################################################

module "security_protection" {
  source = "../../modules/security-protection"

  environment                 = var.environment
  enable_shield_advanced      = false
  alb_arn                     = module.load_balancer.alb_arn
  cloudfront_distribution_arn = module.cdn.distribution_arn
}

################################################################################
# Networking
################################################################################

module "networking" {
  source = "../../modules/networking"

  environment              = var.environment
  vpc_cidr                 = var.vpc_cidr
  aws_region               = var.aws_region
  enable_all_vpc_endpoints = false
  enable_ecr_vpc_endpoints = false
  enable_flow_log          = true
}

################################################################################
# EKS — scaled down from prod (t4g.medium, 2-5 nodes)
################################################################################

module "eks" {
  source = "../../modules/eks"

  environment               = var.environment
  vpc_id                    = module.networking.vpc_id
  subnet_ids                = module.networking.private_subnet_ids
  cluster_name              = "cobalt-${var.environment}"
  secrets_access_policy_arn = module.security_base.secrets_access_policy_arn
  eks_kms_key_arn           = module.security_base.kms_eks_key_arn
  allowed_api_cidrs         = var.allowed_api_cidrs
  node_instance_types       = ["t4g.medium"]
  capacity_type             = "ON_DEMAND"
  node_min_size             = 2
  node_max_size             = 5
  node_desired_size         = 2
}

################################################################################
# Database — single-AZ, no read replica (cost savings vs prod)
################################################################################

module "database" {
  source = "../../modules/database"

  environment             = var.environment
  vpc_id                  = module.networking.vpc_id
  subnet_ids              = module.networking.database_subnet_ids
  allowed_security_groups = [module.eks.cluster_security_group_id]
  kms_key_arn             = module.security_base.kms_rds_key_arn
  instance_class          = "db.t3.medium"
  enable_multi_az         = false

  providers = {
    aws           = aws
    aws.us_west_2 = aws.us_west_2
  }
}

################################################################################
# Cache
################################################################################

module "cache" {
  source = "../../modules/cache"

  environment             = var.environment
  vpc_id                  = module.networking.vpc_id
  subnet_ids              = module.networking.private_subnet_ids
  allowed_security_groups = [module.eks.cluster_security_group_id]
  kms_key_id              = module.security_base.kms_elasticache_key_arn
  node_type               = "cache.t3.small"
  enable_cache            = true
}

################################################################################
# Storage
################################################################################

module "storage" {
  source = "../../modules/storage"

  environment = var.environment
  kms_key_arn = module.security_base.kms_s3_key_arn
}

################################################################################
# DNS & TLS
################################################################################

module "dns_and_tls" {
  source = "../../modules/dns-and-tls"

  environment        = var.environment
  domain_name        = var.domain_name
  alb_dns_name       = module.load_balancer.alb_dns_name
  cloudfront_domain  = module.cdn.distribution_domain_name
  cloudfront_zone_id = module.cdn.distribution_hosted_zone_id
}

################################################################################
# Load Balancer
################################################################################

module "load_balancer" {
  source = "../../modules/load-balancer"

  environment       = var.environment
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  certificate_arn   = module.dns_and_tls.certificate_arn
  vpc_cidr          = var.vpc_cidr
  log_bucket_name   = module.storage.log_bucket_name
}

################################################################################
# CDN
################################################################################

module "cdn" {
  source = "../../modules/cdn"

  environment            = var.environment
  frontend_bucket_id     = module.storage.frontend_bucket_id
  frontend_bucket_domain = module.storage.frontend_bucket_domain
  alb_dns_name           = module.load_balancer.alb_dns_name
  certificate_arn        = module.dns_and_tls.certificate_arn
  domain_name            = var.domain_name
  log_bucket_domain_name = "${module.storage.log_bucket_name}.s3.amazonaws.com"
}

################################################################################
# Monitoring
################################################################################

module "monitoring" {
  source = "../../modules/monitoring"

  environment             = var.environment
  eks_cluster_name        = module.eks.cluster_name
  rds_instance_id         = "cobalt-${var.environment}"
  alb_arn_suffix          = module.load_balancer.alb_arn_suffix
  elasticache_id          = "cobalt-${var.environment}"
  alert_email             = var.alert_email
  vpc_flow_log_group_name = module.networking.flow_log_group_name
  sns_kms_key_id          = module.security_base.kms_sns_key_arn
}

################################################################################
# AI Incident Response (SNS -> Lambda -> Claude API -> GitHub Issue)
################################################################################

module "incident_response" {
  source = "../../modules/incident-response"

  environment                = var.environment
  enable_incident_response   = false
  sns_alert_topic_arn        = module.monitoring.sns_topic_arn
  secrets_manager_secret_id  = "cobalt-${var.environment}-incident-response"
  secrets_manager_secret_arn = "arn:aws:secretsmanager:${var.aws_region}:*:secret:cobalt-${var.environment}-incident-response-*"
  github_repo                = "Dobson-Software/cobalt"
}

################################################################################
# Outputs
################################################################################

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.networking.vpc_id
}

output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "The endpoint URL for the EKS cluster API server"
  value       = module.eks.cluster_endpoint
}

output "rds_endpoint" {
  description = "The connection endpoint for the primary RDS instance"
  value       = module.database.endpoint
}

output "redis_endpoint" {
  description = "The connection endpoint for the Redis cluster"
  value       = module.cache.endpoint
}

output "s3_uploads_bucket" {
  description = "The name of the S3 bucket used for file uploads"
  value       = module.storage.uploads_bucket
}

output "ecr_repositories" {
  description = "Map of ECR repository URLs for container images"
  value       = module.storage.ecr_repository_urls
}

output "cloudfront_domain" {
  description = "The domain name of the CloudFront distribution"
  value       = module.cdn.distribution_domain_name
}

output "name_servers" {
  description = "The name servers for the Route 53 hosted zone"
  value       = module.dns_and_tls.name_servers
}
