variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "profile_name" {
  description = "AWS CLI profile name"
  type        = string
  default     = "threads-conn-deploy"
}

variable "project_name" {
  description = "Logical name for this Threads integration"
  type        = string
  default     = "threads-connector"
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = "dev"
}

variable "threads_client_id" {
  description = "Threads OAuth client ID"
  type        = string
  sensitive   = true
}

variable "threads_client_secret" {
  description = "Threads OAuth client secret"
  type        = string
  sensitive   = true
}

variable "threads_redirect_uri" {
  description = "Registered OAuth redirect URI"
  type        = string
}

variable "threads_token_url" {
  description = "Threads OAuth token endpoint"
  type        = string
  default     = "https://api.threads.net/oauth/token"
}

variable "threads_api_url" {
  description = "Threads API endpoint to call with the stored token"
  type        = string
  default     = "https://api.threads.net/v1/me"
}

variable "token_base_path" {
  description = "Base SSM Parameter Store path for per-user tokens"
  type        = string
  default     = "/threads/tokens"
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
