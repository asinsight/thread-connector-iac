output "callback_api_invoke_url" {
  description = "Invoke URL for the Threads OAuth callback API"
  value       = module.threads_callback_api.invoke_url
}

output "oauth_redirect_uri" {
  description = "OAuth redirect URI to register in your Threads app settings"
  value       = local.callback_redirect_uri
}

output "threads_api_invoke_url" {
  description = "Invoke URL for the Threads posting API"
  value       = module.threads_api.invoke_url
}

output "threads_api_key_value" {
  description = "API key value for the Threads posting API"
  value       = module.threads_api.api_key_value
  sensitive   = true
}

output "threads_api_key_id" {
  description = "API key ID for the Threads posting API"
  value       = module.threads_api.api_key_id
}
