output "parameter_names" {
  description = "Map of parameter identifiers to their names"
  value       = { for key, param in aws_ssm_parameter.this : key => param.name }
}

output "parameter_arns" {
  description = "Map of parameter identifiers to their ARNs"
  value       = { for key, param in aws_ssm_parameter.this : key => param.arn }
}
