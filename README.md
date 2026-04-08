# fedora-kinoite-setup

Automated first-time desktop setup for Fedora Kinoite (KDE Plasma on ostree).
Modular scripts in `install/`, orchestrated by `install.sh`.

Installs: Homebrew, mise, starship, dotfiles (stow), Nerd Font, Flatpak apps, Epson printer software, KDE Plasma settings, NVIDIA drivers + SecureBoot signing (if detected), TPM2 LUKS auto-unlock, Distrobox, VSCode, Zed, Rust CLI tools, Firefox codecs, ddcutil.

Each script can also be run standalone: `bash install/plasma.sh`

---

## Starting from scratch

1. Flash **Fedora Kinoite** with [Fedora Media Writer](https://github.com/FedoraQt/MediaWriter/releases/latest)
2. Boot from USB, run the Anaconda installer, reboot
3. Connect to the internet, open a terminal (Konsole):

```bash
git clone https://github.com/lbssousa/fedora-kinoite-setup ~/code/fedora-kinoite-setup
cd ~/code/fedora-kinoite-setup
bash install.sh
```

One reboot at the end.

---

## Starting from a Mac (UTM)

If you're running Fedora Kinoite in a UTM virtual machine on Apple Silicon, see [`utm/README.md`](utm/README.md). The setup script creates the VM, downloads the ISO, and syncs this repo into a shared folder so the guest can run `install.sh` automatically.

```bash
./utm/setup-vm.sh
```

---

## Editors & container tooling

`install/editors.sh` installs three editors and the glue to connect them to containers:

### Distrobox

Installed via the [official curl installer](https://github.com/89luca89/distrobox) to `~/.local` — no root, survives OS updates.

### VSCode

Installed via Homebrew using the [ublue-os tap](https://github.com/ublue-os/homebrew-tap). The Dev Containers extension is also installed and configured to use rootless **podman** (daemonless — no socket needed). Two helper scripts are placed in `~/.local/bin`:

- `vscode-distrobox <container>` — opens VSCode attached to a named distrobox container.
- `vscode-container-config <container> [distrobox|toolbx]` — generates the `nameConfig` JSON that Dev Containers needs to attach to an existing distrobox or toolbx container, including a corrected `capsh` terminal profile for toolbx.

### Zed

Installed as a Flatpak from Flathub (`dev.zed.Zed`). The sandbox is configured with `ZED_FLATPAK_NO_ESCAPE=0` so Zed's terminal and tasks can run host-side tools (distrobox, toolbox, etc.) via the bundled `host-spawn`. Two helper scripts are placed in `~/.local/bin`:

- `zed-distrobox <container> [path]` — enter a distrobox container and open a path in Zed.
- `zed-toolbx <container> [path]` — same idea for toolbx (toolbox) containers.

---

## CLI tools

`install/cli-tools.sh` installs Rust-based rewrites of common Unix tools via Homebrew and adds shell aliases for them:

| Tool | Replaces |
|---|---|
| `eza` | `ls` |
| `bat` | `cat` |
| `ripgrep` | `grep` |
| `fd` | `find` |
| `dust` | `du` |
| `procs` | `ps` |
| `bottom` | `top` / `htop` |
| `zoxide` | `cd` |
| `git-delta` | `git diff` pager |
| `sd` | `sed` |

Aliases are appended to `~/.bashrc`. A `zoxide init bash` hook is also added.

Additionally:
- **Bash case-insensitive tab completion** is enabled via `~/.inputrc`.
- **rivalcfg** (SteelSeries mouse configuration) is installed with `pipx`.

---

## Flatpak apps

`install/flatpaks.sh` adds Flathub as a user remote, removes a few pre-installed KDE games, and installs:

| App | Description |
|---|---|
| Bazaar | App browser / store UI |
| Blanket | Ambient sound / focus app |
| Deskflow | KVM / keyboard+mouse sharing |
| LocalSend | Local file transfer |
| Whis | Speech-to-text |
| VLC | Media player |
| Moonlight | Game streaming client |
| Signal | Encrypted messaging |
| SyncThingy | Syncthing GUI (Qt/KDE-friendly) |
| Flatseal | Manage Flatpak permissions |
| Warehouse | Flatpak app manager |
| Ignition | Manage startup apps |
| MissionCenter | System monitor (KDE-friendly) |
| Haruna | Media player (KDE-native, built on libmpv) |

---

## Firefox codecs

`install/firefox-codecs.sh` enables RPM Fusion repositories and layers the following packages so the system Firefox can play H.264, AAC, MP3, and other proprietary formats:

- `ffmpeg-libs`
- `gstreamer1-plugins-bad-freeworld`
- `gstreamer1-plugins-ugly`
- `gstreamer1-plugin-libav`

Requires a reboot to take effect (staged via `rpm-ostree install`).

---

## rpm-ostree packages

`install/rpm-ostree.sh` layers packages that have no Flatpak or Homebrew equivalent:

- **gcc + make** — required by Neovim Treesitter to compile parsers. Homebrew's gcc lacks system `libc` headers on Kinoite; the system gcc provides a complete toolchain.
- **ddcutil** — DDC/CI monitor control (brightness, contrast, etc.) via I²C. After rebooting, add your user to the `i2c` group:

  ```bash
  sudo usermod -aG i2c $USER
  ```

---

## System tweaks

`install/sudo-tweaks.sh` applies the following system-level changes (runs last to avoid blocking earlier steps on a skipped password prompt):

- **GeoClue → BeaconDB** — replaces Mozilla Location Services with [BeaconDB](https://beacondb.net), an open-source, community-run Wi-Fi/cell location service. Writes `/etc/geoclue/conf.d/99-beacondb.conf`.
- **sshd** — enabled and started via `systemctl enable --now sshd`.

---

## NVIDIA + SecureBoot

If your system has an NVIDIA GPU and SecureBoot is enabled, the install script:

1. Generates a Machine Owner Key (MOK) and registers it with `mokutil`
2. Builds and installs the `akmods-keys` RPM (based on [CheariX/silverblue-akmods-keys](https://github.com/CheariX/silverblue-akmods-keys)) so the keys are accessible inside the rpm-ostree transaction
3. Installs `akmod-nvidia` — the modules are signed automatically using those keys

**After the first reboot** a blue "MOK Management" screen will appear. Select **Enroll MOK** and enter the password you set during `nvidia-secureboot.sh` to complete key enrollment.

---

## TPM2 LUKS auto-unlock

If your disk is LUKS2-encrypted and your system has a TPM2 chip, run:

```bash
bash install/tpm2-luks.sh
```

This uses `systemd-cryptenroll` to bind a LUKS keyslot to the TPM2 chip (PCR 0+2+7). On subsequent boots the disk is unlocked automatically. Your regular passphrase remains as a fallback.

To remove TPM2 auto-unlock:

```bash
sudo systemd-cryptenroll --wipe-slot=tpm2 /dev/<device>
```

---

## Manual Follow-Up

- **Device name** — System Settings → About This System
- **Display resolution / scaling** — System Settings → Display & Monitor

---

Follows the [Universal Blue](https://universal-blue.org) philosophy: Flatpak for GUI apps, Homebrew for CLI tools, rpm-ostree only for drivers. Each layer updates independently and the system stays clean.
