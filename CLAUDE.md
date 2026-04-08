# fedora-kinoite-setup

Automated first-time desktop setup for Fedora Kinoite (KDE Plasma on ostree). Modular scripts in `install/`, orchestrated by `install.sh`.

## Repo structure

- `install.sh` — main entry point, runs scripts in tiered order
- `install/*.sh` — individual modules (brew, plasma, flatpaks, nvidia, tpm2-luks, etc.)
- `ascii.sh` — banner art

## Companion repo

Dotfiles live at `~/code/dotfiles` (github.com/johnelliott/dotfiles). That repo uses GNU Stow. This repo's `install/dotfiles.sh` clones and runs it.

## Key conventions

- Scripts use `return` (not `exit`) for errors because they're sourced by `install.sh`
- KDE Plasma settings go in `install/plasma.sh` via `kwriteconfig6` (falls back to `kwriteconfig5`)
- Flatpak IDs go in `install/flatpaks.sh`
- Shell hooks (brew, starship, mise) are appended to `~/.bashrc` by `brew.sh` and `dev-tools.sh`
- NVIDIA SecureBoot signing is handled by `install/nvidia-secureboot.sh` using the akmods-keys approach (https://github.com/CheariX/silverblue-akmods-keys); run before `install/nvidia.sh`
- TPM2 LUKS auto-unlock is handled by `install/tpm2-luks.sh` using `systemd-cryptenroll`

## Platform

- Fedora Kinoite (immutable, rpm-ostree based, KDE Plasma)
- `/usr/` is read-only — use `/etc/` for system config, home dir for user config
- Homebrew installs to `/home/linuxbrew/.linuxbrew`
- KDE Plasma on Wayland
