# Threads Connector Infrastructure

A serverless AWS infrastructure for integrating with the Threads API, enabling OAuth authentication and automated posting to Threads.

## Purpose

This project provides a complete Infrastructure as Code (IaC) solution for:

- **OAuth Authentication Flow**: Handle Threads OAuth callbacks and securely store user access tokens
- **Automated Posting**: Create and publish posts to Threads on behalf of authenticated users
- **Token Management**: Exchange short-lived tokens for long-lived tokens and store them securely in AWS Secrets Manager
- **API Gateway Endpoints**: Expose REST APIs for OAuth callbacks and post creation

## Architecture

### High-Level Flow

```
User → OAuth Flow → Callback Lambda → Secrets Manager
                                          ↓
User → API Request → API Lambda → Threads API
                         ↑
                   Secrets Manager
```

### Components

1. **Callback Lambda** ([source/callback/main.py](source/callback/main.py))
   - Handles OAuth redirect from Threads
   - Exchanges authorization code for access tokens
   - Converts short-lived tokens to long-lived tokens
   - Stores tokens in AWS Secrets Manager

2. **API Lambda** ([source/api/main.py](source/api/main.py))
   - Accepts post creation requests
   - Retrieves user tokens from Secrets Manager
   - Creates Threads post containers
   - Publishes posts to Threads

3. **API Gateway**
   - `GET /callback` - OAuth callback endpoint (public)
   - `POST /post` - Post creation endpoint (API key protected)

4. **AWS Secrets Manager**
   - Stores Threads app credentials (APP_ID, APP_SECRET)
   - Stores user access tokens (short-lived and long-lived)

## Project Structure

```
thread-connector-iac/
├── source/
│   ├── api/
│   │   └── main.py              # Lambda function for posting to Threads
│   └── callback/
│       └── main.py              # Lambda function for OAuth callback
├── terraform/
│   ├── modules/
│   │   ├── api_gateway/         # Reusable API Gateway module
│   │   ├── lambda/              # Reusable Lambda module
│   │   ├── security_groups/     # VPC security groups (if needed)
│   │   └── vpc/                 # VPC configuration (if needed)
│   ├── apigateway.tf            # API Gateway resources
│   ├── lambda.tf                # Lambda function definitions
│   ├── locals.tf                # Local variables and computed values
│   ├── outputs.tf               # Terraform outputs
│   ├── providers.tf             # AWS provider configuration
│   ├── variables.tf             # Input variables
│   └── versions.tf              # Terraform version constraints
├── terraform_iam/
│   ├── modules/
│   │   └── iam/                 # IAM module (if separated)
│   ├── iam.tf                   # IAM roles and policies
│   └── ...                      # IAM-specific configuration
└── README.md
```

### Pattern Description

This project follows a **modular Terraform structure** with:

- **Separation of Concerns**: Lambda functions, API Gateway, and IAM are defined in separate files
- **Reusable Modules**: Common infrastructure patterns (Lambda, API Gateway) are abstracted into modules
- **Environment-based Configuration**: Variables allow deployment to different environments (dev, staging, prod)
- **Security Best Practices**:
  - API key authentication for posting endpoint
  - IAM roles with least privilege access
  - Secrets Manager for credential storage
  - Input sanitization in Lambda functions

## Requirements

### Tools

- **Terraform** >= 1.0
- **AWS CLI** configured with appropriate credentials
- **Python** 3.11 (for Lambda runtime)
- **boto3** (AWS SDK for Python)
- **requests** library (for HTTP requests)

### AWS Resources

- AWS Account with permissions to create:
  - Lambda functions
  - API Gateway REST APIs
  - IAM roles and policies
  - Secrets Manager secrets
  - CloudWatch log groups

### Threads API

- Threads App ID and App Secret
- Registered OAuth redirect URI in Threads app settings

## Setup

### 1. Configure AWS Credentials

Create an AWS CLI profile or ensure default credentials are configured:

```bash
aws configure --profile threads-conn-deploy
```

### 2. Store Threads App Credentials

Create a secret in AWS Secrets Manager with your Threads app credentials:

```bash
aws secretsmanager create-secret \
  --name threads_app_credentials \
  --secret-string '{"APP_ID":"your-app-id","APP_SECRET":"your-app-secret"}' \
  --region us-east-1
```

### 3. Deploy IAM Resources (Optional)

If using separate IAM deployment:

```bash
cd terraform_iam
terraform init
terraform plan
terraform apply
```

### 4. Deploy Main Infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 5. Configure Threads App

After deployment, Terraform will output the OAuth redirect URI. Register this URL in your Threads app settings:

```bash
terraform output oauth_redirect_uri
```

