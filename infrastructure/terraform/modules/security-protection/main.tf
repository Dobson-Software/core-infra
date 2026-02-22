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
# Security Protection Module — Shield Advanced for ALB and CloudFront
# NOTE: This module depends on ALB/CDN resources existing first.
################################################################################

################################################################################
# Shield Advanced
################################################################################

resource "aws_shield_protection" "alb" {
  count = var.enable_shield_advanced && var.alb_arn != "" ? 1 : 0

  name         = "cobalt-${var.environment}-alb-shield"
  resource_arn = var.alb_arn

  tags = {
    Environment = var.environment
    Module      = "security-protection"
  }
}

resource "aws_shield_protection" "cloudfront" {
  count = var.enable_shield_advanced && var.cloudfront_distribution_arn != "" ? 1 : 0

  name         = "cobalt-${var.environment}-cloudfront-shield"
  resource_arn = var.cloudfront_distribution_arn

  tags = {
    Environment = var.environment
    Module      = "security-protection"
  }
}

