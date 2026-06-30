#!/usr/bin/env bash
# capture-hcp-run-evidence.sh
#
# Purpose:
#   Capture Terraform plan, policy-check, and run-task evidence from an HCP Terraform run.
#   This script is intended for Azure DevOps pipeline evidence collection. HCP
#   Terraform still owns Terraform execution; ADO only retrieves and publishes
#   the run evidence.

set -Eeuo pipefail

ORGANIZATION=""
WORKSPACE=""
RUN_ID=""
VCS_REVISION=""
OUTPUT_DIR="hcp-evidence"
ALLOW_LATEST_RUN=false
FAIL_ON_DESTROY=false
FAIL_ON_POLICY_FAILURE=false
FAIL_ON_RUN_TASK_FAILURE=false

usage() {
  cat <<'EOF'
Usage:
  capture-hcp-run-evidence.sh --organization <org> --workspace <workspace> [options]

Required:
  --organization <org>        HCP Terraform organization name.
  --workspace <workspace>     HCP Terraform workspace name.

Options:
  --run-id <id>               Capture a specific HCP run. If omitted, the script
                              tries to match --vcs-revision.
  --vcs-revision <sha>        Commit SHA to match against recent HCP runs.
  --allow-latest-run <bool>   When true and no --vcs-revision match is found,
                              fall back to the latest run in the workspace.
                              Default: false.
  --output-dir <dir>          Evidence output directory. Default: hcp-evidence.
  --fail-on-destroy <bool>    Fail when plan includes delete/replace actions.
  --fail-on-policy-failure <bool>
                              Fail when HCP policy checks are failed/errored.
  --fail-on-run-task-failure <bool>
                              Fail when HCP run tasks report failed/errored states.
  -h, --help                  Show this help text.

Environment:
  HCP_TOKEN or TFE_TOKEN must contain an HCP Terraform API token.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --organization) ORGANIZATION="${2:?Missing value for --organization}"; shift 2 ;;
    --workspace) WORKSPACE="${2:?Missing value for --workspace}"; shift 2 ;;
    --run-id) RUN_ID="${2:?Missing value for --run-id}"; shift 2 ;;
    --vcs-revision) VCS_REVISION="${2:?Missing value for --vcs-revision}"; shift 2 ;;
    --allow-latest-run) ALLOW_LATEST_RUN="${2:?Missing value for --allow-latest-run}"; shift 2 ;;
    --output-dir) OUTPUT_DIR="${2:?Missing value for --output-dir}"; shift 2 ;;
    --fail-on-destroy) FAIL_ON_DESTROY="${2:?Missing value for --fail-on-destroy}"; shift 2 ;;
    --fail-on-policy-failure) FAIL_ON_POLICY_FAILURE="${2:?Missing value for --fail-on-policy-failure}"; shift 2 ;;
    --fail-on-run-task-failure) FAIL_ON_RUN_TASK_FAILURE="${2:?Missing value for --fail-on-run-task-failure}"; shift 2 ;;
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

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to parse HCP Terraform API responses." >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

api_get() {
  local url="$1"
  curl -LfsS \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/vnd.api+json" \
    "$url"
}

api_get_with_status() {
  local url="$1"
  local output_file="$2"
  local err_file="$3"

  curl -LsS \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/vnd.api+json" \
    -o "$output_file" \
    -w "%{http_code}" \
    "$url" 2>"$err_file"
}

