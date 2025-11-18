module "terraform_iam" {
  source = "./modules/iam"

  user_name   = "${local.name_prefix}-terraform"
  role_name   = "${local.name_prefix}-terraform"
  policy_name = "${local.name_prefix}-terraform-policy"

  tags = local.tags
}
