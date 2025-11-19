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

variable "threads_token_url" {
  description = "Threads OAuth token endpoint"
  type        = string
  default     = "https://graph.threads.net/oauth/access_token"
}

variable "threads_api_url" {
  description = "Threads API endpoint to call with the stored token"
  type        = string
  default     = "https://api.threads.net/v1/me"
}

variable "credentials_secret_name" {
  description = "Secrets Manager secret name storing the Threads app credentials (APP_ID and APP_SECRET)"
  type        = string
  default     = "threads_app_credentials"
}

variable "secret_name_prefix" {
  description = "Prefix for Secrets Manager secret names storing user access tokens"
  type        = string
  default     = "threads/tokens"
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
