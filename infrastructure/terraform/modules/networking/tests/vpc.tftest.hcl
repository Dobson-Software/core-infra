################################################################################
# Networking Module Tests — VPC, Subnets, Flow Logs, Endpoints
################################################################################

mock_provider "aws" {
  override_data {
    target = data.aws_availability_zones.available
    values = {
      names = ["us-east-1a", "us-east-1b", "us-east-1c"]
    }
  }
}

override_module {
  target = module.vpc
  outputs = {
    vpc_id                       = "vpc-mock123"
    vpc_cidr_block               = "10.0.0.0/16"
    private_subnets              = ["subnet-priv-1", "subnet-priv-2", "subnet-priv-3"]
    public_subnets               = ["subnet-pub-1", "subnet-pub-2", "subnet-pub-3"]
    database_subnets             = ["subnet-db-1", "subnet-db-2", "subnet-db-3"]
    private_subnets_cidr_blocks  = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
    private_route_table_ids      = ["rtb-priv-1"]
    vpc_flow_log_id              = "fl-mock123"
    vpc_flow_log_destination_arn = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/vpc-flow-log/cobalt-dev"
  }
}

variables {
  environment = "dev"
  vpc_cidr    = "10.0.0.0/16"
  aws_region  = "us-east-1"
}

run "vpc_cidr_is_correct" {
  command = plan

  assert {
    condition     = module.vpc.vpc_cidr_block == "10.0.0.0/16"
    error_message = "VPC CIDR block should be 10.0.0.0/16"
  }
}

run "creates_three_private_subnets" {
  command = plan

  assert {
    condition     = length(module.vpc.private_subnets) == 3
    error_message = "Should create exactly 3 private subnets"
  }
}

run "creates_three_public_subnets" {
  command = plan

  assert {
    condition     = length(module.vpc.public_subnets) == 3
    error_message = "Should create exactly 3 public subnets"
  }
}

run "creates_three_database_subnets" {
  command = plan

  assert {
    condition     = length(module.vpc.database_subnets) == 3
    error_message = "Should create exactly 3 database subnets"
  }
}

run "flow_logs_enabled" {
  command = plan

  assert {
    condition     = module.vpc.vpc_flow_log_id != ""
    error_message = "VPC flow logs should be enabled"
  }
}

run "s3_endpoint_created" {
  command = plan

  assert {
    condition     = aws_vpc_endpoint.s3.vpc_endpoint_type == "Gateway"
    error_message = "S3 VPC endpoint should be a Gateway type"
  }
}

run "ecr_dkr_endpoint_created" {
  command = plan

  assert {
    condition     = aws_vpc_endpoint.ecr_dkr[0].vpc_endpoint_type == "Interface"
    error_message = "ECR Docker endpoint should be an Interface type"
  }
}

run "ecr_api_endpoint_created" {
  command = plan

  assert {
    condition     = aws_vpc_endpoint.ecr_api[0].vpc_endpoint_type == "Interface"
    error_message = "ECR API endpoint should be an Interface type"
  }
}

run "secretsmanager_endpoint_created" {
  command = plan

  assert {
    condition     = aws_vpc_endpoint.secretsmanager[0].vpc_endpoint_type == "Interface"
    error_message = "Secrets Manager endpoint should be an Interface type"
  }
}

run "logs_endpoint_created" {
  command = plan

  assert {
    condition     = aws_vpc_endpoint.logs[0].vpc_endpoint_type == "Interface"
    error_message = "CloudWatch Logs endpoint should be an Interface type"
  }
}
