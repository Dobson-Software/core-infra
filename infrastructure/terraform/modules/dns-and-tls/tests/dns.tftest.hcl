################################################################################
# DNS & TLS Module Tests — Route53, ACM, Maintenance Bucket
################################################################################

mock_provider "aws" {}

variables {
  environment        = "dev"
  domain_name        = "dev.cobaltplatform.com"
  alb_dns_name       = "cobalt-dev-alb-123456.us-east-1.elb.amazonaws.com"
  cloudfront_domain  = "d111111abcdef8.cloudfront.net"
  cloudfront_zone_id = "Z2FDTNDATAQYW2"
}

run "hosted_zone_uses_domain_name" {
  command = plan

  assert {
    condition     = aws_route53_zone.main.name == "dev.cobaltplatform.com"
    error_message = "Route53 hosted zone must use the provided domain name"
  }
}

run "acm_certificate_domain" {
  command = plan

  assert {
    condition     = aws_acm_certificate.main.domain_name == "dev.cobaltplatform.com"
    error_message = "ACM certificate must use the provided domain name"
  }
}

run "acm_certificate_dns_validation" {
  command = plan

  assert {
    condition     = aws_acm_certificate.main.validation_method == "DNS"
    error_message = "ACM certificate must use DNS validation"
  }
}

run "acm_certificate_wildcard_san" {
  command = plan

  assert {
    condition     = contains(aws_acm_certificate.main.subject_alternative_names, "*.dev.cobaltplatform.com")
    error_message = "ACM certificate must include wildcard SAN for the domain"
  }
}

run "health_check_uses_https" {
  command = plan

  assert {
    condition     = aws_route53_health_check.alb.type == "HTTPS"
    error_message = "ALB health check must use HTTPS"
  }
}

run "health_check_port_443" {
  command = plan

  assert {
    condition     = aws_route53_health_check.alb.port == 443
    error_message = "ALB health check must use port 443"
  }
}

run "health_check_path" {
  command = plan

  assert {
    condition     = aws_route53_health_check.alb.resource_path == "/actuator/health"
    error_message = "ALB health check path must be /actuator/health"
  }
}

run "primary_a_record_type" {
  command = plan

  assert {
    condition     = aws_route53_record.primary_a.type == "A"
    error_message = "Primary record must be type A"
  }
}

run "primary_aaaa_record_type" {
  command = plan

  assert {
    condition     = aws_route53_record.primary_aaaa.type == "AAAA"
    error_message = "Primary IPv6 record must be type AAAA"
  }
}

run "maintenance_bucket_name" {
  command = plan

  assert {
    condition     = aws_s3_bucket.maintenance.bucket == "cobalt-maintenance-dev"
    error_message = "Maintenance bucket name must follow naming convention"
  }
}

run "maintenance_bucket_encryption" {
  command = plan

  assert {
    condition     = aws_s3_bucket_server_side_encryption_configuration.maintenance.rule[0].apply_server_side_encryption_by_default[0].sse_algorithm == "AES256"
    error_message = "Maintenance bucket must use AES256 encryption"
  }
}

run "maintenance_bucket_blocks_public_access" {
  command = plan

  assert {
    condition     = aws_s3_bucket_public_access_block.maintenance.block_public_acls == true
    error_message = "Maintenance bucket must block public ACLs"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.maintenance.block_public_policy == true
    error_message = "Maintenance bucket must block public policy"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.maintenance.restrict_public_buckets == true
    error_message = "Maintenance bucket must restrict public buckets"
  }
}

run "maintenance_website_index_document" {
  command = plan

  assert {
    condition     = aws_s3_bucket_website_configuration.maintenance.index_document[0].suffix == "index.html"
    error_message = "Maintenance website index document must be index.html"
  }
}

run "secondary_a_record_is_failover" {
  command = plan

  assert {
    condition     = aws_route53_record.secondary_a.type == "A"
    error_message = "Secondary failover record must be type A"
  }

  assert {
    condition     = aws_route53_record.secondary_a.set_identifier == "secondary"
    error_message = "Secondary failover record set identifier must be 'secondary'"
  }
}
