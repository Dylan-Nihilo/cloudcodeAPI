#!/usr/bin/env bash
# Pull the latest upstream sub2api into the subtree.
# Pin a specific upstream ref by passing it as $1 (recommended for reproducibility).
set -euo pipefail

cd "$(dirname "$0")/.."

REF="${1:-main}"

echo "Pulling sub2api upstream at ref: $REF"
git subtree pull --prefix=sub2api sub2api-upstream "$REF" --squash
echo "Done. Review changes with: git log -n 5 --oneline"
