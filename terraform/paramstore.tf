module "threads_param_store" {
  source = "./modules/parameter_store"

  parameters = {
    client_id = {
      name        = "/threads/oauth/client_id"
      description = "Threads OAuth client ID"
      value       = var.threads_client_id
    }
    client_secret = {
      name        = "/threads/oauth/client_secret"
      description = "Threads OAuth client secret"
      value       = var.threads_client_secret
    }
    redirect_uri = {
      name        = "/threads/oauth/redirect_uri"
      description = "Threads OAuth redirect URI"
      type        = "String"
      value       = var.threads_redirect_uri
    }
  }

  tags = local.tags
}
