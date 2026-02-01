output "lambda_function_name" {
  description = "Name of the incident responder Lambda function"
  value       = var.enable_incident_response ? aws_lambda_function.incident_responder[0].function_name : ""
}

output "lambda_function_arn" {
  description = "ARN of the incident responder Lambda function"
  value       = var.enable_incident_response ? aws_lambda_function.incident_responder[0].arn : ""
}

output "lambda_log_group" {
  description = "CloudWatch log group for the incident responder Lambda"
  value       = var.enable_incident_response ? aws_cloudwatch_log_group.lambda_logs[0].name : ""
}
