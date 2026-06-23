#!/usr/bin/env bash
# validate-terraform-root.sh
#
# Purpose:
#   Local pre-push validation for deployable Terraform root repositories.
#   Designed for HCP Terraform controlled state/CI.
#
# Safe default behavior:
#   - Runs terraform init -backend=false.
#   - Runs validate/lint/scans.
#   - Does not apply.
#   - Does not touch HCP remote state unless --hcp-speculative-plan is explicitly used.
#
# Typical usage:
#   ./validate-terraform-root.sh
#   ./validate-terraform-root.sh --path workload-landing-zone/np1/app1
#   ./validate-terraform-root.sh --discover --strict
#   ./validate-terraform-root.sh --path . --safe-local-plan
#   ./validate-terraform-root.sh --path . --hcp-speculative-plan

set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"
TARGET_PATH="."
DISCOVER=false
STRICT=false
SAFE_LOCAL_PLAN=false
HCP_SPECULATIVE_PLAN=false
SKIP_TFLINT=false
SKIP_CHECKOV=false
SKIP_GITLEAKS=false
SKIP_TFSEC=false
SKIP_MODULE_SOURCE_CHECK=false
SKIP_REQUIRED_FILE_CHECK=false
UPGRADE=false
ARTIFACT_DIR=""
FAILURES=0
WARNINGS=0

usage() {
  cat <<'EOF'
Usage:
  validate-terraform-root.sh [options]

Options:
  --path <dir>              Terraform root directory to validate. Default: current directory.
  --discover                Discover and validate deployable roots under the path.
  --strict                  Fail on warnings such as missing README, missing backend/cloud config, local module source, or missing required files.
  --safe-local-plan         Run terraform plan -refresh=false after init -backend=false. Useful but may fail when required variables/data sources are unavailable locally.
  --hcp-speculative-plan    Run terraform init with real backend/cloud config and terraform plan. This can trigger an HCP speculative plan. Never runs apply.
  --upgrade                 Run terraform init -upgrade. Disabled by default.
  --skip-tflint             Skip TFLint even if installed.
  --skip-checkov            Skip Checkov even if installed.
  --skip-gitleaks           Skip Gitleaks even if installed.
  --skip-tfsec              Skip tfsec even if installed.
  --skip-module-source-check Skip local/pinned module source hygiene checks.
  --skip-required-file-check Skip root file contract checks.
  --artifact-dir <dir>      Directory for logs. Default: <root>/.local-validation/<timestamp>.
  -h, --help                Show this help text.

Recommended safe pre-push command:
  ./validate-terraform-root.sh --discover --strict

Recommended deeper local check:
  ./validate-terraform-root.sh --discover --strict --safe-local-plan

HCP speculative plan:
  Use only when your root has valid HCP cloud/backend configuration and you are authenticated with terraform login.
  This script never runs terraform apply.

Notes:
  --safe-local-plan runs from a temporary copy with Terraform cloud blocks removed so HCP-backed roots can be planned locally
  with -backend=false. If terraform.tfvars or terraform.tfvars.example exists, it is used automatically. When a root declares
  subscription_id or tenant_id variables, ARM_SUBSCRIPTION_ID/ARM_TENANT_ID are used when present; otherwise the active
  Azure CLI account is used when available.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --path) TARGET_PATH="${2:?Missing value for --path}"; shift 2 ;;
    --discover) DISCOVER=true; shift ;;
    --strict) STRICT=true; shift ;;
    --safe-local-plan) SAFE_LOCAL_PLAN=true; shift ;;
    --hcp-speculative-plan) HCP_SPECULATIVE_PLAN=true; shift ;;
    --upgrade) UPGRADE=true; shift ;;
    --skip-tflint) SKIP_TFLINT=true; shift ;;
    --skip-checkov) SKIP_CHECKOV=true; shift ;;
    --skip-gitleaks) SKIP_GITLEAKS=true; shift ;;
    --skip-tfsec) SKIP_TFSEC=true; shift ;;
    --skip-module-source-check) SKIP_MODULE_SOURCE_CHECK=true; shift ;;
    --skip-required-file-check) SKIP_REQUIRED_FILE_CHECK=true; shift ;;
    --artifact-dir) ARTIFACT_DIR="${2:?Missing value for --artifact-dir}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

