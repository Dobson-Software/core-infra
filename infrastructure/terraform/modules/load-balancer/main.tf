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
# Load Balancer Module — ALB, Target Groups, WAF
################################################################################

################################################################################
# Security Group
################################################################################

resource "aws_security_group" "alb" {
  name_prefix = "cobalt-alb-${var.environment}-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow traffic to frontend and core-service on port 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow traffic to notification-service"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow traffic to violations-service"
    from_port   = 8082
    to_port     = 8082
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name        = "cobalt-alb-${var.environment}"
    Environment = var.environment
  }
}

################################################################################
# Application Load Balancer
################################################################################

resource "aws_lb" "cobalt" {
  name               = "cobalt-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.environment == "prod"

  access_logs {
    bucket  = var.log_bucket_name
    prefix  = "alb"
    enabled = true
  }

  tags = {
    Environment = var.environment
    Module      = "load-balancer"
  }
}

################################################################################
# Target Groups
################################################################################

resource "aws_lb_target_group" "core_service" {
  name        = "cobalt-core-${var.environment}"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/actuator/health"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
  }

  tags = { Environment = var.environment }
}

resource "aws_lb_target_group" "notification_service" {
  name        = "cobalt-notif-${var.environment}"
  port        = 8081
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/actuator/health"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
  }

  tags = { Environment = var.environment }
}

resource "aws_lb_target_group" "violations_service" {
  name        = "cobalt-viol-${var.environment}"
  port        = 8082
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/actuator/health"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
  }

  tags = { Environment = var.environment }
}

resource "aws_lb_target_group" "frontend" {
  name        = "cobalt-frontend-${var.environment}"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
  }

  tags = { Environment = var.environment }
}

################################################################################
# HTTPS Listener + Path-Based Routing
################################################################################

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.cobalt.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_lb_listener_rule" "violations_api" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.violations_service.arn
  }

  condition {
    path_pattern {
      values = ["/api/v1/violations/*"]
    }
  }
}

resource "aws_lb_listener_rule" "notification_api" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.notification_service.arn
  }

  condition {
    path_pattern {
      values = ["/api/v1/notifications/*"]
    }
  }
}

resource "aws_lb_listener_rule" "core_api" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 30

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.core_service.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

################################################################################
# HTTP -> HTTPS Redirect
################################################################################

resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.cobalt.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

################################################################################
# WAFv2
################################################################################

resource "aws_wafv2_web_acl" "cobalt" {
  name        = "cobalt-${var.environment}-waf"
  description = "WAF for Cobalt ALB"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  # AWS Managed Common Rule Set
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
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # SQL Injection Protection
  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 2

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
      metric_name                = "AWSManagedRulesSQLiRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # Rate Limiting
  rule {
    name     = "RateLimitPerIP"
    priority = 3

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
      metric_name                = "RateLimitPerIP"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "cobalt-${var.environment}-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    Environment = var.environment
    Module      = "load-balancer"
  }
}

resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = aws_lb.cobalt.arn
  web_acl_arn  = aws_wafv2_web_acl.cobalt.arn
}
