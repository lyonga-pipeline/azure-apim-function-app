#!/usr/bin/env bash
# PHASE2 NEW: v5 3.5. Read-only evidence; never triggers policy scans or remediations.
set -euo pipefail
if [ "$#" -ne 2 ]; then
  printf 'Usage: bash collect-evidence.sh <management-group-name> <output-directory>\n' >&2
  exit 2
fi
mg="$1"
output="$2"
case "$mg" in *[!a-zA-Z0-9_.-]*|"") printf 'Use a bare management-group name.\n' >&2; exit 2;; esac
umask 077
mkdir -p "$output"
scope="/providers/Microsoft.Management/managementGroups/$mg"
az account show --output json > "$output/execution-context.json"
az policy assignment list --scope "$scope" --output json > "$output/assignments.json"
az policy exemption list --scope "$scope" --output json > "$output/exemptions.json"
az policy state summarize --management-group "$mg" --output json > "$output/compliance-summary.json"
date -u '+%Y-%m-%dT%H:%M:%SZ' > "$output/collected-at.txt"
printf 'Evidence collected. Review inheritance, exemptions and control applicability with GRC.\n'
