################################################################################
# Database Module Tests — RDS Instance Classes, Encryption, HA, Backups
################################################################################

mock_provider "aws" {}

mock_provider "aws" {
  alias = "us_west_2"
}

variables {
  environment             = "dev"
  vpc_id                  = "vpc-test123"
  subnet_ids              = ["subnet-a", "subnet-b", "subnet-c"]
  allowed_security_groups = ["sg-test123"]
  db_password             = "test-password-not-real"
  kms_key_arn             = "arn:aws:kms:us-east-1:123456789012:key/test-key"
}

run "dev_uses_t4g_micro_instance" {
  command = plan

  assert {
    condition     = aws_db_instance.primary.instance_class == "db.t4g.micro"
    error_message = "Dev environment should use db.t4g.micro instance class"
  }
}

run "dev_single_az" {
  command = plan

  assert {
    condition     = aws_db_instance.primary.multi_az == false
    error_message = "Dev environment should not enable multi-AZ"
  }
}

run "dev_backup_retention_7_days" {
  command = plan

  assert {
    condition     = aws_db_instance.primary.backup_retention_period == 7
    error_message = "Dev backup retention should be 7 days"
  }
}

run "dev_no_deletion_protection" {
  command = plan

  assert {
    condition     = aws_db_instance.primary.deletion_protection == false
    error_message = "Dev should not have deletion protection"
  }
}

run "dev_no_read_replica" {
  command = plan

  assert {
    condition     = length(aws_db_instance.read_replica) == 0
    error_message = "Dev should not create a read replica"
  }
}

run "encryption_enabled" {
  command = plan

  assert {
    condition     = aws_db_instance.primary.storage_encrypted == true
    error_message = "Storage encryption must be enabled"
  }
}

run "prod_uses_r6g_large_instance" {
  command = plan

  variables {
    environment = "prod"
  }

  assert {
    condition     = aws_db_instance.primary.instance_class == "db.r6g.large"
    error_message = "Prod environment should use db.r6g.large instance class"
  }
}

run "prod_multi_az_enabled" {
  command = plan

  variables {
    environment = "prod"
  }

  assert {
    condition     = aws_db_instance.primary.multi_az == true
    error_message = "Prod environment should enable multi-AZ"
  }
}

run "prod_backup_retention_30_days" {
  command = plan

  variables {
    environment = "prod"
  }

  assert {
    condition     = aws_db_instance.primary.backup_retention_period == 30
    error_message = "Prod backup retention should be 30 days"
  }
}

run "prod_deletion_protection_enabled" {
  command = plan

  variables {
    environment = "prod"
  }

  assert {
    condition     = aws_db_instance.primary.deletion_protection == true
    error_message = "Prod should have deletion protection enabled"
  }
}

run "prod_creates_read_replica" {
  command = plan

  variables {
    environment = "prod"
  }

  assert {
    condition     = length(aws_db_instance.read_replica) == 1
    error_message = "Prod should create exactly one read replica"
  }
}
