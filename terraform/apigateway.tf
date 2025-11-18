module "threads_callback_api" {
  source = "./modules/api_gateway"

  api_name            = "${local.name_prefix}-callback"
  description         = "API Gateway callback endpoint for Threads OAuth"
  stage_name          = var.environment
  resource_path_part  = "callback"
  lambda_invoke_arn   = module.callback_lambda.invoke_arn
  lambda_function_name = module.callback_lambda.function_name

  require_api_key = false
  endpoint_type   = "REGIONAL"

  tags = local.tags
}
