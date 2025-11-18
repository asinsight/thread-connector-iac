output "function_arn" {
  description = "ARN of the Lambda function."
  value       = aws_lambda_function.this.arn
}

output "function_name" {
  description = "Name of the Lambda function."
  value       = aws_lambda_function.this.function_name
}

output "qualified_arn" {
  description = "Qualified ARN for the published version."
  value       = aws_lambda_function.this.qualified_arn
}

output "invoke_arn" {
  description = "Invoke ARN of the Lambda function."
  value       = aws_lambda_function.this.invoke_arn
}

output "function_version" {
  description = "Latest published function version."
  value       = aws_lambda_function.this.version
}

output "role_arn" {
  description = "IAM role ARN associated with the Lambda function."
  value       = local.lambda_role_arn
}

output "log_group_name" {
  description = "CloudWatch log group name used by the function."
  value = try(
    aws_cloudwatch_log_group.this[0].name,
    coalesce(var.log_group_name, "/aws/lambda/${var.function_name}")
  )
}
