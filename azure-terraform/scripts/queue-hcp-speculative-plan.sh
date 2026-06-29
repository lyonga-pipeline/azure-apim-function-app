#!/usr/bin/env bash
# queue-hcp-speculative-plan.sh
#
# Purpose:
#   Upload the checked-out repository configuration to HCP Terraform and queue a
#   plan-only run for the exact commit being validated by Azure DevOps.

set -Eeuo pipefail

ORGANIZATION=""
WORKSPACE=""
SOURCE_DIR="."
VCS_REVISION=""
OUTPUT_DIR="hcp-evidence"

usage() {
  cat <<'EOF'
Usage:
  queue-hcp-speculative-plan.sh --organization <org> --workspace <workspace> [options]

Required:
  --organization <org>        HCP Terraform organization name.
  --workspace <workspace>     HCP Terraform workspace name.

Options:
  --source-dir <dir>          Repository root to archive and upload. Default: .
  --vcs-revision <sha>        Commit SHA to include in the HCP run message.
  --output-dir <dir>          Evidence output directory. Default: hcp-evidence.
  -h, --help                  Show this help text.

Environment:
  HCP_TOKEN or TFE_TOKEN must contain a user or team token with permission to
  queue plans in the workspace. Organization tokens cannot create configuration
  versions or runs.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --organization) ORGANIZATION="${2:?Missing value for --organization}"; shift 2 ;;
    --workspace) WORKSPACE="${2:?Missing value for --workspace}"; shift 2 ;;
    --source-dir) SOURCE_DIR="${2:?Missing value for --source-dir}"; shift 2 ;;
    --vcs-revision) VCS_REVISION="${2:?Missing value for --vcs-revision}"; shift 2 ;;
    --output-dir) OUTPUT_DIR="${2:?Missing value for --output-dir}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

TOKEN="${HCP_TOKEN:-${TFE_TOKEN:-}}"

if [[ -z "$ORGANIZATION" || -z "$WORKSPACE" ]]; then
  echo "Organization and workspace are required." >&2
  usage
  exit 1
fi

if [[ -z "$TOKEN" ]]; then
  echo "HCP_TOKEN or TFE_TOKEN is required." >&2
  exit 1
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "Source directory does not exist: $SOURCE_DIR" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to parse HCP Terraform API responses." >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

api_json() {
  local method="$1"
  local url="$2"
  local data_file="${3:-}"

  if [[ -n "$data_file" ]]; then
    curl -fsS \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/vnd.api+json" \
      --request "$method" \
      --data @"$data_file" \
      "$url"
  else
    curl -fsS \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/vnd.api+json" \
      --request "$method" \
      "$url"
  fi
}

workspace_file="$OUTPUT_DIR/queue-workspace.json"
api_json GET "https://app.terraform.io/api/v2/organizations/${ORGANIZATION}/workspaces/${WORKSPACE}" > "$workspace_file"
workspace_id="$(jq -r '.data.id // empty' "$workspace_file")"

if [[ -z "$workspace_id" ]]; then
  echo "Unable to resolve workspace ID for ${ORGANIZATION}/${WORKSPACE}." >&2
  cat "$workspace_file" >&2
  exit 1
fi

archive_file="$OUTPUT_DIR/configuration.tar.gz"
tar \
  --exclude='.git' \
  --exclude='.terraform' \
  --exclude='.terraform.lock.hcl' \
  --exclude='*.tfplan' \
  --exclude='*.tfstate' \
  --exclude='*.tfstate.*' \
  -C "$SOURCE_DIR" \
  -czf "$archive_file" .

cv_payload="$OUTPUT_DIR/configuration-version-payload.json"
cat > "$cv_payload" <<'JSON'
{
  "data": {
    "type": "configuration-versions",
    "attributes": {
      "auto-queue-runs": false,
      "speculative": true
    }
  }
}
JSON

cv_file="$OUTPUT_DIR/configuration-version.json"
api_json POST "https://app.terraform.io/api/v2/workspaces/${workspace_id}/configuration-versions" "$cv_payload" > "$cv_file"

configuration_version_id="$(jq -r '.data.id // empty' "$cv_file")"
upload_url="$(jq -r '.data.attributes["upload-url"] // empty' "$cv_file")"

if [[ -z "$configuration_version_id" || -z "$upload_url" ]]; then
  echo "Unable to create uploadable HCP configuration version." >&2
  cat "$cv_file" >&2
  exit 1
fi

curl -fsS \
  -H "Content-Type: application/octet-stream" \
  --request PUT \
  --data-binary @"$archive_file" \
  "$upload_url" >/dev/null

run_payload="$OUTPUT_DIR/run-create-payload.json"
jq -n \
  --arg workspace_id "$workspace_id" \
  --arg configuration_version_id "$configuration_version_id" \
  --arg revision "$VCS_REVISION" \
  '{
    data: {
      type: "runs",
      attributes: {
        message: ("ADO speculative plan evidence" + (if $revision == "" then "" else " for commit " + $revision end)),
        "plan-only": true
      },
      relationships: {
        workspace: {
          data: {
            type: "workspaces",
            id: $workspace_id
          }
        },
        "configuration-version": {
          data: {
            type: "configuration-versions",
            id: $configuration_version_id
          }
        }
      }
    }
  }' > "$run_payload"

run_file="$OUTPUT_DIR/queued-run.json"
api_json POST "https://app.terraform.io/api/v2/runs" "$run_payload" > "$run_file"

run_id="$(jq -r '.data.id // empty' "$run_file")"
if [[ -z "$run_id" ]]; then
  echo "Unable to create HCP run." >&2
  cat "$run_file" >&2
  exit 1
fi

printf '%s\n' "$run_id" > "$OUTPUT_DIR/run-id.txt"
echo "Queued HCP speculative plan run: ${run_id}"
