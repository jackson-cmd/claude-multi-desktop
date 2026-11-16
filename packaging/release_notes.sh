#!/usr/bin/env bash
# Print the release notes of VERSION: its CHANGELOG.md section followed by the ways to install.
set -euo pipefail
cd "$(dirname "$0")/.."
v="$1"
awk -v v="$v" '/^## / { on = (index($0, "## " v " ") == 1 || $0 == "## " v) ; next } on' CHANGELOG.md | sed '/./,$!d'
cat <<NOTES

### Install

\`\`\`bash
brew install jackson-cmd/tap/claude-multi-desktop
\`\`\`

- **Mac installer:** \`claude-multi-desktop-$v.pkg\` below installs the command and the Claude Multi Desktop app.
- **Disk image:** \`claude-multi-desktop-$v.dmg\` below; drag Claude Multi Desktop to Applications and double-click it.
- **npm:** \`npx claude-multi-desktop add Work\`
- **Claude Code plugin:** \`/plugin marketplace add jackson-cmd/claude-multi-desktop\`, then \`/plugin install account-handoff@multi-desktop\`

The .pkg and .dmg are not signed with an Apple Developer ID, so macOS asks once: on macOS 15 or later open System Settings → Privacy & Security and click **Open Anyway**; on macOS 14 or earlier right-click the file and choose Open.

Unofficial; not affiliated with Anthropic. For legitimate use only, with accounts you are entitled to use. Do not use it to get around usage limits or to share accounts.
NOTES
