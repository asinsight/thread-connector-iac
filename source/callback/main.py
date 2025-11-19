"""
Threads OAuth callback Lambda function.

This Lambda function:
1. Receives authorization code from query parameters
2. Loads app credentials from Secrets Manager
3. Exchanges authorization code for short-lived access token
4. Exchanges short-lived token for long-lived token
5. Stores both tokens to Secrets Manager
"""

import json
import logging
import os
from typing import Any, Dict
from urllib.parse import urlencode
from urllib.request import Request, urlopen

import boto3
import requests
from botocore.exceptions import ClientError

# Configure logging
LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)

# AWS clients
secrets_manager = boto3.client("secretsmanager")


class MissingParameterError(Exception):
    """Custom exception for missing required parameters."""
    pass


class SecretRetrievalError(Exception):
    """Custom exception for secret retrieval errors."""
    pass


class TokenExchangeError(Exception):
    """Custom exception for token exchange errors."""
    pass


class SecretStorageError(Exception):
    """Custom exception for secret storage errors."""
    pass


def _get_code_from_params(event: Dict[str, Any]) -> str:
    """
    Extract authorization code from query string parameters.

    Args:
        event: Lambda event dictionary

    Returns:
        Authorization code

    Raises:
        MissingParameterError: If code parameter is missing
    """
    params = event.get("queryStringParameters") or {}
    code = params.get("code")

    if not code:
        LOGGER.error("Missing 'code' parameter in request")
        raise MissingParameterError("Authorization code is required")

    LOGGER.info("Successfully extracted authorization code")
    return code


def _load_app_credentials(credentials_secret_name: str) -> tuple[str, str]:
    """
    Load APP_ID and APP_SECRET from Secrets Manager.

    Args:
        credentials_secret_name: Name of the secret containing app credentials

    Returns:
        Tuple of (app_id, app_secret)

    Raises:
        SecretRetrievalError: If credentials cannot be retrieved
    """
    try:
        response = secrets_manager.get_secret_value(SecretId=credentials_secret_name)
        secret_string = response["SecretString"]
        credentials = json.loads(secret_string)

        app_id = credentials.get("APP_ID")
        app_secret = credentials.get("APP_SECRET")

        if not app_id or not app_secret:
            LOGGER.error("APP_ID or APP_SECRET missing from credentials secret")
            raise SecretRetrievalError("Invalid credentials format in secret")

        LOGGER.info("Successfully loaded app credentials from Secrets Manager")
        return app_id, app_secret

    except secrets_manager.exceptions.ResourceNotFoundException:
        LOGGER.error(f"Credentials secret not found: {credentials_secret_name}")
        raise SecretRetrievalError(f"Credentials secret not found: {credentials_secret_name}")
    except ClientError as e:
        error_code = e.response.get("Error", {}).get("Code", "Unknown")
        LOGGER.error(f"Failed to retrieve credentials secret: {error_code}")
        raise SecretRetrievalError(f"Failed to retrieve credentials: {error_code}") from e
    except json.JSONDecodeError as e:
        LOGGER.error(f"Failed to parse credentials secret: {e}")
        raise SecretRetrievalError("Invalid JSON in credentials secret") from e
    except KeyError as e:
        LOGGER.error(f"Missing required field in credentials secret: {e}")
        raise SecretRetrievalError(f"Missing required field: {e}") from e


def _exchange_token(code: str, app_id: str, app_secret: str, redirect_uri: str, token_url: str) -> str:
    """
    Exchange authorization code for access token.

    Args:
        code: Authorization code
        app_id: Threads app ID
        app_secret: Threads app secret
        redirect_uri: OAuth redirect URI
        token_url: Token endpoint URL

    Returns:
        Access token

    Raises:
        TokenExchangeError: If token exchange fails
    """
    form_data = {
        "client_id": int(app_id),
        "client_secret": app_secret,
        "redirect_uri": redirect_uri,
        "code": code,
        "grant_type": "authorization_code"
    }

    try:
        LOGGER.info("Exchanging authorization code for access token")
        response = requests.post(token_url, data=form_data, timeout=30)
        response.raise_for_status()

        data = response.json()
        access_token = data.get("access_token")

        if not access_token:
            LOGGER.error("No access_token in response from token endpoint")
            raise TokenExchangeError("No access_token in response")

        LOGGER.info("Successfully exchanged code for access token")
        return access_token

    except requests.exceptions.HTTPError as e:
        error_body = e.response.text if e.response else "No error body"
        LOGGER.error(f"HTTP error during token exchange: {e.response.status_code} - {error_body}")
        raise TokenExchangeError(f"Token exchange failed with HTTP {e.response.status_code}") from e
    except requests.exceptions.RequestException as e:
        LOGGER.error(f"Request error during token exchange: {e}")
        raise TokenExchangeError("Failed to reach token endpoint") from e
    except json.JSONDecodeError as e:
        LOGGER.error(f"Failed to parse token response: {e}")
        raise TokenExchangeError("Invalid JSON response from token endpoint") from e
    except ValueError as e:
        LOGGER.error(f"Invalid app_id format: {e}")
        raise TokenExchangeError("Invalid app_id format") from e


