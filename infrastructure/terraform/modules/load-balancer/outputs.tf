output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.cobalt.arn
}

output "alb_arn_suffix" {
  description = "ARN suffix of the ALB (for CloudWatch dimensions)"
  value       = aws_lb.cobalt.arn_suffix
}

output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.cobalt.dns_name
}

output "alb_zone_id" {
  description = "Route53 zone ID of the ALB"
  value       = aws_lb.cobalt.zone_id
}

output "target_group_arns" {
  description = "Map of target group ARNs"
  value = {
    core_service         = aws_lb_target_group.core_service.arn
    notification_service = aws_lb_target_group.notification_service.arn
    violations_service   = aws_lb_target_group.violations_service.arn
    frontend             = aws_lb_target_group.frontend.arn
  }
}

output "waf_acl_arn" {
  description = "ARN of the WAFv2 Web ACL"
  value       = aws_wafv2_web_acl.cobalt.arn
}
