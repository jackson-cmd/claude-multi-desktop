#!/usr/bin/env bash
# shellcheck disable=SC2016  # single quotes are intended: these strings must not expand
# Tests for claude-multi-desktop. They run in a throwaway HOME with a fake Claude.app and never open Claude.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOL="$ROOT/claude-multi-desktop"
T="$(mktemp -d)"
stop_stand_ins() { local p; [ -f "$T/pids" ] || return 0; while read -r p; do kill -9 "$p" 2>/dev/null || true; done < "$T/pids"; }
trap 'stop_stand_ins; rm -rf "$T"' EXIT

export HOME="$T/home" CMD_APPS_DIR="$T/apps" CLAUDE_APP="$T/Claude.app" CLAUDE_CONFIG_DIR="$T/home/.claude"
mkdir -p "$HOME/Library/Application Support" "$CLAUDE_APP/Contents/MacOS"
# A stand-in for Claude: it runs until asked to quit, or ignores that when STUBBORN is set. Nothing here opens it,
# except start_claude below.
cat > "$CLAUDE_APP/Contents/MacOS/Claude" <<'EOF'
#!/bin/sh
if [ -n "${STUBBORN:-}" ]; then trap '' TERM; else trap 'exit 0' TERM; fi
while :; do sleep 0.1; done
EOF
chmod +x "$CLAUDE_APP/Contents/MacOS/Claude"
start_claude() { # [ARGS...]: run the stand-in in the background, detached so the system reaps it when it ends
  ( "$CLAUDE_APP/Contents/MacOS/Claude" "$@" >/dev/null 2>&1 & echo $! >> "$T/pids" )
  sleep 0.3
}

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

# icons: the Claude icon with a badge, any picture, a new colour later
PB=/usr/libexec/PlistBuddy
plist_val() { "$PB" -c "Print :$2" "$CMD_APPS_DIR/Claude $1.app/Contents/Info.plist" 2>/dev/null; }
check "add with the Claude icon and a badge" "$TOOL" add Badge --icon claude
check "Claude icon was drawn" test -s "$CMD_APPS_DIR/Claude Badge.app/Contents/Resources/icon.icns"
check "icon style is recorded" test "$(plist_val Badge ClaudeMultiDesktopIcon)" = claude
check "add with a picture" "$TOOL" add Picture --icon "$ROOT/site/assets/social.png"
check "picture icon was drawn" test -s "$CMD_APPS_DIR/Claude Picture.app/Contents/Resources/icon.icns"
check "picture style is recorded" test "$(plist_val Picture ClaudeMultiDesktopIcon)" = image
printf 'not a picture\n' > "$T/notes.txt"
refuse "refuse a missing picture" "$TOOL" add Nope --icon "$T/missing.png"
refuse "refuse a file that is not a picture" "$TOOL" add Nope --icon "$T/notes.txt"
check "a refused picture creates no launcher" test ! -e "$CMD_APPS_DIR/Claude Nope.app"
before="$(cksum < "$CMD_APPS_DIR/Claude Badge.app/Contents/Resources/icon.icns")"
check "icon NAME --color" "$TOOL" icon Badge --color 7A5AE0
check "new colour is recorded" test "$(plist_val Badge ClaudeMultiDesktopColor)" = 7A5AE0
check "icon was redrawn" test "$before" != "$(cksum < "$CMD_APPS_DIR/Claude Badge.app/Contents/Resources/icon.icns")"
check "icon NAME --icon letter" "$TOOL" icon Badge --icon letter
check "style changed to letter" test "$(plist_val Badge ClaudeMultiDesktopIcon)" = letter
refuse "refuse a colour for a picture icon" "$TOOL" icon Picture --color 7A5AE0
refuse "refuse icon with nothing to change" "$TOOL" icon Badge
refuse "refuse icon for a missing launcher" "$TOOL" icon Nobody --color 7A5AE0
"$PB" -c "Delete :ClaudeMultiDesktopIcon" -c "Delete :ClaudeMultiDesktopColor" "$CMD_APPS_DIR/Claude Picture.app/Contents/Info.plist"
check "a launcher from 0.1.0 (no recorded style) takes a new colour" "$TOOL" icon Picture --color 2E9D6A

# rename: the launcher gets a new name, the account folder stays
check "rename Badge to Studio" "$TOOL" rename Badge Studio
check "old launcher name is gone" test ! -e "$CMD_APPS_DIR/Claude Badge.app"
check "renamed launcher keeps its account folder" grep -qF 'Application Support/Claude-Badge"' "$CMD_APPS_DIR/Claude Studio.app/Contents/MacOS/launcher"
check "renamed launcher shows its new name" test "$(plist_val Studio CFBundleName)" = "Claude Studio"
check "renamed launcher keeps its colour" test "$(plist_val Studio ClaudeMultiDesktopColor)" = 7A5AE0
check "rename can change only the case" "$TOOL" rename Studio studio
check "case-only rename worked" bash -c 'ls "$1" | grep -qx "Claude studio.app"' _ "$CMD_APPS_DIR"
refuse "refuse renaming onto an existing launcher" "$TOOL" rename studio Picture
refuse "refuse renaming a launcher this tool did not make" "$TOOL" rename Nobody Other2
refuse "refuse a bad new name" "$TOOL" rename studio 'a/b'
refuse "refuse adding a launcher for a folder a renamed launcher uses" "$TOOL" add Badge
out="$("$TOOL" list --names)"
check "list --names prints bare names" grep -qx "studio" <<< "$out"
"$TOOL" remove studio >/dev/null; "$TOOL" remove Picture >/dev/null

