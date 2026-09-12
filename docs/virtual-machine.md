# Virtual-machine validation

The VM test is a real KVM/QEMU guest, not a container presented as an Arch installation.

## Automated acceptance test

```bash
./scripts/test-vm.sh
```

The script:

1. downloads the official Arch Linux cloud QCOW2 image and verifies its upstream SHA-256 file;
2. creates a disposable 32 GiB sparse overlay, ephemeral SSH key and NoCloud seed;
3. attaches a read-only archive of the current working tree, excluding Git and VM artifacts;
4. boots the guest with KVM and user-mode networking bound only to loopback;
5. updates the guest, installs the base, graphical-login and VM package profiles;
6. deploys every Stow package into the guest user's HOME;
7. runs the full repository checker and clean Neovim installation;
8. checks the Hyprland configuration and required workstation executables;
9. runs the selected system profile as a dry-run so the test does not pretend firewall, Bluetooth or hardware effects occurred.

The host HOME, packages, services and firewall are not modified. Failed runs preserve logs and the overlay under ignored `.vm-test/`; successful runs clean the disposable run directory unless `--keep` is used.

## Interactive graphical VM

Run acceptance while retaining its tested overlay, then open that exact guest:

```bash
./scripts/test-vm.sh --keep
./scripts/open-tested-vm.sh
```

Alternatively, perform acceptance and graphical opening in one command:

```bash
./scripts/test-vm.sh --gui
```

After automated acceptance, the opener enables only the generic graphical-login and VM guest-service modules, assigns a new random console passphrase, reboots and keeps the QEMU window running. The passphrase and SSH key exist only in ignored local VM state and are never committed. Stop it cleanly with:

```bash
./scripts/open-tested-vm.sh --stop
```

Optional resource overrides:

```bash
VM_MEMORY_MB=12288 VM_CPUS=6 ./scripts/test-vm.sh --gui
```

Stop a kept VM with its recorded PID, then remove `.vm-test/run` when its evidence is no longer needed. The verified base image remains cached to avoid a repeated download.

## What the VM can and cannot prove

It proves package installation, deployment, editor installation, configuration parsing and the generic login path on a clean Arch guest. It cannot prove physical Bluetooth pairing, real microphone/speaker behavior, GPU-specific acceleration, disk partitioning or the user's private external AI services. Those remain explicit destination-side checks rather than simulated successes.
