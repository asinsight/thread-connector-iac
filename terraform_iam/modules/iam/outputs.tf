output "user_name" {
  description = "Name of the IAM user"
  value       = aws_iam_user.terraform.name
}

output "user_arn" {
  description = "ARN of the IAM user"
  value       = aws_iam_user.terraform.arn
}

output "role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.terraform.name
}

output "role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.terraform.arn
}

output "policy_arn" {
  description = "ARN of the IAM policy"
  value       = aws_iam_policy.terraform.arn
}

output "access_key_id" {
  description = "Access key ID for the IAM user"
  value       = aws_iam_access_key.terraform.id
  sensitive   = true
}

output "secret_access_key" {
  description = "Secret access key for the IAM user"
  value       = aws_iam_access_key.terraform.secret
  sensitive   = true
}
