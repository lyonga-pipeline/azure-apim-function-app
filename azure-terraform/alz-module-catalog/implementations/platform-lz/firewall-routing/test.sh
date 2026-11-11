#!/usr/bin/env bash
# PHASE 2 ROUTING FOLLOW-UP: local/mock tests only; never applies live Azure.
set -euo pipefail
catalog="$(cd "$(dirname "$0")/../../.." && pwd)"
scratch="$(mktemp -d "${TMPDIR:-/tmp}/compeer-firewall-routing.XXXXXX")"
trap 'rm -rf "$scratch"' EXIT
export TF_PLUGIN_CACHE_DIR="${TF_PLUGIN_CACHE_DIR:-$scratch/providers}"
mkdir -p "$TF_PLUGIN_CACHE_DIR"
for owner in platform-connectivity platform-directory-services; do
  root="$catalog/implementations/platform-lz/workspaces/$owner"
  export TF_DATA_DIR="$scratch/$owner"
  terraform -chdir="$root" init -backend=false -input=false -no-color
  terraform -chdir="$root" validate -no-color
  terraform -chdir="$root" test -no-color
  # Exercise the actual merged root tfvars as well as the portable example.
  terraform -chdir="$root" test -no-color -test-directory=routing-example-tests
  terraform -chdir="$root" test -no-color -test-directory=routing-example-tests -var-file=firewall-routing.tfvars.example
  if [[ "$owner" == "platform-connectivity" ]]; then
    terraform -chdir="$root" test -no-color -test-directory=compeer-example-tests -var-file=compeer-existing-hub.tfvars.example
    terraform -chdir="$root" test -no-color -test-directory=compeer-pilot-tests -var-file=examples/compeer-pilot.tfvars
  fi
  terraform -chdir="$root" test -no-color -test-directory=phase2-tests -var-file=phase2.tfvars.example
done
