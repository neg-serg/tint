#!/usr/bin/env bash
# Screenshot demo: the git ruleset — hashes, refs, stats and paths.
set -u

prompt() {
  printf '\n\033[1;38;2;54;124;176m❯\033[0m \033[38;2;165;193;230m%s\033[0m\n' "$*"
}

prompt "git log --stat --oneline -4 | tint -r git"
git -C "$(dirname "$0")/.." log --stat --oneline -4 | tint -r git

# Let the window outlive the screenshot, then close itself cleanly.
sleep 12
