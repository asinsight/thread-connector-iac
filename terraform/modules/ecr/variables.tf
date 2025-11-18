variable "repository_name" {
  type        = string
  description = "Name of the ECR repository."
}

variable "image_tag_mutability" {
  type        = string
  description = "Tag mutability setting for the repository."
  default     = "MUTABLE"
}

variable "scan_on_push" {
  type        = bool
  description = "Whether to enable image scan on push."
  default     = true
}

variable "force_delete" {
  type        = bool
  description = "Whether to allow the repository to be deleted even if it contains images."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the repository."
  default     = {}
}
