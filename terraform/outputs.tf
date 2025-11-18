output "terraform_role_arn" {
  description = "IAM role ARN to assume for Terraform applies"
  value       = aws_iam_role.terraform.arn
}

output "terraform_user_name" {
  description = "IAM user created for running Terraform applies"
  value       = aws_iam_user.terraform.name
}

output "terraform_access_key_id" {
  description = "Access key ID for the Terraform IAM user"
  value       = aws_iam_access_key.terraform.id
  sensitive   = true
}

output "terraform_secret_access_key" {
  description = "Secret access key for the Terraform IAM user"
  value       = aws_iam_access_key.terraform.secret
  sensitive   = true
}
