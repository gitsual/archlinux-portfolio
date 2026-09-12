#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
dry_run=false
no_install=false
system_profile=false
desktop_login=false
vm_profile=false
noninteractive=false

usage() {
	cat <<'USAGE'
Usage: scripts/bootstrap.sh [--dry-run] [--no-install] [--noconfirm] [--system] [--desktop-login] [--vm]

Profiles:
  base             Portable workstation packages and user configuration (always)
  --desktop-login  Add greetd/tuigreet for a complete graphical login path
  --vm             Add QEMU/SPICE guest integration
  --system         Apply selected system profiles after installation
USAGE
}

while (($#)); do
	case "$1" in
	--dry-run) dry_run=true ;;
	--no-install) no_install=true ;;
	--noconfirm) noninteractive=true ;;
	--system) system_profile=true ;;
	--desktop-login) desktop_login=true ;;
	--vm) vm_profile=true ;;
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

# shellcheck disable=SC1091
source /etc/os-release
[[ "${ID:-}" == arch ]] || {
	printf 'This bootstrap supports Arch Linux only.\n' >&2
	exit 1
}

mapfile -t official < <(grep -Ev '^[[:space:]]*(#|$)' "$repo_root/packages/pacman.txt")
mapfile -t aur < <(grep -Ev '^[[:space:]]*(#|$)' "$repo_root/packages/aur.txt")
if $desktop_login; then
	mapfile -t optional < <(grep -Ev '^[[:space:]]*(#|$)' "$repo_root/packages/desktop-login.txt")
	official+=("${optional[@]}")
fi
if $vm_profile; then
	mapfile -t optional < <(grep -Ev '^[[:space:]]*(#|$)' "$repo_root/packages/vm.txt")
	official+=("${optional[@]}")
fi
mapfile -t official < <(printf '%s\n' "${official[@]}" | LC_ALL=C sort -u)

system_args=()
$desktop_login && system_args+=(--desktop-login)
$vm_profile && system_args+=(--vm)

if $dry_run; then
	printf 'would install official packages (%d): %s\n' "${#official[@]}" "${official[*]}"
	((${#aur[@]})) && printf 'would install AUR packages (%d): %s\n' "${#aur[@]}" "${aur[*]}"
	HOME="${HOME}" "$repo_root/scripts/deploy.sh" --all --dry-run
	if $system_profile; then
		"$repo_root/scripts/apply-system.sh" --dry-run "${system_args[@]}"
	fi
	exit 0
fi

if ! $no_install; then
	pacman_args=(-S --needed)
	$noninteractive && pacman_args+=(--noconfirm)
	sudo pacman "${pacman_args[@]}" -- "${official[@]}"
	if ((${#aur[@]})); then
		helper=""
		command -v paru >/dev/null && helper=paru
		command -v yay >/dev/null && helper=yay
		[[ -n "$helper" ]] || {
			printf 'AUR packages exist but no paru/yay helper is installed.\n' >&2
			exit 1
		}
		aur_args=(-S --needed)
		$noninteractive && aur_args+=(--noconfirm)
		"$helper" "${aur_args[@]}" -- "${aur[@]}"
	fi
fi

"$repo_root/scripts/deploy.sh" --all
"$repo_root/scripts/check.sh"
if $system_profile; then
	"$repo_root/scripts/apply-system.sh" "${system_args[@]}"
fi
