locals {
  name_prefix = "${var.project_name}-${var.environment}"
  tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
    },
    var.tags
  )

  # Compute callback API invoke URL to avoid circular dependency
  # Format: https://{api-id}.execute-api.{region}.amazonaws.com/{stage}/{path}
  callback_redirect_uri = "https://${module.threads_callback_api.rest_api_id}.execute-api.${var.aws_region}.amazonaws.com/${var.environment}/callback"
}
