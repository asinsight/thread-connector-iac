"""
Threads API posting Lambda function.

This Lambda function:
1. Receives user_id and post_text from request body
2. Retrieves user access token from AWS Secrets Manager
3. Creates a Threads post container
4. Publishes the container
5. Returns the published post ID
"""

import json
import logging
import os
import urllib.request
import urllib.parse
from typing import Any, Dict

import boto3
from botocore.exceptions import ClientError

# Configure logging
LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)

# AWS clients
secrets_manager = boto3.client("secretsmanager")


class TokenNotFoundError(Exception):
    """Custom exception for token not found errors."""
    pass


class APIError(Exception):
    """Custom exception for API-related errors."""
    pass


class ValidationError(Exception):
    """Custom exception for validation errors."""
    pass


def _get_long_lived_token_from_secrets_manager(user_id: str, secret_name_prefix: str) -> str:
    """
    Retrieve user long-lived access token from AWS Secrets Manager.

    Args:
        user_id: User identifier
        secret_name_prefix: Prefix for secret name

    Returns:
        Long-lived access token

    Raises:
        TokenNotFoundError: If token is not found
    """
    secret_name = f"{secret_name_prefix}/{user_id}"

    try:
        response = secrets_manager.get_secret_value(SecretId=secret_name)
        secret_string = response["SecretString"]
        secret_data = json.loads(secret_string)

        long_lived_token = secret_data.get("long_lived_token")
        if not long_lived_token:
            LOGGER.error(f"Secret exists but no long_lived_token found for user {user_id}")
            raise TokenNotFoundError(f"Long-lived token not found for user: {user_id}")

        return long_lived_token

    except secrets_manager.exceptions.ResourceNotFoundException:
        LOGGER.warning(f"Secret not found for user: {user_id}")
        raise TokenNotFoundError(f"Token not found for user: {user_id}")
    except ClientError as e:
        error_code = e.response.get("Error", {}).get("Code", "Unknown")
        LOGGER.error(f"Failed to retrieve secret for user {user_id}: {error_code}")
        raise TokenNotFoundError(f"Failed to retrieve token for user: {user_id}") from e
    except json.JSONDecodeError as e:
        LOGGER.error(f"Failed to parse secret value for user {user_id}: {e}")
        raise TokenNotFoundError(f"Invalid token data for user: {user_id}") from e


def _create_threads_container(post_text: str, topic_tag: str, access_token: str) -> str:
    """
    Create a Threads post container.

    Args:
        post_text: Text content to post
        access_token: Long-lived access token

    Returns:
        Container creation ID

    Raises:
        APIError: If container creation fails
    """
    post_url = "https://graph.threads.net/v1.0/me/threads"

    post_payload = {
        "media_type": "TEXT",
        "text": post_text,
        "access_token": access_token,
        "topic_tag": topic_tag
    }

    data = urllib.parse.urlencode(post_payload).encode()

    try:
        LOGGER.info("Creating Threads post container")
        request = urllib.request.Request(post_url, data=data, method="POST")

        with urllib.request.urlopen(request, timeout=30) as response:
            body = response.read().decode()
            response_data = json.loads(body)

            container_id = response_data.get("id")
            if not container_id:
                LOGGER.error("No container ID in response from Threads API")
                raise APIError("Failed to create post container")

            LOGGER.info(f"Created container with ID: {container_id}")
            return container_id

    except urllib.error.HTTPError as e:
        error_body = e.read().decode() if e.fp else "No error body"
        LOGGER.error(f"HTTP error creating container: {e.code} - {error_body}")
        raise APIError(f"Threads API returned HTTP {e.code}: {error_body}") from e
    except urllib.error.URLError as e:
        LOGGER.error(f"URL error creating container: {e.reason}")
        raise APIError("Failed to reach Threads API") from e
    except json.JSONDecodeError as e:
        LOGGER.error(f"Failed to parse container creation response: {e}")
        raise APIError("Invalid JSON response from Threads API") from e
    except Exception as e:
        LOGGER.error(f"Unexpected error creating container: {e}")
        raise APIError(f"Unexpected error creating container: {e}") from e


