#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
pnpm install --frozen-lockfile
pnpm build
pnpm pkg . --targets node18-macos-arm64,node18-macos-x64,node18-win-x64 --out-path dist-bin
