#!/usr/bin/env bash
set -euo pipefail

if [[ "${ALLOW_LIVE_AZURE_TEST:-}" != "true" ]]; then
  printf '%s\n' 'Refusing deployment: set ALLOW_LIVE_AZURE_TEST=true only for an approved isolated test subscription.' >&2
  exit 2
fi
if [[ "${TF_VAR_enable_vault_test:-true}" == "false" && ( "${VERIFY_PRIVATE_DNS:-false}" == "true" || "${VERIFY_SECRET_ACCESS:-false}" == "true" || "${TF_VAR_enable_secret_probe_operator:-false}" == "true" ) ]]; then
  printf '%s\n' 'Secretless spoke: disable vault DNS/secret probes and temporary vault operator access before deploying.' >&2
  exit 2
fi
: "${TF_VAR_test_subscription_id:?Set the isolated test subscription UUID}"
: "${TF_VAR_run_id:?Set a unique run ID}"
: "${TF_VAR_cost_center:?Set the approved test cost center}"
: "${TF_VAR_created_on:?Set a stable YYYY-MM-DD test-run date}"
if [[ "${TF_VAR_enable_optional_operations_test:-false}" == "true" ]]; then
  : "${TF_VAR_notification_email:?Set the approved test notification email}"
fi
cd "$(dirname "$0")"
export TF_VAR_allow_live_deployment=true

for command in terraform python3 az; do
  command -v "$command" >/dev/null || { printf 'Required executable missing: %s\n' "$command" >&2; exit 2; }
done
probe_arguments=()
if [[ "${VERIFY_PRIVATE_DNS:-false}" == "true" ]]; then probe_arguments+=(--private-dns); fi
if [[ "${VERIFY_SECRET_ACCESS:-false}" == "true" ]]; then
  [[ "${TF_VAR_enable_secret_probe_operator:-false}" == "true" ]] || { printf '%s\n' 'Secret probe requires explicit temporary operator-role approval.' >&2; exit 2; }
  python3 -c 'import azure.identity; import azure.keyvault.secrets'
  probe_arguments+=(--secret-probe)
fi

cleanup() {
  local status=$?
  trap - EXIT
  if ! terraform destroy -auto-approve -input=false -no-color; then
    printf '%s\n' 'Cleanup failed. Preserve this working directory/state in protected storage and remediate the tagged test resources.' >&2
    exit 1
  fi
  exit "$status"
}

terraform init -input=false -no-color
trap cleanup EXIT
terraform apply -auto-approve -input=false -no-color
terraform output -json spoke | python3 verify_spoke.py "${probe_arguments[@]}"
