terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

################################################################################
# Networking Module — VPC, Subnets, Endpoints
################################################################################

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "cobalt-${var.environment}-vpc"
  cidr = var.vpc_cidr

  azs              = local.azs
  private_subnets  = [for i in range(3) : cidrsubnet(var.vpc_cidr, 8, i)]
  public_subnets   = [for i in range(3) : cidrsubnet(var.vpc_cidr, 8, i + 100)]
  database_subnets = [for i in range(3) : cidrsubnet(var.vpc_cidr, 8, i + 200)]

  create_database_subnet_group = true

  enable_nat_gateway   = true
  single_nat_gateway   = var.environment != "prod"
  enable_dns_hostnames = true
  enable_dns_support   = true

  # VPC Flow Logs
  enable_flow_log                      = var.enable_flow_log
  create_flow_log_cloudwatch_log_group = var.enable_flow_log
  create_flow_log_cloudwatch_iam_role  = var.enable_flow_log
  flow_log_max_aggregation_interval    = 60

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  tags = {
    Environment = var.environment
    Module      = "networking"
  }
}

################################################################################
# VPC Endpoints
################################################################################

resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "cobalt-vpce-${var.environment}-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "cobalt-vpce-${var.environment}"
  }
}

# S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc.private_route_table_ids

  tags = {
    Name = "cobalt-${var.environment}-s3-endpoint"
  }
}

# ECR Docker Interface Endpoint
resource "aws_vpc_endpoint" "ecr_dkr" {
  count = var.enable_ecr_vpc_endpoints ? 1 : 0

  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "cobalt-${var.environment}-ecr-dkr-endpoint"
  }
}

# ECR API Interface Endpoint
resource "aws_vpc_endpoint" "ecr_api" {
  count = var.enable_ecr_vpc_endpoints ? 1 : 0

  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "cobalt-${var.environment}-ecr-api-endpoint"
  }
}

# Secrets Manager Interface Endpoint
resource "aws_vpc_endpoint" "secretsmanager" {
  count = var.enable_all_vpc_endpoints ? 1 : 0

  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "cobalt-${var.environment}-secretsmanager-endpoint"
  }
}

# CloudWatch Logs Interface Endpoint
resource "aws_vpc_endpoint" "logs" {
  count = var.enable_all_vpc_endpoints ? 1 : 0

  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "cobalt-${var.environment}-logs-endpoint"
  }
}
