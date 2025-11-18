variable "user_name" {
  description = "Name for the Terraform IAM user"
  type        = string
}

variable "role_name" {
  description = "Name for the Terraform IAM role"
  type        = string
}

variable "policy_name" {
  description = "Name for the Terraform IAM policy"
  type        = string
}

variable "tags" {
  description = "Tags to apply to IAM resources"
  type        = map(string)
  default     = {}
}
