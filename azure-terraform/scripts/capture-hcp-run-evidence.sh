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
                              tries to match --vcs-revision, then falls back to
                              the latest run in the workspace.
  --vcs-revision <sha>        Commit SHA to match against recent HCP runs.
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
  curl -fsS \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/vnd.api+json" \
    "$url"
}

find_run_id() {
  local runs_file="$OUTPUT_DIR/runs.json"
  api_get "https://app.terraform.io/api/v2/organizations/${ORGANIZATION}/workspaces/${WORKSPACE}/runs?page%5Bsize%5D=20" > "$runs_file"

  if [[ -n "$VCS_REVISION" ]]; then
    jq -r --arg revision "$VCS_REVISION" '
      .data[]
      | select(
          (.attributes["vcs-revision"] // "") == $revision
          or (.attributes["commit-sha"] // "") == $revision
          or (.attributes.message // "" | contains($revision))
        )
      | .id
    ' "$runs_file" | head -n 1
    return
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
api_get "https://app.terraform.io/api/v2/runs/${RUN_ID}" > "$OUTPUT_DIR/run.json"

PLAN_ID="$(jq -r '.data.relationships.plan.data.id // empty' "$OUTPUT_DIR/run.json")"
if [[ -z "$PLAN_ID" ]]; then
  echo "Run ${RUN_ID} does not have a plan relationship yet." >&2
  exit 1
fi

PLAN_JSON="$OUTPUT_DIR/plan.json"
for attempt in $(seq 1 30); do
  if api_get "https://app.terraform.io/api/v2/plans/${PLAN_ID}/json-output" > "$PLAN_JSON.tmp" 2>"$OUTPUT_DIR/plan-download.err"; then
    if jq -e '.resource_changes? // empty' "$PLAN_JSON.tmp" >/dev/null 2>&1; then
      mv "$PLAN_JSON.tmp" "$PLAN_JSON"
      break
    fi
  fi

  if [[ "$attempt" -eq 30 ]]; then
    echo "Plan JSON was not available after ${attempt} attempts." >&2
    cat "$OUTPUT_DIR/plan-download.err" >&2 || true
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
