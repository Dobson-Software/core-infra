################################################################################
# Cobalt AI Incident Response Module
#
# SNS alarm → Lambda → Claude API → GitHub Issue + Slack
################################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.0"
    }
  }
}

################################################################################
# Secrets from AWS Secrets Manager
################################################################################

data "aws_secretsmanager_secret_version" "incident_response" {
  count     = var.enable_incident_response ? 1 : 0
  secret_id = var.secrets_manager_secret_id
}

locals {
  enabled = var.enable_incident_response
  secrets = local.enabled ? jsondecode(data.aws_secretsmanager_secret_version.incident_response[0].secret_string) : {}
}

################################################################################
# Lambda Function
################################################################################

data "archive_file" "lambda_zip" {
  count       = local.enabled ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/../../../lambda/incident-responder"
  output_path = "${path.module}/files/incident-responder.zip"
}

resource "aws_lambda_function" "incident_responder" {
  count = local.enabled ? 1 : 0

  function_name    = "cobalt-${var.environment}-incident-responder"
  description      = "AI-powered incident response — analyzes alerts via Claude API"
  handler          = "handler.handler"
  runtime          = "python3.12"
  timeout          = 120
  memory_size      = 256
  filename         = data.archive_file.lambda_zip[0].output_path
  source_code_hash = data.archive_file.lambda_zip[0].output_base64sha256

  role = aws_iam_role.lambda_role[0].arn

  environment {
    variables = {
      ENVIRONMENT       = var.environment
      ANTHROPIC_API_KEY = lookup(local.secrets, "anthropic_api_key", "")
      AXIOM_API_TOKEN   = lookup(local.secrets, "axiom_api_token", "")
      AXIOM_DATASET     = "cobalt-logs"
      GITHUB_TOKEN      = lookup(local.secrets, "github_token", "")
      GITHUB_REPO       = var.github_repo
      SLACK_WEBHOOK_URL = lookup(local.secrets, "slack_webhook_url", "")
    }
  }

  reserved_concurrent_executions = 5

  tags = {
    Environment = var.environment
    Module      = "incident-response"
  }
}

################################################################################
# SNS Subscription — alarm topic triggers Lambda
################################################################################

resource "aws_sns_topic_subscription" "alarm_to_lambda" {
  count = local.enabled ? 1 : 0

  topic_arn = var.sns_alert_topic_arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.incident_responder[0].arn
}

resource "aws_lambda_permission" "sns_invoke" {
  count = local.enabled ? 1 : 0

  statement_id  = "AllowSNSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.incident_responder[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = var.sns_alert_topic_arn
}

################################################################################
# IAM Role for Lambda
################################################################################

resource "aws_iam_role" "lambda_role" {
  count = local.enabled ? 1 : 0

  name = "cobalt-${var.environment}-incident-responder-role"

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
    Module      = "incident-response"
  }
}

resource "aws_iam_role_policy" "lambda_policy" {
  count = local.enabled ? 1 : 0

  name = "cobalt-${var.environment}-incident-responder-policy"
  role = aws_iam_role.lambda_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Sid    = "SecretsManagerRead"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.secrets_manager_secret_arn
      },
      {
        Sid    = "CloudWatchMetricsRead"
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricData",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:GetMetricStatistics"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  count = local.enabled ? 1 : 0

  role       = aws_iam_role.lambda_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

################################################################################
# CloudWatch Log Group for Lambda
################################################################################

resource "aws_cloudwatch_log_group" "lambda_logs" {
  count = local.enabled ? 1 : 0

  name              = "/aws/lambda/cobalt-${var.environment}-incident-responder"
  retention_in_days = 30

  tags = {
    Environment = var.environment
    Module      = "incident-response"
  }
}
