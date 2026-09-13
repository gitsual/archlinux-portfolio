#!/usr/bin/env bash
# Session-only host placement for the graphical test VM.
# Never rewrites the host configuration; a Hyprland reload clears it.
#
# Picks an empty host workspace, sends every QEMU window there fullscreen so
# the guest is offered the whole monitor resolution, and switches to it.
set -Eeuo pipefail
command -v hyprctl >/dev/null || exit 0
[[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] || exit 0

rule="portfolio-vm-window"
workspace="${VM_HOST_WORKSPACE:-$(hyprctl -j workspaces | python -c '
import json, sys
used = {w["id"] for w in json.load(sys.stdin) if w["windows"]}
print(next(i for i in range(1, 11) if i not in used))
')}"
[[ "$workspace" =~ ^[0-9]+$ ]] || {
	printf 'Invalid host workspace: %s\n' "$workspace" >&2
	exit 2
}

if [[ "$(hyprctl eval 'return true' 2>&1)" == ok ]]; then
	hyprctl eval "
hl.window_rule({ name = '$rule', match = { class = '^(qemu.*)$' }, workspace = '$workspace', fullscreen = true })
hl.dispatch(hl.dsp.focus({ workspace = $workspace }))
" >/dev/null
else
	hyprctl --batch "\
keyword windowrule workspace $workspace, match:class ^(qemu.*)$; \
keyword windowrule fullscreen on, match:class ^(qemu.*)$; \
dispatch workspace $workspace" >/dev/null
fi
printf 'QEMU windows open fullscreen on host workspace %s.\n' "$workspace"
