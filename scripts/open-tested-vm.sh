#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
run="${VM_WORKDIR:-$repo_root/.vm-test}/run"
pidfile="$run/qemu.pid"

if [[ "${1:-}" == --stop ]]; then
	if [[ -f "$pidfile" ]] && kill -0 "$(<"$pidfile")" 2>/dev/null; then
		kill "$(<"$pidfile")"
		printf '%s\n' 'Tested VM stopped'
	else
		printf '%s\n' 'Tested VM is not running'
	fi
	exit 0
fi
[[ $# -eq 0 ]] || {
	printf 'Usage: %s [--stop]\n' "$0" >&2
	exit 2
}

for file in system.qcow2 seed.iso repository.iso id_ed25519; do
	[[ -f "$run/$file" ]] || {
		printf 'Missing tested VM artifact: %s; run scripts/test-vm.sh --keep first\n' "$file" >&2
		exit 1
	}
done
if [[ -f "$pidfile" ]] && kill -0 "$(<"$pidfile")" 2>/dev/null; then
	printf '%s\n' 'Tested VM is already running'
	exit 0
fi

host_address="$(printf '%d.%d.%d.%d' 127 0 0 1)"
port="${VM_SSH_PORT:-$(python -c 'import socket; s=socket.socket(); s.bind(("localhost", 0)); print(s.getsockname()[1]); s.close()')}"
memory="${VM_MEMORY_MB:-8192}"
cpus="${VM_CPUS:-4}"
rm -f -- "$pidfile" "$run/qga.sock"

qemu-system-x86_64 \
	-enable-kvm -machine q35,accel=kvm -cpu host \
	-smp "$cpus" -m "$memory" \
	-drive "if=virtio,format=qcow2,file=$run/system.qcow2" \
	-drive "media=cdrom,readonly=on,file=$run/seed.iso" \
	-drive "media=cdrom,readonly=on,file=$run/repository.iso" \
	-netdev "user,id=net0,hostfwd=tcp:$host_address:$port-:22" \
	-device virtio-net-pci,netdev=net0 \
	-device virtio-serial-pci -chardev spicevmc,id=vdagent,name=vdagent \
	-device virtserialport,chardev=vdagent,name=com.redhat.spice.0 \
	-chardev "socket,path=$run/qga.sock,server=on,wait=off,id=qga0" \
	-device virtserialport,chardev=qga0,name=org.qemu.guest_agent.0 \
	-display gtk -device virtio-vga -daemonize -pidfile "$pidfile" \
	-serial "file:$run/interactive-serial.log"

ssh_opts=(-i "$run/id_ed25519" -p "$port" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5)
ready=false
for _ in {1..90}; do
	if ssh "${ssh_opts[@]}" "portfolio@$host_address" true >/dev/null 2>&1; then ready=true; break; fi
	sleep 2
done
$ready || {
	printf '%s\n' 'Interactive VM did not become reachable' >&2
	exit 1
}

console_passphrase="$(python -c 'import secrets; print(secrets.token_urlsafe(12))')"
printf 'portfolio:%s\n' "$console_passphrase" | ssh "${ssh_opts[@]}" "portfolio@$host_address" 'sudo chpasswd'
ssh "${ssh_opts[@]}" "portfolio@$host_address" 'cd "$HOME/archlinux-portfolio" && ./scripts/apply-system.sh --desktop-login --vm'
printf 'user=portfolio\npassphrase=%s\nssh_port=%s\n' "$console_passphrase" "$port" >"$run/console-login.txt"
chmod 600 "$run/console-login.txt"
ssh "${ssh_opts[@]}" "portfolio@$host_address" 'sudo systemctl reboot' || true

printf 'Interactive tested VM is running; login details: %s\n' "$run/console-login.txt"
printf 'Stop it with: %s --stop\n' "$repo_root/scripts/open-tested-vm.sh"
