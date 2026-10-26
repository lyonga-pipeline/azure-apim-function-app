#!/usr/bin/env bash
set -euo pipefail

catalog=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$catalog"
export TF_IN_AUTOMATION=true

terraform version -json | python3 -c '
import json, re, sys
version = json.load(sys.stdin)["terraform_version"]
match = re.fullmatch(r"(\d+)\.(\d+)\.(\d+)", version)
if match is None or not ((1, 11, 4) <= tuple(map(int, match.groups())) < (2, 0, 0)):
    sys.exit("Use stable Terraform >=1.11.4, <2.0.0; detected " + version)
print("Testing catalog with Terraform " + version)
'

blueprint=patterns/terraform-azurerm-compeer-spoke-landing-zone
python3 -m unittest discover -s "$blueprint/integration-tests" -v
python3 -m unittest discover -s implementations/workload-lz/tests -v

roots=(
  "$blueprint"
  patterns/terraform-azurerm-compeer-workload-key-vault
  patterns/terraform-azurerm-compeer-hub-spoke-peering
  patterns/terraform-azurerm-compeer-network-peering
  implementations/workload-lz/shared
  implementations/workload-lz/workspaces/workload-internal-apps-prod
  implementations/workload-lz/workspaces/workload-internal-apps-nonprod
  implementations/platform-lz/workspaces/platform-network-peering
  modules/terraform-azurerm-compeer-naming
  modules/terraform-azurerm-compeer-virtual-network
  modules/terraform-azurerm-compeer-storage-account
  modules/terraform-azurerm-compeer-application-insights
  modules/terraform-azurerm-compeer-key-vault
  modules/terraform-azurerm-compeer-key-vault-key
  modules/terraform-azurerm-compeer-monitor-metric-alert
  modules/terraform-azurerm-compeer-vnet-peering
  modules/terraform-azurerm-compeer-private-dns-vnet-link
)
for root in "${roots[@]}"; do
  terraform -chdir="$root" init -backend=false -input=false -no-color
  case "$root" in
    implementations/*/workspaces/*) terraform -chdir="$root" validate -no-color ;;
  esac
  terraform -chdir="$root" test -no-color
done

nonprod_examples=implementations/workload-lz/workspaces/workload-internal-apps-nonprod
for profile in create-new reuse-existing; do
  terraform -chdir="$nonprod_examples" test -no-color -test-directory=example-tests -var-file="$profile.tfvars.example"
done

vault_examples=patterns/terraform-azurerm-compeer-workload-key-vault/examples
terraform -chdir="$vault_examples" init -backend=false -input=false -no-color
terraform -chdir="$vault_examples" validate -no-color
for variant in "$vault_examples"/variants/*.tfvars; do
  terraform -chdir="$vault_examples" test -no-color -var-file=baseline.tfvars -var-file="variants/$(basename "$variant")"
done

examples="$blueprint/examples"
terraform -chdir="$examples" init -backend=false -input=false -no-color
terraform -chdir="$examples" validate -no-color
for variant in "$examples"/variants/*.tfvars; do
  terraform -chdir="$examples" test -no-color -var-file=baseline.tfvars -var-file="variants/$(basename "$variant")"
done

terraform -chdir="$blueprint/integration-tests" init -backend=false -input=false -no-color
terraform -chdir="$blueprint/integration-tests" validate -no-color
bash -n "$blueprint/integration-tests/run.sh"
