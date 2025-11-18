output "lambda_security_group_id" {
  description = "ID of the Lambda security group"
  value       = aws_security_group.lambda.id
}

output "endpoint_security_group_id" {
  description = "ID of the interface endpoint security group"
  value       = aws_security_group.endpoints.id
}
