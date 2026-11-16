#!/usr/bin/env bash
# shellcheck disable=SC2016  # single quotes are intended: these strings must not expand
# Tests for claude-multi-desktop. They run in a throwaway HOME with a fake Claude.app and never open Claude.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOL="$ROOT/claude-multi-desktop"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT

export HOME="$T/home" CMD_APPS_DIR="$T/apps" CLAUDE_APP="$T/Claude.app" CLAUDE_CONFIG_DIR="$T/home/.claude"
mkdir -p "$HOME/Library/Application Support" "$CLAUDE_APP/Contents/MacOS"
printf '#!/bin/sh\n' > "$CLAUDE_APP/Contents/MacOS/Claude"; chmod +x "$CLAUDE_APP/Contents/MacOS/Claude"

pass=0; fail=0
ok()   { pass=$((pass + 1)); printf '  ok    %s\n' "$1"; }
bad()  { fail=$((fail + 1)); printf '  FAIL  %s\n' "$1"; }
check() { local name="$1"; shift; if "$@" >/dev/null 2>&1; then ok "$name"; else bad "$name"; fi; }
refuse() { local name="$1"; shift; if "$@" >/dev/null 2>&1; then bad "$name"; else ok "$name"; fi; }

echo "claude-multi-desktop tests"

check "version prints" "$TOOL" version
check "help prints" "$TOOL" help

# add
check "add Work" "$TOOL" add Work
APP="$CMD_APPS_DIR/Claude Work.app"
check "launcher is executable" test -x "$APP/Contents/MacOS/launcher"
check "Info.plist is valid" plutil -lint "$APP/Contents/Info.plist"
check "launcher points at its own folder" grep -qF 'user-data-dir="$HOME/Library/Application Support/Claude-Work"' "$APP/Contents/MacOS/launcher"
check "launcher opens a new Claude instance" grep -qF "open -n -a \"$CLAUDE_APP\"" "$APP/Contents/MacOS/launcher"
check "launcher has no absolute home path" bash -c "! grep -qF '$HOME' '$APP/Contents/MacOS/launcher'"
check "icon was drawn" test -s "$APP/Contents/Resources/icon.icns"
check "add a name with a space" "$TOOL" add "Client A" --color '#2E9D6A'
check "add a launcher for the default account" "$TOOL" add Main --default
check "default launcher uses the default folder" grep -qF 'Application Support/Claude"' "$CMD_APPS_DIR/Claude Main.app/Contents/MacOS/launcher"

# refusals
refuse "refuse a duplicate name" "$TOOL" add Work
refuse "refuse a second launcher for the same account" "$TOOL" add Main2 --default
refuse "refuse a slash in the name" "$TOOL" add "a/b"
refuse "refuse a quote in the name" "$TOOL" add 'a"b'
refuse "refuse a dollar sign in the name" "$TOOL" add 'a$b'
refuse "refuse names ending in 3p" "$TOOL" add Team-3p
refuse "refuse a bad colour" "$TOOL" add Blue --color nothex
refuse "refuse an unknown command" "$TOOL" frobnicate
refuse "refuse opening a missing launcher" "$TOOL" open Nobody

# list
out="$("$TOOL" list)"
for n in "Claude Work" "Claude Client A" "Claude Main"; do
  check "list shows $n" grep -qF "$n" <<< "$out"
done

# remove
mkdir -p "$HOME/Library/Application Support/Claude-Work"
check "remove keeps the account folder by default" "$TOOL" remove Work
check "account folder still there" test -d "$HOME/Library/Application Support/Claude-Work"
check "launcher gone" test ! -e "$APP"
"$TOOL" add Work >/dev/null
check "remove --delete-data --yes deletes the folder" "$TOOL" remove Work --delete-data --yes
check "account folder deleted" test ! -e "$HOME/Library/Application Support/Claude-Work"
mkdir -p "$HOME/Library/Application Support/Claude"
refuse "never delete the default account folder" "$TOOL" remove Main --delete-data --yes
check "default folder survives" test -d "$HOME/Library/Application Support/Claude"
mkdir -p "$CMD_APPS_DIR/Claude Other.app/Contents/MacOS"; printf '#!/bin/bash\n' > "$CMD_APPS_DIR/Claude Other.app/Contents/MacOS/launcher"
refuse "never remove a launcher this tool did not make" "$TOOL" remove Other
check "foreign launcher survives" test -e "$CMD_APPS_DIR/Claude Other.app"

# peers: two live sessions (this shell's pid and its parent's) recorded by two different accounts
mkdir -p "$CLAUDE_CONFIG_DIR/sessions" \
  "$HOME/Library/Application Support/Claude/claude-code-sessions" \
  "$HOME/Library/Application Support/Claude-Personal/claude-code-sessions"
printf '{"pid":%s,"hostSessionId":"local_aaa111","status":"idle","name":"paper review"}' $$ > "$CLAUDE_CONFIG_DIR/sessions/$$.json"
printf '{"pid":%s,"hostSessionId":"local_bbb222","status":"busy","name":"trip planning","extra":null}' "$PPID" > "$CLAUDE_CONFIG_DIR/sessions/$PPID.json"
printf '{"pid":999999,"hostSessionId":"local_ccc333","status":"idle","name":"long gone"}' > "$CLAUDE_CONFIG_DIR/sessions/999999.json"
printf '{"sessionId":"aaa111"}' > "$HOME/Library/Application Support/Claude/claude-code-sessions/a.json"
printf '{"sessionId":"bbb222"}' > "$HOME/Library/Application Support/Claude-Personal/claude-code-sessions/b.json"
out="$("$TOOL" peers)"
check "peers maps a session to the default account" grep -Eq '^default +idle +paper review' <<< "$out"
check "peers maps a session to the Personal account" grep -Eq '^Personal +busy +trip planning' <<< "$out"
check "peers skips sessions whose process has ended" bash -c "! grep -q 'long gone' <<< \"\$1\"" _ "$out"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