# doctor: a launcher whose Claude.app has moved, one that cannot run, a lost icon, a folder whose launcher was removed
check "doctor passes when nothing is wrong" "$TOOL" doctor
MOVED="$CMD_APPS_DIR/Claude Moved.app"
mkdir -p "$T/Old/Claude.app/Contents/MacOS"; cp "$CLAUDE_APP/Contents/MacOS/Claude" "$T/Old/Claude.app/Contents/MacOS/"
CLAUDE_APP="$T/Old/Claude.app" "$TOOL" add Moved >/dev/null
rm -rf "$T/Old"
refuse "doctor finds a launcher whose Claude.app is gone" "$TOOL" doctor
check "list marks that launcher broken" bash -c '"$1" list | grep -Eq "^Claude Moved +broken"' _ "$TOOL"
chmod -x "$MOVED/Contents/MacOS/launcher"
rm "$MOVED/Contents/Resources/icon.icns"
mkdir -p "$HOME/Library/Application Support/Claude-Old"
if out="$("$TOOL" doctor --fix 2>&1)"; then ok "doctor --fix repairs them"; else bad "doctor --fix repairs them"; fi
check "repaired launcher opens the Claude.app found now" grep -qF "open -n -a \"$CLAUDE_APP\"" "$MOVED/Contents/MacOS/launcher"
check "repaired launcher keeps its account folder" grep -qF 'user-data-dir="$HOME/Library/Application Support/Claude-Moved"' "$MOVED/Contents/MacOS/launcher"
check "repaired launcher can run" test -x "$MOVED/Contents/MacOS/launcher"
check "lost icon is drawn again" test -s "$MOVED/Contents/Resources/icon.icns"
check "doctor names a folder whose launcher was removed" grep -qF 'claude-multi-desktop add "Old"' <<< "$out"
check "doctor passes after --fix" "$TOOL" doctor
cp -R "$MOVED" "$CMD_APPS_DIR/Claude Moved copy.app"   # what duplicating the launcher in Finder makes
refuse "doctor finds two launchers for one account" "$TOOL" doctor
rm -rf "$CMD_APPS_DIR/Claude Moved copy.app"; "$TOOL" remove Moved >/dev/null
refuse "refuse an unknown doctor option" "$TOOL" doctor --frobnicate

# quit: the stand-in plays Claude in one account, then in several, then one that will not quit
WORKDIR="$HOME/Library/Application Support/Claude-Work"
start_claude --user-data-dir="$WORKDIR"
check "list shows an open account as open" bash -c '"$1" list | grep -Eq "^Claude Work +open"' _ "$TOOL"
check "quit Work" "$TOOL" quit Work
check "Work is closed" bash -c '! "$1" list | grep -Eq "^Claude Work +open"' _ "$TOOL"
check "quit says when an account is not open" bash -c '"$1" quit Work | grep -q "^Not open Claude Work"' _ "$TOOL"
start_claude --user-data-dir="$WORKDIR"
start_claude --user-data-dir="$HOME/Library/Application Support/Claude-Client A"
start_claude   # the default account, opened the normal way with no flag
check "the default account opened the normal way shows as open" bash -c '"$1" list | grep -Eq "^Claude Main +open"' _ "$TOOL"
check "quit --all" "$TOOL" quit --all
check "every account is closed" bash -c '! "$1" list | grep -q " open "' _ "$TOOL"
check "quit --all with nothing open says so" bash -c '"$1" quit --all | grep -q "No Claude window was open"' _ "$TOOL"
refuse "refuse quit with no name" "$TOOL" quit
refuse "refuse quit for a missing launcher" "$TOOL" quit Nobody
STUBBORN=1 start_claude --user-data-dir="$WORKDIR"
if out="$(CMD_QUIT_WAIT=1 "$TOOL" quit Work 2>&1)"; then bad "quit reports a window that does not close"
elif grep -q "^Running  Claude Work: still open after 1s" <<< "$out"; then ok "quit reports a window that does not close"
else bad "quit reports a window that does not close"; fi
mkdir -p "$WORKDIR"
refuse "never delete the folder of an open account" "$TOOL" remove Work --delete-data --yes
check "folder of the open account survives" test -d "$WORKDIR"
stop_stand_ins
"$TOOL" add Work >/dev/null

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
