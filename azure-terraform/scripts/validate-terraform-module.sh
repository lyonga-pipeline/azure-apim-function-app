#!/usr/bin/env bash
# validate-terraform-module.sh
#
# Purpose:
#   Local pre-push validation for reusable Terraform modules.
#   Safe by default: uses terraform init -backend=false and never runs apply.
#
# Typical usage:
#   ./validate-terraform-module.sh
#   ./validate-terraform-module.sh --path modules/storage-account
#   ./validate-terraform-module.sh --path . --strict --plan-examples
#
# Optional tools used when installed:
#   tflint, checkov, gitleaks, terraform-docs

set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$SCRIPT_NAME"
TARGET_PATH="."
DISCOVER=false
STRICT=false
PLAN_EXAMPLES=false
SKIP_TFLINT=false
SKIP_CHECKOV=false
SKIP_GITLEAKS=false
SKIP_TESTS=false
SKIP_EXAMPLES=false
SKIP_DOCS=false
UPGRADE=false
ARTIFACT_DIR=""
FAILURES=0
WARNINGS=0

usage() {
  cat <<'EOF'
Usage:
  validate-terraform-module.sh [options]

Options:
  --path <dir>          Module directory to validate. Default: current directory.
  --discover            Discover and validate module directories under the path. If the path has a modules/ child, that child is used.
  --strict              Fail on warnings such as missing README, missing examples, local module sources, or missing version constraints.
  --plan-examples       Run terraform plan -refresh=false for each example after validate. Disabled by default.
  --upgrade             Run terraform init -upgrade -backend=false. Disabled by default to avoid surprise lock/provider changes.
  --skip-tflint         Skip TFLint even if installed.
  --skip-checkov        Skip Checkov even if installed.
  --skip-gitleaks       Skip Gitleaks even if installed.
  --skip-tests          Skip terraform test.
  --skip-examples       Skip examples validation.
  --skip-docs           Skip terraform-docs README check.
  --artifact-dir <dir>  Directory for logs. Default: <module>/.local-validation/<timestamp>.
  -h, --help            Show this help text.

Exit behavior:
  0 = all required checks passed
  1 = at least one required check failed, or strict-mode warning failed
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --path) TARGET_PATH="${2:?Missing value for --path}"; shift 2 ;;
    --discover) DISCOVER=true; shift ;;
    --strict) STRICT=true; shift ;;
    --plan-examples) PLAN_EXAMPLES=true; shift ;;
    --upgrade) UPGRADE=true; shift ;;
    --skip-tflint) SKIP_TFLINT=true; shift ;;
    --skip-checkov) SKIP_CHECKOV=true; shift ;;
    --skip-gitleaks) SKIP_GITLEAKS=true; shift ;;
    --skip-tests) SKIP_TESTS=true; shift ;;
    --skip-examples) SKIP_EXAMPLES=true; shift ;;
    --skip-docs) SKIP_DOCS=true; shift ;;
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

LOG_FILE="$ARTIFACT_DIR/module-validation.log"
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
    strict_warn "$name failed. Review $LOG_FILE for details."
  fi
}

require_cmd() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    return 0
  fi
  return 1
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

terraform_init_backend_false() {
  local dir="$1"
  if [[ "$UPGRADE" == "true" ]]; then
    terraform -chdir="$dir" init -backend=false -input=false -upgrade
  else
    terraform -chdir="$dir" init -backend=false -input=false
  fi
}

check_required_files() {
  log "Checking module file contract"

  contains_tf_files "$TARGET_PATH" || fail "No .tf files found in module path: $TARGET_PATH"

  [[ -f "$TARGET_PATH/main.tf" ]] || strict_warn "main.tf not found. Module should normally have main.tf."
  [[ -f "$TARGET_PATH/variables.tf" ]] || strict_warn "variables.tf not found. Module should expose a stable input contract."
  [[ -f "$TARGET_PATH/outputs.tf" ]] || strict_warn "outputs.tf not found. Module should expose explicit outputs where needed."
  [[ -f "$TARGET_PATH/versions.tf" ]] || strict_warn "versions.tf not found. Pin Terraform and provider constraints."
  [[ -f "$TARGET_PATH/README.md" ]] || strict_warn "README.md not found. Certified modules should document usage, inputs, outputs, examples, and upgrade notes."

  if ! grep -R --include='*.tf' -nE 'required_version|required_providers' "$TARGET_PATH" >/dev/null 2>&1; then
    strict_warn "No required_version or required_providers found. Add provider/Terraform constraints."
  fi

  if [[ ! -d "$TARGET_PATH/examples" ]]; then
    strict_warn "examples/ directory not found. Modules should include at least examples/basic."
  fi

  if [[ ! -d "$TARGET_PATH/tests" ]]; then
    strict_warn "tests/ directory not found. Add .tftest.hcl files for module assertions."
  fi
}

