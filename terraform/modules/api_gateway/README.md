# API Gateway Module

This module provisions an AWS API Gateway REST API that forwards POST requests to a Lambda function. It also supports optional API key enforcement with either a user-supplied key (via environment variables or external secret stores) or an automatically generated random key to avoid hard-coding credentials in Terraform state.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `api_name` | Name of the API Gateway REST API. | `string` | n/a | yes |
| `description` | Description for the API. | `string` | `""` | no |
| `stage_name` | Deployment stage name. | `string` | n/a | yes |
| `resource_path_part` | Path segment that receives POST requests. | `string` | n/a | yes |
| `lambda_invoke_arn` | Invoke ARN of the Lambda integration target. | `string` | n/a | yes |
| `lambda_function_name` | Name of the Lambda function (for permissions). | `string` | n/a | yes |
| `require_api_key` | Whether to enforce an API key on the method. | `bool` | `false` | no |
| `api_key_name` | API key name (when enabled). | `string` | `"default-api-key"` | no |
| `api_key_description` | API key description. | `string` | `""` | no |
| `api_key_value` | Sensitive API key value. Leave `null` to auto-generate a secure random key that can be read securely from Terraform output. | `string` | `null` | no |
| `usage_plan_name` | Name of the API Gateway usage plan. | `string` | `"default-usage-plan"` | no |
| `throttle_burst_limit` | Usage plan burst limit. | `number` | `5` | no |
| `throttle_rate_limit` | Usage plan rate limit. | `number` | `10` | no |
| `endpoint_type` | REST API endpoint type. | `string` | `"REGIONAL"` | no |
| `tags` | Tags applied to created resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `invoke_url` | Invoke URL for the deployed stage. |
| `rest_api_id` | ID of the REST API. |
| `api_key_id` | ID of the created API key (when enabled). |
| `api_key_value` | Sensitive API key value (user-provided or generated). |

## Getting an API key for testing

If `require_api_key` is `true`, you need to include an `x-api-key` header when calling the POST endpoint. The key is available from Terraform outputs:

```sh
terraform output -raw api_gateway_api_key_value
```

The invoke URL for the stage is available via `terraform output api_gateway_invoke_url`.

API key enforcement is disabled by default. To enable it (for example in a shared environment), set `require_api_key = true` when instantiating the module.

## Example request body

POST requests should include a JSON body that lists the ASINs to process:

```json
{
  "asins": ["B0C5T25JJP", "B0C6QWKLP1"]
}
```

Alternatively, a single ASIN can be provided via `asin`:

```json
{
  "asin": "B0C5T25JJP"
}
```
