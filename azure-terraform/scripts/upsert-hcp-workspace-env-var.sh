#!/usr/bin/env bash
# upsert-hcp-workspace-env-var.sh
#
# Purpose:
#   Create or update a sensitive HCP Terraform workspace environment variable.
#   The workload pipeline uses this to make TFE_TOKEN available inside the HCP
#   run environment so the tfe_outputs data source can read platform outputs.

set -Eeuo pipefail

ORGANIZATION=""
WORKSPACE=""
KEY=""
VALUE_ENV=""
FALLBACK_VALUE_ENV=""
OUTPUT_DIR="hcp-evidence"

usage() {
  cat <<'EOF'
Usage:
  upsert-hcp-workspace-env-var.sh --organization <org> --workspace <workspace> --key <env-var-key> --value-env <secret-env-var> [options]

Required:
  --organization <org>              HCP Terraform organization name.
  --workspace <workspace>           HCP Terraform workspace name.
  --key <env-var-key>               Workspace environment variable key to set.
  --value-env <secret-env-var>      Local environment variable containing the
                                    value to store.

Options:
  --fallback-value-env <env-var>    Fallback local environment variable used
                                    when --value-env is empty or unresolved.
  --output-dir <dir>                Evidence output directory. Default:
                                    hcp-evidence.
  -h, --help                        Show this help text.

Environment:
  HCP_TOKEN or TFE_TOKEN must contain an HCP Terraform API token with permission
  to read the target workspace and manage its variables.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --organization) ORGANIZATION="${2:?Missing value for --organization}"; shift 2 ;;
    --workspace) WORKSPACE="${2:?Missing value for --workspace}"; shift 2 ;;
    --key) KEY="${2:?Missing value for --key}"; shift 2 ;;
    --value-env) VALUE_ENV="${2:?Missing value for --value-env}"; shift 2 ;;
    --fallback-value-env) FALLBACK_VALUE_ENV="${2:-}"; shift 2 ;;
    --output-dir) OUTPUT_DIR="${2:?Missing value for --output-dir}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

TOKEN="${HCP_TOKEN:-${TFE_TOKEN:-}}"

if [[ -z "$ORGANIZATION" || -z "$WORKSPACE" || -z "$KEY" || -z "$VALUE_ENV" ]]; then
  echo "Organization, workspace, key, and value-env are required." >&2
  usage
  exit 1
fi

if [[ -z "$TOKEN" ]]; then
  echo "HCP_TOKEN or TFE_TOKEN is required to manage HCP workspace variables." >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to parse HCP Terraform API responses." >&2
  exit 1
fi

is_unresolved_ado_macro() {
  case "${1:-}" in
    \$\(*\)) return 0 ;;
    *) return 1 ;;
  esac
}

env_value() {
  local name="${1:-}"
  local value=""

  if [[ -n "$name" ]]; then
    value="${!name:-}"
  fi

  if is_unresolved_ado_macro "$value"; then
    value=""
  fi

  printf '%s\n' "$value"
}

SECRET_VALUE="$(env_value "$VALUE_ENV")"

if [[ -z "$SECRET_VALUE" && -n "$FALLBACK_VALUE_ENV" ]]; then
  SECRET_VALUE="$(env_value "$FALLBACK_VALUE_ENV")"
fi

if [[ -z "$SECRET_VALUE" ]]; then
  echo "No secret value was found in '${VALUE_ENV}' or fallback '${FALLBACK_VALUE_ENV}'." >&2
  echo "Set a pipeline secret variable such as HCP_OUTPUTS_TOKEN, or allow fallback to HCP_TOKEN." >&2
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

workspace_file="$OUTPUT_DIR/workspace-variable-sync-workspace.json"
api_json GET "https://app.terraform.io/api/v2/organizations/${ORGANIZATION}/workspaces/${WORKSPACE}" > "$workspace_file"
workspace_id="$(jq -r '.data.id // empty' "$workspace_file")"

if [[ -z "$workspace_id" ]]; then
  echo "Unable to resolve workspace ID for ${ORGANIZATION}/${WORKSPACE}." >&2
  cat "$workspace_file" >&2
  exit 1
fi

vars_file="$OUTPUT_DIR/workspace-variable-sync-vars.json"
api_json GET "https://app.terraform.io/api/v2/workspaces/${workspace_id}/vars?page%5Bsize%5D=100" > "$vars_file"

var_id="$(
  jq -r \
    --arg key "$KEY" \
    'first(.data[]? | select(.attributes.key == $key and .attributes.category == "env") | .id) // empty' \
    "$vars_file"
)"

payload_file="$(mktemp)"
trap 'rm -f "$payload_file"' EXIT

jq -n \
  --arg key "$KEY" \
  --arg value "$SECRET_VALUE" \
  '{
    data: {
      type: "vars",
      attributes: {
        key: $key,
        value: $value,
        category: "env",
        hcl: false,
        sensitive: true
      }
    }
  }' > "$payload_file"

action="created"
if [[ -n "$var_id" ]]; then
  action="updated"
  api_json PATCH "https://app.terraform.io/api/v2/workspaces/${workspace_id}/vars/${var_id}" "$payload_file" >/dev/null
else
  api_json POST "https://app.terraform.io/api/v2/workspaces/${workspace_id}/vars" "$payload_file" >/dev/null
fi

jq -n \
  --arg organization "$ORGANIZATION" \
  --arg workspace "$WORKSPACE" \
  --arg key "$KEY" \
  --arg action "$action" \
  '{
    organization: $organization,
    workspace: $workspace,
    key: $key,
    category: "env",
    sensitive: true,
    action: $action
  }' > "$OUTPUT_DIR/workspace-variable-sync.json"

echo "Sensitive HCP workspace env var '${KEY}' ${action} in ${ORGANIZATION}/${WORKSPACE}."
