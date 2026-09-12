#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
dry_run=false
security=false
bluetooth=false
desktop_login=false
vm_profile=false
selection_made=false

usage() {
	cat <<'USAGE'
Usage: scripts/apply-system.sh [--dry-run] [--security] [--bluetooth] [--desktop-login] [--vm]

With no module selector, the backward-compatible security and Bluetooth profiles
are applied. Selectors compose without enabling unrelated services.
USAGE
}

while (($#)); do
	case "$1" in
	--dry-run) dry_run=true ;;
	--security) security=true; selection_made=true ;;
	--bluetooth) bluetooth=true; selection_made=true ;;
	--desktop-login) desktop_login=true; selection_made=true ;;
	--vm) vm_profile=true; selection_made=true ;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		printf 'Unknown option: %s\n' "$1" >&2
		exit 2
		;;
	esac
	shift
done

if ! $selection_made; then
	security=true
	bluetooth=true
fi

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

services=()
start_services=()
if $bluetooth; then
	install_config "$repo_root/system/etc/bluetooth/main.conf" /etc/bluetooth/main.conf
	services+=(bluetooth.service)
fi
if $security; then
	install_config "$repo_root/system/etc/clamav/freshclam.conf" /etc/clamav/freshclam.conf
	install_config "$repo_root/system/etc/clamav/clamd.conf" /etc/clamav/clamd.conf
	if $dry_run; then
		printf '%s\n' 'would set UFW defaults: deny incoming, allow outgoing, enable'
	else
		sudo ufw default deny incoming
		sudo ufw default allow outgoing
		sudo ufw --force enable
	fi
	services+=(clamav-freshclam.service ufw.service fstrim.timer)
fi
if $desktop_login; then
	install_config "$repo_root/system/etc/greetd/config.toml" /etc/greetd/config.toml
	services+=(greetd.service)
fi
if $vm_profile; then
	start_services+=(qemu-guest-agent.service)
fi

if $dry_run; then
	((${#services[@]})) && printf 'would enable services: %s\n' "${services[*]}"
	((${#start_services[@]})) && printf 'would start device-activated services: %s\n' "${start_services[*]}"
	$security && printf '%s\n' 'would enable the user ClamAV scan timer'
	exit 0
fi

((${#services[@]})) && sudo systemctl enable --now "${services[@]}"
((${#start_services[@]})) && sudo systemctl start "${start_services[@]}"
if $security; then
	systemctl --user daemon-reload
	systemctl --user enable --now clamav-home-scan.timer
fi
printf '%s\n' 'selected system profiles applied; replaced files were backed up'
