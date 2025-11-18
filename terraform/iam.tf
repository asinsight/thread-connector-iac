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

resource "aws_iam_role_policy_attachment" "terraform_admin" {
  role       = aws_iam_role.terraform.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
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
