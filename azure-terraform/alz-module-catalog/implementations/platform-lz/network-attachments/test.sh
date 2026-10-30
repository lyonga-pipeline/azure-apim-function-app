#!/usr/bin/env bash
# Mock/local verification only: never queues an HCP run or applies Azure resources.
set -euo pipefail
catalog="$(cd "$(dirname "$0")/../../.." && pwd)"
scratch="$(mktemp -d "${TMPDIR:-/tmp}/compeer-attachments.XXXXXX")"
trap 'rm -rf "$scratch"' EXIT
export TF_PLUGIN_CACHE_DIR="${TF_PLUGIN_CACHE_DIR:-$scratch/providers}"
mkdir -p "$TF_PLUGIN_CACHE_DIR"
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s "$catalog/implementations/platform-lz/network-attachments/tests" -v
verify() {
  local directory="$1"
  export TF_DATA_DIR="$scratch/$(basename "$directory")"
  terraform -chdir="$directory" init -backend=false -input=false -no-color
  if ! grep -q 'configuration_aliases' "$directory"/*.tf; then
    terraform -chdir="$directory" validate -no-color
  fi
  terraform -chdir="$directory" test -no-color
}
verify "$catalog/patterns/terraform-azapi-compeer-network-attachments"
verify "$catalog/patterns/terraform-azapi-compeer-network-attachments/modules/attachment-names"
verify "$catalog/implementations/platform-lz/templates/network-attachments"
for example in "$catalog/patterns/terraform-azapi-compeer-network-attachments/examples/shared-platform.tfvars.example" "$catalog/patterns/terraform-azapi-compeer-network-attachments/examples/application-environments/"*.tfvars.example; do
  terraform -chdir="$catalog/implementations/platform-lz/templates/network-attachments" test -no-color -test-directory=example-tests -var-file="$example"
done
for environment in nonprod prod; do
  verify "$catalog/implementations/platform-lz/workspaces/platform-network-peering-$environment"
done
# Backward compatibility: no caller or resource-address changes to these APIs.
verify "$catalog/patterns/terraform-azurerm-compeer-hub-spoke-peering"
verify "$catalog/patterns/terraform-azurerm-compeer-network-peering"
verify "$catalog/implementations/platform-lz/workspaces/platform-network-peering"
