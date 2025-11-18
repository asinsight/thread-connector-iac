variable "parameters" {
  description = "Map of parameters to create in SSM Parameter Store"
  type = map(object({
    name        = optional(string)
    description = optional(string, "")
    type        = optional(string, "SecureString")
    value       = string
    key_id      = optional(string)
    tier        = optional(string, "Standard")
    overwrite   = optional(bool, true)
  }))
}

variable "tags" {
  description = "Tags to apply to created parameters"
  type        = map(string)
  default     = {}
}
