"""Simple helper to test invoking the API Gateway endpoint.

Usage example:
  python tools/invoke_api_gateway.py --invoke-url https://example.execute-api.aws.com/dev/callback --code <auth_code> --user-id alice

Pass in the Invoke URL from the API Gateway console. The script sends a GET
request with ``user_id`` and optional ``code`` query parameters to mimic the
Lambda proxy integration and prints the HTTP status plus response body so you
can see when API Gateway returns a 502.
"""

import argparse
import sys
import urllib.error
import urllib.request
import urllib.parse


def _get(url: str, params: dict, timeout: int = 10) -> tuple[int, str]:
  query = urllib.parse.urlencode(params)
  request = urllib.request.Request(f"{url}?{query}", method="GET")

  try:
    with urllib.request.urlopen(request, timeout=timeout) as response:
      return response.status, response.read().decode()
  except urllib.error.HTTPError as exc:
    return exc.code, exc.read().decode()
  except urllib.error.URLError as exc:  # Network/DNS issues
    return 0, str(exc)


def main() -> int:
  parser = argparse.ArgumentParser(description="Invoke the API Gateway endpoint")
  parser.add_argument("--invoke-url", required=True, help="Full Invoke URL for the API Gateway stage")
  parser.add_argument(
    "--user-id",
    default="default",
    help="User ID to include as a query parameter",
  )
  parser.add_argument(
    "--code",
    help="Authorization code for the callback endpoint (omit when calling the data API)",
  )
  parser.add_argument(
    "--timeout",
    type=int,
    default=10,
    help="Request timeout in seconds",
  )

  args = parser.parse_args()

  params: dict[str, str] = {"user_id": args.user_id}
  if args.code:
    params["code"] = args.code

  status, body = _get(args.invoke_url, params, timeout=args.timeout)
  print(f"Status: {status}")
  print(body)

  if status == 502:
    print(
      "The callback Lambda returns 502 when it cannot exchange the authorization code",
      "for an access token. Double-check the code and OAuth/SSM configuration.",
      sep="\n",
    )

  return 0


if __name__ == "__main__":
  sys.exit(main())
