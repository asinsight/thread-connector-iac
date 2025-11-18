variable "name" {
  description = "Prefix for security group names"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the security groups will live"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block of the VPC to scope ingress rules"
  type        = string
}

variable "tags" {
  description = "Common tags to apply"
  type        = map(string)
  default     = {}
}
