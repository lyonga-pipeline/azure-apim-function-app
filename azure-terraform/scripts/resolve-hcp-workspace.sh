#!/usr/bin/env bash
# resolve-hcp-workspace.sh
#
# Purpose:
#   Resolve a Terraform environment root to the correct HCP Terraform workspace.
#   This is intended for workload repositories that have one root/workspace per
#   environment, such as environments/np1, environments/np2, environments/np3,
#   and environments/prod.

set -Eeuo pipefail

SOURCE_DIR="."
TERRAFORM_WORKING_DIRECTORY=""
DEFAULT_TERRAFORM_WORKING_DIRECTORY=""
ENVIRONMENT_ROOT_PREFIX="environments"
WORKSPACE_MAP_FILE="azure-terraform/pipelines/workspace-maps/hcp-workspace-map.json"
WORKSPACE_PREFIX=""
FALLBACK_WORKSPACE=""
HCP_ORGANIZATION=""
OUTPUT_DIR="hcp-evidence"
CHANGED_FILES_FILE=""

usage() {
  cat <<'EOF'
Usage:
  resolve-hcp-workspace.sh [options]

Options:
  --source-dir <dir>                    Checked-out repository root. Default: .
  --terraform-working-directory <dir>   Explicit Terraform root. If omitted,
                                        the script infers one root from changed
                                        files.
  --default-terraform-working-directory <dir>
                                        Default root used when changed files do
                                        not point to exactly one environment.
                                        An explicit --terraform-working-directory
                                        still wins.
  --environment-root-prefix <dir>       Parent folder containing environment
                                        roots. Default: environments.
  --workspace-map-file <file>           JSON map file relative to source dir.
                                        Default: azure-terraform/pipelines/workspace-maps/hcp-workspace-map.json.
  --workspace-prefix <prefix>           Optional fallback; builds
                                        <prefix>-<environment>.
  --fallback-workspace <workspace>      Optional single-workspace fallback.
  --hcp-organization <org>              Optional HCP organization for evidence.
  --output-dir <dir>                    Directory for resolution evidence.
  --changed-files-file <file>           Optional file list for tests/manual use.
  -h, --help                            Show this help text.

Environment:
  HCP_WORKSPACE_MAP may contain an inline JSON object. A source-controlled map
  file is preferred when present.
EOF
}

normalize_path() {
  local value="${1:-}"
  value="${value#./}"
  value="${value%/}"
  printf '%s\n' "$value"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-dir) SOURCE_DIR="${2:?Missing value for --source-dir}"; shift 2 ;;
    --terraform-working-directory) TERRAFORM_WORKING_DIRECTORY="${2:-}"; shift 2 ;;
    --default-terraform-working-directory) DEFAULT_TERRAFORM_WORKING_DIRECTORY="${2:-}"; shift 2 ;;
    --environment-root-prefix) ENVIRONMENT_ROOT_PREFIX="${2:?Missing value for --environment-root-prefix}"; shift 2 ;;
    --workspace-map-file) WORKSPACE_MAP_FILE="${2:-}"; shift 2 ;;
    --workspace-prefix) WORKSPACE_PREFIX="${2:-}"; shift 2 ;;
    --fallback-workspace) FALLBACK_WORKSPACE="${2:-}"; shift 2 ;;
    --hcp-organization) HCP_ORGANIZATION="${2:-}"; shift 2 ;;
    --output-dir) OUTPUT_DIR="${2:?Missing value for --output-dir}"; shift 2 ;;
    --changed-files-file) CHANGED_FILES_FILE="${2:?Missing value for --changed-files-file}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to resolve HCP workspace maps." >&2
  exit 1
fi

