import json
import logging
import os
import urllib.request

import boto3

LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)

ssm_client = boto3.client("ssm")


def _get_token(user_id: str, base_path: str) -> str | None:
  parameter_name = f"{base_path}/{user_id}"
  try:
    response = ssm_client.get_parameter(
      Name=parameter_name,
      WithDecryption=True,
    )
    return response["Parameter"]["Value"]
  except ssm_client.exceptions.ParameterNotFound:
    LOGGER.warning("Token not found for user %s", user_id)
    return None


def _call_threads_api(token: str) -> dict:
  api_url = os.environ["THREADS_API_URL"]
  request = urllib.request.Request(
    api_url,
    headers={"Authorization": f"Bearer {token}"},
  )

  with urllib.request.urlopen(request) as response:
    body = response.read().decode()
    LOGGER.info("Threads API response: %s", body)
    return json.loads(body)


def lambda_handler(event, _context):
  LOGGER.info("Received event: %s", json.dumps(event))

  params = event.get("queryStringParameters") or {}
  body = event.get("body") or ""

  user_id = params.get("user_id") or "default"
  if body:
    try:
      parsed_body = json.loads(body)
      user_id = parsed_body.get("user_id", user_id)
    except json.JSONDecodeError:
      LOGGER.warning("Unable to parse body, expecting JSON with user_id")

  token = _get_token(user_id, os.environ["TOKEN_BASE_PATH"])
  if not token:
    return {
      "statusCode": 404,
      "body": json.dumps({"message": "Token not found", "user_id": user_id}),
    }

  api_response = _call_threads_api(token)

  return {
    "statusCode": 200,
    "body": json.dumps({"user_id": user_id, "data": api_response}),
  }
