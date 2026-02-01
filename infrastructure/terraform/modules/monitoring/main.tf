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
# Monitoring Module — CloudWatch Dashboards, Alarms, SNS
################################################################################

################################################################################
# SNS Topic for Alerts
################################################################################

resource "aws_sns_topic" "alerts" {
  name              = "cobalt-${var.environment}-alerts"
  kms_master_key_id = var.sns_kms_key_id != "" ? var.sns_kms_key_id : "alias/aws/sns"

  tags = {
    Environment = var.environment
    Module      = "monitoring"
  }
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

################################################################################
# CloudWatch Dashboard
################################################################################

resource "aws_cloudwatch_dashboard" "cobalt" {
  dashboard_name = "cobalt-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "EKS CPU Utilization"
          metrics = [["AWS/EKS", "node_cpu_utilization", "ClusterName", var.eks_cluster_name]]
          period  = 300
          stat    = "Average"
          region  = data.aws_region.current.name
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "RDS CPU Utilization"
          metrics = [["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.rds_instance_id]]
          period  = 300
          stat    = "Average"
          region  = data.aws_region.current.name
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title = "ALB Request Count & Latency"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title = "ElastiCache CPU & Memory"
          metrics = [
            ["AWS/ElastiCache", "CPUUtilization", "ReplicationGroupId", var.elasticache_id],
            ["AWS/ElastiCache", "DatabaseMemoryUsagePercentage", "ReplicationGroupId", var.elasticache_id]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
        }
      }
    ]
  })
}

data "aws_region" "current" {}

################################################################################
# CloudWatch Alarms
################################################################################

# CPU > 80%
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "cobalt-${var.environment}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU utilization exceeds 80%"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  tags = { Environment = var.environment }
}

# RDS connections > 80%
resource "aws_cloudwatch_metric_alarm" "rds_connections_high" {
  alarm_name          = "cobalt-${var.environment}-rds-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS connection count exceeds 80% of max"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  tags = { Environment = var.environment }
}

# ALB 5xx > 1%
resource "aws_cloudwatch_metric_alarm" "alb_5xx_high" {
  alarm_name          = "cobalt-${var.environment}-alb-5xx-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 1

  metric_query {
    id          = "error_rate"
    expression  = "(errors / requests) * 100"
    label       = "5xx Error Rate"
    return_data = true
  }

  metric_query {
    id = "errors"
    metric {
      metric_name = "HTTPCode_Target_5XX_Count"
      namespace   = "AWS/ApplicationELB"
      period      = 300
      stat        = "Sum"
      dimensions = {
        LoadBalancer = var.alb_arn_suffix
      }
    }
  }

  metric_query {
    id = "requests"
    metric {
      metric_name = "RequestCount"
      namespace   = "AWS/ApplicationELB"
      period      = 300
      stat        = "Sum"
      dimensions = {
        LoadBalancer = var.alb_arn_suffix
      }
    }
  }

  alarm_description = "ALB 5xx error rate exceeds 1%"
  alarm_actions     = [aws_sns_topic.alerts.arn]
  ok_actions        = [aws_sns_topic.alerts.arn]

  tags = { Environment = var.environment }
}

# ALB latency > 2s
resource "aws_cloudwatch_metric_alarm" "alb_latency_high" {
  alarm_name          = "cobalt-${var.environment}-alb-latency-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Average"
  threshold           = 2
  alarm_description   = "ALB average latency exceeds 2 seconds"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  tags = { Environment = var.environment }
}

################################################################################
# VPC Flow Log Alerting
################################################################################

resource "aws_cloudwatch_log_metric_filter" "vpc_rejected_packets" {
  count          = var.vpc_flow_log_group_name != "" ? 1 : 0
  name           = "cobalt-${var.environment}-vpc-rejected-packets"
  pattern        = "[version, account_id, interface_id, srcaddr, dstaddr, srcport, dstport, protocol, packets, bytes, start, end, action=\"REJECT\", log_status]"
  log_group_name = var.vpc_flow_log_group_name

  metric_transformation {
    name          = "VPCRejectedPackets"
    namespace     = "Cobalt/${var.environment}"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "vpc_rejected_packets_high" {
  count               = var.vpc_flow_log_group_name != "" ? 1 : 0
  alarm_name          = "cobalt-${var.environment}-vpc-rejected-packets-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "VPCRejectedPackets"
  namespace           = "Cobalt/${var.environment}"
  period              = 300
  statistic           = "Sum"
  threshold           = 1000
  alarm_description   = "VPC flow log rejected packets exceed 1000 in 5 minutes"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  tags = { Environment = var.environment }
}
