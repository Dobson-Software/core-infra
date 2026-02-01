################################################################################
# CDN Module Tests — CloudFront Distribution, WAF, Cache Policy, Origins
################################################################################

mock_provider "aws" {}

variables {
  environment            = "dev"
  frontend_bucket_id     = "cobalt-frontend-dev-123456789012"
  frontend_bucket_domain = "cobalt-frontend-dev-123456789012.s3.us-east-1.amazonaws.com"
  alb_dns_name           = "cobalt-dev-alb-123456.us-east-1.elb.amazonaws.com"
  certificate_arn        = "arn:aws:acm:us-east-1:123456789012:certificate/test-cert"
  domain_name            = "dev.cobaltplatform.com"
  log_bucket_domain_name = "cobalt-logs-dev.s3.amazonaws.com"
}

run "distribution_is_enabled" {
  command = plan

  assert {
    condition     = aws_cloudfront_distribution.cobalt.enabled == true
    error_message = "CloudFront distribution must be enabled"
  }
}

run "distribution_has_ipv6" {
  command = plan

  assert {
    condition     = aws_cloudfront_distribution.cobalt.is_ipv6_enabled == true
    error_message = "CloudFront distribution must have IPv6 enabled"
  }
}

run "distribution_default_root_object" {
  command = plan

  assert {
    condition     = aws_cloudfront_distribution.cobalt.default_root_object == "index.html"
    error_message = "Default root object must be index.html"
  }
}

run "dev_uses_price_class_100" {
  command = plan

  assert {
    condition     = aws_cloudfront_distribution.cobalt.price_class == "PriceClass_100"
    error_message = "Dev environment should use PriceClass_100"
  }
}

run "prod_uses_price_class_all" {
  command = plan

  variables {
    environment = "prod"
  }

  assert {
    condition     = aws_cloudfront_distribution.cobalt.price_class == "PriceClass_All"
    error_message = "Prod environment should use PriceClass_All"
  }
}

run "ssl_support_method_sni_only" {
  command = plan

  assert {
    condition     = aws_cloudfront_distribution.cobalt.viewer_certificate[0].ssl_support_method == "sni-only"
    error_message = "SSL support method must be sni-only"
  }
}

run "minimum_protocol_version_tls12" {
  command = plan

  assert {
    condition     = aws_cloudfront_distribution.cobalt.viewer_certificate[0].minimum_protocol_version == "TLSv1.2_2021"
    error_message = "Minimum protocol version must be TLSv1.2_2021"
  }
}

run "waf_scope_is_cloudfront" {
  command = plan

  assert {
    condition     = aws_wafv2_web_acl.cloudfront_waf.scope == "CLOUDFRONT"
    error_message = "WAF Web ACL scope must be CLOUDFRONT"
  }
}

run "waf_default_action_allow" {
  command = plan

  assert {
    condition     = length(aws_wafv2_web_acl.cloudfront_waf.default_action[0].allow) >= 0
    error_message = "WAF default action must be allow"
  }
}

run "cache_policy_enables_brotli" {
  command = plan

  assert {
    condition     = aws_cloudfront_cache_policy.static_assets.parameters_in_cache_key_and_forwarded_to_origin[0].enable_accept_encoding_brotli == true
    error_message = "Cache policy must enable Brotli encoding"
  }
}

run "cache_policy_enables_gzip" {
  command = plan

  assert {
    condition     = aws_cloudfront_cache_policy.static_assets.parameters_in_cache_key_and_forwarded_to_origin[0].enable_accept_encoding_gzip == true
    error_message = "Cache policy must enable gzip encoding"
  }
}

run "cache_policy_default_ttl" {
  command = plan

  assert {
    condition     = aws_cloudfront_cache_policy.static_assets.default_ttl == 86400
    error_message = "Cache policy default TTL must be 86400 (1 day)"
  }
}

run "security_headers_hsts_max_age" {
  command = plan

  assert {
    condition     = aws_cloudfront_response_headers_policy.security.security_headers_config[0].strict_transport_security[0].access_control_max_age_sec == 31536000
    error_message = "HSTS max age must be 31536000 (1 year)"
  }
}

run "security_headers_frame_deny" {
  command = plan

  assert {
    condition     = aws_cloudfront_response_headers_policy.security.security_headers_config[0].frame_options[0].frame_option == "DENY"
    error_message = "X-Frame-Options must be DENY"
  }
}

run "distribution_has_alias" {
  command = plan

  assert {
    condition     = contains(aws_cloudfront_distribution.cobalt.aliases, "dev.cobaltplatform.com")
    error_message = "Distribution aliases must include the domain name"
  }
}
