variable "function_name" {
  description = "Name of the Lambda function."
  type        = string
}

variable "description" {
  description = "Description for the Lambda function."
  type        = string
  default     = "Managed by Terraform"
}

variable "package_type" {
  description = "Lambda deployment package type (Zip or Image)."
  type        = string
  default     = "Zip"

  validation {
    condition     = contains(["Zip", "Image"], var.package_type)
    error_message = "package_type must be either Zip or Image."
  }
}

variable "handler" {
  description = "Function entrypoint handler. Required when using the Zip package type."
  type        = string
  default     = null

  validation {
    condition     = var.package_type == "Image" || var.handler != null
    error_message = "handler must be provided when package_type is Zip."
  }
}

variable "runtime" {
  description = "Runtime identifier (for example, python3.11). Required when using the Zip package type."
  type        = string
  default     = null

  validation {
    condition     = var.package_type == "Image" || var.runtime != null
    error_message = "runtime must be provided when package_type is Zip."
  }
}

variable "image_uri" {
  description = "URI for the container image in ECR. Required when using the Image package type."
  type        = string
  default     = null

  validation {
    condition     = var.package_type == "Zip" || var.image_uri != null
    error_message = "image_uri must be provided when package_type is Image."
  }
}

variable "architectures" {
  description = "CPU architectures to target."
  type        = list(string)
  default     = ["x86_64"]
}

variable "memory_size" {
  description = "Amount of memory in MB assigned to the function."
  type        = number
  default     = 128
}

variable "timeout" {
  description = "Function timeout in seconds."
  type        = number
  default     = 3
}

variable "publish" {
  description = "Whether to publish a new version on each update."
  type        = bool
  default     = false
}

variable "reserved_concurrent_executions" {
  description = "Number of concurrent executions reserved for the function. Use null for unreserved."
  type        = number
  default     = null
}

variable "environment_variables" {
  description = "Environment variables to inject into the Lambda runtime."
  type        = map(string)
  default     = {}
}

variable "kms_key_arn" {
  description = "KMS key ARN used to encrypt environment variables."
  type        = string
  default     = null
}

variable "layers" {
  description = "List of Lambda layer ARNs."
  type        = list(string)
  default     = []
}

variable "package_source_file" {
  description = "Path to the local .zip file that contains the Lambda deployment package. Mutually exclusive with S3 inputs."
  type        = string
  default     = null

  validation {
    condition = (
      var.package_type == "Image" ? (
        var.package_source_file == null && var.package_s3_bucket == null && var.package_s3_key == null
      ) : (
        (var.package_source_file != null && var.package_s3_bucket == null && var.package_s3_key == null) ||
        (var.package_source_file == null && var.package_s3_bucket != null && var.package_s3_key != null)
      )
    )
    error_message = "Provide either package_source_file or package_s3_bucket and package_s3_key, but not both."
  }
}

variable "package_s3_bucket" {
  description = "S3 bucket that stores the Lambda deployment package."
  type        = string
  default     = null
}

variable "package_s3_key" {
  description = "S3 key that stores the Lambda deployment package."
  type        = string
  default     = null
}

variable "package_s3_object_version" {
  description = "S3 object version for the deployment package."
  type        = string
  default     = null
}

variable "source_code_hash" {
  description = "Base64-encoded SHA256 hash of the deployment package to trigger updates on source changes."
  type        = string
  default     = null
}

variable "dead_letter_target_arn" {
  description = "ARN of the SNS topic or SQS queue for Lambda dead-letter configuration."
  type        = string
  default     = null
}

variable "tracing_mode" {
  description = "X-Ray tracing mode. Set to null to disable explicit configuration."
  type        = string
  default     = "PassThrough"

  validation {
    condition     = var.tracing_mode == null || contains(["PassThrough", "Active"], var.tracing_mode)
    error_message = "Valid tracing_mode values are PassThrough, Active, or null."
  }
}

variable "ephemeral_storage_size" {
  description = "Ephemeral storage size in MB (512-10240)."
  type        = number
  default     = null

  validation {
    condition = var.ephemeral_storage_size == null || (
      var.ephemeral_storage_size >= 512 && var.ephemeral_storage_size <= 10240
    )
    error_message = "ephemeral_storage_size must be between 512 and 10240 MB."
  }
}

variable "vpc_config" {
  description = "Optional VPC configuration for the Lambda function."
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "role_arn" {
  description = "Existing IAM role ARN for the Lambda function. When null, a role is created."
  type        = string
  default     = null
}

variable "role_name" {
  description = "Name to use for the IAM role that is created. When null, a name prefix is generated."
  type        = string
  default     = null
}

variable "role_path" {
  description = "Path for the IAM role."
  type        = string
  default     = null
}

variable "iam_permissions_boundary" {
  description = "Permissions boundary ARN applied to the IAM role created by the module."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to created resources."
  type        = map(string)
  default     = {}
}

variable "create_log_group" {
  description = "Whether to manage the CloudWatch log group for the Lambda function."
  type        = bool
  default     = true
}

variable "log_group_name" {
  description = "Override name for the CloudWatch log group. Defaults to /aws/lambda/<function_name>."
  type        = string
  default     = null
}

variable "log_retention_in_days" {
  description = "Number of days to retain logs. Null keeps the default retention forever."
  type        = number
  default     = null
}

variable "log_group_kms_key_id" {
  description = "KMS key ARN used to encrypt the log group."
  type        = string
  default     = null
}
