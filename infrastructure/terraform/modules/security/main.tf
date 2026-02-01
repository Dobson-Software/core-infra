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
# Security Module — KMS, CloudTrail, IRSA Policies, Secrets Manager
################################################################################

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

################################################################################
# KMS Customer Managed Keys
################################################################################

resource "aws_kms_key" "rds" {
  description             = "Cobalt ${var.environment} - RDS encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Environment = var.environment
    Module      = "security"
    Purpose     = "rds"
  }
}

resource "aws_kms_alias" "rds" {
  name          = "alias/cobalt-${var.environment}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

resource "aws_kms_key" "s3" {
  description             = "Cobalt ${var.environment} - S3 encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Environment = var.environment
    Module      = "security"
    Purpose     = "s3"
  }
}

resource "aws_kms_alias" "s3" {
  name          = "alias/cobalt-${var.environment}-s3"
  target_key_id = aws_kms_key.s3.key_id
}

resource "aws_kms_key" "secrets" {
  description             = "Cobalt ${var.environment} - Secrets Manager encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Environment = var.environment
    Module      = "security"
    Purpose     = "secrets-manager"
  }
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/cobalt-${var.environment}-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}

resource "aws_kms_key" "eks" {
  description             = "Cobalt ${var.environment} - EKS envelope encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Environment = var.environment
    Module      = "security"
    Purpose     = "eks"
  }
}

resource "aws_kms_alias" "eks" {
  name          = "alias/cobalt-${var.environment}-eks"
  target_key_id = aws_kms_key.eks.key_id
}

################################################################################
# CloudTrail
################################################################################

resource "aws_s3_bucket" "cloudtrail" {
  bucket = "cobalt-${var.environment}-cloudtrail-${local.account_id}"

  tags = {
    Environment = var.environment
    Module      = "security"
  }
}

resource "aws_s3_bucket_versioning" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    id     = "glacier-transition"
    status = "Enabled"

    filter {}

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail.arn}/AWSLogs/${local.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_cloudtrail" "main" {
  name                       = "cobalt-${var.environment}"
  s3_bucket_name             = aws_s3_bucket.cloudtrail.id
  is_multi_region_trail      = true
  enable_log_file_validation = true
  kms_key_id                 = aws_kms_key.s3.arn

  tags = {
    Environment = var.environment
    Module      = "security"
  }

  depends_on = [aws_s3_bucket_policy.cloudtrail]
}

################################################################################
# IRSA IAM Policies for Service Accounts
################################################################################

# S3 Access Policy
resource "aws_iam_policy" "s3_access" {
  name = "cobalt-${var.environment}-s3-access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::cobalt-uploads-${var.environment}-*",
          "arn:aws:s3:::cobalt-uploads-${var.environment}-*/*"
        ]
      }
    ]
  })

  tags = { Environment = var.environment }
}

# Secrets Manager Access Policy
resource "aws_iam_policy" "secrets_access" {
  name = "cobalt-${var.environment}-secrets-access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:${data.aws_region.current.name}:${local.account_id}:secret:cobalt/${var.environment}/*"
      },
      {
        Effect   = "Allow"
        Action   = "kms:Decrypt"
        Resource = aws_kms_key.secrets.arn
      }
    ]
  })

  tags = { Environment = var.environment }
}

# CloudWatch Logs Access Policy
resource "aws_iam_policy" "cloudwatch_logs" {
  name = "cobalt-${var.environment}-cloudwatch-logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${local.account_id}:log-group:/cobalt/${var.environment}/*"
      }
    ]
  })

  tags = { Environment = var.environment }
}

################################################################################
# Secrets Manager Secrets with Rotation
################################################################################

resource "aws_secretsmanager_secret" "jwt_secret" {
  name       = "cobalt/${var.environment}/jwt-secret"
  kms_key_id = aws_kms_key.secrets.arn

  tags = {
    Environment = var.environment
    Module      = "security"
  }
}

resource "aws_secretsmanager_secret" "stripe_keys" {
  name       = "cobalt/${var.environment}/stripe-keys"
  kms_key_id = aws_kms_key.secrets.arn

  tags = {
    Environment = var.environment
    Module      = "security"
  }
}

resource "aws_secretsmanager_secret" "twilio_credentials" {
  name       = "cobalt/${var.environment}/twilio-credentials"
  kms_key_id = aws_kms_key.secrets.arn

  tags = {
    Environment = var.environment
    Module      = "security"
  }
}

resource "aws_secretsmanager_secret" "socrata_token" {
  name       = "cobalt/${var.environment}/socrata-token"
  kms_key_id = aws_kms_key.secrets.arn

  tags = {
    Environment = var.environment
    Module      = "security"
  }
}

resource "aws_secretsmanager_secret" "db_password" {
  name       = "cobalt/${var.environment}/db-password"
  kms_key_id = aws_kms_key.secrets.arn

  tags = {
    Environment = var.environment
    Module      = "security"
  }
}