TARGET_PATH="$(cd "$TARGET_PATH" && pwd -P)"
if [[ -z "$ARTIFACT_DIR" ]]; then
  ARTIFACT_DIR="$TARGET_PATH/.local-validation/$(date +%Y%m%d-%H%M%S)"
fi
mkdir -p "$ARTIFACT_DIR"

LOG_FILE="$ARTIFACT_DIR/root-validation.log"
touch "$LOG_FILE"

if [[ -t 1 ]]; then
  RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'; BLUE=$'\033[0;34m'; NC=$'\033[0m'
else
  RED=""; GREEN=""; YELLOW=""; BLUE=""; NC=""
fi

log()  { echo "${BLUE}[$(date +%H:%M:%S)]${NC} $*" | tee -a "$LOG_FILE"; }
pass() { echo "${GREEN}PASS:${NC} $*" | tee -a "$LOG_FILE"; }
warn() { WARNINGS=$((WARNINGS+1)); echo "${YELLOW}WARN:${NC} $*" | tee -a "$LOG_FILE"; }
fail() { FAILURES=$((FAILURES+1)); echo "${RED}FAIL:${NC} $*" | tee -a "$LOG_FILE"; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1
}

run_required() {
  local name="$1"; shift
  log "Running: $name"
  if "$@" >>"$LOG_FILE" 2>&1; then
    pass "$name"
  else
    fail "$name"
  fi
}

run_optional() {
  local name="$1"; shift
  log "Running optional check: $name"
  if "$@" >>"$LOG_FILE" 2>&1; then
    pass "$name"
  else
    fail "$name"
  fi
}

strict_warn() {
  local message="$1"
  if [[ "$STRICT" == "true" ]]; then
    fail "$message"
  else
    warn "$message"
  fi
}

contains_tf_files() {
  local dir="$1"
  find "$dir" -maxdepth 1 -type f -name '*.tf' | grep -q .
}

has_backend_or_cloud_config() {
  local dir="$1"
  grep -R --include='*.tf' -nE 'backend[[:space:]]+"|cloud[[:space:]]*\{' "$dir" \
    --exclude-dir=.terraform --exclude-dir=.git >/dev/null 2>&1
}

terraform_init_backend_false() {
  local dir="$1"
  if [[ "$UPGRADE" == "true" ]]; then
    terraform -chdir="$dir" init -backend=false -input=false -upgrade
  else
    terraform -chdir="$dir" init -backend=false -input=false
  fi
}

terraform_init_real_backend() {
  local dir="$1"
  if [[ "$UPGRADE" == "true" ]]; then
    terraform -chdir="$dir" init -input=false -upgrade
  else
    terraform -chdir="$dir" init -input=false
  fi
}

discover_roots() {
  local base="$1"

  # A deployable root is any directory containing .tf files, excluding common non-root dirs.
  # We exclude modules/patterns/examples/tests because those are handled by module or pattern validation.
  find "$base" \
    \( -path '*/.terraform' -o -path '*/.git' -o -path '*/scripts' -o -path '*/scripts/*' -o -path '*/modules' -o -path '*/modules/*' -o -path '*/patterns' -o -path '*/patterns/*' -o -path '*/examples' -o -path '*/examples/*' -o -path '*/tests' -o -path '*/tests/*' \) -prune \
    -o -type f -name '*.tf' -print \
    | xargs -r -n1 dirname \
    | sort -u
}

has_readme_context() {
  local dir="$1"

  [[ -f "$dir/README.md" ]] ||
    [[ -f "$(dirname "$dir")/README.md" ]] ||
    [[ -f "$(dirname "$(dirname "$dir")")/README.md" ]]
}

check_required_files_for_root() {
  local dir="$1"

  if [[ "$SKIP_REQUIRED_FILE_CHECK" == "true" ]]; then
    warn "Skipping required file check for $dir"
    return
  fi

  log "Checking deployable root file contract: ${dir#$TARGET_PATH/}"

  [[ -f "$dir/versions.tf" || -f "$dir/terraform.tf" ]] || strict_warn "$dir: versions.tf or terraform.tf not found. Root should pin Terraform and provider constraints."

  if [[ -f "$dir/providers.tf" || -f "$dir/provider.tf" ]] ||
    grep -R --include='*.tf' -nE 'provider[[:space:]]+"' "$dir" --exclude-dir=.terraform --exclude-dir=.git >/dev/null 2>&1; then
    pass "$dir: provider configuration detected"
  else
    strict_warn "$dir: providers.tf/provider.tf not found. Root should own provider/subscription context."
  fi
  [[ -f "$dir/variables.tf" ]] || strict_warn "$dir: variables.tf not found. Root should expose explicit deployment inputs."
  [[ -f "$dir/outputs.tf" ]] || warn "$dir: outputs.tf not found. This may be acceptable, but shared IDs should be explicit where needed."
  if has_readme_context "$dir"; then
    pass "$dir: README context detected"
  else
    strict_warn "$dir: README.md not found. Root should document workspace mapping, variables, policy behavior, exceptions, and support path."
  fi

  if has_backend_or_cloud_config "$dir"; then
    pass "$dir: backend/cloud workspace configuration detected"
  else
    strict_warn "$dir: no backend/cloud workspace configuration detected. Deployable roots should normally map to HCP Terraform workspace/state."
  fi

  if ! grep -R --include='*.tf' -nE 'required_version|required_providers' "$dir" --exclude-dir=.terraform --exclude-dir=.git >/dev/null 2>&1; then
    strict_warn "$dir: no required_version or required_providers found."
  fi
}

check_module_sources_for_root() {
  local dir="$1"

  if [[ "$SKIP_MODULE_SOURCE_CHECK" == "true" ]]; then
    warn "Skipping module source hygiene check for $dir"
    return
  fi

  log "Checking module source hygiene: ${dir#$TARGET_PATH/}"

  local local_sources
  local_sources="$(grep -R --include='*.tf' -nE 'source[[:space:]]*=[[:space:]]*"(\.\./|\.\/|/)' "$dir" \
    --exclude-dir=.terraform --exclude-dir=.git || true)"

  if [[ -n "$local_sources" ]]; then
    echo "$local_sources" >> "$LOG_FILE"
    strict_warn "$dir: local module source paths found. For governed deployable roots, prefer pinned HCP registry modules unless this is an approved temporary exception."
  else
    pass "$dir: no local module sources detected"
  fi

  local unpinned_registry_sources
  # Heuristic: registry sources should usually have a version attribute in the same module block.
  # This is intentionally conservative and may require manual review for complex formatting.
  unpinned_registry_sources="$(awk '
    BEGIN { inmod=0; modline=""; has_source=0; has_version=0; source_line="" }
    /^[[:space:]]*module[[:space:]]+"/ { inmod=1; modline=FILENAME ":" FNR; has_source=0; has_version=0; source_line="" }
    inmod && /source[[:space:]]*=/ { has_source=1; source_line=FILENAME ":" FNR ":" $0 }
    inmod && /version[[:space:]]*=/ { has_version=1 }
    inmod && /^[[:space:]]*}/ {
      if (has_source && !has_version && source_line !~ /(\.\.\/|\.\/|git::|\/)/) print source_line
      inmod=0
    }
  ' "$dir"/*.tf 2>/dev/null || true)"

  if [[ -n "$unpinned_registry_sources" ]]; then
    echo "$unpinned_registry_sources" >> "$LOG_FILE"
    strict_warn "$dir: possible unpinned registry module source found. Add module version constraints."
  else
    pass "$dir: no obvious unpinned registry modules detected"
  fi
}

check_risky_root_patterns() {
  local dir="$1"
  log "Checking risky deployment patterns: ${dir#$TARGET_PATH/}"

  local risky
  risky="$(grep -R --include='*.tf' -nE '(ignore_changes[[:space:]]*=|target_resource_id[[:space:]]*=|public_network_access_enabled[[:space:]]*=[[:space:]]*true|allow_blob_public_access[[:space:]]*=[[:space:]]*true|shared_access_key_enabled[[:space:]]*=[[:space:]]*true|skip_provider_registration|skip_credentials_validation)' "$dir" \
    --exclude-dir=.terraform --exclude-dir=.git || true)"

  if [[ -n "$risky" ]]; then
    echo "$risky" >> "$LOG_FILE"
    warn "$dir: risky patterns detected. Review lifecycle ignores, public access, storage shared keys, provider skips, and diagnostic target IDs."
  else
    pass "$dir: no high-level risky patterns detected"
  fi
}

check_tfvars_secret_risk() {
  local dir="$1"
  log "Checking tfvars and secret-like values: ${dir#$TARGET_PATH/}"

  local secret_hits
  secret_hits="$(grep -R -nEi '(password|client_secret|clientsecret|token|access_key|private_key|secret_value)[[:space:]]*=[[:space:]]*"[^"]+"' "$dir" \
    --include='*.tfvars' --include='*.tfvars.example' --include='*.auto.tfvars' \
    --exclude-dir=.terraform --exclude-dir=.git || true)"

  if [[ -n "$secret_hits" ]]; then
    echo "$secret_hits" >> "$LOG_FILE"
    fail "$dir: possible committed secret-like Terraform variable values found. Use HCP sensitive variables or approved secret references."
  else
    pass "$dir: no obvious committed Terraform secrets detected"
  fi
}

strip_cloud_blocks_for_local_plan() {
  local dir="$1"

  find "$dir" -maxdepth 1 -type f -name '*.tf' -print0 |
    while IFS= read -r -d '' tf_file; do
      perl -0pi -e 's/\n[ \t]*cloud[ \t]*\{[ \t\r\n]*(?:organization[ \t]*=[ \t]*"[^"]+"[ \t\r\n]*)?(?:workspaces[ \t]*\{[^{}]*\}[ \t\r\n]*)?\}//sg' "$tf_file"
    done
}

rewrite_local_module_sources_for_local_plan() {
  local rewrite_base="$1"
  local tf_file
  local source_base

  find "$rewrite_base" -type f -name '*.tf' ! -path '*/.terraform/*' ! -path '*/.git/*' -print0 |
    while IFS= read -r -d '' tf_file; do
      source_base="$(cd "$(dirname "$tf_file")" && pwd)"
      SOURCE_BASE="$source_base" perl -MFile::Spec -MCwd=abs_path -0pi -e '
        s/source(\s*=\s*)"((?:\.\.\/|\.\/)[^"]+)"/
          my $resolved = abs_path(File::Spec->catdir($ENV{SOURCE_BASE}, $2)) || File::Spec->rel2abs($2, $ENV{SOURCE_BASE});
          "source$1\"$resolved\"";
        /gex
      ' "$tf_file"
    done
}

