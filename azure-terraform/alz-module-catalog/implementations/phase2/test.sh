#!/usr/bin/env bash
# PHASE2 NEW: offline/mock suite only. No Azure/HCP apply or live integration test.
set -euo pipefail
catalog="$(cd "$(dirname "$0")/../.." && pwd)"
scratch="$(mktemp -d "${TMPDIR:-/tmp}/compeer-phase2-tests.XXXXXX")"
trap 'rm -rf "$scratch"' EXIT
export TF_PLUGIN_CACHE_DIR="${TF_PLUGIN_CACHE_DIR:-$scratch/provider-cache}"
mkdir -p "$TF_PLUGIN_CACHE_DIR"
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s "$catalog/implementations/phase2/tests" -v
patterns=(
  terraform-azurerm-compeer-platform-observability
  terraform-azurerm-compeer-platform-services
  terraform-azurerm-compeer-log-archive
  terraform-azurerm-compeer-phase2-governance
  terraform-azurerm-compeer-hcp-governance
  terraform-azurerm-compeer-security-automation
  terraform-azurerm-compeer-spoke-landing-zone
  terraform-azurerm-compeer-workload-key-vault
  terraform-azurerm-compeer-platform-management
  terraform-azurerm-compeer-platform-policy
  terraform-azurerm-compeer-platform-connectivity
  terraform-azurerm-compeer-platform-hybrid-connectivity
  terraform-azurerm-compeer-network-peering
  terraform-azurerm-compeer-directory-services
  terraform-azurerm-compeer-global-governance
  terraform-azurerm-compeer-workload-identity
  terraform-azurerm-compeer-sentinel-content
  terraform-azurerm-compeer-palo-alto-hub
  terraform-azurerm-compeer-cloudflare-connectors
  terraform-cloudflare-compeer-edge-baseline
  terraform-azurerm-compeer-subscription-onboarding
  terraform-azurerm-compeer-subscription-vending
)
verify() {
  local directory="$1"
  shift
  export TF_DATA_DIR="$scratch/data-$(basename "$directory")"
  printf '\nVerifying %s\n' "$directory"
  terraform -chdir="$directory" init -backend=false -input=false -no-color
  # Reusable modules with provider aliases require a caller. Their mock tests
  # and the independently validated deployment roots supply those bindings.
  if ! grep -q 'configuration_aliases' "$directory"/*.tf; then
    terraform -chdir="$directory" validate -no-color
  fi
  terraform -chdir="$directory" test -no-color "$@"
}
for name in "${patterns[@]}"; do verify "$catalog/patterns/$name"; done
for name in terraform-azurerm-compeer-actiongroup terraform-azurerm-compeer-action-group terraform-azurerm-compeer-storage-account terraform-azurerm-compeer-key-vault-key terraform-azurerm-compeer-disk-encryption-set; do
  verify "$catalog/modules/$name"
done
while IFS= read -r relative; do
  root="$catalog/$relative"
  verify "$root" -filter=tests/defaults.tftest.hcl -var-file=terraform.tfvars.example
  if [[ -f "$root/tests/pilot.tftest.hcl" ]]; then
    terraform -chdir="$root" test -no-color -filter=tests/pilot.tftest.hcl -var-file=approved-pilot.tfvars.example
  fi
  if [[ -f "$root/tests/attachment.tftest.hcl" ]]; then
    terraform -chdir="$root" test -no-color -filter=tests/attachment.tftest.hcl -var-file=terraform.tfvars.example
  fi
done < <(python3 -c 'import json,sys; print("\n".join(item["path"] for item in json.load(open(sys.argv[1]))["new_roots"]))' "$catalog/implementations/phase2/implementation-map.json")
while IFS= read -r relative; do
  root="$catalog/$relative"
  verify "$root" -test-directory=phase2-tests -var-file=phase2.tfvars.example
  if [[ -d "$root/tests" ]]; then
    terraform -chdir="$root" test -no-color
  fi
done < <(python3 -c 'import json,sys; print("\n".join(item["path"] for item in json.load(open(sys.argv[1]))["existing_roots"]))' "$catalog/implementations/phase2/implementation-map.json")
printf '\nPhase 2 mock/structural validation completed. Live acceptance is separate.\n'
