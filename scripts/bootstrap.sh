#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
dry_run=false
no_install=false
system_profile=false

while (($#)); do
	case "$1" in
	--dry-run) dry_run=true ;;
	--no-install) no_install=true ;;
	--system) system_profile=true ;;
	-h | --help)
		printf 'Usage: scripts/bootstrap.sh [--dry-run] [--no-install] [--system]\n'
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

if $dry_run; then
	printf 'would install official packages (%d): %s\n' "${#official[@]}" "${official[*]}"
	((${#aur[@]})) && printf 'would install AUR packages (%d): %s\n' "${#aur[@]}" "${aur[*]}"
	HOME="${HOME}" "$repo_root/scripts/deploy.sh" --all --dry-run
	exit 0
fi

if ! $no_install; then
	sudo pacman -S --needed -- "${official[@]}"
	if ((${#aur[@]})); then
		helper=""
		command -v paru >/dev/null && helper=paru
		command -v yay >/dev/null && helper=yay
		[[ -n "$helper" ]] || {
			printf 'AUR packages exist but no paru/yay helper is installed.\n' >&2
			exit 1
		}
		"$helper" -S --needed -- "${aur[@]}"
	fi
fi

"$repo_root/scripts/deploy.sh" --all
"$repo_root/scripts/check.sh"
if $system_profile; then
	"$repo_root/scripts/apply-system.sh"
fi