active_az_account_value() {
  local query="$1"

  if require_cmd az; then
    az account show --query "$query" -o tsv 2>/dev/null || true
  fi
}

terraform_safe_local_plan() {
  local dir="$1"
  local tmp_dir
  local tmp_root
  local repo_root
  local tmp_repo
  local relative_root
  local plan_args=("-refresh=false" "-input=false" "-no-color")

  dir="$(cd "$dir" && pwd -P)"
  tmp_dir="$(mktemp -d)"

  repo_root="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || true)"
  if [[ -n "$repo_root" && "$dir" == "$repo_root"* ]]; then
    tmp_repo="$tmp_dir/repo"
    mkdir -p "$tmp_repo"

    if require_cmd rsync; then
      rsync -a --exclude='.terraform' --exclude='.git' --exclude='.local-validation' "$repo_root/" "$tmp_repo/"
    else
      cp -R "$repo_root/." "$tmp_repo/"
      find "$tmp_repo" -type d \( -name '.terraform' -o -name '.git' -o -name '.local-validation' \) -prune -exec rm -rf {} +
    fi

    relative_root="${dir#$repo_root}"
    relative_root="${relative_root#/}"
    if [[ -n "$relative_root" ]]; then
      tmp_root="$tmp_repo/$relative_root"
    else
      tmp_root="$tmp_repo"
    fi

    rewrite_local_module_sources_for_local_plan "$tmp_repo"
  else
    tmp_root="$tmp_dir/root"
    mkdir -p "$tmp_root"
    cp -R "$dir/." "$tmp_root/"
    rewrite_local_module_sources_for_local_plan "$tmp_root"
  fi

  strip_cloud_blocks_for_local_plan "$tmp_root"

  terraform_init_backend_false "$tmp_root" >/dev/null

  if [[ -f "$tmp_root/terraform.tfvars" ]]; then
    plan_args+=("-var-file=terraform.tfvars")
  elif [[ -f "$tmp_root/terraform.tfvars.example" ]]; then
    plan_args+=("-var-file=terraform.tfvars.example")
  fi

  local subscription_id="${ARM_SUBSCRIPTION_ID:-}"
  local tenant_id="${ARM_TENANT_ID:-}"

  if [[ -z "$subscription_id" ]]; then
    subscription_id="$(active_az_account_value id)"
  fi
  if [[ -z "$tenant_id" ]]; then
    tenant_id="$(active_az_account_value tenantId)"
  fi

  if [[ -n "$subscription_id" ]] && grep -R --include='*.tf' -n 'variable[[:space:]]*"subscription_id"' "$tmp_root" >/dev/null 2>&1; then
    plan_args+=("-var=subscription_id=$subscription_id")
  fi
  if [[ -n "$tenant_id" ]] && grep -R --include='*.tf' -n 'variable[[:space:]]*"tenant_id"' "$tmp_root" >/dev/null 2>&1; then
    plan_args+=("-var=tenant_id=$tenant_id")
  fi

  terraform -chdir="$tmp_root" plan "${plan_args[@]}"
  local rc=$?
  rm -rf "$tmp_dir"
  return "$rc"
}