resource "aws_secretsmanager_secret_rotation" "db_password" {
  count = var.enable_secret_rotation ? 1 : 0

  secret_id           = aws_secretsmanager_secret.db_password.id
  rotation_lambda_arn = "arn:aws:lambda:${data.aws_region.current.name}:${local.account_id}:function:cobalt-${var.environment}-secret-rotation"

  rotation_rules {
    automatically_after_days = 30
  }
}

################################################################################
# GuardDuty
################################################################################

resource "aws_guardduty_detector" "main" {
  count = var.enable_guardduty ? 1 : 0

  enable = true

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }

  tags = {
    Environment = var.environment
    Module      = "security"
  }
}

resource "aws_sns_topic" "guardduty_alerts" {
  count = var.enable_guardduty ? 1 : 0

  name              = "cobalt-${var.environment}-guardduty-alerts"
  kms_master_key_id = aws_kms_key.secrets.arn

  tags = {
    Environment = var.environment
    Module      = "security"
  }
}

resource "aws_sns_topic_subscription" "guardduty_email" {
  count = var.enable_guardduty && var.alert_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.guardduty_alerts[0].arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  count = var.enable_guardduty ? 1 : 0

  name        = "cobalt-${var.environment}-guardduty-findings"
  description = "Route GuardDuty findings with severity >= 4 to SNS"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [{ numeric = [">=", 4] }]
    }
  })

  tags = {
    Environment = var.environment
    Module      = "security"
  }
}

resource "aws_cloudwatch_event_target" "guardduty_sns" {
  count = var.enable_guardduty ? 1 : 0

  rule      = aws_cloudwatch_event_rule.guardduty_findings[0].name
  target_id = "guardduty-to-sns"
  arn       = aws_sns_topic.guardduty_alerts[0].arn
}

resource "aws_sns_topic_policy" "guardduty_alerts" {
  count = var.enable_guardduty ? 1 : 0

  arn = aws_sns_topic.guardduty_alerts[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEventBridgePublish"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.guardduty_alerts[0].arn
      }
    ]
  })
}

################################################################################
# Shield Advanced (optional)
################################################################################

resource "aws_shield_protection" "alb" {
  count = var.enable_shield_advanced && var.alb_arn != "" ? 1 : 0

  name         = "cobalt-${var.environment}-alb-shield"
  resource_arn = var.alb_arn

  tags = {
    Environment = var.environment
    Module      = "security"
  }
}

resource "aws_shield_protection" "cloudfront" {
  count = var.enable_shield_advanced && var.cloudfront_distribution_arn != "" ? 1 : 0

  name         = "cobalt-${var.environment}-cloudfront-shield"
  resource_arn = var.cloudfront_distribution_arn

  tags = {
    Environment = var.environment
    Module      = "security"
  }
}

################################################################################
# AWS Config
################################################################################

resource "aws_s3_bucket" "config" {
  bucket = "cobalt-${var.environment}-config-${local.account_id}"

  tags = {
    Environment = var.environment
    Module      = "security"
  }
}

resource "aws_s3_bucket_versioning" "config" {
  bucket = aws_s3_bucket.config.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config" {
  bucket = aws_s3_bucket.config.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "config" {
  bucket = aws_s3_bucket.config.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "config" {
  bucket = aws_s3_bucket.config.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSConfigBucketPermissionsCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.config.arn
      },
      {
        Sid    = "AWSConfigBucketDelivery"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.config.arn}/AWSLogs/${local.account_id}/Config/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role" "config" {
  name = "cobalt-${var.environment}-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })

  tags = { Environment = var.environment }
}

resource "aws_iam_role_policy_attachment" "config" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_config_configuration_recorder" "main" {
  name     = "cobalt-${var.environment}"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported = true
  }
}

resource "aws_config_delivery_channel" "main" {
  name           = "cobalt-${var.environment}"
  s3_bucket_name = aws_s3_bucket.config.bucket

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.main]
}

# AWS Config Managed Rules
resource "aws_config_config_rule" "s3_encryption" {
  name = "cobalt-${var.environment}-s3-encryption"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "rds_encryption" {
  name = "cobalt-${var.environment}-rds-encryption"

  source {
    owner             = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "vpc_flow_logs" {
  name = "cobalt-${var.environment}-vpc-flow-logs"

  source {
    owner             = "AWS"
    source_identifier = "VPC_FLOW_LOGS_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "encrypted_volumes" {
  name = "cobalt-${var.environment}-encrypted-volumes"

  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "iam_password_policy" {
  name = "cobalt-${var.environment}-iam-password-policy"

  source {
    owner             = "AWS"
    source_identifier = "IAM_PASSWORD_POLICY"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "restricted_common_ports" {
  name = "cobalt-${var.environment}-restricted-common-ports"

  source {
    owner             = "AWS"
    source_identifier = "RESTRICTED_INCOMING_TRAFFIC"
  }

  depends_on = [aws_config_configuration_recorder.main]
}
