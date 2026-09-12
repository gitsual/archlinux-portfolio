#!/usr/bin/env bash
set -Eeuo pipefail
rofi -dmenu -i -p "Hyprland keys" <<'KEYS'
Super + Return          Terminal
Super + R               Rofi launcher
Super + D               dmenu launcher
Super + Alt + R         Wofi launcher
Super + E               Neovim
Super + Q               Close window
Super + Space           Toggle floating
Super + F               Fullscreen
Super + arrows          Move focus
Super + Shift + arrows  Move window
Super + Alt + arrows    Resize window
Super + 1..0            Change workspace
Super + Shift + 1..0    Move window to workspace
Super + Shift + S       Select-area screenshot
Super + L               Lock session
Super + Shift + E       Power menu
KEYS