run_tflint_for_root() {
  local dir="$1"
  if [[ "$SKIP_TFLINT" == "true" ]]; then
    warn "Skipping TFLint for $dir by request"
    return
  fi

  if require_cmd tflint; then
    run_optional "tflint --init for ${dir#$TARGET_PATH/}" tflint --chdir "$dir" --init
    run_optional "tflint for ${dir#$TARGET_PATH/}" tflint --chdir "$dir"
  else
    warn "tflint not installed. Skipping for $dir."
  fi
}

run_checkov_for_root() {
  local dir="$1"
  if [[ "$SKIP_CHECKOV" == "true" ]]; then
    warn "Skipping Checkov for $dir by request"
    return
  fi

  if require_cmd checkov; then
    run_optional "checkov for ${dir#$TARGET_PATH/}" checkov -d "$dir" --framework terraform --quiet --download-external-modules true
  else
    warn "checkov not installed. Skipping for $dir."
  fi
}

run_tfsec_for_root() {
  local dir="$1"
  if [[ "$SKIP_TFSEC" == "true" ]]; then
    warn "Skipping tfsec for $dir by request"
    return
  fi

  if require_cmd tfsec; then
    run_optional "tfsec for ${dir#$TARGET_PATH/}" tfsec "$dir" --no-color
  else
    warn "tfsec not installed. Skipping for $dir."
  fi
}

