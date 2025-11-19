output "terraform_role_arn" {
  description = "IAM role ARN to assume for Terraform applies"
  value       = module.terraform_iam.role_arn
}

output "terraform_user_name" {
  description = "IAM user created for running Terraform applies"
  value       = module.terraform_iam.user_name
}

output "terraform_access_key_id" {
  description = "Access key ID for the Terraform IAM user"
  value       = module.terraform_iam.access_key_id
  sensitive   = true
}

output "terraform_secret_access_key" {
  description = "Secret access key for the Terraform IAM user"
  value       = module.terraform_iam.secret_access_key
  sensitive   = true
}
