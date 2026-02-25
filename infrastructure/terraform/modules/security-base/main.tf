terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

################################################################################
# Security Base Module — KMS, CloudTrail, IRSA Policies, Secrets Manager,
#                        GuardDuty, AWS Config
# NOTE: This module has NO dependencies on ALB/CDN resources.
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
  count = var.enable_cmk_keys ? 1 : 0

  description             = "Cobalt ${var.environment} - RDS encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Environment = var.environment
    Module      = "security-base"
    Purpose     = "rds"
  }
}

resource "aws_kms_alias" "rds" {
  count = var.enable_cmk_keys ? 1 : 0

  name          = "alias/cobalt-${var.environment}-rds"
  target_key_id = aws_kms_key.rds[0].key_id
}

resource "aws_kms_key" "s3" {
  count = var.enable_cmk_keys ? 1 : 0

  description             = "Cobalt ${var.environment} - S3 encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Environment = var.environment
    Module      = "security-base"
    Purpose     = "s3"
  }
}

resource "aws_kms_alias" "s3" {
  count = var.enable_cmk_keys ? 1 : 0

  name          = "alias/cobalt-${var.environment}-s3"
  target_key_id = aws_kms_key.s3[0].key_id
}

resource "aws_kms_key" "secrets" {
  count = var.enable_cmk_keys ? 1 : 0

  description             = "Cobalt ${var.environment} - Secrets Manager encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Environment = var.environment
    Module      = "security-base"
    Purpose     = "secrets-manager"
  }
}

resource "aws_kms_alias" "secrets" {
  count = var.enable_cmk_keys ? 1 : 0

  name          = "alias/cobalt-${var.environment}-secrets"
  target_key_id = aws_kms_key.secrets[0].key_id
}

resource "aws_kms_key" "eks" {
  count = var.enable_cmk_keys ? 1 : 0

  description             = "Cobalt ${var.environment} - EKS envelope encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Environment = var.environment
    Module      = "security-base"
    Purpose     = "eks"
  }
}

resource "aws_kms_alias" "eks" {
  count = var.enable_cmk_keys ? 1 : 0

  name          = "alias/cobalt-${var.environment}-eks"
  target_key_id = aws_kms_key.eks[0].key_id
}

resource "aws_kms_key" "elasticache" {
  count = var.enable_cmk_keys ? 1 : 0

  description             = "Cobalt ${var.environment} - ElastiCache encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Environment = var.environment
    Module      = "security-base"
    Purpose     = "elasticache"
  }
}

resource "aws_kms_alias" "elasticache" {
  count = var.enable_cmk_keys ? 1 : 0

  name          = "alias/cobalt-${var.environment}-elasticache"
  target_key_id = aws_kms_key.elasticache[0].key_id
}

resource "aws_kms_key" "sns" {
  count = var.enable_cmk_keys ? 1 : 0

  description             = "Cobalt ${var.environment} - SNS encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Environment = var.environment
    Module      = "security-base"
    Purpose     = "sns"
  }
}

resource "aws_kms_alias" "sns" {
  count = var.enable_cmk_keys ? 1 : 0

  name          = "alias/cobalt-${var.environment}-sns"
  target_key_id = aws_kms_key.sns[0].key_id
}

################################################################################
# CloudTrail
################################################################################

