output "distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.cobalt.id
}

output "distribution_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.cobalt.domain_name
}

output "distribution_hosted_zone_id" {
  description = "CloudFront distribution hosted zone ID"
  value       = aws_cloudfront_distribution.cobalt.hosted_zone_id
}

output "distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.cobalt.arn
}

output "cloudfront_waf_arn" {
  description = "ARN of the CloudFront WAF Web ACL"
  value       = aws_wafv2_web_acl.cloudfront_waf.arn
}