Example output:
```
https://abc123xyz.execute-api.us-east-1.amazonaws.com/dev/callback
```

### 6. Retrieve API Key

Get the API key for the posting endpoint:

```bash
terraform output threads_api_key_value
```

## Usage

### OAuth Flow (User Authorization)

1. Direct users to the Threads authorization URL:
```
https://threads.net/oauth/authorize?
  client_id=YOUR_APP_ID&
  redirect_uri=YOUR_CALLBACK_URL&
  scope=threads_basic,threads_content_publish&
  response_type=code
```

2. After authorization, Threads redirects to your callback endpoint with an authorization code

3. The callback Lambda automatically:
   - Exchanges the code for an access token
   - Converts it to a long-lived token
   - Stores it in Secrets Manager under `threads/tokens/{user_id}`

### Creating Posts

Send a POST request to the API endpoint:

```bash
curl -X POST https://YOUR_API_URL/dev/post \
  -H "X-API-Key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "default",
    "post_text": "Hello from the Threads API!"
  }'
```

**Request Body:**
- `user_id` (string, required): User identifier (must match the stored token)
- `post_text` (string, required): Text content to post

**Response:**
```json
{
  "id": "1234567890",
  "user_id": "default"
}
```

### Python Example

```python
import requests
import json

api_url = "https://YOUR_API_URL/dev/post"
api_key = "YOUR_API_KEY"

headers = {
    "X-API-Key": api_key,
    "Content-Type": "application/json"
}

data = {
    "user_id": "default",
    "post_text": "Hello from Python!"
}

response = requests.post(api_url, json=data, headers=headers)
print(json.dumps(response.json(), indent=2))
```

## Configuration

### Variables

Key variables in [terraform/variables.tf](terraform/variables.tf):

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region for deployment | `us-east-1` |
| `profile_name` | AWS CLI profile name | `threads-conn-deploy` |
| `project_name` | Logical name for the project | `threads-connector` |
| `environment` | Deployment environment | `dev` |
| `credentials_secret_name` | Secret name for app credentials | `threads_app_credentials` |
| `secret_name_prefix` | Prefix for user token secrets | `threads/tokens` |

### Environment Variables (Lambda)

**Callback Lambda:**
- `THREADS_TOKEN_URL` - Threads OAuth token endpoint
- `REDIRECT_URI` - OAuth redirect URI
- `CREDENTIALS_SECRET_NAME` - Name of app credentials secret
- `SECRET_NAME_PREFIX` - Prefix for user token secrets

**API Lambda:**
- `SECRET_NAME_PREFIX` - Prefix for user token secrets

## Outputs

After deployment, Terraform provides:

- `callback_api_invoke_url` - Full URL for OAuth callback endpoint
- `oauth_redirect_uri` - OAuth redirect URI to register with Threads
- `threads_api_invoke_url` - Full URL for posting endpoint
- `threads_api_key_value` - API key for authentication (sensitive)
- `threads_api_key_id` - API key ID

## Security Considerations

- **API Key Protection**: The posting endpoint requires an API key. Keep this secret
- **Input Sanitization**: User IDs are sanitized to prevent injection attacks
- **Least Privilege IAM**: Lambda functions have minimal required permissions
- **HTTPS Only**: All endpoints use HTTPS encryption
- **Secret Rotation**: Consider implementing secret rotation for long-lived tokens
- **Rate Limiting**: Consider adding AWS WAF for rate limiting and DDoS protection

## Troubleshooting

### View Lambda Logs

```bash
aws logs tail /aws/lambda/threads-connector-dev-api --follow
aws logs tail /aws/lambda/threads-connector-dev-callback --follow
```

### Test Endpoints

```bash
# Test callback endpoint
curl "https://YOUR_API_URL/dev/callback?code=test_code"

# Test posting endpoint
curl -X POST https://YOUR_API_URL/dev/post \
  -H "X-API-Key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"user_id":"default","post_text":"Test post"}'
```

### Common Issues

1. **Token not found**: Ensure the user has completed OAuth flow and token is stored
2. **API key invalid**: Retrieve the API key using `terraform output threads_api_key_value`
3. **Permission denied**: Check IAM roles have correct Secrets Manager permissions
4. **Threads API errors**: Verify app credentials and token validity

## Cleanup

To destroy all infrastructure:

```bash
cd terraform
terraform destroy

# If IAM was deployed separately
cd ../terraform_iam
terraform destroy
```

## License

See [LICENSE](LICENSE) file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Support

For issues related to:
- **Threads API**: See [Threads API Documentation](https://developers.facebook.com/docs/threads)
- **AWS Services**: See [AWS Documentation](https://docs.aws.amazon.com/)
- **This Project**: Open an issue in the repository
