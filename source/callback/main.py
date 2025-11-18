import json
import logging
import os
import urllib.parse
import urllib.request

import boto3

LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)

ssm_client = boto3.client("ssm")


def _get_parameter(name: str, with_decryption: bool = False) -> str:
  response = ssm_client.get_parameter(Name=name, WithDecryption=with_decryption)
  return response["Parameter"]["Value"]


def _store_token(token: str, user_id: str, base_path: str) -> None:
  parameter_name = f"{base_path}/{user_id}"
  ssm_client.put_parameter(
    Name=parameter_name,
    Value=token,
    Type="SecureString",
    Overwrite=True,
  )


def _exchange_code_for_token(code: str) -> str:
  token_url = os.environ["THREADS_TOKEN_URL"]
  client_id = _get_parameter(os.environ["CLIENT_ID_PARAMETER"], with_decryption=True)
  client_secret = _get_parameter(os.environ["CLIENT_SECRET_PARAMETER"], with_decryption=True)
  redirect_uri = os.environ["REDIRECT_URI"]

  payload = urllib.parse.urlencode(
    {
      "client_id": client_id,
      "client_secret": client_secret,
      "redirect_uri": redirect_uri,
      "grant_type": "authorization_code",
      "code": code,
    }
  ).encode()

  request = urllib.request.Request(
    token_url,
    data=payload,
    method="POST",
    headers={"Content-Type": "application/x-www-form-urlencoded"},
  )

  with urllib.request.urlopen(request) as response:
    body = response.read().decode()
    LOGGER.info("Token endpoint response: %s", body)
    parsed = json.loads(body)

  return parsed.get("access_token")


def lambda_handler(event, _context):
  LOGGER.info("Received event: %s", json.dumps(event))

  params = event.get("queryStringParameters") or {}
  body = event.get("body") or ""

  user_id = params.get("user_id") or "default"
  code = params.get("code")

  if not code and body:
    try:
      parsed_body = json.loads(body)
      code = parsed_body.get("code")
      user_id = parsed_body.get("user_id", user_id)
    except json.JSONDecodeError:
      LOGGER.warning("Unable to parse body, expecting JSON with code")

  if not code:
    return {
      "statusCode": 400,
      "body": json.dumps({"message": "Missing authorization code"}),
    }

  access_token = _exchange_code_for_token(code)
  if not access_token:
    return {
      "statusCode": 502,
      "body": json.dumps({"message": "Failed to exchange code for token"}),
    }

  _store_token(access_token, user_id, os.environ["TOKEN_BASE_PATH"])

  return {
    "statusCode": 200,
    "body": json.dumps({"message": "Token stored", "user_id": user_id}),
  }
