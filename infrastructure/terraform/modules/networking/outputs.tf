output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnets
}

output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = module.vpc.database_subnets
}

output "vpc_endpoint_sg_id" {
  description = "Security group ID for VPC endpoints"
  value       = aws_security_group.vpc_endpoints.id
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of the private subnets"
  value       = module.vpc.private_subnets_cidr_blocks
}

output "flow_log_destination_arn" {
  description = "ARN of the VPC flow log destination"
  value       = var.enable_flow_log ? module.vpc.vpc_flow_log_destination_arn : ""
}

output "flow_log_group_name" {
  description = "CloudWatch log group name for VPC flow logs"
  value       = var.enable_flow_log ? regex("log-group:(.+?)(?::\\*)?$", module.vpc.vpc_flow_log_destination_arn)[0] : ""
}
