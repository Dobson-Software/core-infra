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

################################################################################
# WAF v2 WebACL
################################################################################

resource "aws_wafv2_web_acl" "main" {
  count = var.enable_waf ? 1 : 0

  name        = "${var.project_name}-${var.environment}-waf"
  description = "WAF WebACL for ${var.project_name} ALB"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-common-rules"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-sqli"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "RateLimitRule"
    priority = 4

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    Environment = var.environment
    Module      = "security-protection"
  }
}

output "waf_web_acl_arn" {
  value       = var.enable_waf ? aws_wafv2_web_acl.main[0].arn : null
  description = "WAF WebACL ARN for ALB association"
}
