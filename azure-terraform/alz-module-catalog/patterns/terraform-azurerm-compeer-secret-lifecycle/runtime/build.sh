#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT="${1:?Usage: build.sh /absolute/output/rotation.zip (run inside Linux Python 3.12)}"
python -c 'import sys; assert sys.version_info[:2] == (3, 12), "Build with Python 3.12"'
test "$(uname -s)" = Linux || { echo 'Build inside the Azure Functions Python 3.12 Linux image'; exit 1; }
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
python -m pip install --require-hashes --requirement "$ROOT/requirements.lock.txt" --target "$STAGE/.python_packages/lib/site-packages" --disable-pip-version-check
cp "$ROOT/host.json" "$ROOT/function_app.py" "$ROOT/rotation.py" "$ROOT/ports.py" "$STAGE/"
(cd "$STAGE" && zip -qr "$OUT" .)
