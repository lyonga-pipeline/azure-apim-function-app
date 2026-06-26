#!/usr/bin/env bash
# validate-destructive-change-approval.sh
#
# Purpose:
#   Classify Terraform delete/replace actions from HCP plan JSON and validate
#   whether the Azure DevOps pull request acknowledges the destructive impact.

set -Eeuo pipefail

PLAN_JSON=""
POLICY_CONFIG=""
OUTPUT_DIR="hcp-evidence"
ENFORCEMENT_MODE="enforce"
ENFORCE_ONLY_ON_PR=true
REQUIRE_MEDIUM_ACK=true
REQUIRE_HIGH_ACK=true
REQUIRE_HIGH_WORK_ITEM=true

usage() {
  cat <<'EOF'
Usage:
  validate-destructive-change-approval.sh --plan-json <plan.json> --policy-config <policy.json> [options]

Required:
  --plan-json <file>                 HCP Terraform plan JSON file.
  --policy-config <file>             Destructive-change classification policy JSON.

Options:
  --output-dir <dir>                 Evidence output directory. Default: hcp-evidence.
  --enforcement-mode <mode>          enforce or warn. Default: enforce.
  --enforce-only-on-pr <bool>        Enforce PR acknowledgement only during PR validation. Default: true.
  --require-medium-ack <bool>        Require PR acknowledgement for medium impact changes. Default: true.
  --require-high-ack <bool>          Require PR acknowledgement for high impact changes. Default: true.
  --require-high-work-item <bool>    Require linked work item/change reference for high impact changes. Default: true.
  -h, --help                         Show this help text.

Environment:
  ADO_TOKEN                          Azure DevOps OAuth token. Use $(System.AccessToken).
  DESTRUCTIVE_CHANGE_ACK             Optional override. Set true only from a controlled pipeline variable.
  CHANGE_APPROVAL_REFERENCE          Optional approved change/work item reference.

PR acknowledgement:
  The script recognizes a checked PR option like "- [x] Destroy resource" or a line like
  "Change type: Destroy resource".
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --plan-json) PLAN_JSON="${2:?Missing value for --plan-json}"; shift 2 ;;
    --policy-config) POLICY_CONFIG="${2:?Missing value for --policy-config}"; shift 2 ;;
    --output-dir) OUTPUT_DIR="${2:?Missing value for --output-dir}"; shift 2 ;;
    --enforcement-mode) ENFORCEMENT_MODE="${2:?Missing value for --enforcement-mode}"; shift 2 ;;
    --enforce-only-on-pr) ENFORCE_ONLY_ON_PR="${2:?Missing value for --enforce-only-on-pr}"; shift 2 ;;
    --require-medium-ack) REQUIRE_MEDIUM_ACK="${2:?Missing value for --require-medium-ack}"; shift 2 ;;
    --require-high-ack) REQUIRE_HIGH_ACK="${2:?Missing value for --require-high-ack}"; shift 2 ;;
    --require-high-work-item) REQUIRE_HIGH_WORK_ITEM="${2:?Missing value for --require-high-work-item}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ -z "$PLAN_JSON" || -z "$POLICY_CONFIG" ]]; then
  echo "Plan JSON and policy config are required." >&2
  usage
  exit 1
fi

if [[ ! -f "$PLAN_JSON" ]]; then
  echo "Plan JSON not found: $PLAN_JSON" >&2
  exit 1
fi

if [[ ! -f "$POLICY_CONFIG" ]]; then
  echo "Policy config not found: $POLICY_CONFIG" >&2
  exit 1
fi

if [[ "$ENFORCEMENT_MODE" != "enforce" && "$ENFORCEMENT_MODE" != "warn" ]]; then
  echo "Invalid enforcement mode: $ENFORCEMENT_MODE. Use enforce or warn." >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to classify destructive changes." >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

CHANGES_JSON="$OUTPUT_DIR/destructive-changes.json"
SUMMARY_JSON="$OUTPUT_DIR/destructive-change-approval.json"
SUMMARY_MD="$OUTPUT_DIR/destructive-change-approval.md"
PR_CONTEXT="$OUTPUT_DIR/pr-context.json"
VIOLATIONS_FILE="$OUTPUT_DIR/destructive-change-violations.txt"
PR_TEXT_FILE="$OUTPUT_DIR/pr-text.txt"

