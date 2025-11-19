data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "archive_file" "callback" {
  type        = "zip"
  source_dir  = "${path.root}/../source/callback"
  output_path = "${path.root}/callback.zip"
}

data "archive_file" "api" {
  type        = "zip"
  source_dir  = "${path.root}/../source/api"
  output_path = "${path.root}/api.zip"
}

locals {
  token_parameter_arn = "arn:${data.aws_partition.current.partition}:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${var.token_base_path}/*"

  oauth_parameter_arns = compact([
    var.threads_client_id_parameter_name == null ? null : "arn:${data.aws_partition.current.partition}:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${var.threads_client_id_parameter_name}",
    var.threads_client_secret_parameter_name == null ? null : "arn:${data.aws_partition.current.partition}:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${var.threads_client_secret_parameter_name}",
    var.threads_redirect_uri_parameter_name == null ? null : "arn:${data.aws_partition.current.partition}:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${var.threads_redirect_uri_parameter_name}",
  ])
}

module "callback_lambda" {
  source = "./modules/lambda"

  function_name = "${local.name_prefix}-callback"
  description   = "Handles Threads OAuth callbacks and stores access tokens"
  handler       = "main.lambda_handler"
  runtime       = "python3.11"

  package_source_file = data.archive_file.callback.output_path
  source_code_hash    = data.archive_file.callback.output_base64sha256

  timeout     = 30
  memory_size = 256

  environment_variables = {
    THREADS_TOKEN_URL       = var.threads_token_url
    CLIENT_ID_PARAMETER     = var.threads_client_id_parameter_name
    CLIENT_SECRET_PARAMETER = var.threads_client_secret_parameter_name
    REDIRECT_URI            = var.threads_redirect_uri
    TOKEN_BASE_PATH         = var.token_base_path
  }

  tags = local.tags
}

module "api_lambda" {
  source = "./modules/lambda"

  function_name = "${local.name_prefix}-api"
  description   = "Calls the Threads API with a stored token"
  handler       = "main.lambda_handler"
  runtime       = "python3.11"

  package_source_file = data.archive_file.api.output_path
  source_code_hash    = data.archive_file.api.output_base64sha256

  timeout     = 30
  memory_size = 256

  environment_variables = {
    THREADS_API_URL = var.threads_api_url
    TOKEN_BASE_PATH = var.token_base_path
  }

  tags = local.tags
}

data "aws_iam_policy_document" "callback_ssm" {
  statement {
    actions   = ["ssm:GetParameter", "ssm:GetParameters"]
    resources = local.oauth_parameter_arns
  }

  statement {
    actions   = ["ssm:PutParameter", "ssm:GetParameter", "ssm:GetParametersByPath"]
    resources = [local.token_parameter_arn]
  }
}

resource "aws_iam_role_policy" "callback_ssm" {
  name   = "${module.callback_lambda.function_name}-ssm-access"
  role   = module.callback_lambda.role_arn
  policy = data.aws_iam_policy_document.callback_ssm.json
}

data "aws_iam_policy_document" "api_ssm" {
  statement {
    actions   = ["ssm:GetParameter", "ssm:GetParametersByPath"]
    resources = [local.token_parameter_arn]
  }
}

resource "aws_iam_role_policy" "api_ssm" {
  name   = "${module.api_lambda.function_name}-ssm-access"
  role   = module.api_lambda.role_arn
  policy = data.aws_iam_policy_document.api_ssm.json
}
