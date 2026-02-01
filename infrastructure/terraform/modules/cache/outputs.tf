output "endpoint" {
  description = "Redis primary endpoint"
  value       = var.enable_cache ? aws_elasticache_replication_group.cobalt[0].primary_endpoint_address : ""
}

output "port" {
  description = "Redis port"
  value       = var.enable_cache ? aws_elasticache_replication_group.cobalt[0].port : 0
}

output "auth_token" {
  description = "Redis auth token"
  value       = var.enable_cache ? random_password.redis_auth[0].result : ""
  sensitive   = true
}
