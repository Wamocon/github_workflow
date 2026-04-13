#!/usr/bin/env bash
# =============================================================================
# Install pre-commit secret scanner hook
# =============================================================================
# Run this once from the root of your project:
#   bash hooks/install.sh
# =============================================================================

set -euo pipefail

HOOK_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/pre-commit"
HOOK_DST=".git/hooks/pre-commit"

if [[ ! -d ".git" ]]; then
  echo "Error: run this from the root of your git repository." >&2
  exit 1
fi

if [[ ! -f "$HOOK_SRC" ]]; then
  echo "Error: hooks/pre-commit not found. Run from the repo root." >&2
  exit 1
fi

cp "$HOOK_SRC" "$HOOK_DST"
chmod +x "$HOOK_DST"

echo "✔  Pre-commit secret scanner installed at $HOOK_DST"
echo "   The hook will run automatically before every git commit."
echo "   To bypass in an emergency: git commit --no-verify -m \"...\""
