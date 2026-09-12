#!/usr/bin/env bash
set -Eeuo pipefail
repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
dry_run=false
[[ "${1:-}" == --dry-run ]] && dry_run=true
[[ $# -le 1 ]] || {
	printf 'Usage: %s [--dry-run]\n' "$0" >&2
	exit 2
}

install_config() {
	local source=$1 destination=$2
	if $dry_run; then
		printf 'would install %s -> %s\n' "$source" "$destination"
		return
	fi
	if sudo test -e "$destination"; then
		sudo cp -a -- "$destination" "$destination.portfolio-backup.$(date -u +%Y%m%dT%H%M%SZ)"
	fi
	sudo install -Dm644 -- "$source" "$destination"
}

install_config "$repo_root/system/etc/bluetooth/main.conf" /etc/bluetooth/main.conf
install_config "$repo_root/system/etc/clamav/freshclam.conf" /etc/clamav/freshclam.conf
install_config "$repo_root/system/etc/clamav/clamd.conf" /etc/clamav/clamd.conf

if $dry_run; then
	printf '%s\n' 'would set UFW defaults: deny incoming, allow outgoing, enable'
	printf '%s\n' 'would enable Bluetooth, FreshClam, UFW and fstrim timer'
	exit 0
fi
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw --force enable
sudo systemctl enable --now bluetooth.service clamav-freshclam.service ufw.service fstrim.timer
systemctl --user daemon-reload
systemctl --user enable --now clamav-home-scan.timer
printf '%s\n' 'system profile applied; existing UFW allow rules were preserved'
