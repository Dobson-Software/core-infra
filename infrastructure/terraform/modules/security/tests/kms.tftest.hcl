################################################################################
# Security Module Tests — KMS Keys, CloudTrail, S3 Public Access, Secrets
################################################################################

mock_provider "aws" {
  override_data {
    target = data.aws_caller_identity.current
    values = {
      account_id = "123456789012"
    }
  }

  override_data {
    target = data.aws_region.current
    values = {
      name = "us-east-1"
    }
  }
}

variables {
  environment = "dev"
}

run "rds_kms_key_has_rotation" {
  command = plan

  assert {
    condition     = aws_kms_key.rds.enable_key_rotation == true
    error_message = "RDS KMS key must have rotation enabled"
  }
}

run "s3_kms_key_has_rotation" {
  command = plan

  assert {
    condition     = aws_kms_key.s3.enable_key_rotation == true
    error_message = "S3 KMS key must have rotation enabled"
  }
}

run "secrets_kms_key_has_rotation" {
  command = plan

  assert {
    condition     = aws_kms_key.secrets.enable_key_rotation == true
    error_message = "Secrets Manager KMS key must have rotation enabled"
  }
}

run "eks_kms_key_has_rotation" {
  command = plan

  assert {
    condition     = aws_kms_key.eks.enable_key_rotation == true
    error_message = "EKS KMS key must have rotation enabled"
  }
}

run "four_kms_keys_created" {
  command = plan

  assert {
    condition     = aws_kms_key.rds.description != "" && aws_kms_key.s3.description != "" && aws_kms_key.secrets.description != "" && aws_kms_key.eks.description != ""
    error_message = "All four KMS keys (rds, s3, secrets, eks) must be created"
  }
}

run "cloudtrail_is_multi_region" {
  command = plan

  assert {
    condition     = aws_cloudtrail.main.is_multi_region_trail == true
    error_message = "CloudTrail must be multi-region"
  }
}

run "cloudtrail_log_validation_enabled" {
  command = plan

  assert {
    condition     = aws_cloudtrail.main.enable_log_file_validation == true
    error_message = "CloudTrail log file validation must be enabled"
  }
}

run "cloudtrail_bucket_blocks_public_access" {
  command = plan

  assert {
    condition     = aws_s3_bucket_public_access_block.cloudtrail.block_public_acls == true
    error_message = "CloudTrail S3 bucket must block public ACLs"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.cloudtrail.block_public_policy == true
    error_message = "CloudTrail S3 bucket must block public policy"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.cloudtrail.ignore_public_acls == true
    error_message = "CloudTrail S3 bucket must ignore public ACLs"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.cloudtrail.restrict_public_buckets == true
    error_message = "CloudTrail S3 bucket must restrict public buckets"
  }
}

run "jwt_secret_created" {
  command = plan

  assert {
    condition     = aws_secretsmanager_secret.jwt_secret.name == "cobalt/dev/jwt-secret"
    error_message = "JWT secret must be created with correct name"
  }
}

run "db_password_secret_created" {
  command = plan

  assert {
    condition     = aws_secretsmanager_secret.db_password.name == "cobalt/dev/db-password"
    error_message = "DB password secret must be created with correct name"
  }
}

run "cloudtrail_bucket_encrypted_with_kms" {
  command = plan

  assert {
    condition     = [for r in aws_s3_bucket_server_side_encryption_configuration.cloudtrail.rule : r.apply_server_side_encryption_by_default[0].sse_algorithm][0] == "aws:kms"
    error_message = "CloudTrail bucket must use KMS encryption"
  }
}