SOURCE_DIR="$(cd "$SOURCE_DIR" && pwd)"
TERRAFORM_WORKING_DIRECTORY="$(normalize_path "$TERRAFORM_WORKING_DIRECTORY")"
DEFAULT_TERRAFORM_WORKING_DIRECTORY="$(normalize_path "$DEFAULT_TERRAFORM_WORKING_DIRECTORY")"
ENVIRONMENT_ROOT_PREFIX="$(normalize_path "$ENVIRONMENT_ROOT_PREFIX")"
WORKSPACE_MAP_FILE="$(normalize_path "$WORKSPACE_MAP_FILE")"

mkdir -p "$OUTPUT_DIR"

environment_from_root() {
  local root="$1"
  basename "$root"
}

changed_files_for_build() {
  local target_ref="${SYSTEM_PULLREQUEST_TARGETBRANCH:-}"
  local target_branch=""

  if [[ -n "$CHANGED_FILES_FILE" ]]; then
    cat "$CHANGED_FILES_FILE"
    return
  fi

  if [[ -n "$target_ref" ]]; then
    target_branch="${target_ref#refs/heads/}"
    git -C "$SOURCE_DIR" fetch origin "$target_branch" --depth=100 >/dev/null 2>&1 || true
    if git -C "$SOURCE_DIR" rev-parse --verify "origin/${target_branch}" >/dev/null 2>&1; then
      git -C "$SOURCE_DIR" diff --name-only "origin/${target_branch}"...HEAD
      return
    fi
  fi

  if git -C "$SOURCE_DIR" rev-parse --verify HEAD~1 >/dev/null 2>&1; then
    git -C "$SOURCE_DIR" diff --name-only HEAD~1 HEAD
    return
  fi

  git -C "$SOURCE_DIR" ls-files
}

resolved_root="$TERRAFORM_WORKING_DIRECTORY"

if [[ -z "$resolved_root" ]]; then
  roots=()
  while IFS= read -r root; do
    [[ -n "$root" ]] && roots+=("$root")
  done < <(
    changed_files_for_build \
      | awk -v prefix="${ENVIRONMENT_ROOT_PREFIX}/" '
          index($0, prefix) == 1 {
            rest = substr($0, length(prefix) + 1)
            split(rest, parts, "/")
            if (parts[1] != "") print prefix parts[1]
          }
        ' \
      | sort -u
  )

  if [[ "${#roots[@]}" -eq 0 && "$ENVIRONMENT_ROOT_PREFIX" == "environments" ]]; then
    roots=()
    while IFS= read -r root; do
      [[ -n "$root" ]] && roots+=("$root")
    done < <(
      changed_files_for_build \
        | awk '
            {
              n = split($0, parts, "/")
              for (i = 1; i < n; i++) {
                if (parts[i] == "environments" && parts[i + 1] != "") {
                  root = parts[1]
                  for (j = 2; j <= i + 1; j++) {
                    root = root "/" parts[j]
                  }
                  print root
                  break
                }
              }
            }
          ' \
        | sort -u
    )
  fi

  if [[ "${#roots[@]}" -eq 0 ]]; then
    if [[ -n "$DEFAULT_TERRAFORM_WORKING_DIRECTORY" ]]; then
      echo "No Terraform environment root was inferred from changed files; using default root: ${DEFAULT_TERRAFORM_WORKING_DIRECTORY}" >&2
      resolved_root="$DEFAULT_TERRAFORM_WORKING_DIRECTORY"
    else
      echo "No Terraform environment root was inferred from changed files." >&2
      echo "Checked '${ENVIRONMENT_ROOT_PREFIX}/<env>' and, when using the default prefix, any nested '*/environments/<env>' path." >&2
      echo "Set --terraform-working-directory, set --default-terraform-working-directory, or adjust --environment-root-prefix." >&2
      exit 1
    fi
  fi

  if [[ -z "$resolved_root" && "${#roots[@]}" -gt 1 ]]; then
    if [[ -n "$DEFAULT_TERRAFORM_WORKING_DIRECTORY" ]]; then
      echo "Multiple Terraform environment roots changed in this run:" >&2
      printf ' - %s\n' "${roots[@]}" >&2
      echo "Using default root for this single-workspace run: ${DEFAULT_TERRAFORM_WORKING_DIRECTORY}" >&2
      echo "For release-grade multi-environment validation, split the change, set --terraform-working-directory, or run a matrix." >&2
      resolved_root="$DEFAULT_TERRAFORM_WORKING_DIRECTORY"
    else
      echo "Multiple Terraform environment roots changed in this run:" >&2
      printf ' - %s\n' "${roots[@]}" >&2
      echo "This resolver supports one HCP workspace per run. Split the change, set --terraform-working-directory, or run a matrix." >&2
      exit 1
    fi
  fi

  if [[ -z "$resolved_root" ]]; then
    resolved_root="${roots[0]}"
  fi