find_run_id() {
  local runs_file="$OUTPUT_DIR/runs.json"
  local workspace_file="$OUTPUT_DIR/workspace.json"
  local workspace_url="https://app.terraform.io/api/v2/organizations/${ORGANIZATION}/workspaces/${WORKSPACE}"
  local workspace_status_file="$OUTPUT_DIR/workspace-http-status.txt"
  local workspace_err_file="$OUTPUT_DIR/workspace-download.err"
  local workspace_http_status
  local workspace_id
  local runs_url
  local commit_runs_url
  local commit_runs_file="$OUTPUT_DIR/runs-by-commit.json"
  local run_operations="plan_only,plan_and_apply,save_plan,refresh_only,destroy,empty_apply,action_only"
  local status_file="$OUTPUT_DIR/runs-http-status.txt"
  local err_file="$OUTPUT_DIR/runs-download.err"
  local http_status

  workspace_http_status="$(curl -sS \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/vnd.api+json" \
    -o "$workspace_file" \
    -w "%{http_code}" \
    "$workspace_url" 2>"$workspace_err_file")"
  printf '%s\n' "$workspace_http_status" > "$workspace_status_file"

  if [[ "$workspace_http_status" -lt 200 || "$workspace_http_status" -ge 300 ]]; then
    echo "Unable to read HCP Terraform workspace." >&2
    echo "Organization: ${ORGANIZATION}" >&2
    echo "Workspace: ${WORKSPACE}" >&2
    echo "HTTP status: ${workspace_http_status}" >&2
    echo "Endpoint: ${workspace_url}" >&2
    echo "Check that the HCP organization/workspace names are exact and that HCP_TOKEN can read the workspace." >&2
    if [[ -s "$workspace_file" ]]; then
      echo "HCP API response body:" >&2
      cat "$workspace_file" >&2
    fi
    if [[ -s "$workspace_err_file" ]]; then
      echo "curl diagnostics:" >&2
      cat "$workspace_err_file" >&2
    fi
    return 1
  fi

  workspace_id="$(jq -r '.data.id // empty' "$workspace_file")"
  if [[ -z "$workspace_id" ]]; then
    echo "HCP workspace response did not include a workspace ID." >&2
    cat "$workspace_file" >&2
    return 1
  fi

  if [[ -n "$VCS_REVISION" ]]; then
    commit_runs_url="https://app.terraform.io/api/v2/workspaces/${workspace_id}/runs?page%5Bsize%5D=20&filter%5Boperation%5D=${run_operations}&search%5Bcommit%5D=${VCS_REVISION}"

    http_status="$(curl -sS \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/vnd.api+json" \
      -o "$commit_runs_file" \
      -w "%{http_code}" \
      "$commit_runs_url" 2>"$err_file")"

    if [[ "$http_status" -ge 200 && "$http_status" -lt 300 ]]; then
      local commit_search_match
      commit_search_match="$(jq -r '.data[0].id // empty' "$commit_runs_file")"
      if [[ -n "$commit_search_match" ]]; then
        printf '%s\n' "$commit_search_match"
        return
      fi
    fi
  fi

  runs_url="https://app.terraform.io/api/v2/workspaces/${workspace_id}/runs?page%5Bsize%5D=20&filter%5Boperation%5D=${run_operations}"

  http_status="$(curl -sS \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/vnd.api+json" \
    -o "$runs_file" \
    -w "%{http_code}" \
    "$runs_url" 2>"$err_file")"
  printf '%s\n' "$http_status" > "$status_file"

  if [[ "$http_status" -lt 200 || "$http_status" -ge 300 ]]; then
    echo "Unable to list HCP Terraform runs." >&2
    echo "Organization: ${ORGANIZATION}" >&2
    echo "Workspace: ${WORKSPACE}" >&2
    echo "Workspace ID: ${workspace_id}" >&2
    echo "HTTP status: ${http_status}" >&2
    echo "Endpoint: ${runs_url}" >&2
    echo "Check that the HCP organization/workspace names are exact and that HCP_TOKEN can read the workspace and runs." >&2
    if [[ -s "$runs_file" ]]; then
      echo "HCP API response body:" >&2
      cat "$runs_file" >&2
    fi
    if [[ -s "$err_file" ]]; then
      echo "curl diagnostics:" >&2
      cat "$err_file" >&2
    fi
    return 1
  fi

  local run_count
  run_count="$(jq '.data | length' "$runs_file")"
  if [[ "$run_count" -eq 0 ]]; then
    echo "HCP workspace ${WORKSPACE} was found, but it has no runs to capture yet." >&2
    echo "Queue a speculative or normal HCP run first, then rerun this evidence pipeline." >&2
    return 1
  fi

  if [[ -n "$VCS_REVISION" ]]; then
    local matched_run_id
    matched_run_id="$(jq -r --arg revision "$VCS_REVISION" '
      .data[]
      | select(
          (.attributes["vcs-revision"] // "") == $revision
          or (.attributes["commit-sha"] // "") == $revision
          or (.attributes.message // "" | contains($revision))
        )
      | .id
    ' "$runs_file" | head -n 1)"

    if [[ -n "$matched_run_id" ]]; then
      printf '%s\n' "$matched_run_id"
      return
    fi

    if [[ "$ALLOW_LATEST_RUN" != "true" ]]; then
      echo "No HCP run matched commit ${VCS_REVISION}." >&2
      echo "Queue an HCP run for the same Git commit, pass --run-id, or set --allow-latest-run true for manual testing only." >&2
      return 1
    fi

    echo "No HCP run matched commit ${VCS_REVISION}; falling back to latest workspace run because --allow-latest-run is true." >&2
  fi

  jq -r '.data[0].id // empty' "$runs_file"
}

if [[ -z "$RUN_ID" ]]; then
  RUN_ID="$(find_run_id)"
fi

if [[ -z "$RUN_ID" || "$RUN_ID" == "null" ]]; then
  echo "No HCP Terraform run found for workspace ${WORKSPACE}." >&2
  exit 1
fi

echo "Capturing evidence for HCP run: $RUN_ID"
for attempt in $(seq 1 60); do
  api_get "https://app.terraform.io/api/v2/runs/${RUN_ID}" > "$OUTPUT_DIR/run.json"
  RUN_STATUS="$(jq -r '.data.attributes.status // "unknown"' "$OUTPUT_DIR/run.json")"
  PLAN_ID="$(jq -r '.data.relationships.plan.data.id // empty' "$OUTPUT_DIR/run.json")"

  if [[ -n "$PLAN_ID" ]]; then
    echo "HCP run ${RUN_ID} status=${RUN_STATUS}, plan=${PLAN_ID}"
    break
  fi

  if [[ "$RUN_STATUS" == "errored" || "$RUN_STATUS" == "canceled" || "$RUN_STATUS" == "force_canceled" ]]; then
    echo "Run ${RUN_ID} reached terminal status ${RUN_STATUS} before a plan relationship was available." >&2
    exit 1
  fi

  if [[ "$attempt" -eq 60 ]]; then
    echo "Run ${RUN_ID} did not expose a plan relationship after ${attempt} attempts. Last status: ${RUN_STATUS}" >&2
    exit 1
  fi

  sleep 10
done

PLAN_JSON="$OUTPUT_DIR/plan.json"
for attempt in $(seq 1 60); do
  api_get "https://app.terraform.io/api/v2/runs/${RUN_ID}" > "$OUTPUT_DIR/run.json"
  RUN_STATUS="$(jq -r '.data.attributes.status // "unknown"' "$OUTPUT_DIR/run.json")"

  http_status="$(api_get_with_status \
    "https://app.terraform.io/api/v2/plans/${PLAN_ID}/json-output" \
    "$PLAN_JSON.tmp" \
    "$OUTPUT_DIR/plan-download.err")"
  printf '%s\n' "$http_status" > "$OUTPUT_DIR/plan-json-http-status.txt"

  if [[ "$http_status" -ge 200 && "$http_status" -lt 300 ]]; then
    if jq -e '.format_version? // empty' "$PLAN_JSON.tmp" >/dev/null 2>&1; then
      mv "$PLAN_JSON.tmp" "$PLAN_JSON"
      break
    fi
    cp "$PLAN_JSON.tmp" "$OUTPUT_DIR/plan-json-last-response.json" || true
  fi

  if [[ "$RUN_STATUS" == "errored" || "$RUN_STATUS" == "canceled" || "$RUN_STATUS" == "force_canceled" ]]; then
    echo "Run ${RUN_ID} reached terminal status ${RUN_STATUS} before plan JSON was available." >&2
    cat "$OUTPUT_DIR/run.json" >&2 || true
    exit 1
  fi

  echo "Waiting for plan JSON: attempt=${attempt}, run_status=${RUN_STATUS}, http_status=${http_status}"

  if [[ "$attempt" -eq 60 ]]; then
    echo "Plan JSON was not available after ${attempt} attempts." >&2
    echo "Last plan JSON HTTP status: ${http_status}" >&2
    cat "$OUTPUT_DIR/plan-download.err" >&2 || true
    if [[ -s "$PLAN_JSON.tmp" ]]; then
      echo "Last plan JSON response body:" >&2
      cat "$PLAN_JSON.tmp" >&2
    fi
    exit 1
  fi

  sleep 10
done

api_get "https://app.terraform.io/api/v2/runs/${RUN_ID}/policy-checks" > "$OUTPUT_DIR/policy-checks.json" || {
  echo '{"data":[]}' > "$OUTPUT_DIR/policy-checks.json"
}

api_get "https://app.terraform.io/api/v2/runs/${RUN_ID}/task-stages?include=task-results,policy-evaluations&page%5Bsize%5D=100" > "$OUTPUT_DIR/task-stages.json" || {
  echo '{"data":[],"included":[]}' > "$OUTPUT_DIR/task-stages.json"
}

ADDS="$(jq '[.resource_changes[]? | select((.change.actions | index("create")) and (.change.actions | index("delete") | not))] | length' "$PLAN_JSON")"
UPDATES="$(jq '[.resource_changes[]? | select(.change.actions | index("update"))] | length' "$PLAN_JSON")"
REPLACES="$(jq '[.resource_changes[]? | select((.change.actions | index("create")) and (.change.actions | index("delete")))] | length' "$PLAN_JSON")"
DESTROYS="$(jq '[.resource_changes[]? | select((.change.actions | index("delete")) and (.change.actions | index("create") | not))] | length' "$PLAN_JSON")"
DESTROY_IMPACT="$(jq '[.resource_changes[]? | select(.change.actions | index("delete"))] | length' "$PLAN_JSON")"

POLICY_FAILURES="$(jq '
  [.data[]?
    | select(
        (.attributes.status // "") == "hard_failed"
        or (.attributes.status // "") == "failed"
        or (.attributes.status // "") == "errored"
      )
  ] | length
' "$OUTPUT_DIR/policy-checks.json")"

RUN_TASK_FAILURES="$(jq '
  [
    .included[]?
    | select(.type == "task-results")
    | select(
        (.attributes.status // "") == "failed"
        or (.attributes.status // "") == "errored"
        or (.attributes.status // "") == "unreachable"
        or (.attributes.status // "") == "canceled"
      )
  ] | length
' "$OUTPUT_DIR/task-stages.json")"

TASK_STAGE_FAILURES="$(jq '
  [
    .data[]?
    | select(
        (.attributes.status // "") == "failed"
        or (.attributes.status // "") == "errored"
        or (.attributes.status // "") == "unreachable"
        or (.attributes.status // "") == "canceled"
      )
  ] | length
' "$OUTPUT_DIR/task-stages.json")"

RUN_TASK_RESULTS="$(jq '[.included[]? | select(.type == "task-results")] | length' "$OUTPUT_DIR/task-stages.json")"
POLICY_EVALUATIONS="$(jq '[.included[]? | select(.type == "policy-evaluations")] | length' "$OUTPUT_DIR/task-stages.json")"

cat > "$OUTPUT_DIR/summary.json" <<EOF
{
  "organization": "$ORGANIZATION",
  "workspace": "$WORKSPACE",
  "run_id": "$RUN_ID",
  "plan_id": "$PLAN_ID",
  "adds": $ADDS,
  "updates": $UPDATES,
  "replaces": $REPLACES,
  "destroys": $DESTROYS,
  "destroy_impact": $DESTROY_IMPACT,
  "policy_failures": $POLICY_FAILURES,
  "task_stage_failures": $TASK_STAGE_FAILURES,
  "run_task_results": $RUN_TASK_RESULTS,
  "run_task_failures": $RUN_TASK_FAILURES,
  "policy_evaluations": $POLICY_EVALUATIONS
}
EOF

cat > "$OUTPUT_DIR/summary.md" <<EOF
# HCP Terraform Evidence

| Field | Value |
| --- | --- |
| Organization | $ORGANIZATION |
| Workspace | $WORKSPACE |
| Run ID | $RUN_ID |
| Plan ID | $PLAN_ID |
| Adds | $ADDS |
| Updates | $UPDATES |
| Replaces | $REPLACES |
| Destroys | $DESTROYS |
| Destroy-impacting changes | $DESTROY_IMPACT |
| Policy failures | $POLICY_FAILURES |
| Task stage failures | $TASK_STAGE_FAILURES |
| Run task results | $RUN_TASK_RESULTS |
| Run task failures | $RUN_TASK_FAILURES |
| Policy evaluations | $POLICY_EVALUATIONS |
EOF

echo "Plan summary: add=${ADDS}, update=${UPDATES}, replace=${REPLACES}, destroy=${DESTROYS}, destroy_impact=${DESTROY_IMPACT}, policy_failures=${POLICY_FAILURES}, run_task_failures=${RUN_TASK_FAILURES}"

if [[ -n "${BUILD_BUILDID:-}" ]]; then
  echo "##vso[task.setvariable variable=hcpRunId]${RUN_ID}"
  echo "##vso[task.setvariable variable=hcpPlanSummary]Add:${ADDS} Update:${UPDATES} Replace:${REPLACES} Destroy:${DESTROYS}"
  echo "##vso[task.setvariable variable=hcpDestroyImpact]${DESTROY_IMPACT}"
  echo "##vso[task.setvariable variable=hcpPolicyFailures]${POLICY_FAILURES}"
  echo "##vso[task.setvariable variable=hcpRunTaskFailures]${RUN_TASK_FAILURES}"
fi

if [[ "$FAIL_ON_DESTROY" == "true" && "$DESTROY_IMPACT" -gt 0 ]]; then
  echo "Plan includes delete or replace actions. Review required before promotion." >&2
  exit 1
fi

if [[ "$FAIL_ON_POLICY_FAILURE" == "true" && "$POLICY_FAILURES" -gt 0 ]]; then
  echo "HCP policy checks reported failures." >&2
  exit 1
fi

if [[ "$FAIL_ON_RUN_TASK_FAILURE" == "true" && "$RUN_TASK_FAILURES" -gt 0 ]]; then
  echo "HCP run tasks reported failures." >&2
  exit 1
fi
