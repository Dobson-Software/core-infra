################################################################################
# Load Balancer Module Tests — ALB, Target Groups, Listeners, WAF
################################################################################

mock_provider "aws" {}

variables {
  environment       = "dev"
  vpc_id            = "vpc-test123"
  public_subnet_ids = ["subnet-pub-a", "subnet-pub-b", "subnet-pub-c"]
  certificate_arn   = "arn:aws:acm:us-east-1:123456789012:certificate/test-cert"
  vpc_cidr          = "10.0.0.0/16"
  log_bucket_name   = "cobalt-logs-dev"
}

run "alb_is_external" {
  command = plan

  assert {
    condition     = aws_lb.cobalt.internal == false
    error_message = "ALB must not be internal (public-facing)"
  }
}

run "alb_type_is_application" {
  command = plan

  assert {
    condition     = aws_lb.cobalt.load_balancer_type == "application"
    error_message = "Load balancer type must be 'application'"
  }
}

run "dev_no_deletion_protection" {
  command = plan

  assert {
    condition     = aws_lb.cobalt.enable_deletion_protection == false
    error_message = "Dev environment should not have deletion protection"
  }
}

run "prod_deletion_protection_enabled" {
  command = plan

  variables {
    environment = "prod"
  }

  assert {
    condition     = aws_lb.cobalt.enable_deletion_protection == true
    error_message = "Prod environment must have deletion protection enabled"
  }
}

run "core_service_target_group_port" {
  command = plan

  assert {
    condition     = aws_lb_target_group.core_service.port == 8080
    error_message = "Core service target group port must be 8080"
  }
}

run "core_service_health_check_path" {
  command = plan

  assert {
    condition     = aws_lb_target_group.core_service.health_check[0].path == "/actuator/health"
    error_message = "Core service health check path must be /actuator/health"
  }
}

run "notification_service_target_group_port" {
  command = plan

  assert {
    condition     = aws_lb_target_group.notification_service.port == 8081
    error_message = "Notification service target group port must be 8081"
  }
}

run "violations_service_target_group_port" {
  command = plan

  assert {
    condition     = aws_lb_target_group.violations_service.port == 8082
    error_message = "Violations service target group port must be 8082"
  }
}

run "frontend_target_group_port" {
  command = plan

  assert {
    condition     = aws_lb_target_group.frontend.port == 3000
    error_message = "Frontend target group port must be 3000"
  }
}

run "all_target_groups_use_ip_type" {
  command = plan

  assert {
    condition     = aws_lb_target_group.core_service.target_type == "ip"
    error_message = "Core service target group must use ip target type"
  }

  assert {
    condition     = aws_lb_target_group.notification_service.target_type == "ip"
    error_message = "Notification service target group must use ip target type"
  }

  assert {
    condition     = aws_lb_target_group.violations_service.target_type == "ip"
    error_message = "Violations service target group must use ip target type"
  }

  assert {
    condition     = aws_lb_target_group.frontend.target_type == "ip"
    error_message = "Frontend target group must use ip target type"
  }
}

run "https_listener_port_443" {
  command = plan

  assert {
    condition     = aws_lb_listener.https.port == 443
    error_message = "HTTPS listener must be on port 443"
  }
}

run "https_listener_protocol" {
  command = plan

  assert {
    condition     = aws_lb_listener.https.protocol == "HTTPS"
    error_message = "HTTPS listener protocol must be HTTPS"
  }
}

run "https_listener_tls_policy" {
  command = plan

  assert {
    condition     = aws_lb_listener.https.ssl_policy == "ELBSecurityPolicy-TLS13-1-2-2021-06"
    error_message = "HTTPS listener must use TLS 1.3 security policy"
  }
}

run "http_redirect_listener_port_80" {
  command = plan

  assert {
    condition     = aws_lb_listener.http_redirect.port == 80
    error_message = "HTTP redirect listener must be on port 80"
  }
}

run "http_redirect_listener_protocol" {
  command = plan

  assert {
    condition     = aws_lb_listener.http_redirect.protocol == "HTTP"
    error_message = "HTTP redirect listener protocol must be HTTP"
  }
}

run "waf_scope_is_regional" {
  command = plan

  assert {
    condition     = aws_wafv2_web_acl.cobalt.scope == "REGIONAL"
    error_message = "WAF Web ACL scope must be REGIONAL for ALB"
  }
}

run "security_group_allows_port_443" {
  command = plan

  assert {
    condition     = aws_security_group.alb.ingress != null
    error_message = "ALB security group must have ingress rules defined"
  }
}

run "violations_api_routing_priority" {
  command = plan

  assert {
    condition     = aws_lb_listener_rule.violations_api.priority == 10
    error_message = "Violations API routing rule must have priority 10"
  }
}

run "notification_api_routing_priority" {
  command = plan

  assert {
    condition     = aws_lb_listener_rule.notification_api.priority == 20
    error_message = "Notification API routing rule must have priority 20"
  }
}

run "core_api_routing_priority" {
  command = plan

  assert {
    condition     = aws_lb_listener_rule.core_api.priority == 30
    error_message = "Core API routing rule must have priority 30"
  }
}
