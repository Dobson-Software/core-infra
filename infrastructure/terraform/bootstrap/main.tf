# Bootstrap module — run once to create the Terraform state infrastructure.
#
# Usage:
#   cd infrastructure/terraform/bootstrap
#   terraform init
#   terraform apply
#
# This creates:
#   - S3 bucket for Terraform state (versioned, encrypted, access-blocked)
#   - DynamoDB table for state locking
#
# After applying, configure backend in environment files:
#   terraform {
#     backend "s3" {
#       bucket         = "cobalt-terraform-state"
#       key            = "env/<environment>/terraform.tfstate"
#       region         = "us-east-1"
#       dynamodb_table = "cobalt-terraform-locks"
#       encrypt        = true
#     }
#   }

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project   = "cobalt"
      ManagedBy = "terraform-bootstrap"
    }
  }
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "cobalt-terraform-state"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "cobalt-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }
}

output "state_bucket_name" {
  value       = aws_s3_bucket.terraform_state.bucket
  description = "Name of the S3 bucket for Terraform state"
}

output "lock_table_name" {
  value       = aws_dynamodb_table.terraform_locks.name
  description = "Name of the DynamoDB table for state locking"
}