def _publish_threads_container(container_id: str, access_token: str) -> str:
    """
    Publish a Threads post container.

    Args:
        container_id: Container creation ID
        access_token: Long-lived access token

    Returns:
        Published post ID

    Raises:
        APIError: If publishing fails
    """
    publish_url = "https://graph.threads.net/v1.0/me/threads_publish"

    publish_payload = {
        "creation_id": container_id,
        "access_token": access_token
    }

    data = urllib.parse.urlencode(publish_payload).encode()

    try:
        LOGGER.info(f"Publishing Threads container: {container_id}")
        request = urllib.request.Request(publish_url, data=data, method="POST")

        with urllib.request.urlopen(request, timeout=30) as response:
            body = response.read().decode()
            response_data = json.loads(body)

            post_id = response_data.get("id")
            if not post_id:
                LOGGER.error("No post ID in response from Threads API")
                raise APIError("Failed to publish post")

            LOGGER.info(f"Published post with ID: {post_id}")
            return post_id

    except urllib.error.HTTPError as e:
        error_body = e.read().decode() if e.fp else "No error body"
        LOGGER.error(f"HTTP error publishing container: {e.code} - {error_body}")
        raise APIError(f"Threads API returned HTTP {e.code}: {error_body}") from e
    except urllib.error.URLError as e:
        LOGGER.error(f"URL error publishing container: {e.reason}")
        raise APIError("Failed to reach Threads API") from e
    except json.JSONDecodeError as e:
        LOGGER.error(f"Failed to parse publish response: {e}")
        raise APIError("Invalid JSON response from Threads API") from e
    except Exception as e:
        LOGGER.error(f"Unexpected error publishing container: {e}")
        raise APIError(f"Unexpected error publishing container: {e}") from e


def _parse_request_body(event: Dict[str, Any]) -> tuple[str, str]:
    """
    Extract user_id and post_text from request body.

    Args:
        event: Lambda event dictionary

    Returns:
        Tuple of (user_id, post_text)

    Raises:
        ValidationError: If required parameters are missing
    """
    body = event.get("body", "")

    if not body:
        raise ValidationError("Request body is required")

    try:
        parsed_body = json.loads(body)
    except json.JSONDecodeError as e:
        LOGGER.error(f"Failed to parse request body: {e}")
        raise ValidationError("Invalid JSON in request body") from e

    user_id = parsed_body.get("user_id")
    post_text = parsed_body.get("post_text")
    topic_tag = parsed_body.get("topic_tag")

    if not user_id:
        raise ValidationError("user_id is required")

    if not post_text:
        raise ValidationError("post_text is required")

    # Sanitize user_id to prevent injection
    user_id = "".join(c for c in user_id if c.isalnum() or c in ("-", "_"))
    if not user_id:
        raise ValidationError("user_id contains invalid characters")

    return user_id, post_text, topic_tag


def lambda_handler(event: Dict[str, Any], _context: Any) -> Dict[str, Any]:
    """
    Lambda handler for Threads post creation.

    Args:
        event: API Gateway event
        _context: Lambda context

    Returns:
        API Gateway response with post ID
    """
    LOGGER.info("Received Threads post creation request")

    try:
        # Step 1: Parse user_id and post_text from request body
        user_id, post_text, topic_tag = _parse_request_body(event)
        LOGGER.info(f"Creating post for user: {user_id}")

        # Step 2: Get secret name prefix from environment
        secret_name_prefix = os.environ.get("SECRET_NAME_PREFIX")
        if not secret_name_prefix:
            raise ValidationError("SECRET_NAME_PREFIX environment variable not set")

        # Step 3: Load long-lived token from Secrets Manager
        access_token = _get_long_lived_token_from_secrets_manager(user_id, secret_name_prefix)

        # Step 4: Create Threads post container
        container_id = _create_threads_container(post_text, topic_tag, access_token)

        # Step 5: Publish the container
        post_id = _publish_threads_container(container_id, access_token)

        # Step 6: Return the post ID
        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json",
            },
            "body": json.dumps({
                "id": post_id,
                "user_id": user_id
            }),
        }

    except ValidationError as e:
        LOGGER.warning(f"Validation error: {e}")
        return {
            "statusCode": 400,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({
                "error": "Bad Request",
                "message": str(e)
            }),
        }

    except TokenNotFoundError as e:
        LOGGER.warning(f"Token not found: {e}")
        return {
            "statusCode": 404,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({
                "error": "Not Found",
                "message": str(e)
            }),
        }

    except APIError as e:
        LOGGER.error(f"API error: {e}")
        return {
            "statusCode": 502,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({
                "error": "Bad Gateway",
                "message": str(e)
            }),
        }

    except Exception as e:
        LOGGER.exception("Unexpected error in post creation handler")
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({
                "error": "Internal Server Error",
                "message": "An unexpected error occurred"
            }),
        }
