variable "api_name" {
  description = "Name of the API Gateway REST API."
  type        = string
}

variable "description" {
  description = "Description for the API Gateway REST API."
  type        = string
  default     = ""
}

variable "stage_name" {
  description = "Deployment stage name."
  type        = string
}

variable "resource_path_part" {
  description = "Path part that will receive the callback requests."
  type        = string
}

variable "lambda_invoke_arn" {
  description = "Invoke ARN for the Lambda function target."
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the Lambda function to grant invoke permissions."
  type        = string
}

variable "require_api_key" {
  description = "Whether the method should require an API key."
  type        = bool
  default     = false
}

variable "api_key_name" {
  description = "Name for the API key when API key requirement is enabled."
  type        = string
  default     = "default-api-key"
}

variable "api_key_description" {
  description = "Description for the generated API key."
  type        = string
  default     = ""
}

variable "api_key_value" {
  description = "Optional fixed API key value. Leave null to auto-generate a random value."
  type        = string
  default     = null
  sensitive   = true
}

variable "usage_plan_name" {
  description = "Name of the usage plan associated with the API key."
  type        = string
  default     = "default-usage-plan"
}

variable "throttle_burst_limit" {
  description = "Burst limit for usage plan throttling."
  type        = number
  default     = 5
}

variable "throttle_rate_limit" {
  description = "Rate limit for usage plan throttling."
  type        = number
  default     = 10
}

variable "endpoint_type" {
  description = "Type of endpoint configuration for the REST API."
  type        = string
  default     = "REGIONAL"
}

variable "http_method" {
  description = "HTTP method for the API Gateway method (GET, POST, etc.)."
  type        = string
  default     = "GET"
}

variable "tags" {
  description = "Tags to apply to API Gateway resources."
  type        = map(string)
  default     = {}
}
