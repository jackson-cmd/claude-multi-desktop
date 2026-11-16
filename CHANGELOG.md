# Changelog

## 0.1.1 (2026-11-15)

- **More ways to install.** Homebrew (`brew install jackson-cmd/tap/claude-multi-desktop`), a Mac installer (`.pkg`), a disk image (`.dmg`), npm (`npx claude-multi-desktop`), PyPI (`pipx install claude-multi-desktop`, `uvx claude-multi-desktop`) and a Claude Code plugin marketplace.
- **Claude Multi Desktop app.** The installer and the disk image carry a small double-click app that adds, opens, renames and removes accounts through dialogs, so you never need Terminal.
- **Custom icons.** `add NAME --icon claude` gives the launcher your own Claude icon with a coloured letter badge, drawn on your Mac from the Claude.app you have (nothing from Anthropic is shipped). `--icon /path/to/picture` uses any picture. `icon NAME` changes the icon or colour of an existing launcher.
- **Rename.** `rename NAME NEW` gives a launcher a new name and keeps its sign-in and chats.
- **account-handoff plugin for Claude Code.** One skill that hands a task to a Claude Code session in another account and relays the reply. It refuses to move work to another account because one account has reached a usage limit.
- `list --names` prints bare launcher names for scripts.

## 0.1.0 (2026-11-15)

First release: `add`, `add --default`, `list`, `open`, `peers` and `remove`, in one bash script with no dependencies.