run_gitleaks_for_base() {
  if [[ "$SKIP_GITLEAKS" == "true" ]]; then
    warn "Skipping Gitleaks by request"
    return
  fi

  if require_cmd gitleaks; then
    run_optional "gitleaks detect" gitleaks detect --source "$TARGET_PATH" --no-git --redact --verbose
  else
    warn "gitleaks not installed. Skipping."
  fi
}

validate_one_root() {
  local dir="$1"

  if ! contains_tf_files "$dir"; then
    warn "$dir has no first-level .tf files. Skipping."
    return
  fi

  log "------------------------------------------------------------"
  log "Validating Terraform root: $dir"
  log "------------------------------------------------------------"

  check_required_files_for_root "$dir"
  check_module_sources_for_root "$dir"
  check_risky_root_patterns "$dir"
  check_tfvars_secret_risk "$dir"

  run_required "terraform fmt -check -diff for ${dir#$TARGET_PATH/}" terraform -chdir="$dir" fmt -check -diff
  run_required "terraform init -backend=false for ${dir#$TARGET_PATH/}" terraform_init_backend_false "$dir"
  run_required "terraform validate for ${dir#$TARGET_PATH/}" terraform -chdir="$dir" validate -no-color

  run_tflint_for_root "$dir"
  run_checkov_for_root "$dir"
  run_tfsec_for_root "$dir"

  if [[ "$SAFE_LOCAL_PLAN" == "true" ]]; then
    run_required "terraform plan -refresh=false with backend disabled for ${dir#$TARGET_PATH/}" terraform_safe_local_plan "$dir"
  fi

  if [[ "$HCP_SPECULATIVE_PLAN" == "true" ]]; then
    if has_backend_or_cloud_config "$dir"; then
      log "HCP speculative plan requested for $dir. This will initialize the real backend/cloud configuration but will not apply."
      run_required "terraform init with real backend for ${dir#$TARGET_PATH/}" terraform_init_real_backend "$dir"
      run_required "terraform plan speculative for ${dir#$TARGET_PATH/}" terraform -chdir="$dir" plan -input=false -no-color
    else
      fail "$dir: --hcp-speculative-plan requested, but no backend/cloud config was detected."
    fi
  fi
}

