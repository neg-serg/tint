#!/usr/bin/env bash
# Screenshot demo: a service log — timestamps, interface names, states, paths.
set -u

prompt() {
  printf '\n\033[1;38;2;54;124;176m❯\033[0m \033[38;2;165;193;230m%s\033[0m\n' "$*"
}

prompt "journalctl -b -u systemd-networkd -n 14 | tint -r journalctl"
journalctl -b -u systemd-networkd --no-pager -n 14 | tint -r journalctl

# Let the window outlive the screenshot, then close itself cleanly.
sleep 12
