# Services and maintenance

## User services included

- PipeWire, PipeWire-Pulse and WirePlumber are enabled by their packages/socket activation.
- `clamav-home-scan.timer` schedules a low-priority weekly malware scan.
- Desktop daemons (Waybar, Dunst, Hyprpaper, keyring and portal) start from Hyprland.

## System services

`apply-system.sh` enables:

- `bluetooth.service`;
- `clamav-freshclam.service`;
- `ufw.service`;
- `fstrim.timer`.

Application servers, private synchronization jobs, gaming watchdogs and machine-bound device services are intentionally not copied. Their reusable ideas are represented by the generic audio profiles, storage architecture and timer patterns without publishing private paths, service endpoints or device identities.

## Update cycle

```bash
sudo pacman -Syu
./scripts/update-manifests.sh
./scripts/check.sh
```

Use `./scripts/update-manifests.sh --full-local` for ignored private snapshots of all explicitly installed packages before deciding what belongs in the public curated manifest.
