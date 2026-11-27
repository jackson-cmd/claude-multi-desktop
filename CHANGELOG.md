# Changelog

## Unreleased

- **`quit NAME` and `quit --all`.** Quit Claude in one account, several, or every account (including one opened the normal way), as ⌘Q does, and wait until each window has closed. If a window does not close, for example because it is asking about unsaved work, the command says so and exits with an error. `quit --all` is the first step of [Updating Claude Desktop](README.md#updating-claude-desktop).
- **`doctor` and `doctor --fix`.** Checks every launcher: that the Claude.app it opens is still there, that it can run, that no two launchers open the same account (as happens when a launcher is duplicated in Finder), and that it has an icon. It also lists account folders whose launcher was removed, with the `add` command that brings them back. `--fix` points launchers at the Claude.app found now (after Claude.app was moved or reinstalled elsewhere), makes them runnable and redraws lost icons; it never touches sign-ins or chats.
- **`list` shows broken launchers.** A launcher whose Claude.app is gone shows as `broken`, with a hint to run `doctor --fix`.
- **Claude Multi Desktop app.** New choices: quit an account, quit every account before updating Claude, and check and repair launchers.
- **GitHub Packages.** Each release's npm package is also published to GitHub Packages as `@jackson-cmd/claude-multi-desktop`, so it shows under Packages on the repository page.
- An account counts as open only when Claude's main process runs with its folder; Claude opened the normal way counts for the default account only when it is the Claude.app this tool finds.

## 0.1.3 (2026-11-15)

- Clean up.

## 0.1.2 (2026-11-15)

- **Clear steps when macOS blocks the app.** The disk image now has a text file next to the app, "If macOS blocks the app.txt", with the steps to allow the unsigned app or installer on macOS 15 and later (Privacy & Security → Open Anyway) and on macOS 14 and earlier (right-click → Open). The README has the same steps.
- **npm.** `npx claude-multi-desktop add Work` or `npm install -g claude-multi-desktop`. The README and the website list only the install methods that work: Homebrew, the installer, the disk image, npm, the Claude Code plugin, curl and git.

## 0.1.1 (2026-11-15)

- **More ways to install.** Homebrew (`brew install jackson-cmd/tap/claude-multi-desktop`), a Mac installer (`.pkg`), a disk image (`.dmg`) and a Claude Code plugin marketplace, plus npm and PyPI packaging.
- **Claude Multi Desktop app.** The installer and the disk image carry a small double-click app that adds, opens, renames and removes accounts through dialogs, so you never need Terminal.
- **Custom icons.** `add NAME --icon claude` gives the launcher your own Claude icon with a coloured letter badge, drawn on your Mac from the Claude.app you have (nothing from Anthropic is shipped). `--icon /path/to/picture` uses any picture. `icon NAME` changes the icon or colour of an existing launcher.
- **Rename.** `rename NAME NEW` gives a launcher a new name and keeps its sign-in and chats.
- **account-handoff plugin for Claude Code.** One skill that hands a task to a Claude Code session in another account and relays the reply. It refuses to move work to another account because one account has reached a usage limit.
- `list --names` prints bare launcher names for scripts.

## 0.1.0 (2026-11-15)

First release: `add`, `add --default`, `list`, `open`, `peers` and `remove`, in one bash script with no dependencies.
