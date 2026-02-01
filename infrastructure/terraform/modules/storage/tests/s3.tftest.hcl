################################################################################
# Storage Module Tests — S3 Buckets, ECR Repositories, Lifecycle Policies
################################################################################

mock_provider "aws" {}

variables {
  environment = "dev"
  kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/test-key"
}

run "uploads_bucket_encryption_uses_kms" {
  command = plan

  assert {
    condition     = aws_s3_bucket_server_side_encryption_configuration.uploads.rule[0].apply_server_side_encryption_by_default[0].sse_algorithm == "aws:kms"
    error_message = "Uploads bucket must use aws:kms encryption"
  }
}

run "uploads_bucket_versioning_enabled" {
  command = plan

  assert {
    condition     = aws_s3_bucket_versioning.uploads.versioning_configuration[0].status == "Enabled"
    error_message = "Uploads bucket versioning must be enabled"
  }
}

run "uploads_bucket_blocks_public_access" {
  command = plan

  assert {
    condition     = aws_s3_bucket_public_access_block.uploads.block_public_acls == true
    error_message = "Uploads bucket must block public ACLs"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.uploads.block_public_policy == true
    error_message = "Uploads bucket must block public policy"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.uploads.ignore_public_acls == true
    error_message = "Uploads bucket must ignore public ACLs"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.uploads.restrict_public_buckets == true
    error_message = "Uploads bucket must restrict public buckets"
  }
}

run "frontend_bucket_encryption_aes256" {
  command = plan

  assert {
    condition     = aws_s3_bucket_server_side_encryption_configuration.frontend.rule[0].apply_server_side_encryption_by_default[0].sse_algorithm == "AES256"
    error_message = "Frontend bucket must use AES256 encryption"
  }
}

run "frontend_bucket_blocks_public_access" {
  command = plan

  assert {
    condition     = aws_s3_bucket_public_access_block.frontend.block_public_acls == true
    error_message = "Frontend bucket must block public ACLs"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.frontend.restrict_public_buckets == true
    error_message = "Frontend bucket must restrict public buckets"
  }
}

run "ecr_repos_created_for_all_services" {
  command = plan

  assert {
    condition     = length(aws_ecr_repository.services) == 4
    error_message = "Must create ECR repositories for all 4 services (core, notification, violations, frontend)"
  }
}

run "ecr_image_tag_immutability" {
  command = plan

  assert {
    condition     = aws_ecr_repository.services["cobalt/core-service"].image_tag_mutability == "IMMUTABLE"
    error_message = "ECR repositories must have IMMUTABLE image tag mutability"
  }
}

run "ecr_scan_on_push_enabled" {
  command = plan

  assert {
    condition     = aws_ecr_repository.services["cobalt/core-service"].image_scanning_configuration[0].scan_on_push == true
    error_message = "ECR repositories must have scan on push enabled"
  }
}

run "ecr_encryption_uses_kms" {
  command = plan

  assert {
    condition     = aws_ecr_repository.services["cobalt/core-service"].encryption_configuration[0].encryption_type == "KMS"
    error_message = "ECR repositories must use KMS encryption"
  }
}

run "ecr_lifecycle_policies_created" {
  command = plan

  assert {
    condition     = length(aws_ecr_lifecycle_policy.services) == 4
    error_message = "Lifecycle policies must be created for all 4 ECR repositories"
  }
}

run "dev_no_s3_replication" {
  command = plan

  assert {
    condition     = length(aws_s3_bucket_replication_configuration.uploads) == 0
    error_message = "Dev environment should not have S3 replication"
  }
}

run "dev_no_ecr_replication" {
  command = plan

  assert {
    condition     = length(aws_ecr_replication_configuration.cross_region) == 0
    error_message = "Dev environment should not have ECR cross-region replication"
  }
}

run "prod_enables_s3_replication" {
  command = plan

  variables {
    environment = "prod"
  }

  assert {
    condition     = length(aws_s3_bucket_replication_configuration.uploads) == 1
    error_message = "Prod environment must enable S3 replication"
  }
}

run "prod_enables_ecr_replication" {
  command = plan

  variables {
    environment = "prod"
  }

  assert {
    condition     = length(aws_ecr_replication_configuration.cross_region) == 1
    error_message = "Prod environment must enable ECR cross-region replication"
  }
}
