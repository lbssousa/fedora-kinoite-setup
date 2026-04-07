# UTM VM Setup

Automated Fedora Silverblue VM provisioning for UTM on macOS (Apple Silicon).

## Quick start

```bash
./utm/setup-vm.sh              # creates "silverblue-work"
./utm/setup-vm.sh my-vm-name   # custom name
```

## What it does

1. Installs UTM + utmctl via Homebrew (if missing)
2. Downloads Fedora Silverblue 43 aarch64 ISO (~2.8 GB, cached in `~/UTM-share/.cache/`)
3. Syncs this repository into `~/UTM-share/` so the guest can access it
4. Creates the VM via AppleScript (aarch64, 16 GB RAM, 64 GB disk, VirtFS sharing, virtio-gpu)
5. Patches in sound support (intel-hda) via PlistBuddy
6. Creates `~/UTM-share/run-setup.sh` helper for the guest

## After install

One manual step: set `~/UTM-share` as the shared directory in UTM (VM settings > Sharing).

Then inside the VM after first boot:

```bash
sudo mkdir -p /mnt/utm-share && sudo mount -t virtiofs share /mnt/utm-share && /mnt/utm-share/run-setup.sh
```

## Layout

```
~/UTM-share/
  .cache/                           # ISO downloads
  silverblue-setup/                 # synced copy of this repo
  run-setup.sh                      # guest helper (mounts share + runs install.sh)
```

## Requirements

- macOS on Apple Silicon
- [Homebrew](https://brew.sh)