resource "aws_s3_bucket" "cloudtrail" {
  bucket = "cobalt-${var.environment}-cloudtrail-${local.account_id}"

  tags = {
    Environment = var.environment
    Module      = "security-base"
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
      kms_master_key_id = var.enable_cmk_keys ? aws_kms_key.s3[0].arn : null
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
  kms_key_id                 = var.enable_cmk_keys ? aws_kms_key.s3[0].arn : null

  tags = {
    Environment = var.environment
    Module      = "security-base"
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
        Resource = var.enable_cmk_keys ? aws_kms_key.secrets[0].arn : "arn:aws:kms:*:*:alias/aws/secretsmanager"
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
#
# NOTE: Application secrets (jwt-secret, stripe-keys, twilio-credentials,
# socrata-token, etc.) are managed by the secrets-bootstrap module in the
# cobalt repo. Only the db-password secret remains here because it is used
# by the secret-rotation Lambda defined below.
################################################################################

resource "aws_secretsmanager_secret" "db_password" {
  name       = "cobalt/${var.environment}/db-password"
  kms_key_id = var.enable_cmk_keys ? aws_kms_key.secrets[0].arn : null

  tags = {
    Environment = var.environment
    Module      = "security-base"
  }
}

################################################################################
# Secret Rotation Lambda
################################################################################

# IAM role for the rotation Lambda
resource "aws_iam_role" "secret_rotation" {
  count = var.enable_secret_rotation ? 1 : 0

  name = "cobalt-${var.environment}-secret-rotation"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Module      = "security-base"
  }
}

resource "aws_iam_role_policy" "secret_rotation" {
  count = var.enable_secret_rotation ? 1 : 0

  name = "secret-rotation-policy"
  role = aws_iam_role.secret_rotation[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecretVersionStage"
        ]
        Resource = aws_secretsmanager_secret.db_password.arn
      },
      {
        Effect   = "Allow"
        Action   = "secretsmanager:GetRandomPassword"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${local.account_id}:log-group:/aws/lambda/cobalt-${var.environment}-secret-rotation:*"
      },
      {
        Effect   = "Allow"
        Action   = "kms:Decrypt"
        Resource = var.enable_cmk_keys ? aws_kms_key.secrets[0].arn : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "secret_rotation_basic" {
  count = var.enable_secret_rotation ? 1 : 0

  role       = aws_iam_role.secret_rotation[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Secret rotation Lambda handler.
# Implements the four-step Secrets Manager rotation lifecycle:
#   createSecret  — generate a new random password and store as AWSPENDING
#   setSecret     — connect to RDS and ALTER USER with the pending password
#   testSecret    — verify RDS connectivity with the pending password
#   finishSecret  — promote AWSPENDING to AWSCURRENT
#
# The secret value is stored as JSON: {"username":"cobalt","password":"...","host":"...","port":5432,"dbname":"cobalt"}
# See: https://docs.aws.amazon.com/secretsmanager/latest/userguide/rotating-secrets-lambda-function-overview.html
data "archive_file" "secret_rotation" {
  count = var.enable_secret_rotation ? 1 : 0

  type        = "zip"
  output_path = "${path.module}/lambda/secret-rotation.zip"

  source {
    content  = <<-PYTHON
import json
import logging
import os
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

secrets_client = boto3.client('secretsmanager')


def lambda_handler(event, context):
    """Secrets Manager rotation handler for RDS PostgreSQL passwords."""
    step = event['Step']
    secret_arn = event['SecretId']
    token = event['ClientRequestToken']

    logger.info(f"Secret rotation step: {step}, secret: {secret_arn}, token: {token}")

    # Verify the secret exists and rotation is enabled
    metadata = secrets_client.describe_secret(SecretId=secret_arn)
    if not metadata.get('RotationEnabled'):
        raise ValueError(f"Secret {secret_arn} does not have rotation enabled")
    versions = metadata.get('VersionIdsToStages', {})
    if token not in versions:
        raise ValueError(f"Token {token} not found in secret versions")

    if step == "createSecret":
        _create_secret(secret_arn, token, versions)
    elif step == "setSecret":
        _set_secret(secret_arn, token)
    elif step == "testSecret":
        _test_secret(secret_arn, token)
    elif step == "finishSecret":
        _finish_secret(secret_arn, token, versions)
    else:
        raise ValueError(f"Unknown step: {step}")


def _create_secret(secret_arn, token, versions):
    """Generate a new password and store it as AWSPENDING."""
    # If AWSPENDING already exists for this token, createSecret was already called
    if 'AWSPENDING' in versions.get(token, []):
        logger.info("createSecret: AWSPENDING already exists for this token, skipping")
        return

    # Get the current secret value to preserve connection metadata
    try:
        current = secrets_client.get_secret_value(
            SecretId=secret_arn, VersionStage='AWSCURRENT'
        )
        current_dict = json.loads(current['SecretString'])
    except (KeyError, json.JSONDecodeError):
        current_dict = {}

    # Generate a new random password
    passwd = secrets_client.get_random_password(
        PasswordLength=32,
        ExcludeCharacters='/@"\\\'',
        RequireEachIncludedType=True,
    )

    # Preserve connection metadata, update password
    new_secret = {
        'username': current_dict.get('username', 'cobalt'),
        'password': passwd['RandomPassword'],
        'host': current_dict.get('host', ''),
        'port': current_dict.get('port', 5432),
        'dbname': current_dict.get('dbname', 'cobalt'),
    }

    secrets_client.put_secret_value(
        SecretId=secret_arn,
        ClientRequestToken=token,
        SecretString=json.dumps(new_secret),
        VersionStages=['AWSPENDING'],
    )
    logger.info("createSecret: new password generated and stored as AWSPENDING")


def _set_secret(secret_arn, token):
    """Connect to RDS as the current user and ALTER the password to the pending value."""
    import pg8000.native

    # Get the current credentials (to authenticate)
    current = secrets_client.get_secret_value(
        SecretId=secret_arn, VersionStage='AWSCURRENT'
    )
    current_dict = json.loads(current['SecretString'])

    # Get the pending credentials (new password)
    pending = secrets_client.get_secret_value(
        SecretId=secret_arn, VersionStage='AWSPENDING', VersionId=token
    )
    pending_dict = json.loads(pending['SecretString'])

    # Connect using current password and set the new one
    conn = pg8000.native.Connection(
        user=current_dict['username'],
        password=current_dict['password'],
        host=current_dict['host'],
        port=int(current_dict.get('port', 5432)),
        database=current_dict.get('dbname', 'cobalt'),
        ssl_context=True,
    )
    try:
        username = pending_dict['username']
        new_password = pending_dict['password']
        conn.run(
            f"ALTER USER {pg8000.native.identifier(username)} WITH PASSWORD :pwd",
            pwd=new_password,
        )
        logger.info(f"setSecret: password updated for user {username}")
    finally:
        conn.close()


def _test_secret(secret_arn, token):
    """Verify RDS connectivity using the pending password."""
    import pg8000.native

    pending = secrets_client.get_secret_value(
        SecretId=secret_arn, VersionStage='AWSPENDING', VersionId=token
    )
    pending_dict = json.loads(pending['SecretString'])

    conn = pg8000.native.Connection(
        user=pending_dict['username'],
        password=pending_dict['password'],
        host=pending_dict['host'],
        port=int(pending_dict.get('port', 5432)),
        database=pending_dict.get('dbname', 'cobalt'),
        ssl_context=True,
    )
    try:
        result = conn.run("SELECT 1")
        logger.info(f"testSecret: connection verified, result={result}")
    finally:
        conn.close()


def _finish_secret(secret_arn, token, versions):
    """Promote AWSPENDING to AWSCURRENT."""
    current_version = None
    for version_id, stages in versions.items():
        if 'AWSCURRENT' in stages:
            if version_id == token:
                logger.info("finishSecret: version already AWSCURRENT, nothing to do")
                return
            current_version = version_id
            break

    secrets_client.update_secret_version_stage(
        SecretId=secret_arn,
        VersionStage='AWSCURRENT',
        MoveToVersionId=token,
        RemoveFromVersionId=current_version,
    )
    logger.info(f"finishSecret: promoted {token} to AWSCURRENT")
PYTHON
    filename = "lambda_function.py"
  }
}

resource "aws_lambda_function" "secret_rotation" {
  count = var.enable_secret_rotation ? 1 : 0

  function_name    = "cobalt-${var.environment}-secret-rotation"
  description      = "Rotates the Cobalt DB password in Secrets Manager"
  role             = aws_iam_role.secret_rotation[0].arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  timeout          = 30
  filename         = data.archive_file.secret_rotation[0].output_path
  source_code_hash = data.archive_file.secret_rotation[0].output_base64sha256

  # pg8000 (pure-Python PostgreSQL driver) is required for setSecret/testSecret steps.
  # Provide it via a Lambda layer or bundle it in the deployment package.
  # Example layer ARN: aws_lambda_layer_version.pg8000.arn
  layers = var.pg8000_layer_arn != "" ? [var.pg8000_layer_arn] : []

  environment {
    variables = {
      SECRETS_MANAGER_ENDPOINT = ""
    }
  }

  tags = {
    Environment = var.environment
    Module      = "security-base"
  }

  lifecycle {
    precondition {
      condition     = var.pg8000_layer_arn != ""
      error_message = "pg8000_layer_arn must be set when secret rotation is enabled. Build the layer: pip install pg8000 -t python/ && zip -r pg8000-layer.zip python/"
    }
  }
}

resource "aws_lambda_permission" "secret_rotation" {
  count = var.enable_secret_rotation ? 1 : 0

  statement_id  = "AllowSecretsManagerInvocation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.secret_rotation[0].function_name
  principal     = "secretsmanager.amazonaws.com"
}

resource "aws_secretsmanager_secret_rotation" "db_password" {
  count = var.enable_secret_rotation ? 1 : 0

  secret_id           = aws_secretsmanager_secret.db_password.id
  rotation_lambda_arn = aws_lambda_function.secret_rotation[0].arn

  rotation_rules {
    automatically_after_days = 30
  }

  depends_on = [aws_lambda_permission.secret_rotation]
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
    Module      = "security-base"
  }
}

resource "aws_sns_topic" "guardduty_alerts" {
  count = var.enable_guardduty ? 1 : 0

  name              = "cobalt-${var.environment}-guardduty-alerts"
  kms_master_key_id = var.enable_cmk_keys ? aws_kms_key.sns[0].arn : "alias/aws/sns"

  tags = {
    Environment = var.environment
    Module      = "security-base"
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
    Module      = "security-base"
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
# AWS Config
################################################################################

resource "aws_s3_bucket" "config" {
  count  = var.enable_config ? 1 : 0
  bucket = "cobalt-${var.environment}-config-${local.account_id}"

  tags = {
    Environment = var.environment
    Module      = "security-base"
  }
}

resource "aws_s3_bucket_versioning" "config" {
  count  = var.enable_config ? 1 : 0
  bucket = aws_s3_bucket.config[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config" {
  count  = var.enable_config ? 1 : 0
  bucket = aws_s3_bucket.config[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.enable_cmk_keys ? aws_kms_key.s3[0].arn : null
    }
  }
}

resource "aws_s3_bucket_public_access_block" "config" {
  count  = var.enable_config ? 1 : 0
  bucket = aws_s3_bucket.config[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "config" {
  count  = var.enable_config ? 1 : 0
  bucket = aws_s3_bucket.config[0].id

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
        Resource = aws_s3_bucket.config[0].arn
      },
      {
        Sid    = "AWSConfigBucketDelivery"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.config[0].arn}/AWSLogs/${local.account_id}/Config/*"
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
  count = var.enable_config ? 1 : 0
  name  = "cobalt-${var.environment}-config-role"

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
  count      = var.enable_config ? 1 : 0
  role       = aws_iam_role.config[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_config_configuration_recorder" "main" {
  count    = var.enable_config ? 1 : 0
  name     = "cobalt-${var.environment}"
  role_arn = aws_iam_role.config[0].arn

  recording_group {
    all_supported = true
  }
}

resource "aws_config_delivery_channel" "main" {
  count          = var.enable_config ? 1 : 0
  name           = "cobalt-${var.environment}"
  s3_bucket_name = aws_s3_bucket.config[0].bucket

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_configuration_recorder_status" "main" {
  count      = var.enable_config ? 1 : 0
  name       = aws_config_configuration_recorder.main[0].name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.main]
}

# AWS Config Managed Rules
resource "aws_config_config_rule" "s3_encryption" {
  count = var.enable_config ? 1 : 0
  name  = "cobalt-${var.environment}-s3-encryption"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "rds_encryption" {
  count = var.enable_config ? 1 : 0
  name  = "cobalt-${var.environment}-rds-encryption"

  source {
    owner             = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "vpc_flow_logs" {
  count = var.enable_config ? 1 : 0
  name  = "cobalt-${var.environment}-vpc-flow-logs"

  source {
    owner             = "AWS"
    source_identifier = "VPC_FLOW_LOGS_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "encrypted_volumes" {
  count = var.enable_config ? 1 : 0
  name  = "cobalt-${var.environment}-encrypted-volumes"

  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "iam_password_policy" {
  count = var.enable_config ? 1 : 0
  name  = "cobalt-${var.environment}-iam-password-policy"

  source {
    owner             = "AWS"
    source_identifier = "IAM_PASSWORD_POLICY"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "restricted_common_ports" {
  count = var.enable_config ? 1 : 0
  name  = "cobalt-${var.environment}-restricted-common-ports"

  source {
    owner             = "AWS"
    source_identifier = "RESTRICTED_INCOMING_TRAFFIC"
  }

  depends_on = [aws_config_configuration_recorder.main]
}
