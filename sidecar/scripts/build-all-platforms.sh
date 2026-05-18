#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
pnpm install --frozen-lockfile
pnpm build
pnpm exec pkg . --targets node22-macos-arm64,node22-macos-x64,node22-win-x64 --out-path dist-bin
