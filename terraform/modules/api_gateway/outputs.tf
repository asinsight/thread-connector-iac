output "invoke_url" {
  description = "Invoke URL for the deployed API stage."
  value       = aws_api_gateway_stage.this.invoke_url
}

output "rest_api_id" {
  description = "Identifier of the REST API."
  value       = aws_api_gateway_rest_api.this.id
}

output "api_key_id" {
  description = "Identifier of the generated API key when enabled."
  value       = try(aws_api_gateway_api_key.this[0].id, null)
}

output "api_key_value" {
  description = "Value of the API key when one is generated."
  value       = var.require_api_key ? local.api_key_value : null
  sensitive   = true
}
