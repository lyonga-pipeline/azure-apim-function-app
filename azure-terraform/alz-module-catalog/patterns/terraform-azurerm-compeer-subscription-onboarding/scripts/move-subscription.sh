#!/usr/bin/env bash
# move-subscription.sh
#
# Ops helper for the step Terraform normally owns: relocate a CSP-provisioned
# subscription from the Tenant Root Group to its target management group.
#
# Use this only when the subscription-onboarding Terraform workspace cannot run
# (e.g. the subscription was just handed over and you need it placed before the
# next plan). The Terraform `azurerm_management_group_subscription_association`
# resource is the source of truth; run `terraform plan` afterwards and it will
# show no change if this script placed the subscription correctly.
#
# Requires: az CLI >= 2.50, logged in with rights to write management group
# subscription associations (Management Group Contributor at the target, or
# Owner on the Tenant Root Group).
#
# Usage:
#   ./move-subscription.sh --subscription <SUB_GUID> --management-group <MG_NAME> [--dry-run]
#
set -euo pipefail

SUB=""
MG=""
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --subscription) SUB="$2"; shift 2 ;;
    --management-group) MG="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$SUB" || -z "$MG" ]]; then
  echo "ERROR: --subscription and --management-group are required." >&2
  exit 2
fi

if ! [[ "$SUB" =~ ^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$ ]]; then
  echo "ERROR: --subscription must be a bare subscription GUID." >&2
  exit 2
fi

# Where is the subscription now?
CURRENT_MG="$(az account management-group subscription show-sub-under-mg \
  --name "$MG" --subscription "$SUB" --query name -o tsv 2>/dev/null || true)"

if [[ "$CURRENT_MG" == "$MG" ]]; then
  echo "No-op: subscription $SUB is already under management group '$MG'."
  exit 0
fi

echo "Plan: add subscription $SUB to management group '$MG'"
echo "      (Azure removes it from its current group automatically)."

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "--dry-run set; not making changes."
  exit 0
fi

az account management-group subscription add --name "$MG" --subscription "$SUB"
echo "Done. Run 'terraform plan' in the subscription-onboarding workspace to reconcile state."