def _exchange_for_long_lived_token(access_token: str, app_secret: str) -> str:
    """
    Exchange short-lived access token for long-lived token.

    Args:
        access_token: Short-lived access token
        app_secret: Threads app secret

    Returns:
        Long-lived access token

    Raises:
        TokenExchangeError: If token exchange fails
    """
    token_url = "https://graph.threads.net/access_token"

    params = {
        "grant_type": "th_exchange_token",
        "client_secret": app_secret,
        "access_token": access_token
    }

    url = token_url + "?" + urlencode(params)

    try:
        LOGGER.info("Exchanging short-lived token for long-lived token")
        req = Request(url, method="GET")
        with urlopen(req) as resp:
            body = resp.read().decode("utf-8")

        data = json.loads(body)
        long_lived_token = data.get("access_token")

        if not long_lived_token:
            LOGGER.error("No access_token in response from long-lived token endpoint")
            raise TokenExchangeError("No access_token in long-lived token response")

        LOGGER.info("Successfully exchanged for long-lived token")
        return long_lived_token

    except json.JSONDecodeError as e:
        LOGGER.error(f"Failed to parse long-lived token response: {e}")
        raise TokenExchangeError("Invalid JSON response from long-lived token endpoint") from e
    except Exception as e:
        LOGGER.error(f"Error during long-lived token exchange: {e}")
        raise TokenExchangeError(f"Failed to exchange for long-lived token: {e}") from e


def _store_access_token(access_token: str, long_lived_token: str, user_id: str, secret_name_prefix: str) -> None:
    """
    Store access token and long-lived token to Secrets Manager.

    Args:
        access_token: OAuth access token (short-lived)
        long_lived_token: Long-lived access token
        user_id: User identifier
        secret_name_prefix: Prefix for secret name

    Raises:
        SecretStorageError: If token storage fails
    """
    secret_name = f"{secret_name_prefix}/{user_id}"
    secret_value = json.dumps({
        "access_token": access_token,
        "long_lived_token": long_lived_token
    })

    try:
        # Try to update existing secret first
        try:
            secrets_manager.update_secret(
                SecretId=secret_name,
                SecretString=secret_value
            )
            LOGGER.info(f"Updated existing secret: {secret_name}")
        except secrets_manager.exceptions.ResourceNotFoundException:
            # Secret doesn't exist, create it
            secrets_manager.create_secret(
                Name=secret_name,
                SecretString=secret_value,
                Description=f"Threads access token for user {user_id}"
            )
            LOGGER.info(f"Created new secret: {secret_name}")

    except ClientError as e:
        error_code = e.response.get("Error", {}).get("Code", "Unknown")
        LOGGER.error(f"Failed to store access token: {error_code}")
        raise SecretStorageError(f"Failed to store token: {error_code}") from e


def lambda_handler(event: Dict[str, Any], _context: Any) -> Dict[str, Any]:
    """
    Lambda handler for Threads OAuth callback.

    Args:
        event: API Gateway event
        _context: Lambda context

    Returns:
        API Gateway response
    """
    LOGGER.info("Received OAuth callback request")

    try:
        # Step 1: Get authorization code from query parameters
        code = _get_code_from_params(event)

        # Extract user_id from params (with default fallback)
        params = event.get("queryStringParameters") or {}
        user_id = params.get("user_id", "default")
        # Sanitize user_id to prevent injection
        user_id = "".join(c for c in user_id if c.isalnum() or c in ("-", "_"))
        if not user_id:
            user_id = "default"

        # Get environment variables
        credentials_secret_name = os.environ.get("CREDENTIALS_SECRET_NAME", "threads_app_credentials")
        redirect_uri = os.environ["REDIRECT_URI"]
        token_url = os.environ.get("THREADS_TOKEN_URL", "https://graph.threads.net/oauth/access_token")
        secret_name_prefix = os.environ.get("SECRET_NAME_PREFIX", "threads/tokens")

        # Step 2: Load app credentials from Secrets Manager
        app_id, app_secret = _load_app_credentials(credentials_secret_name)

        # Step 3: Exchange authorization code for access token
        access_token = _exchange_token(code, app_id, app_secret, redirect_uri, token_url)

        # Step 4: Exchange short-lived token for long-lived token
        long_lived_token = _exchange_for_long_lived_token(access_token, app_secret)

        # Step 5: Store both tokens to Secrets Manager
        _store_access_token(access_token, long_lived_token, user_id, secret_name_prefix)

        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({
                "message": "Token stored successfully",
                "user_id": user_id
            }),
        }

    except MissingParameterError as e:
        LOGGER.warning(f"Missing parameter: {e}")
        return {
            "statusCode": 400,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({
                "error": "Bad Request",
                "message": str(e)
            }),
        }

    except SecretRetrievalError as e:
        LOGGER.error(f"Secret retrieval error: {e}")
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({
                "error": "Internal Server Error",
                "message": "Failed to retrieve app credentials"
            }),
        }

    except TokenExchangeError as e:
        LOGGER.error(f"Token exchange error: {e}")
        return {
            "statusCode": 502,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({
                "error": "Bad Gateway",
                "message": "Failed to exchange authorization code for token"
            }),
        }

    except SecretStorageError as e:
        LOGGER.error(f"Secret storage error: {e}")
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({
                "error": "Internal Server Error",
                "message": "Failed to store access token"
            }),
        }

    except Exception as e:
        LOGGER.exception("Unexpected error in callback handler")
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({
                "error": "Internal Server Error",
                "message": "An unexpected error occurred"
            }),
        }
