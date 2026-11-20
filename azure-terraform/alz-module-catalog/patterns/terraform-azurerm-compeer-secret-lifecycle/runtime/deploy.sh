#!/usr/bin/env bash
set -euo pipefail
: "${ROTATION_RG:?Missing resource group}"
: "${ROTATION_APP:?Missing Function App}"
: "${ROTATION_ZIP:?Missing package}"
: "${ROTATION_SUBSCRIPTION:?Missing target subscription}"

az webapp deploy --subscription "$ROTATION_SUBSCRIPTION" \
  --resource-group "$ROTATION_RG" --name "$ROTATION_APP" --src-path "$ROTATION_ZIP" \
  --type zip --clean true --restart true --async false --only-show-errors --output none

# Successful ZIP upload alone does not prove that the Functions worker indexed.
for attempt in $(seq 1 18); do
  INDEXED="$(az functionapp function list --subscription "$ROTATION_SUBSCRIPTION" \
    --resource-group "$ROTATION_RG" --name "$ROTATION_APP" --query '[].name' \
    --only-show-errors --output json)"
  if python3 - "$INDEXED" <<'PY'
import json
import sys
names = {name.rsplit('/', 1)[-1] for name in json.loads(sys.argv[1])}
sys.exit(0 if {'reconcile', 'rotate', 'lifecycle_event', 'request_rotation'} <= names else 1)
PY
  then
    exit 0
  fi
  sleep 10
done
echo 'Function indexing did not complete. Check private DNS, host identity, storage, package and runtime logs.' >&2
exit 1
