#!/usr/bin/env python3
"""
test_script.py — Unleash live AWS Assessment end-to-end test

Usage:
    pip install boto3 requests

    python test/test_script.py \
        --user-pool-id  us-east-1_XXXXXXXXX \
        --client-id     XXXXXXXXXXXXXXXXXXXXXXXXXX \
        --username      your@email.com \
        --password      YourPassword1! \
        --primary-url   https://XXXXXXXX.execute-api.us-east-1.amazonaws.com \
        --secondary-url https://YYYYYYYY.execute-api.eu-west-1.amazonaws.com

    # Or use Terraform outputs directly:
    python test/test_script.py \
        --user-pool-id  $(terraform output -raw cognito_user_pool_id) \
        --client-id     $(terraform output -raw cognito_client_id) \
        --username      your@email.com \
        --password      YourPassword1! \
        --primary-url   $(terraform output -raw primary_api_url) \
        --secondary-url $(terraform output -raw secondary_api_url)
"""

import argparse
import json
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

import boto3
import requests


# ── Authentication ────────────────────────────────────────────────────────────

def get_jwt(user_pool_id: str, client_id: str, username: str, password: str) -> str:
    """Authenticate with Cognito USER_PASSWORD_AUTH and return an ID token."""
    client = boto3.client("cognito-idp", region_name="us-east-1")

    print(f"\n[AUTH] Authenticating '{username}' ...")

    try:
        resp = client.initiate_auth(
            AuthFlow="USER_PASSWORD_AUTH",
            AuthParameters={"USERNAME": username, "PASSWORD": password},
            ClientId=client_id,
        )
    except client.exceptions.NotAuthorizedException as e:
        print(f"[AUTH] ✗ Authentication failed: {e}")
        print("       Tip: make sure you have set a permanent password (see README).")
        sys.exit(1)
    except client.exceptions.UserNotFoundException:
        print(f"[AUTH] ✗ User '{username}' not found in pool '{user_pool_id}'.")
        sys.exit(1)

    # Handle first-login NEW_PASSWORD_REQUIRED challenge
    if resp.get("ChallengeName") == "NEW_PASSWORD_REQUIRED":
        print("[AUTH] NEW_PASSWORD_REQUIRED challenge — setting permanent password ...")
        resp = client.respond_to_auth_challenge(
            ClientId=client_id,
            ChallengeName="NEW_PASSWORD_REQUIRED",
            ChallengeResponses={"USERNAME": username, "NEW_PASSWORD": password},
            Session=resp["Session"],
        )

    token = resp["AuthenticationResult"]["IdToken"]
    print(f"[AUTH] ✓ Token obtained (preview): {token[:50]}...")
    return token


# ── HTTP call ─────────────────────────────────────────────────────────────────

def call_endpoint(label: str, url: str, token: str) -> dict:
    headers = {"Authorization": token}
    start = time.perf_counter()
    try:
        resp = requests.get(url, headers=headers, timeout=30)
        latency_ms = (time.perf_counter() - start) * 1000
        try:
            body = resp.json()
        except Exception:
            body = {"raw": resp.text}
        return {
            "label":      label,
            "url":        url,
            "status":     resp.status_code,
            "latency_ms": round(latency_ms, 1),
            "body":       body,
            "error":      None,
        }
    except requests.exceptions.RequestException as e:
        latency_ms = (time.perf_counter() - start) * 1000
        return {
            "label":      label,
            "url":        url,
            "status":     0,
            "latency_ms": round(latency_ms, 1),
            "body":       {},
            "error":      str(e),
        }


# ── Concurrent runner ─────────────────────────────────────────────────────────

def run_concurrent(tasks: list) -> list:
    results = []
    with ThreadPoolExecutor(max_workers=len(tasks)) as pool:
        futures = {pool.submit(call_endpoint, *t): t[0] for t in tasks}
        for future in as_completed(futures):
            results.append(future.result())
    return sorted(results, key=lambda r: r["label"])


# ── Assertions ────────────────────────────────────────────────────────────────

def assert_region(result: dict, expected_region: str) -> bool:
    if result["error"]:
        print(f"  [✗ ERROR] {result['label']} — {result['error']}")
        return False

    actual = result["body"].get("region", "")
    passed = actual == expected_region
    icon   = "✓ PASS" if passed else "✗ FAIL"
    print(
        f"  [{icon}] {result['label']:<30} "
        f"HTTP {result['status']} | {result['latency_ms']:>8.1f} ms | "
        f"region={actual!r}  (expected {expected_region!r})"
    )
    if not passed:
        print(f"          body: {json.dumps(result['body'])}")
    return passed


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Unleash live deployment test")
    parser.add_argument("--user-pool-id",  required=True, help="Cognito User Pool ID")
    parser.add_argument("--client-id",     required=True, help="Cognito App Client ID")
    parser.add_argument("--username",      required=True, help="Cognito username (email)")
    parser.add_argument("--password",      required=True, help="Cognito password")
    parser.add_argument("--primary-url",   required=True, help="us-east-1 API base URL")
    parser.add_argument("--secondary-url", required=True, help="eu-west-1 API base URL")
    args = parser.parse_args()

    primary   = args.primary_url.rstrip("/")
    secondary = args.secondary_url.rstrip("/")

    # ── Step 1: Authenticate ──────────────────────────────────────────────────
    token = get_jwt(args.user_pool_id, args.client_id, args.username, args.password)

    all_passed = True

    # ── Step 2: /greet — concurrent, both regions ─────────────────────────────
    print("\n── /greet  (concurrent — both regions) " + "─" * 30)
    greet_results = run_concurrent([
        ("us-east-1  /greet", f"{primary}/greet",   token),
        ("eu-west-1  /greet", f"{secondary}/greet", token),
    ])
    for r in greet_results:
        expected = "us-east-1" if "us-east-1" in r["label"] else "eu-west-1"
        if not assert_region(r, expected):
            all_passed = False

    # ── Step 3: /dispatch — concurrent, both regions ──────────────────────────
    print("\n── /dispatch  (concurrent — both regions) " + "─" * 27)
    dispatch_results = run_concurrent([
        ("us-east-1  /dispatch", f"{primary}/dispatch",   token),
        ("eu-west-1  /dispatch", f"{secondary}/dispatch", token),
    ])
    for r in dispatch_results:
        status = "✓" if r["status"] == 200 else "✗"
        print(
            f"  [{status}] {r['label']:<30} "
            f"HTTP {r['status']} | {r['latency_ms']:>8.1f} ms | "
            f"body={json.dumps(r['body'])}"
        )

    # ── Step 4: Latency summary ───────────────────────────────────────────────
    print("\n── Latency summary " + "─" * 49)
    all_results = greet_results + dispatch_results
    for r in sorted(all_results, key=lambda x: x["latency_ms"]):
        print(f"  {r['label']:<35}  {r['latency_ms']:>8.1f} ms")

    # ── Result ────────────────────────────────────────────────────────────────
    print()
    if all_passed:
        print("✓  All assertions passed.")
        sys.exit(0)
    else:
        print("✗  Some assertions FAILED — review output above.")
        sys.exit(1)


if __name__ == "__main__":
    main()
