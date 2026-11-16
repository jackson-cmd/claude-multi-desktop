"""Run multiple Claude Desktop accounts at once on a Mac, sharing one Claude Code setup.

This package only carries the claude-multi-desktop bash script and starts it with /bin/bash, so
`pipx install claude-multi-desktop` and `uvx claude-multi-desktop` give the same command as Homebrew.
"""
import os
import sys

__version__ = "0.1.3"
SCRIPT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "claude-multi-desktop")


def main():
    if sys.platform != "darwin":
        sys.exit("claude-multi-desktop: Claude Desktop launchers need macOS")
    os.execv("/bin/bash", ["/bin/bash", SCRIPT] + sys.argv[1:])
