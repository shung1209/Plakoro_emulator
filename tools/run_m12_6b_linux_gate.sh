#!/usr/bin/env bash
set -euo pipefail

EXE="${1:-./build/linux/Plakorov2.x86_64}"

if [[ ! -x "$EXE" ]]; then
  echo "Executable not found or not executable: $EXE" >&2
  echo "Usage: $0 [path/to/Plakorov2.x86_64]" >&2
  exit 2
fi

echo "[12.6b] Linux phase 1/2: write persistence probe"
"$EXE" -- --m12.6b-gate --phase=write

echo "[12.6b] Linux phase 2/2: restart and verify persistence probe"
"$EXE" -- --m12.6b-gate --phase=verify

echo "[12.6b] Linux export gate PASSED"
