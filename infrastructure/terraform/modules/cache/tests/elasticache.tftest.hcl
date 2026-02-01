################################################################################
# Cache Module Tests — ElastiCache Redis Replication Group, SG, Subnet Group
################################################################################

mock_provider "aws" {}

mock_provider "random" {}

variables {
  environment             = "dev"
  vpc_id                  = "vpc-test123"
  subnet_ids              = ["subnet-a", "subnet-b", "subnet-c"]
  allowed_security_groups = ["sg-test123"]
  kms_key_id              = "arn:aws:kms:us-east-1:123456789012:key/test-key"
}

run "dev_uses_t3_medium_node_type" {
  command = plan

  assert {
    condition     = aws_elasticache_replication_group.cobalt.node_type == "cache.t3.medium"
    error_message = "Dev environment should use cache.t3.medium node type"
  }
}

run "dev_single_cache_cluster" {
  command = plan

  assert {
    condition     = aws_elasticache_replication_group.cobalt.num_cache_clusters == 1
    error_message = "Dev environment should have exactly 1 cache cluster"
  }
}

run "dev_no_automatic_failover" {
  command = plan

  assert {
    condition     = aws_elasticache_replication_group.cobalt.automatic_failover_enabled == false
    error_message = "Dev environment should not enable automatic failover"
  }
}

run "dev_no_snapshots" {
  command = plan

  assert {
    condition     = aws_elasticache_replication_group.cobalt.snapshot_retention_limit == 0
    error_message = "Dev environment should have snapshot retention limit of 0"
  }
}

run "engine_is_redis" {
  command = plan

  assert {
    condition     = aws_elasticache_replication_group.cobalt.engine == "redis"
    error_message = "Engine must be redis"
  }
}

run "engine_version_is_7" {
  command = plan

  assert {
    condition     = aws_elasticache_replication_group.cobalt.engine_version == "7.0"
    error_message = "Engine version must be 7.0"
  }
}

run "at_rest_encryption_enabled" {
  command = plan

  assert {
    condition     = aws_elasticache_replication_group.cobalt.at_rest_encryption_enabled == true
    error_message = "At-rest encryption must be enabled"
  }
}

run "transit_encryption_enabled" {
  command = plan

  assert {
    condition     = aws_elasticache_replication_group.cobalt.transit_encryption_enabled == true
    error_message = "Transit encryption must be enabled"
  }
}

run "port_is_6379" {
  command = plan

  assert {
    condition     = aws_elasticache_replication_group.cobalt.port == 6379
    error_message = "Redis port should be 6379"
  }
}

run "security_group_allows_6379" {
  command = plan

  assert {
    condition     = aws_security_group.redis.ingress != null
    error_message = "Redis security group must have ingress rules defined"
  }
}

run "subnet_group_uses_provided_subnets" {
  command = plan

  assert {
    condition     = length(aws_elasticache_subnet_group.cobalt.subnet_ids) == 3
    error_message = "Subnet group should contain all 3 provided subnets"
  }
}

run "prod_uses_r6g_large_node_type" {
  command = plan

  variables {
    environment = "prod"
  }

  assert {
    condition     = aws_elasticache_replication_group.cobalt.node_type == "cache.r6g.large"
    error_message = "Prod environment should use cache.r6g.large node type"
  }
}

run "prod_two_cache_clusters" {
  command = plan

  variables {
    environment = "prod"
  }

  assert {
    condition     = aws_elasticache_replication_group.cobalt.num_cache_clusters == 2
    error_message = "Prod environment should have 2 cache clusters"
  }
}

run "prod_automatic_failover_enabled" {
  command = plan

  variables {
    environment = "prod"
  }

  assert {
    condition     = aws_elasticache_replication_group.cobalt.automatic_failover_enabled == true
    error_message = "Prod environment should enable automatic failover"
  }
}

run "prod_snapshot_retention_7_days" {
  command = plan

  variables {
    environment = "prod"
  }

  assert {
    condition     = aws_elasticache_replication_group.cobalt.snapshot_retention_limit == 7
    error_message = "Prod snapshot retention should be 7 days"
  }
}
