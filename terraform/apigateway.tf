module "threads_callback_api" {
  source = "./modules/api_gateway"

  api_name            = "${local.name_prefix}-callback"
  description         = "API Gateway callback endpoint for Threads OAuth"
  stage_name          = var.environment
  resource_path_part  = "callback"
  lambda_invoke_arn   = module.callback_lambda.invoke_arn
  lambda_function_name = module.callback_lambda.function_name

  http_method     = "GET"
  require_api_key = false
  endpoint_type   = "REGIONAL"

  tags = local.tags
}

module "threads_api" {
  source = "./modules/api_gateway"

  api_name            = "${local.name_prefix}-api"
  description         = "API Gateway endpoint for Threads posting"
  stage_name          = var.environment
  resource_path_part  = "post"
  lambda_invoke_arn   = module.api_lambda.invoke_arn
  lambda_function_name = module.api_lambda.function_name

  http_method      = "POST"
  require_api_key  = true
  api_key_name     = "${local.name_prefix}-api-key"
  api_key_description = "API key for Threads posting endpoint"
  usage_plan_name  = "${local.name_prefix}-usage-plan"
  endpoint_type    = "REGIONAL"

  tags = local.tags
}