jq --slurpfile policy_file "$POLICY_CONFIG" '
  def policy: $policy_file[0];

  def array_contains($items; $value):
    any($items[]?; . == $value);

  def pattern_matches($patterns; $value):
    any($patterns[]?; . as $pattern | ($value | test($pattern; "i")));

  def classify($type; $address):
    if array_contains((policy.impact.high.resource_types // []); $type)
      or pattern_matches((policy.impact.high.address_patterns // []); $address)
    then "high"
    elif array_contains((policy.impact.medium.resource_types // []); $type)
      or pattern_matches((policy.impact.medium.address_patterns // []); $address)
    then "medium"
    elif array_contains((policy.impact.low.resource_types // []); $type)
      or pattern_matches((policy.impact.low.address_patterns // []); $address)
    then "low"
    else (policy.default_impact // "medium")
    end;

  [
    .resource_changes[]?
    | select(.change.actions | index("delete"))
    | {
        address: .address,
        mode: .mode,
        type: .type,
        name: .name,
        actions: .change.actions,
        impact: classify(.type; .address)
      }
  ]
' "$PLAN_JSON" > "$CHANGES_JSON"

TOTAL="$(jq 'length' "$CHANGES_JSON")"
LOW="$(jq '[.[] | select(.impact == "low")] | length' "$CHANGES_JSON")"
MEDIUM="$(jq '[.[] | select(.impact == "medium")] | length' "$CHANGES_JSON")"
HIGH="$(jq '[.[] | select(.impact == "high")] | length' "$CHANGES_JSON")"

PR_ID="${SYSTEM_PULLREQUEST_PULLREQUESTID:-}"
PR_TITLE=""
PR_DESCRIPTION=""
PR_FETCHED=false
WORK_ITEM_COUNT=0
WORK_ITEM_FETCHED=false

fetch_pr_context() {
  if [[ -z "$PR_ID" ]]; then
    return
  fi

  if [[ -z "${ADO_TOKEN:-}" ]]; then
    echo "ADO_TOKEN is not available; PR acknowledgement cannot be verified." >&2
    return
  fi

  if [[ -z "${SYSTEM_COLLECTIONURI:-}" || -z "${SYSTEM_TEAMPROJECT:-}" || -z "${BUILD_REPOSITORY_ID:-}" ]]; then
    echo "Required Azure DevOps PR environment variables are not available." >&2
    return
  fi

  local project_encoded
  project_encoded="$(jq -nr --arg value "$SYSTEM_TEAMPROJECT" '$value | @uri')"

  local base_url="${SYSTEM_COLLECTIONURI%/}/${project_encoded}/_apis/git/repositories/${BUILD_REPOSITORY_ID}/pullRequests/${PR_ID}"

  if curl -fsS \
    -H "Authorization: Bearer ${ADO_TOKEN}" \
    -H "Accept: application/json" \
    "${base_url}?api-version=7.1" > "$PR_CONTEXT"; then
    PR_FETCHED=true
    PR_TITLE="$(jq -r '.title // ""' "$PR_CONTEXT")"
    PR_DESCRIPTION="$(jq -r '.description // ""' "$PR_CONTEXT")"
  fi

  if curl -fsS \
    -H "Authorization: Bearer ${ADO_TOKEN}" \
    -H "Accept: application/json" \
    "${base_url}/workitems?api-version=7.1" > "$OUTPUT_DIR/pr-work-items.json"; then
    WORK_ITEM_FETCHED=true
    WORK_ITEM_COUNT="$(jq '.count // (.value | length) // 0' "$OUTPUT_DIR/pr-work-items.json")"
  fi
}

fetch_pr_context
printf '%s\n\n%s\n' "$PR_TITLE" "$PR_DESCRIPTION" > "$PR_TEXT_FILE"

DESTROY_ACK=false
if [[ "${DESTRUCTIVE_CHANGE_ACK:-}" == "true" ]]; then
  DESTROY_ACK=true
elif grep -Eiq '(^|[[:space:]])\[[xX]\][[:space:]]*Destroy[[:space:]_-]*resource\b' "$PR_TEXT_FILE"; then
  DESTROY_ACK=true
elif grep -Eiq '^.*change[[:space:]_-]*type[[:space:]]*[:=-][[:space:]]*.*Destroy[[:space:]_-]*resource\b' "$PR_TEXT_FILE"; then
  DESTROY_ACK=true
fi

HIGH_APPROVAL=false
if [[ "${CHANGE_APPROVAL_REFERENCE:-}" != "" ]]; then
  HIGH_APPROVAL=true
elif [[ "$WORK_ITEM_COUNT" -gt 0 ]]; then
  HIGH_APPROVAL=true
elif grep -Eiq '(CHG[0-9]{4,}|CRQ[0-9]{4,}|AB#[0-9]+|change[[:space:]_-]*(request|record|ticket)[[:space:]]*[:#=-][[:space:]]*[A-Za-z0-9-]+|approval[[:space:]_-]*(reference|ticket)[[:space:]]*[:#=-][[:space:]]*[A-Za-z0-9-]+)' "$PR_TEXT_FILE"; then
  HIGH_APPROVAL=true
fi

: > "$VIOLATIONS_FILE"

ACK_ENFORCEMENT_ACTIVE=true
if [[ "$ENFORCE_ONLY_ON_PR" == "true" && -z "$PR_ID" ]]; then
  ACK_ENFORCEMENT_ACTIVE=false
fi

if [[ "$TOTAL" -gt 0 ]]; then
  echo "##vso[task.logissue type=warning]Terraform plan contains ${TOTAL} delete/replace action(s): low=${LOW}, medium=${MEDIUM}, high=${HIGH}."
fi

if [[ "$TOTAL" -gt 0 && "$ACK_ENFORCEMENT_ACTIVE" != "true" ]]; then
  echo "##vso[task.logissue type=warning]PR acknowledgement enforcement skipped because this build is not running in PR validation context."
fi

if [[ "$ACK_ENFORCEMENT_ACTIVE" == "true" && "$MEDIUM" -gt 0 && "$REQUIRE_MEDIUM_ACK" == "true" && "$DESTROY_ACK" != "true" ]]; then
  echo "Medium-impact delete/replace actions require PR acknowledgement using the Destroy resource change type." >> "$VIOLATIONS_FILE"
fi

if [[ "$ACK_ENFORCEMENT_ACTIVE" == "true" && "$HIGH" -gt 0 && "$REQUIRE_HIGH_ACK" == "true" && "$DESTROY_ACK" != "true" ]]; then
  echo "High-impact delete/replace actions require PR acknowledgement using the Destroy resource change type." >> "$VIOLATIONS_FILE"
fi

if [[ "$ACK_ENFORCEMENT_ACTIVE" == "true" && "$HIGH" -gt 0 && "$REQUIRE_HIGH_WORK_ITEM" == "true" && "$HIGH_APPROVAL" != "true" ]]; then
  echo "High-impact delete/replace actions require a linked work item, change ticket, or approved change reference." >> "$VIOLATIONS_FILE"
fi

PR_CONTEXT_REQUIRED=false
if [[ "$MEDIUM" -gt 0 && "$REQUIRE_MEDIUM_ACK" == "true" && "$DESTROY_ACK" != "true" ]]; then
  PR_CONTEXT_REQUIRED=true
fi

if [[ "$HIGH" -gt 0 && "$REQUIRE_HIGH_ACK" == "true" && "$DESTROY_ACK" != "true" ]]; then
  PR_CONTEXT_REQUIRED=true
fi

if [[ "$HIGH" -gt 0 && "$REQUIRE_HIGH_WORK_ITEM" == "true" && "$HIGH_APPROVAL" != "true" ]]; then
  PR_CONTEXT_REQUIRED=true
fi

if [[ "$ACK_ENFORCEMENT_ACTIVE" == "true" && "$TOTAL" -gt 0 && -n "$PR_ID" && "$PR_FETCHED" != "true" && "$PR_CONTEXT_REQUIRED" == "true" ]]; then
  echo "PR context could not be fetched, so destructive-change acknowledgement could not be verified." >> "$VIOLATIONS_FILE"
fi

VIOLATION_COUNT="$(grep -cve '^[[:space:]]*$' "$VIOLATIONS_FILE" || true)"

jq -n \
  --argjson total "$TOTAL" \
  --argjson low "$LOW" \
  --argjson medium "$MEDIUM" \
  --argjson high "$HIGH" \
  --arg pr_id "$PR_ID" \
  --argjson pr_fetched "$PR_FETCHED" \
  --argjson destroy_ack "$DESTROY_ACK" \
  --argjson work_item_fetched "$WORK_ITEM_FETCHED" \
  --argjson work_item_count "$WORK_ITEM_COUNT" \
  --argjson high_approval "$HIGH_APPROVAL" \
  --argjson ack_enforcement_active "$ACK_ENFORCEMENT_ACTIVE" \
  --arg enforcement_mode "$ENFORCEMENT_MODE" \
  --slurpfile changes "$CHANGES_JSON" \
  --rawfile violations "$VIOLATIONS_FILE" \
  '{
    destructive_changes: {
      total: $total,
      low: $low,
      medium: $medium,
      high: $high
    },
    pull_request: {
      id: $pr_id,
      fetched: $pr_fetched,
      destroy_resource_acknowledged: $destroy_ack,
      work_item_lookup_succeeded: $work_item_fetched,
      linked_work_item_count: $work_item_count,
      high_impact_approval_found: $high_approval,
      acknowledgement_enforcement_active: $ack_enforcement_active
    },
    enforcement_mode: $enforcement_mode,
    violations: ($violations | split("\n") | map(select(length > 0))),
    changes: $changes[0]
  }' > "$SUMMARY_JSON"

cat > "$SUMMARY_MD" <<EOF
# Destructive Change Review

| Field | Value |
| --- | --- |
| Destructive changes | $TOTAL |
| Low impact | $LOW |
| Medium impact | $MEDIUM |
| High impact | $HIGH |
| PR ID | ${PR_ID:-N/A} |
| PR context fetched | $PR_FETCHED |
| Destroy resource acknowledged | $DESTROY_ACK |
| Linked work items | $WORK_ITEM_COUNT |
| High-impact approval found | $HIGH_APPROVAL |
| PR acknowledgement enforcement active | $ACK_ENFORCEMENT_ACTIVE |
| Enforcement mode | $ENFORCEMENT_MODE |

## Required Action Model

| Impact | Action |
| --- | --- |
| Low | Warn only. |
| Medium | Require PR acknowledgement with the Destroy resource change type. |
| High | Require PR acknowledgement plus linked work item, change ticket, or approved change reference. |

## Destructive Resources

| Impact | Type | Address | Actions |
| --- | --- | --- | --- |
EOF

if [[ "$TOTAL" -eq 0 ]]; then
  echo "| none | none | none | none |" >> "$SUMMARY_MD"
else
  jq -r '.[] | "| \(.impact) | \(.type) | `\(.address)` | \(.actions | join(",")) |"' "$CHANGES_JSON" >> "$SUMMARY_MD"
fi

cat >> "$SUMMARY_MD" <<EOF

## Violations

EOF

if [[ "$VIOLATION_COUNT" -eq 0 ]]; then
  echo "None." >> "$SUMMARY_MD"
else
  sed 's/^/- /' "$VIOLATIONS_FILE" >> "$SUMMARY_MD"
fi

if [[ "$VIOLATION_COUNT" -gt 0 ]]; then
  while IFS= read -r violation; do
    [[ -z "$violation" ]] && continue
    if [[ "$ENFORCEMENT_MODE" == "enforce" ]]; then
      echo "##vso[task.logissue type=error]$violation"
    else
      echo "##vso[task.logissue type=warning]$violation"
    fi
  done < "$VIOLATIONS_FILE"
fi

if [[ "$DESTROY_ACK" == "true" && "$TOTAL" -eq 0 ]]; then
  echo "##vso[task.logissue type=warning]PR acknowledges Destroy resource, but the Terraform plan has no delete/replace actions."
fi

echo "Destructive change summary: total=${TOTAL}, low=${LOW}, medium=${MEDIUM}, high=${HIGH}, ack=${DESTROY_ACK}, high_approval=${HIGH_APPROVAL}, violations=${VIOLATION_COUNT}"

if [[ "$ENFORCEMENT_MODE" == "enforce" && "$VIOLATION_COUNT" -gt 0 ]]; then
  exit 1
fi