check_no_deployable_backend_in_module() {
  log "Checking module does not define backend/cloud workspace configuration"

  if grep -R --include='*.tf' -nE 'backend[[:space:]]+"|cloud[[:space:]]*\{' "$TARGET_PATH" \
    --exclude-dir=.terraform --exclude-dir=.git >/dev/null 2>&1; then
    strict_warn "Backend/cloud workspace configuration found in module tree. Reusable modules should not own state/backend configuration."
  else
    pass "No backend/cloud workspace config detected in module"
  fi
}

check_module_source_hygiene() {
  log "Checking module source hygiene"

  local bad_sources
  bad_sources="$(grep -R --include='*.tf' -nE 'source[[:space:]]*=[[:space:]]*"(\.\./|\.\/|/)' "$TARGET_PATH" \
    --exclude-dir=.terraform --exclude-dir=.git --exclude-dir=examples --exclude-dir=tests || true)"

  if [[ -n "$bad_sources" ]]; then
    echo "$bad_sources" >> "$LOG_FILE"
    strict_warn "Local module source paths found outside examples/tests. Prefer pinned HCP private registry modules or explicit companion module composition."
  else
    pass "No local module source paths found outside examples/tests"
  fi
}

check_variable_validation_presence() {
  log "Checking for input validation blocks"

  if grep -R --include='*.tf' -n 'validation[[:space:]]*{' "$TARGET_PATH" --exclude-dir=.terraform --exclude-dir=.git >/dev/null 2>&1; then
    pass "Variable validation blocks detected"
  else
    strict_warn "No variable validation blocks detected. Add validations for environment, naming, region, SKU, public access, and required tags."
  fi
}

check_sensitive_patterns() {
  log "Checking for risky Terraform patterns"

  local risky
  risky="$(grep -R --include='*.tf' -nE '(ignore_changes[[:space:]]*=|prevent_destroy[[:space:]]*=|skip_provider_registration|allow_nested_items_to_be_public[[:space:]]*=[[:space:]]*true|shared_access_key_enabled[[:space:]]*=[[:space:]]*true|public_network_access_enabled[[:space:]]*=[[:space:]]*true)' "$TARGET_PATH" \
    --exclude-dir=.terraform --exclude-dir=.git || true)"

  if [[ -n "$risky" ]]; then
    echo "$risky" >> "$LOG_FILE"
    warn "Risky patterns detected. Review ignore_changes, public access flags, provider skips, and lifecycle controls."
  else
    pass "No high-level risky patterns detected"
  fi
}

validate_examples() {
  if [[ "$SKIP_EXAMPLES" == "true" ]]; then
    warn "Skipping example validation by request"
    return
  fi

  if [[ ! -d "$TARGET_PATH/examples" ]]; then
    strict_warn "No examples/ directory to validate"
    return
  fi

  local found=false
  while IFS= read -r -d '' example_dir; do
    contains_tf_files "$example_dir" || continue
    found=true
    log "Validating example: ${example_dir#$TARGET_PATH/}"

    run_required "terraform init -backend=false for ${example_dir#$TARGET_PATH/}" terraform_init_backend_false "$example_dir"
    run_required "terraform validate for ${example_dir#$TARGET_PATH/}" terraform -chdir="$example_dir" validate -no-color

    if [[ "$PLAN_EXAMPLES" == "true" ]]; then
      run_required "terraform plan -refresh=false for ${example_dir#$TARGET_PATH/}" terraform -chdir="$example_dir" plan -refresh=false -input=false -no-color
    fi
  done < <(find "$TARGET_PATH/examples" -mindepth 1 -maxdepth 1 -type d -print0)

  if [[ "$found" == "false" ]]; then
    strict_warn "examples/ exists but no first-level example directories with .tf files were found"
  fi
}

check_terraform_docs() {
  if [[ "$SKIP_DOCS" == "true" ]]; then
    warn "Skipping terraform-docs check by request"
    return
  fi

  if require_cmd terraform-docs; then
    # Non-destructive check. It generates markdown to artifact file so it does not rewrite README.
    run_optional "terraform-docs generation" terraform-docs markdown table "$TARGET_PATH" --output-file "$ARTIFACT_DIR/terraform-docs.generated.md" --output-mode inject
  else
    warn "terraform-docs not installed. Skipping README generation check."
  fi
}

