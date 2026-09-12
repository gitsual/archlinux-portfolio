#!/usr/bin/env bash
set -Eeuo pipefail
chosen="$(printf '%s\n' 'Lock' 'Suspend' 'Log out' 'Reboot' 'Power off' | rofi -dmenu -i -p 'Power')" || exit 0
case "$chosen" in
Lock) hyprlock ;;
Suspend) systemctl suspend ;;
'Log out') hyprctl dispatch exit ;;
Reboot) systemctl reboot ;;
'Power off') systemctl poweroff ;;
esac
