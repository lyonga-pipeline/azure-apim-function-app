"""Plan the actual example with mock providers and synthetic credentials only.

Run after terraform init -backend=false. TF_DATA_DIR is honored, so provider
caches need not live in the repository. No real account/API token is needed.
"""

import base64
import json
import os
from pathlib import Path
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]


def main():
    env = os.environ.copy()
    env.pop("CLOUDFLARE_API_TOKEN", None)
    result = subprocess.run(
        ["terraform", "console", "-var-file=example.tfvars"],
        input="jsonencode(var.cloudflare_edge)\n",
        text=True, capture_output=True, check=True, cwd=ROOT, env=env,
    )
    edge = json.loads(json.loads(result.stdout.strip()))

    def sanitize(value):
        if isinstance(value, dict):
            return {key: sanitize(item) for key, item in value.items()}
        if isinstance(value, list):
            return [sanitize(item) for item in value]
        if isinstance(value, str) and value.startswith("REPLACE"):
            if "TEAM-SLUG" in value:
                return "compeer-test"
            if "ACCOUNT_ID" in value or "MANAGED_WAF_ID" in value:
                return "0123456789abcdef0123456789abcdef"
            if value.endswith("_ID"):
                return "00000000-0000-4000-8000-000000000001"
            return "CHG-synthetic-test"
        return value

    fixture = {
        "cloudflare_edge": sanitize(edge),
        "cloudflare_tunnel_secrets": {
            "external_nonprod": base64.b64encode(b"n" * 32).decode(),
            "external_prod": base64.b64encode(b"p" * 32).decode(),
        },
    }
    with tempfile.TemporaryDirectory(prefix="compeer-edge-example-") as folder:
        varfile = Path(folder) / "synthetic.tfvars.json"
        varfile.write_text(json.dumps(fixture), encoding="utf-8")
        subprocess.run(
            ["terraform", "test", "-test-directory=example-tests", f"-var-file={varfile}"],
            check=True, cwd=ROOT, env=env,
        )


if __name__ == "__main__":
    main()
