#!/usr/bin/env bash
# Screenshot demo: the scanners do most of the work.
#
# Rendered in the author's kitty (neg palette, Iosevka). The prompt is drawn by
# hand so a shot does not depend on the shell's prompt theme; the commands are
# real and so is their output.
set -u

prompt() {
  printf '\n\033[1;38;2;54;124;176m❯\033[0m \033[38;2;165;193;230m%s\033[0m\n' "$*"
}

prompt "df -h"
df -h | head -9 | tint -r df

prompt "ip -br a"
ip -br a | tint -r ip

prompt "ss -tuln"
ss -tuln | head -11 | tint -r ss

sleep 12
