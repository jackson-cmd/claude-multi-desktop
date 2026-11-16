#!/usr/bin/env bash
# Install each release file into a throwaway place and run it: the wheel, the npm package, the app in the disk image
# and the installer's payload. With --system the .pkg is also installed for real (sudo; meant for CI runners).
# Usage: packaging/smoke.sh DIST [--system]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
D="$(cd "$1" && pwd)"
v="$(sed -n 's/^VERSION="\(.*\)"$/\1/p' "$ROOT/claude-multi-desktop")"
T="$(mktemp -d)"; M=""
trap '[ -z "$M" ] || hdiutil detach -quiet "$M" || true; rm -rf "$T"' EXIT

python3 -m venv "$T/venv" && "$T/venv/bin/pip" install -q "$D/claude_multi_desktop-$v-py3-none-any.whl"
npm install -g -s --prefix "$T/npm" "$D/claude-multi-desktop-$v.tgz"
pkgutil --expand-full "$D/claude-multi-desktop-$v.pkg" "$T/pkg"
M="$(hdiutil attach -nobrowse -readonly "$D/claude-multi-desktop-$v.dmg" | tail -1 | cut -f3)"
codesign --verify --deep --strict "$M/Claude Multi Desktop.app"

export HOME="$T/home" CMD_APPS_DIR="$T/apps" CLAUDE_APP="$T/Claude.app"
mkdir -p "$HOME" "$CLAUDE_APP/Contents/MacOS"
printf '#!/bin/sh\n' > "$CLAUDE_APP/Contents/MacOS/Claude"; chmod +x "$CLAUDE_APP/Contents/MacOS/Claude"
fail=0
try() { # LABEL COMMAND...: prints the right version and makes a launcher
  local label="$1"; shift
  if [ "$("$@" version)" = "claude-multi-desktop $v" ] && "$@" add "Smoke $label" >/dev/null && [ -d "$CMD_APPS_DIR/Claude Smoke $label.app" ]; then
    echo "  ok    $label"
  else echo "  FAIL  $label"; fail=1; fi
}
try wheel "$T/venv/bin/claude-multi-desktop"
try npm "$T/npm/bin/claude-multi-desktop"
try dmg /bin/bash "$M/Claude Multi Desktop.app/Contents/Resources/claude-multi-desktop"
try pkg-payload /bin/bash "$T/pkg/component.pkg/Payload/usr/local/bin/claude-multi-desktop"
if [ "${2:-}" = --system ]; then
  sudo installer -pkg "$D/claude-multi-desktop-$v.pkg" -target / >/dev/null
  try pkg /usr/local/bin/claude-multi-desktop
  if [ -d "/Applications/Claude Multi Desktop.app" ]; then echo "  ok    pkg installed the app"; else echo "  FAIL  pkg app"; fail=1; fi
fi
[ "$fail" -eq 0 ]
