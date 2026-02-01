output "endpoint" {
  description = "Primary RDS endpoint"
  value       = aws_db_instance.primary.endpoint
}

output "read_replica_endpoint" {
  description = "Read replica endpoint (empty if not prod)"
  value       = length(aws_db_instance.read_replica) > 0 ? aws_db_instance.read_replica[0].endpoint : ""
}

output "port" {
  description = "RDS port"
  value       = aws_db_instance.primary.port
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.primary.db_name
}
