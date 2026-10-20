#!/usr/bin/env bash
# The four checks. Everything must pass before Studio sees the code.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
echo "== 1/4 rojo build" && rojo build default.project.json -o build/game.rbxl
echo "== 2/4 tests" && lune run tests/run.luau
echo "== 3/4 selene" && selene src && (cd tests && selene .)
echo "== 4/4 stylua" && stylua --check src tests
echo "All four checks passed."
