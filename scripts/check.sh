#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$repo_root"

printf '%s\n' '[1/8] shell syntax'
while IFS= read -r -d '' file; do bash -n "$file"; done < <(find scripts dotfiles -type f \( -name '*.sh' -o -name 'workstation-security-audit' \) -print0)

printf '%s\n' '[2/8] shellcheck'
if command -v shellcheck >/dev/null; then
	mapfile -d '' shell_files < <(find scripts dotfiles -type f \( -name '*.sh' -o -name 'workstation-security-audit' \) -print0)
	shellcheck "${shell_files[@]}"
else
	printf '%s\n' 'shellcheck not installed; syntax checks still ran'
fi

printf '%s\n' '[3/8] structured configuration'
python -c 'import ast, pathlib; ast.parse(pathlib.Path("scripts/privacy-scan.py").read_text())'
python -c 'import ast, pathlib; ast.parse(pathlib.Path("scripts/configure-audio.py").read_text())'
python -m json.tool dotfiles/waybar/.config/waybar/config >/dev/null
while IFS= read -r -d '' file; do
	nvim --headless --clean -u NONE -c "lua assert(loadfile([[${file}]]))" -c qa
done < <(find dotfiles/nvim -type f -name '*.lua' -print0)
systemd-analyze verify dotfiles/security/.config/systemd/user/*.service dotfiles/security/.config/systemd/user/*.timer

printf '%s\n' '[4/8] package manifests'
for manifest in packages/pacman.txt packages/aur.txt; do
	[[ -f "$manifest" ]]
	diff -u "$manifest" <(LC_ALL=C sort -u "$manifest")
done

printf '%s\n' '[5/8] symlinks and unexpected binaries'
if find . -path ./.git -prune -o -type l ! -exec test -e {} \; -print -quit | grep -q .; then
	printf '%s\n' 'broken symlink found' >&2
	exit 1
fi
if find . -path ./.git -prune -o -type f -print0 | xargs -0 file | grep -Ev 'text|empty|SVG|JSON|Python script|shell script' >/dev/null; then
	printf '%s\n' 'unexpected binary file found' >&2
	exit 1
fi

printf '%s\n' '[6/8] privacy and secret scan'
python scripts/privacy-scan.py .
if command -v gitleaks >/dev/null; then
	gitleaks detect --no-banner --no-git --source .
else
	printf '%s\n' 'gitleaks not installed; explicit privacy scanner completed'
fi

printf '%s\n' '[7/8] deployment script dry run'
dry_home="$(mktemp -d "${TMPDIR:-/tmp}/archportfolio-dry-run.XXXXXX")"
trap 'rm -rf -- "$dry_home"' EXIT
HOME="$dry_home" XDG_STATE_HOME="$dry_home/.local/state" "$repo_root/scripts/deploy.sh" --all --dry-run
rm -rf -- "$dry_home"
trap - EXIT

printf '%s\n' '[8/8] isolated deployment regression'
"$repo_root/scripts/test-deploy.sh"

printf '%s\n' 'all repository checks passed'
