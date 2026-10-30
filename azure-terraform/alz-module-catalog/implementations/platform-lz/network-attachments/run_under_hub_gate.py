"""Queue an exact reviewed HCP configuration while a protected ADO hub gate is held.

Never auto-apply, force-cancel, change workspace settings, or grant Azure access.
Network reviewers approve the full plan in HCP while this job holds the gate.
"""

import argparse
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


FINISHED = {"applied", "planned_and_finished", "discarded", "errored", "canceled", "force_canceled"}
SUCCESS = {"applied", "planned_and_finished"}


class HCP:
    def __init__(self, token):
        self.token = token

    def request(self, path, payload=None):
        request = urllib.request.Request(
            "https://app.terraform.io/api/v2/" + path,
            data=None if payload is None else json.dumps(payload).encode(),
            headers={"Authorization": "Bearer " + self.token, "Content-Type": "application/vnd.api+json"},
            method="GET" if payload is None else "POST",
        )
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                return json.load(response) if response.status != 202 else {}
        except urllib.error.HTTPError as error:
            # Never echo response bodies, credentials or configuration contents into CI logs.
            raise RuntimeError(f"HCP request failed: HTTP {error.code} for {path}") from None


def preflight(client, config, workspace, configuration, commit):
    if workspace not in config["workspaces"]:
        raise ValueError("Workspace is not in the network-approved hub gate inventory")
    if not re.fullmatch(r"[0-9a-fA-F]{40}", commit) or not re.fullmatch(r"cv-[A-Za-z0-9]+", configuration):
        raise ValueError("An exact reviewed Git commit and HCP configuration version are required")
    selected = None
    for name, directory in config["workspaces"].items():
        path = "organizations/{}/workspaces/{}".format(
            urllib.parse.quote(config["organization"], safe=""), urllib.parse.quote(name, safe="")
        )
        data = client.request(path)["data"]
        if data["attributes"].get("auto-apply", True):
            raise ValueError(f"Disable auto-apply for hub writer {name} before using the gate")
        run = data["relationships"].get("current-run", {}).get("data")
        if run:
            status = client.request("runs/" + run["id"])["data"]["attributes"]["status"]
            if status not in FINISHED:
                raise ValueError(f"Hub writer {name} has an unfinished run {run['id']} ({status}); reconcile it first")
        if name == workspace:
            if data["attributes"].get("working-directory") != directory:
                raise ValueError("HCP working directory does not match the approved environment root")
            current = data["relationships"].get("current-configuration-version", {}).get("data")
            if not current or current["id"] != configuration:
                raise ValueError("Use the workspace's current reviewed configuration version")
            selected = data
    version = client.request("configuration-versions/" + configuration)["data"]["attributes"]
    if version["status"] != "uploaded" or version.get("speculative", True):
        raise ValueError("Configuration must be uploaded and non-speculative")
    ingress = client.request("configuration-versions/" + configuration + "/ingress-attributes")["data"]["attributes"]
    if (ingress.get("commit-sha", "").lower() != commit.lower()
            or ingress.get("branch") != "main" or ingress.get("is-pull-request", True)
            or ingress.get("identifier") != config["vcs_identifier"]):
        raise ValueError("Configuration must match the approved repository and exact main-branch commit")
    return selected["id"]


def queue(client, workspace_id, configuration):
    return client.request("runs", {"data": {
        "type": "runs",
        "attributes": {"message": "Network-approved shared-hub gate", "auto-apply": False,
                       "is-destroy": False, "plan-only": False, "refresh": True},
        "relationships": {
            "workspace": {"data": {"type": "workspaces", "id": workspace_id}},
            "configuration-version": {"data": {"type": "configuration-versions", "id": configuration}},
        },
    }})["data"]["id"]


def wait(client, run_id, timeout_seconds, sleep=time.sleep, monotonic=time.monotonic):
    started = monotonic()
    previous = None
    while True:
        run = client.request("runs/" + run_id)["data"]["attributes"]
        status = run["status"]
        if status != previous:
            print(f"{run_id}: {status}", flush=True)
            previous = status
        if status in FINISHED:
            if status not in SUCCESS:
                raise RuntimeError(f"Run ended as {status}; inspect partial changes and acceptance before retry")
            return
        if monotonic() - started > timeout_seconds:
            # Another gated job checks all current runs and refuses to write until this is reconciled.
            raise RuntimeError(f"Run {run_id} remains active. Do not release operational incident control or queue another hub writer")
        sleep(15)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", required=True, type=Path)
    parser.add_argument("--workspace", required=True)
    parser.add_argument("--configuration-version", required=True)
    parser.add_argument("--commit", required=True)
    parser.add_argument("--timeout-seconds", type=int, default=10800)
    args = parser.parse_args()
    if os.environ.get("COMPEER_HUB_GATE_HELD") != "true":
        raise ValueError("Run only inside the protected shared-hub deployment job")
    token = os.environ.get("HCP_TOKEN")
    if not token:
        raise ValueError("HCP_TOKEN must come from the protected pipeline secret store")
    config = json.loads(args.config.read_text())
    client = HCP(token)
    workspace_id = preflight(client, config, args.workspace, args.configuration_version, args.commit)
    run_id = queue(client, workspace_id, args.configuration_version)
    print(f"Review and confirm this full plan in HCP: https://app.terraform.io/app/{config['organization']}/workspaces/{args.workspace}/runs/{run_id}", flush=True)
    wait(client, run_id, args.timeout_seconds)
    print("HCP run finished. Complete read-only Azure and DNS/inspection acceptance before closing the change.")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, RuntimeError, KeyError, OSError) as error:
        print(f"Blocked: {error}", file=sys.stderr)
        sys.exit(1)
