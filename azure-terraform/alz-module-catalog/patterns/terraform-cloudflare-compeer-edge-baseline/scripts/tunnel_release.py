"""Explicit release steps: token handoff and replica readiness; never print secrets."""

import argparse
import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request
import uuid


def request_json(url, bearer, method="GET", body=None):
    data = None if body is None else json.dumps(body).encode()
    request = urllib.request.Request(
        url, data=data, method=method,
        headers={"Authorization": "Bearer " + bearer, "Content-Type": "application/json"},
    )
    # Do not follow redirects while carrying a credential to a different host.
    class NoRedirect(urllib.request.HTTPRedirectHandler):
        def redirect_request(self, req, fp, code, msg, headers, newurl):
            return None

    opener = urllib.request.build_opener(NoRedirect)
    for attempt in range(4):
        try:
            with opener.open(request, timeout=30) as response:
                return json.load(response)
        except urllib.error.HTTPError as exc:
            if exc.code not in (429, 500, 502, 503, 504) or attempt == 3:
                raise RuntimeError("API request failed with HTTP " + str(exc.code)) from None
        except (urllib.error.URLError, TimeoutError):
            if attempt == 3:
                raise RuntimeError("API connection failed") from None
        time.sleep(2 ** attempt)
    raise RuntimeError("API retry limit reached")


def validate_inventory(inventory):
    if not inventory:
        raise ValueError("Inventory must contain at least one tunnel")
    targets = set()
    for item in inventory:
        if not re.fullmatch(r"[a-fA-F0-9]{32}", item["account_id"]):
            raise ValueError("Invalid account ID")
        uuid.UUID(item["tunnel_id"])
        if not re.fullmatch(r"https://[a-zA-Z0-9-]+\.vault\.azure\.net", item["vault_uri"]):
            raise ValueError("Invalid Azure public-cloud vault URI (no trailing slash)")
        if not re.fullmatch(r"[a-zA-Z0-9-]{1,127}", item["secret_name"]):
            raise ValueError("Invalid secret name")
        target = (item["vault_uri"].lower(), item["secret_name"].lower())
        if target in targets:
            raise ValueError("Distinct tunnel inventory entries cannot share a secret target")
        targets.add(target)
        if not isinstance(item.get("minimum_replicas", 2), int) or item.get("minimum_replicas", 2) < 2:
            raise ValueError("Production gate requires at least two replicas")


def cloudflare(item, suffix, api_token):
    path = "https://api.cloudflare.com/client/v4/accounts/{}/cfd_tunnel/{}/{}".format(
        item["account_id"], item["tunnel_id"], suffix,
    )
    result = request_json(path, api_token)
    if not result.get("success"):
        raise RuntimeError("Cloudflare rejected the request")
    return result["result"]


def sync_token(item, api_token, azure_token):
    token = cloudflare(item, "token", api_token)
    if not isinstance(token, str) or not token.strip():
        raise RuntimeError("Cloudflare returned an empty token")
    url = item["vault_uri"] + "/secrets/" + item["secret_name"] + "?api-version=7.4"
    try:
        existing = request_json(url, azure_token)
    except RuntimeError as exc:
        if str(exc) != "API request failed with HTTP 404":
            raise
        existing = {}
    if existing.get("value") == token:
        return
    request_json(url, azure_token, "PUT", {"value": token, "contentType": "cloudflare-tunnel-token"})


def connected_replicas(connections):
    # The API groups connections per connector. Count only connectors with
    # active connections, not four transport connections as four replicas.
    return len({connector["id"] for connector in connections
                if connector.get("id") and any(
                    not conn.get("is_pending_reconnect", False)
                    for conn in connector.get("conns", []))})


def check_rollout(plan):
    groups = {}
    for resource in plan.get("resource_changes", []):
        change = resource.get("change", {})
        actions = change.get("actions", [])
        if resource.get("type") == "azurerm_windows_virtual_machine" and "delete" in actions:
            raise ValueError("Windows VM deletion/replacement needs a separate cutover review")
        if resource.get("type") != "azurerm_virtual_machine_run_command" or resource.get("name") != "cloudflared":
            continue
        if actions in (["no-op"], ["read"], ["create"]):
            continue
        before = change.get("before") or {}
        after = change.get("after") or {}
        # Unknown/missing grouping fails closed for existing replicas.
        scope = (before.get("tags") or {}).get("cloudflare_tunnel_scope")
        new_scope = (after.get("tags") or {}).get("cloudflare_tunnel_scope")
        if not scope or (new_scope is not None and new_scope != scope):
            raise ValueError("Unknown or changed tunnel scope needs a separate cutover review")
        groups[scope] = groups.get(scope, 0) + 1
        if groups[scope] > 1:
            raise ValueError("Only one existing replica per tunnel may change in a release stage")


def verify_replicas(item, api_token, timeout):
    deadline = time.monotonic() + timeout
    while True:
        count = connected_replicas(cloudflare(item, "connections", api_token))
        if count >= item.get("minimum_replicas", 2):
            return
        if time.monotonic() >= deadline:
            raise RuntimeError("Replica readiness timed out")
        time.sleep(10)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["sync-token", "verify-replicas", "check-rollout"])
    parser.add_argument("inventory", help="Reviewed reference inventory, or Terraform plan JSON for check-rollout")
    parser.add_argument("--timeout", type=int, default=300)
    args = parser.parse_args()
    try:
        with open(args.inventory, encoding="utf-8") as source:
            inventory = json.load(source)
        if args.action == "check-rollout":
            check_rollout(inventory)
            print("Rollout plan permits at most one existing replica change per tunnel.")
            return 0
        validate_inventory(inventory)
        api_token = os.environ["CLOUDFLARE_API_TOKEN"]
        if args.timeout < 1 or not api_token:
            raise ValueError("Positive timeout and API credentials required")
        if args.action == "sync-token":
            # Use the release job's existing OIDC Azure CLI login, never a saved client secret.
            azure_token = subprocess.run(
                ["az", "account", "get-access-token", "--resource", "https://vault.azure.net",
                 "--query", "accessToken", "--output", "tsv"],
                check=True, capture_output=True, text=True, timeout=60,
            ).stdout.strip()
            if not azure_token:
                raise RuntimeError("Azure credential unavailable")
            for item in inventory:
                sync_token(item, api_token, azure_token)
        else:
            for item in inventory:
                verify_replicas(item, api_token, args.timeout)
        print("Release step completed. External application/security acceptance remains required.")
        return 0
    except Exception:
        # Never echo HTTP bodies, process stderr, inventory credentials or traceback locals.
        print("Release step failed. Check approved inventory, scoped credentials and service connectivity.", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
