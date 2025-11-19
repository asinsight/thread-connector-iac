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
  # Secrets Manager ARN for user access tokens
  token_secret_arn = "arn:${data.aws_partition.current.partition}:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.secret_name_prefix}/*"

  # Secrets Manager ARN for app credentials
  credentials_secret_arn = "arn:${data.aws_partition.current.partition}:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.credentials_secret_name}"
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

  layers = ["arn:aws:lambda:us-east-1:601333025120:layer:requests-layer:1"]

  environment_variables = {
    THREADS_TOKEN_URL        = var.threads_token_url
    REDIRECT_URI             = local.callback_redirect_uri
    CREDENTIALS_SECRET_NAME  = var.credentials_secret_name
    SECRET_NAME_PREFIX       = var.secret_name_prefix
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

  layers = ["arn:aws:lambda:us-east-1:601333025120:layer:requests-layer:1"]

  environment_variables = {
    THREADS_API_URL    = var.threads_api_url
    SECRET_NAME_PREFIX = var.secret_name_prefix
  }

  tags = local.tags
}

data "aws_iam_policy_document" "callback_secrets" {
  statement {
    sid = "AppCredentialsAccess"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = ["${local.credentials_secret_arn}*"]
  }

  statement {
    sid = "UserTokensAccess"
    actions = [
      "secretsmanager:CreateSecret",
      "secretsmanager:UpdateSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:TagResource"
    ]
    resources = [local.token_secret_arn]
  }
}

resource "aws_iam_role_policy" "callback_secrets" {
  name   = "${module.callback_lambda.function_name}-secrets-access"
  role   = module.callback_lambda.role_name
  policy = data.aws_iam_policy_document.callback_secrets.json
}

data "aws_iam_policy_document" "api_secrets" {
  statement {
    sid = "SecretsManagerReadAccess"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [local.token_secret_arn]
  }
}

resource "aws_iam_role_policy" "api_secrets" {
  name   = "${module.api_lambda.function_name}-secrets-access"
  role   = module.api_lambda.role_name
  policy = data.aws_iam_policy_document.api_secrets.json
}
