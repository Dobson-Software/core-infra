################################################################################
# Monitoring Module Tests — CloudWatch Alarms, SNS, Dashboard
################################################################################

mock_provider "aws" {}

variables {
  environment             = "dev"
  eks_cluster_name        = "cobalt-dev"
  rds_instance_id         = "cobalt-dev-primary"
  alb_arn_suffix          = "app/cobalt-dev/1234567890"
  elasticache_id          = "cobalt-dev"
  alert_email             = "alerts@cobaltplatform.com"
  vpc_flow_log_group_name = "/aws/vpc/cobalt-dev-flow-logs"
  sns_kms_key_id          = "arn:aws:kms:us-east-1:123456789012:key/test-key"
}

run "sns_topic_name" {
  command = plan

  assert {
    condition     = aws_sns_topic.alerts.name == "cobalt-dev-alerts"
    error_message = "SNS topic name must follow naming convention"
  }
}

run "sns_topic_kms_encryption" {
  command = plan

  assert {
    condition     = aws_sns_topic.alerts.kms_master_key_id == "arn:aws:kms:us-east-1:123456789012:key/test-key"
    error_message = "SNS topic must be encrypted with the provided KMS key"
  }
}

run "sns_email_subscription_protocol" {
  command = plan

  assert {
    condition     = aws_sns_topic_subscription.email.protocol == "email"
    error_message = "SNS subscription protocol must be email"
  }
}

run "sns_email_subscription_endpoint" {
  command = plan

  assert {
    condition     = aws_sns_topic_subscription.email.endpoint == "alerts@cobaltplatform.com"
    error_message = "SNS subscription endpoint must match the provided alert email"
  }
}

run "dashboard_name" {
  command = plan

  assert {
    condition     = aws_cloudwatch_dashboard.cobalt.dashboard_name == "cobalt-dev"
    error_message = "Dashboard name must follow naming convention"
  }
}

run "rds_cpu_alarm_threshold" {
  command = plan

  assert {
    condition     = aws_cloudwatch_metric_alarm.rds_cpu_high.threshold == 80
    error_message = "RDS CPU alarm threshold must be 80"
  }
}

run "rds_cpu_alarm_comparison_operator" {
  command = plan

  assert {
    condition     = aws_cloudwatch_metric_alarm.rds_cpu_high.comparison_operator == "GreaterThanThreshold"
    error_message = "RDS CPU alarm must use GreaterThanThreshold comparison"
  }
}

run "rds_cpu_alarm_evaluation_periods" {
  command = plan

  assert {
    condition     = aws_cloudwatch_metric_alarm.rds_cpu_high.evaluation_periods == 3
    error_message = "RDS CPU alarm must evaluate over 3 periods"
  }
}

run "rds_cpu_alarm_namespace" {
  command = plan

  assert {
    condition     = aws_cloudwatch_metric_alarm.rds_cpu_high.namespace == "AWS/RDS"
    error_message = "RDS CPU alarm namespace must be AWS/RDS"
  }
}

run "rds_connections_alarm_threshold" {
  command = plan

  assert {
    condition     = aws_cloudwatch_metric_alarm.rds_connections_high.threshold == 80
    error_message = "RDS connections alarm threshold must be 80"
  }
}

run "rds_connections_alarm_metric" {
  command = plan

  assert {
    condition     = aws_cloudwatch_metric_alarm.rds_connections_high.metric_name == "DatabaseConnections"
    error_message = "RDS connections alarm metric must be DatabaseConnections"
  }
}

run "alb_5xx_alarm_threshold" {
  command = plan

  assert {
    condition     = aws_cloudwatch_metric_alarm.alb_5xx_high.threshold == 1
    error_message = "ALB 5xx alarm threshold must be 1 (percent)"
  }
}

run "alb_latency_alarm_threshold" {
  command = plan

  assert {
    condition     = aws_cloudwatch_metric_alarm.alb_latency_high.threshold == 2
    error_message = "ALB latency alarm threshold must be 2 seconds"
  }
}

run "alb_latency_alarm_metric" {
  command = plan

  assert {
    condition     = aws_cloudwatch_metric_alarm.alb_latency_high.metric_name == "TargetResponseTime"
    error_message = "ALB latency alarm metric must be TargetResponseTime"
  }
}

run "alb_latency_alarm_namespace" {
  command = plan

  assert {
    condition     = aws_cloudwatch_metric_alarm.alb_latency_high.namespace == "AWS/ApplicationELB"
    error_message = "ALB latency alarm namespace must be AWS/ApplicationELB"
  }
}

run "vpc_rejected_packets_alarm_threshold" {
  command = plan

  assert {
    condition     = aws_cloudwatch_metric_alarm.vpc_rejected_packets_high.threshold == 1000
    error_message = "VPC rejected packets alarm threshold must be 1000"
  }
}

run "vpc_rejected_packets_metric_filter_pattern" {
  command = plan

  assert {
    condition     = aws_cloudwatch_log_metric_filter.vpc_rejected_packets.name == "cobalt-dev-vpc-rejected-packets"
    error_message = "VPC rejected packets metric filter name must follow naming convention"
  }
}