discover_modules() {
  local base="$1"

  if [[ -d "$base/modules" ]]; then
    base="$base/modules"
  fi

  find "$base" -mindepth 1 -maxdepth 1 -type d \
    ! -name '.terraform' \
    ! -name '.git' \
    ! -name '.local-validation' \
    -print0 |
    while IFS= read -r -d '' module_dir; do
      contains_tf_files "$module_dir" && printf '%s\n' "$module_dir"
    done |
    sort
}

validate_discovered_modules() {
  local modules=()
  local discovered_module

  while IFS= read -r discovered_module; do
    modules+=("$discovered_module")
  done < <(discover_modules "$TARGET_PATH")

  if [[ "${#modules[@]}" -eq 0 ]]; then
    fail "No Terraform module directories found under $TARGET_PATH"
    print_summary
  fi

  log "Discovered ${#modules[@]} Terraform module(s)"

  local child_args=()
  [[ "$STRICT" == "true" ]] && child_args+=(--strict)
  [[ "$PLAN_EXAMPLES" == "true" ]] && child_args+=(--plan-examples)
  [[ "$UPGRADE" == "true" ]] && child_args+=(--upgrade)
  [[ "$SKIP_TFLINT" == "true" ]] && child_args+=(--skip-tflint)
  [[ "$SKIP_CHECKOV" == "true" ]] && child_args+=(--skip-checkov)
  [[ "$SKIP_GITLEAKS" == "true" ]] && child_args+=(--skip-gitleaks)
  [[ "$SKIP_TESTS" == "true" ]] && child_args+=(--skip-tests)
  [[ "$SKIP_EXAMPLES" == "true" ]] && child_args+=(--skip-examples)
  [[ "$SKIP_DOCS" == "true" ]] && child_args+=(--skip-docs)

  local module_dir
  for module_dir in "${modules[@]}"; do
    log "Validating discovered module: ${module_dir#$TARGET_PATH/}"
    if "$SCRIPT_PATH" --path "$module_dir" --artifact-dir "$ARTIFACT_DIR/$(basename "$module_dir")" "${child_args[@]}" >>"$LOG_FILE" 2>&1; then
      pass "module ${module_dir#$TARGET_PATH/}"
    else
      fail "module ${module_dir#$TARGET_PATH/}"
    fi
  done
}

run_tflint() {
  if [[ "$SKIP_TFLINT" == "true" ]]; then
    warn "Skipping TFLint by request"
    return
  fi

  if require_cmd tflint; then
    run_optional "tflint --init" tflint --chdir "$TARGET_PATH" --init
    run_optional "tflint --recursive" tflint --chdir "$TARGET_PATH" --recursive
  else
    warn "tflint not installed. Skipping."
  fi
}

run_checkov() {
  if [[ "$SKIP_CHECKOV" == "true" ]]; then
    warn "Skipping Checkov by request"
    return
  fi

  if require_cmd checkov; then
    run_optional "checkov Terraform scan" checkov -d "$TARGET_PATH" --framework terraform --quiet --download-external-modules true
  else
    warn "checkov not installed. Skipping."
  fi
}

run_gitleaks() {
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

run_terraform_tests() {
  if [[ "$SKIP_TESTS" == "true" ]]; then
    warn "Skipping terraform test by request"
    return
  fi

  if find "$TARGET_PATH" -maxdepth 3 \( -name '*.tftest.hcl' -o -name '*.tftest.json' \) | grep -q .; then
    run_required "terraform test" terraform -chdir="$TARGET_PATH" test -no-color
  else
    strict_warn "No Terraform test files found. Add tests/*.tftest.hcl for module certification."
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
  log "Starting Terraform module validation"
  log "Module path: $TARGET_PATH"

  require_cmd terraform || { echo "terraform is required but not installed"; exit 1; }

  terraform version >> "$LOG_FILE" 2>&1 || true

  if [[ "$DISCOVER" == "true" ]]; then
    validate_discovered_modules
    print_summary
    return 0
  fi

  check_required_files
  check_no_deployable_backend_in_module
  check_module_source_hygiene
  check_variable_validation_presence
  check_sensitive_patterns

  run_required "terraform fmt -recursive -check -diff" terraform -chdir="$TARGET_PATH" fmt -recursive -check -diff
  run_required "terraform init -backend=false" terraform_init_backend_false "$TARGET_PATH"
  run_required "terraform validate" terraform -chdir="$TARGET_PATH" validate -no-color

  run_tflint
  run_checkov
  run_gitleaks
  run_terraform_tests
  validate_examples
  check_terraform_docs

  print_summary
}

main "$@"
