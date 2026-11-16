#!/usr/bin/env bash
# Every place that states the version must agree with VERSION in the script. Give a Homebrew formula (a path or a
# URL) as the first argument to check it too, e.g. after the tap is bumped:
#   bash tests/test_version.sh https://raw.githubusercontent.com/jackson-cmd/homebrew-tap/main/Formula/claude-multi-desktop.rb
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
v="$(sed -n 's/^VERSION="\(.*\)"$/\1/p' claude-multi-desktop)"
fail=0
check() { if [ "$2" = "$v" ]; then printf '  ok    %-34s %s\n' "$1" "$2"; else printf '  FAIL  %-34s says "%s", the script says %s\n' "$1" "$2" "$v"; fail=1; fi; }
json() { python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(eval(sys.argv[2], {"d": d}))' "$1" "$2"; }

echo "version $v"
check package.json "$(json package.json 'd["version"]')"
check pyproject.toml "$(sed -n 's/^version = "\(.*\)"$/\1/p' pyproject.toml)"
check "python __version__" "$(sed -n 's/^__version__ = "\(.*\)"$/\1/p' packaging/python/claude_multi_desktop/__init__.py)"
check "plugin.json" "$(json plugins/account-handoff/.claude-plugin/plugin.json 'd["version"]')"
check "marketplace.json" "$(json .claude-plugin/marketplace.json 'd["plugins"][0]["version"]')"
check "CHANGELOG.md newest section" "$(sed -n 's/^## \([0-9][^ ]*\).*/\1/p' CHANGELOG.md | head -1)"
check "site softwareVersion" "$(sed -n 's/.*"softwareVersion": "\([^"]*\)".*/\1/p' site/index.html)"
if [ -n "${1:-}" ]; then
  if [ -f "$1" ]; then formula="$(cat "$1")"; else formula="$(curl -fsSL "$1")"; fi
  check "Homebrew formula" "$(sed -n 's|.*/archive/refs/tags/v\([^"]*\)\.tar\.gz".*|\1|p' <<< "$formula")"
fi
[ "$fail" -eq 0 ]
