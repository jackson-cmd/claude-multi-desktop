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
- **PyPI:** \`uvx claude-multi-desktop add Work\` or \`pipx install claude-multi-desktop\`
- **Claude Code plugin:** \`/plugin marketplace add jackson-cmd/claude-multi-desktop\`, then \`/plugin install account-handoff@multi-desktop\`

### If macOS blocks the app or installer

If macOS says *"Apple could not verify 'Claude Multi Desktop' is free of malware"*: the app and the installer are not signed with an Apple Developer ID, so macOS blocks them the first time you open them. The code is open source, and you only need to allow it once.

**macOS 15 (Sequoia) and later**

1. Double-click the app (or the \`.pkg\`) once. When macOS blocks it, click **Done**.
2. Open **System Settings → Privacy & Security** and scroll down to the **Security** section. You will see *"'Claude Multi Desktop' was blocked to protect your Mac."* (for the installer, its file name). Click **Open Anyway**.
3. Enter your Mac login password (or use Touch ID). If macOS asks once more, click **Open Anyway** again. From then on it opens normally.

**macOS 14 (Sonoma) and earlier**

1. Right-click (or Control-click) the app (or the \`.pkg\`) and choose **Open**.
2. Click **Open** in the dialog. You only do this once.

Want no warning at all? Install with Homebrew instead: \`brew install jackson-cmd/tap/claude-multi-desktop\`.

Unofficial; not affiliated with Anthropic. For legitimate use only, with accounts you are entitled to use. Do not use it to get around usage limits or to share accounts.
NOTES
