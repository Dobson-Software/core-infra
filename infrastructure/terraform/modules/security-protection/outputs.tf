output "shield_alb_protection_id" {
  description = "ID of the Shield Advanced protection for ALB"
  value       = var.enable_shield_advanced && var.alb_arn != "" ? aws_shield_protection.alb[0].id : ""
}

output "shield_cloudfront_protection_id" {
  description = "ID of the Shield Advanced protection for CloudFront"
  value       = var.enable_shield_advanced && var.cloudfront_distribution_arn != "" ? aws_shield_protection.cloudfront[0].id : ""
}
