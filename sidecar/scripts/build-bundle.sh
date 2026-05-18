#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
pnpm install --frozen-lockfile
pnpm build
pnpm exec pkg . --out-path dist-bin
echo "Binaries in $(pwd)/dist-bin/"
ls -la dist-bin/
