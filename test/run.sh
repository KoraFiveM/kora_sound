#!/usr/bin/env bash
# Smoke tests plus a syntax check of every Lua file. Run from anywhere.
set -euo pipefail
cd "$(dirname "$0")/.."
lua5.4 test/client.lua
lua5.4 test/server.lua
command -v node >/dev/null && node test/sounds.cjs
find . -name '*.lua' -not -path './.git/*' -print0 | xargs -0 -n1 luac5.4 -p