print_summary() {
  echo "" | tee -a "$LOG_FILE"
  echo "Validation summary" | tee -a "$LOG_FILE"
  echo "------------------" | tee -a "$LOG_FILE"
  echo "Target path : $TARGET_PATH" | tee -a "$LOG_FILE"
  echo "Artifacts   : $ARTIFACT_DIR" | tee -a "$LOG_FILE"
  echo "Warnings    : $WARNINGS" | tee -a "$LOG_FILE"
  echo "Failures    : $FAILURES" | tee -a "$LOG_FILE"

  if [[ "$FAILURES" -gt 0 ]]; then
    echo "${RED}Result      : FAILED${NC}" | tee -a "$LOG_FILE"
    exit 1
  fi

  echo "${GREEN}Result      : PASSED${NC}" | tee -a "$LOG_FILE"
}

main() {
  require_cmd terraform || { echo "terraform is required but not installed"; exit 1; }

  log "Starting Terraform deployable-root validation"
  log "Base path: $TARGET_PATH"

  terraform version >> "$LOG_FILE" 2>&1 || true

  # Repository-wide formatting check first. This catches formatting in roots, locals, docs examples, etc.
  run_required "terraform fmt -recursive -check -diff for repository/path" terraform -chdir="$TARGET_PATH" fmt -recursive -check -diff

  run_gitleaks_for_base

  if [[ "$DISCOVER" == "true" ]]; then
    roots=()
    while IFS= read -r discovered_root; do
      roots+=("$discovered_root")
    done < <(discover_roots "$TARGET_PATH")

    if [[ "${#roots[@]}" -eq 0 ]]; then
      fail "No deployable Terraform roots found under $TARGET_PATH"
    else
      log "Discovered ${#roots[@]} Terraform root(s)"
      for root in "${roots[@]}"; do
        validate_one_root "$root"
      done
    fi
  else
    validate_one_root "$TARGET_PATH"
  fi

  print_summary
}

main "$@"
