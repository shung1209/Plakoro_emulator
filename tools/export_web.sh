#!/usr/bin/env bash
set -euo pipefail
GODOT_BIN="${GODOT_BIN:-godot}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
rm -rf web
mkdir -p web
"$GODOT_BIN" --headless --path "$ROOT" --export-release Web web/index.html
touch web/.nojekyll
( cd web && zip -r ../Plakoro_Adventures_Web_itch_github.zip . )
echo "Exported: $ROOT/web/index.html"
echo "Upload ZIP: $ROOT/Plakoro_Adventures_Web_itch_github.zip"
