# silverblue-setup

Automated first-time desktop setup for Fedora Silverblue (and Fedora generally).
One entry point, ordered modular scripts — modeled after [Omakub](https://github.com/basecamp/omakub).

---

## Starting from scratch (e.g. an old ThinkPad)

**1. Get Fedora Media Writer**

| Platform | Link |
|---|---|
| Windows / macOS | [github.com/FedoraQt/MediaWriter/releases/latest](https://github.com/FedoraQt/MediaWriter/releases/latest) |
| Linux | [flathub.org — Fedora Media Writer](https://flathub.org/apps/details/org.fedoraproject.MediaWriter) |

**2. Write Silverblue to a USB drive**

Open Media Writer → select **Fedora Silverblue** from the list → choose your USB drive → Write. Media Writer downloads the ISO and flashes it in one step.

**3. Install Silverblue**

Boot from the USB (usually F12 or F1 on ThinkPads to pick boot device). Follow the Anaconda installer — set your disk, create a user, reboot.

**4. First boot — connect to the internet, open a terminal, then:**

```bash
git clone https://github.com/johnelliott/silverblue-setup ~/code/silverblue-setup
cd ~/code/silverblue-setup
bash install.sh
```

Reboot when it finishes. Done.

---

## Quick Start

```bash
git clone https://github.com/johnelliott/silverblue-setup ~/code/silverblue-setup
cd ~/code/silverblue-setup
bash install.sh
```

The script detects your hardware automatically — NVIDIA drivers install if an NVIDIA GPU is found, everything else runs unconditionally. One reboot at the end.

---

## What It Does

Runs in two tiers. Tier 1 finishes first so your dev environment is usable even if something in Tier 2 fails.

**Tier 1 — Core dev environment**

| Module | Description |
|---|---|
| `system.sh` | Enable sshd, skip GNOME welcome tour |
| `brew.sh` | Install Homebrew (Linuxbrew), configure shell |
| `dev-tools.sh` | Write mise shell hook (tools installed via Brewfile) |
| `dotfiles.sh` | Clone `~/code/dotfiles`, stow nvim config |

**Tier 2 — Desktop polish**

| Module | Description |
|---|---|
| `gnome.sh` | Dark mode, natural scroll, 24h clock, night light, touchpad prefs |
| `flatpaks.sh` | Add Flathub, install GUI apps |
| `extensions.sh` | Install GNOME Shell extensions by UUID |
| `extension-prefs.sh` | Apply dconf settings for extensions |
| `firefox.sh` | arkenfox user.js + personal overrides |
| `cli-tools.sh` | rivalcfg, python-kasa |

**Tier 3 — Opt-in hardware**

| Module | Description |
|---|---|
| `rpm-ostree.sh` | Ghostty terminal (COPR) — staged, reboot required |
| `nvidia.sh` | RPM Fusion, akmod-nvidia, CUDA, container toolkit |

---

## Flatpak Apps Installed

- **Bazaar** — app browser / store UI
- **Extension Manager** — GNOME extensions GUI
- **Blanket** — ambient sound / focus
- **dconf Editor** — low-level settings editor
- **Deskflow** — KVM / keyboard+mouse sharing
- **LocalSend** — local file transfer
- **Whis** — speech-to-text
- **VLC** — media player
- **Moonlight** — game streaming client

> Some Flatpak IDs are marked `# TODO: verify` in `install/flatpaks.sh` — confirm on Flathub before running.

---

## GNOME Extensions Installed

- **GSConnect** — Android integration (KDE Connect)
- **Just Perfection** — shell tweaks, animation speed
- **Caffeine** — prevent screen lock
- **Space Bar** — workspaces in top bar
- **Vitals** — CPU/RAM/temp in top bar
- **Rectangle** — window snapping (like macOS Rectangle)

---

## Running Individual Modules

Each script can be run standalone:

```bash
bash install/flatpaks.sh
bash install/gnome.sh
bash install/dev-tools.sh
```

---

## Items Requiring Manual Follow-Up

- **Display resolution** — hardware-specific, set via Settings or `gnome-randr`
- **Firefox extensions** — install manually from addons.mozilla.org (see `install/firefox.sh`)
- **Extension dconf keys** — after manual configuration, run:
  ```bash
  dconf dump /org/gnome/shell/extensions/ > my-extension-settings.dconf
  ```
  then update `install/extension-prefs.sh` with the output

---

## Post-Install Verification

```bash
flatpak list                              # GUI apps
brew list                                 # CLI tools
gnome-extensions list --enabled           # extensions
ls ~/.mozilla/firefox/*.default*/user.js  # Firefox config
ls ~/code/dotfiles                        # dotfiles
ls ~/.config/nvim                         # stowed nvim config
systemctl is-active sshd                  # SSH daemon
```

---

## After NVIDIA Install

Reboot is required for rpm-ostree changes:

```bash
sudo systemctl reboot
# after reboot:
nvidia-smi
```

---

## Philosophy

This setup follows the same principles as [Universal Blue](https://universal-blue.org), [Bazzite](https://bazzite.gg), and [Bluefin](https://projectbluefin.io): treat the OS as reliable, immutable infrastructure and keep it as clean as possible. Don't fight the system — work with it.

### Application installation hierarchy

1. **Flatpak first** — all GUI applications. Sandboxed, isolated, easy to remove, no impact on the base system.

2. **Homebrew for CLI tools** — installs to `/home/linuxbrew/.linuxbrew`, completely outside the OS layer. Use this for anything terminal-based that isn't a Flatpak.

3. **Distrobox for development** — rather than polluting the host with language runtimes or project dependencies, use a Distrobox container. This lets you `apt`, `dnf`, or `pacman` inside a container while keeping the host pristine. This setup installs mise as a lighter alternative for runtime version management.

4. **rpm-ostree as a last resort** — layering packages onto the base system requires a reboot, pauses atomic updates, and can cause dependency conflicts. Only use it for true system-level drivers (NVIDIA) or kernel modules where nothing else works.

### Why this matters

On an immutable system like Silverblue, the base OS is read-only and managed atomically — upgrades are all-or-nothing and safe to roll back. Layering packages undermines that. The more you layer, the more you drift from the clean base, the harder upgrades become, and the more you lose the benefits that made Silverblue worth using in the first place.

The goal is a system that stays clean over time: OS updated by rpm-ostree, GUI apps updated by `flatpak update`, CLI tools updated by `brew upgrade`, dev runtimes managed by mise. Each layer is independently updateable and easy to reason about.