fi

if [[ ! -d "${SOURCE_DIR}/${resolved_root}" ]]; then
  echo "Terraform working directory does not exist: ${resolved_root}" >&2
  exit 1
fi

if ! find "${SOURCE_DIR}/${resolved_root}" -maxdepth 1 -name '*.tf' -print -quit | grep -q .; then
  echo "Terraform working directory has no .tf files: ${resolved_root}" >&2
  exit 1
fi

environment_key="$(environment_from_root "$resolved_root")"
workspace_map_json="${HCP_WORKSPACE_MAP:-{}}"
workspace_map_source="inline HCP_WORKSPACE_MAP"

if [[ -n "$WORKSPACE_MAP_FILE" && -f "${SOURCE_DIR}/${WORKSPACE_MAP_FILE}" ]]; then
  workspace_map_json="$(cat "${SOURCE_DIR}/${WORKSPACE_MAP_FILE}")"
  workspace_map_source="$WORKSPACE_MAP_FILE"
fi

if ! jq -e 'type == "object"' >/dev/null <<< "$workspace_map_json"; then
  echo "HCP workspace map must be valid JSON object syntax." >&2
  echo "Map source: ${workspace_map_source}" >&2
  exit 1
fi

resolved_workspace="$(
  jq -r \
    --arg root "$resolved_root" \
    --arg env "$environment_key" \
    '.[$root] // .[$env] // empty' \
    <<< "$workspace_map_json"
)"

if [[ -z "$resolved_workspace" && -n "$WORKSPACE_PREFIX" ]]; then
  resolved_workspace="${WORKSPACE_PREFIX}-${environment_key}"
fi

if [[ -z "$resolved_workspace" ]]; then
  resolved_workspace="$FALLBACK_WORKSPACE"
fi

if [[ -z "$resolved_workspace" ]]; then
  echo "Unable to resolve HCP workspace for Terraform root '${resolved_root}'." >&2
  echo "Set a workspace map file, HCP_WORKSPACE_MAP, --workspace-prefix, or --fallback-workspace." >&2
  exit 1
fi

jq -n \
  --arg terraform_working_directory "$resolved_root" \
  --arg environment "$environment_key" \
  --arg hcp_workspace "$resolved_workspace" \
  --arg hcp_organization "$HCP_ORGANIZATION" \
  --arg workspace_map_source "$workspace_map_source" \
  '{
    terraform_working_directory: $terraform_working_directory,
    environment: $environment,
    hcp_workspace: $hcp_workspace,
    hcp_organization: $hcp_organization,
    workspace_map_source: $workspace_map_source
  }' > "${OUTPUT_DIR}/workspace-resolution.json"

printf '%s\n' "$resolved_root" > "${OUTPUT_DIR}/terraform-working-directory.txt"
printf '%s\n' "$resolved_workspace" > "${OUTPUT_DIR}/hcp-workspace.txt"

echo "Resolved Terraform root: ${resolved_root}"
echo "Resolved HCP workspace: ${resolved_workspace}"
echo "Workspace map source: ${workspace_map_source}"
echo "##vso[task.setvariable variable=resolvedTerraformWorkingDirectory]${resolved_root}"
echo "##vso[task.setvariable variable=resolvedHcpWorkspace]${resolved_workspace}"
