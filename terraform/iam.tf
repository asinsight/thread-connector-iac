resource "aws_iam_user" "terraform" {
  name = "${local.name_prefix}-terraform"

  tags = local.tags
}

resource "aws_iam_access_key" "terraform" {
  user = aws_iam_user.terraform.name
}

data "aws_iam_policy_document" "terraform_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.terraform.arn]
    }
  }
}

resource "aws_iam_role" "terraform" {
  name               = "${local.name_prefix}-terraform"
  assume_role_policy = data.aws_iam_policy_document.terraform_assume_role.json

  tags = local.tags
}

data "aws_iam_policy_document" "terraform_permissions" {
  # Lambda permissions
  statement {
    sid = "LambdaManagement"
    actions = [
      "lambda:CreateFunction",
      "lambda:DeleteFunction",
      "lambda:GetFunction",
      "lambda:GetFunctionConfiguration",
      "lambda:UpdateFunctionCode",
      "lambda:UpdateFunctionConfiguration",
      "lambda:ListFunctions",
      "lambda:ListVersionsByFunction",
      "lambda:PublishVersion",
      "lambda:AddPermission",
      "lambda:RemovePermission",
      "lambda:GetPolicy",
      "lambda:TagResource",
      "lambda:UntagResource",
      "lambda:ListTags"
    ]
    resources = ["*"]
  }

  # CloudWatch Logs permissions for Lambda
  statement {
    sid = "CloudWatchLogsManagement"
    actions = [
      "logs:CreateLogGroup",
      "logs:DeleteLogGroup",
      "logs:DescribeLogGroups",
      "logs:PutRetentionPolicy",
      "logs:DeleteRetentionPolicy",
      "logs:TagLogGroup",
      "logs:UntagLogGroup",
      "logs:ListTagsLogGroup"
    ]
    resources = ["*"]
  }

  # API Gateway permissions
  statement {
    sid = "APIGatewayManagement"
    actions = [
      "apigateway:GET",
      "apigateway:POST",
      "apigateway:PUT",
      "apigateway:PATCH",
      "apigateway:DELETE",
      "apigateway:UpdateRestApiPolicy"
    ]
    resources = ["*"]
  }

  # SSM Parameter Store permissions
  statement {
    sid = "SSMParameterManagement"
    actions = [
      "ssm:PutParameter",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
      "ssm:DeleteParameter",
      "ssm:DescribeParameters",
      "ssm:AddTagsToResource",
      "ssm:RemoveTagsFromResource",
      "ssm:ListTagsForResource"
    ]
    resources = ["*"]
  }

  # IAM permissions - scoped to specific operations
  statement {
    sid = "IAMRoleManagement"
    actions = [
      "iam:CreateRole",
      "iam:GetRole",
      "iam:DeleteRole",
      "iam:UpdateRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:TagRole",
      "iam:UntagRole"
    ]
    resources = ["arn:aws:iam::*:role/*"]
  }

  statement {
    sid = "IAMPolicyManagement"
    actions = [
      "iam:CreatePolicy",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:DeletePolicy",
      "iam:ListPolicyVersions",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PutRolePolicy",
      "iam:GetRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:TagPolicy",
      "iam:UntagPolicy"
    ]
    resources = [
      "arn:aws:iam::*:policy/*",
      "arn:aws:iam::*:role/*"
    ]
  }

  statement {
    sid = "IAMUserManagement"
    actions = [
      "iam:CreateUser",
      "iam:GetUser",
      "iam:DeleteUser",
      "iam:UpdateUser",
      "iam:ListUserPolicies",
      "iam:ListAttachedUserPolicies",
      "iam:PutUserPolicy",
      "iam:GetUserPolicy",
      "iam:DeleteUserPolicy",
      "iam:AttachUserPolicy",
      "iam:DetachUserPolicy",
      "iam:CreateAccessKey",
      "iam:DeleteAccessKey",
      "iam:ListAccessKeys",
      "iam:TagUser",
      "iam:UntagUser"
    ]
    resources = ["arn:aws:iam::*:user/*"]
  }

  # Read-only permissions for data sources
  statement {
    sid = "ReadOnlyAccess"
    actions = [
      "iam:GetAccountSummary",
      "iam:ListRoles",
      "iam:ListUsers",
      "iam:ListPolicies",
      "sts:GetCallerIdentity"
    ]
    resources = ["*"]
  }

  # PassRole permission for Lambda execution roles
  statement {
    sid = "PassRoleToLambda"
    actions = [
      "iam:PassRole"
    ]
    resources = ["arn:aws:iam::*:role/*"]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "terraform" {
  name        = "${local.name_prefix}-terraform-policy"
  description = "Scoped permissions for Terraform to manage Threads OAuth infrastructure"
  policy      = data.aws_iam_policy_document.terraform_permissions.json

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "terraform_admin" {
  role       = aws_iam_role.terraform.name
  policy_arn = aws_iam_policy.terraform.arn
}

data "aws_iam_policy_document" "terraform_user_assume" {
  statement {
    actions   = ["sts:AssumeRole"]
    resources = [aws_iam_role.terraform.arn]
  }
}

resource "aws_iam_user_policy" "terraform_assume" {
  name   = "${local.name_prefix}-terraform-assume"
  user   = aws_iam_user.terraform.name
  policy = data.aws_iam_policy_document.terraform_user_assume.json
}
