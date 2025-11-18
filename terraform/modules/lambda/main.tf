locals {
  environment_variables = {
    for k, v in var.environment_variables : k => v
    if v != null
  }

  lambda_role_arn = coalesce(
    var.role_arn,
    try(aws_iam_role.this[0].arn, null)
  )
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_partition" "current" {}

data "aws_iam_policy_document" "lambda_logs" {
  statement {
    sid    = "AllowCreatingLogStreams"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:logs:*:*:*"
    ]
  }
}

resource "aws_iam_role" "this" {
  count = var.role_arn == null ? 1 : 0

  name        = var.role_name
  name_prefix = var.role_name == null ? "${var.function_name}-" : null
  description = "IAM role for Lambda function ${var.function_name}"
  path        = var.role_path

  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  permissions_boundary = var.iam_permissions_boundary

  tags = var.tags

  lifecycle {
    ignore_changes = [tags["Name"]]
  }
}

resource "aws_iam_role_policy" "logs" {
  count = var.role_arn == null ? 1 : 0

  name   = "${var.function_name}-logs"
  role   = aws_iam_role.this[0].id
  policy = data.aws_iam_policy_document.lambda_logs.json
}

resource "aws_cloudwatch_log_group" "this" {
  count = var.create_log_group ? 1 : 0

  name              = coalesce(var.log_group_name, "/aws/lambda/${var.function_name}")
  retention_in_days = var.log_retention_in_days
  kms_key_id        = var.log_group_kms_key_id
  tags              = var.tags
}

resource "aws_lambda_function" "this" {
  function_name = var.function_name
  description   = var.description
  role          = local.lambda_role_arn
  handler       = var.package_type == "Zip" ? var.handler : null
  runtime       = var.package_type == "Zip" ? var.runtime : null
  image_uri     = var.package_type == "Image" ? var.image_uri : null
  architectures = var.architectures
  memory_size   = var.memory_size
  timeout       = var.timeout
  publish       = var.publish
  reserved_concurrent_executions = var.reserved_concurrent_executions
  kms_key_arn   = var.kms_key_arn
  layers        = var.layers
  package_type  = var.package_type
  filename         = var.package_type == "Zip" ? var.package_source_file : null
  s3_bucket        = var.package_type == "Zip" && var.package_source_file == null ? var.package_s3_bucket : null
  s3_key           = var.package_type == "Zip" && var.package_source_file == null ? var.package_s3_key : null
  s3_object_version = var.package_type == "Zip" && var.package_source_file == null ? var.package_s3_object_version : null
  source_code_hash  = var.package_type == "Zip" ? var.source_code_hash : null

  tags = var.tags

  dynamic "environment" {
    for_each = length(local.environment_variables) > 0 ? [local.environment_variables] : []

    content {
      variables = environment.value
    }
  }

  dynamic "dead_letter_config" {
    for_each = var.dead_letter_target_arn != null ? [var.dead_letter_target_arn] : []

    content {
      target_arn = dead_letter_config.value
    }
  }

  dynamic "vpc_config" {
    for_each = var.vpc_config == null ? [] : [var.vpc_config]

    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  dynamic "tracing_config" {
    for_each = var.tracing_mode != null ? [var.tracing_mode] : []

    content {
      mode = tracing_config.value
    }
  }

  dynamic "ephemeral_storage" {
    for_each = var.ephemeral_storage_size != null ? [var.ephemeral_storage_size] : []

    content {
      size = ephemeral_storage.value
    }
  }
}
