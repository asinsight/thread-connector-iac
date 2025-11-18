# Lambda Module

Reusable Terraform module that provisions an AWS Lambda function along with the supporting IAM role and optional CloudWatch log group.

## Features

- Creates or reuses an IAM role for the Lambda function.
- Deploys code either from a local ZIP file, an S3 object, or a container image hosted in ECR.
- Configurable runtime parameters (timeout, memory, architectures, concurrency, layers, environment variables, tracing, VPC networking, etc.).
- Optionally manages the CloudWatch log group with retention and KMS encryption settings.

## Usage

```hcl
module "lambda" {
  source = "./modules/lambda"

  function_name = "example-api"
  handler       = "index.handler"
  runtime       = "nodejs20.x"

  package_source_file = "${path.module}/build/example.zip"
  source_code_hash    = filebase64sha256("${path.module}/build/example.zip")

  memory_size = 512
  timeout     = 10
  architectures = ["arm64"]

  environment_variables = {
    STAGE = var.stage
  }

  tags = {
    Service = "api"
  }
}
```

To deploy a container image, set `package_type = "Image"` and provide `image_uri` instead of the ZIP-related inputs.

Set `package_s3_bucket` and `package_s3_key` (instead of `package_source_file`) when deploying from S3. Populate `terraform.tfvars` or a workspace-specific `.tfvars` file with the values you want to change between environments.

## Inputs

See `variables.tf` for the full list of supported inputs and defaults.

## Outputs

| Name             | Description                               |
| ---------------- | ----------------------------------------- |
| `function_arn`   | ARN of the Lambda function.               |
| `function_name`  | Function name.                            |
| `qualified_arn`  | Qualified ARN of the latest version.      |
| `invoke_arn`     | Invoke ARN for API Gateway or other use.  |
| `function_version` | Latest published version.              |
| `role_arn`       | IAM role ARN in use.                      |
| `log_group_name` | CloudWatch log group name for the lambda. |
