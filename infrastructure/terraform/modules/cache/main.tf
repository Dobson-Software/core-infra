terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

################################################################################
# Cache Module — ElastiCache Redis
################################################################################

resource "aws_elasticache_subnet_group" "cobalt" {
  count = var.enable_cache ? 1 : 0

  name       = "cobalt-${var.environment}"
  subnet_ids = var.subnet_ids

  tags = {
    Environment = var.environment
  }
}

resource "aws_security_group" "redis" {
  count = var.enable_cache ? 1 : 0

  name_prefix = "cobalt-redis-${var.environment}-"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = var.allowed_security_groups
  }

  tags = {
    Name        = "cobalt-redis-${var.environment}"
    Environment = var.environment
  }
}

resource "random_password" "redis_auth" {
  count = var.enable_cache ? 1 : 0

  length  = 32
  special = false
}

resource "aws_elasticache_parameter_group" "cobalt" {
  count = var.enable_cache ? 1 : 0

  name   = "cobalt-${var.environment}-valkey7"
  family = "valkey7"

  description = "Custom parameter group for Cobalt ${var.environment} Valkey cluster"

  tags = {
    Environment = var.environment
    Module      = "cache"
  }
}

################################################################################
# Store Redis Auth Token in Secrets Manager
################################################################################

resource "aws_secretsmanager_secret" "redis_auth" {
  count = var.enable_cache ? 1 : 0

  name = "cobalt/${var.environment}/redis-auth"

  tags = {
    Environment = var.environment
    Module      = "cache"
  }
}

resource "aws_secretsmanager_secret_version" "redis_auth" {
  count = var.enable_cache ? 1 : 0

  secret_id = aws_secretsmanager_secret.redis_auth[0].id
  secret_string = jsonencode({
    password = random_password.redis_auth[0].result
  })
}

resource "aws_elasticache_replication_group" "cobalt" {
  count = var.enable_cache ? 1 : 0

  replication_group_id = "cobalt-${var.environment}"
  description          = "Cobalt Redis cluster - ${var.environment}"

  engine               = "valkey"
  engine_version       = "7.2"
  node_type            = var.environment == "prod" ? "cache.r6g.large" : "cache.t4g.medium"
  num_cache_clusters   = var.environment == "prod" ? 2 : 1
  parameter_group_name = aws_elasticache_parameter_group.cobalt[0].name
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.cobalt[0].name
  security_group_ids = [aws_security_group.redis[0].id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = random_password.redis_auth[0].result
  kms_key_id                 = var.kms_key_id != "" ? var.kms_key_id : null

  automatic_failover_enabled = var.environment == "prod"
  snapshot_retention_limit   = var.environment == "prod" ? 7 : 0

  tags = {
    Environment = var.environment
    Module      = "cache"
  }
}
