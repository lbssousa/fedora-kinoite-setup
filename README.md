# silverblue-setup

Automated first-time desktop setup for Fedora Silverblue (and Fedora generally).
One entry point, ordered modular scripts — modeled after [Omakub](https://github.com/basecamp/omakub).

---

## Starting from scratch

1. Flash **Fedora Silverblue** with [Fedora Media Writer](https://github.com/FedoraQt/MediaWriter/releases/latest)
2. Boot from USB, run the Anaconda installer, reboot
3. Connect to the internet, open a terminal:

```bash
git clone https://github.com/johnelliott/silverblue-setup ~/code/silverblue-setup
cd ~/code/silverblue-setup
bash install.sh
```

NVIDIA drivers install automatically if an NVIDIA GPU is detected. One reboot at the end.

---

## What It Does

Runs in tiers. Tier 1 finishes first so your dev environment is usable even if something later fails.

| Tier | Modules | What happens |
|------|---------|--------------|
| **1 — Dev environment** | `system.sh` `brew.sh` `dev-tools.sh` `dotfiles.sh` | Homebrew, mise, starship, dotfiles (stow) |
| **2 — Desktop polish** | `gnome.sh` `fonts.sh` `flatpaks.sh` `extensions.sh` `extension-prefs.sh` `firefox.sh` `cli-tools.sh` | GNOME prefs, Nerd Font, Flatpak apps, shell extensions, arkenfox Firefox |
| **3 — Hardware** | `rpm-ostree.sh` `nvidia.sh` | Ghostty (COPR), ddcutil, NVIDIA drivers |
| **4 — sudo** | `sudo-tweaks.sh` | sshd, GeoClue |

Each script can also be run standalone: `bash install/gnome.sh`

<details>
<summary>Full inventory (Flatpak IDs, extension UUIDs, GNOME prefs, etc.)</summary>

### GNOME Preferences (`gnome.sh`)

- Dark mode, 12-hour clock, battery percentage, center new windows
- Window buttons: minimize, maximize, close
- Natural scroll, tap-to-click, two-finger scroll
- Keybindings: Ctrl+Alt+T → Ghostty, Ctrl+Alt+W → Whis dictation

### Flatpak Apps

| App | Flatpak ID |
|---|---|
| Bazaar | `io.github.kolunmi.Bazaar` |
| Extension Manager | `com.mattjakeman.ExtensionManager` |
| Blanket | `com.rafaelmardojai.Blanket` |
| dconf Editor | `ca.desrt.dconf-editor` |
| Deskflow | `org.deskflow.deskflow` |
| LocalSend | `org.localsend.localsend_app` |
| Whis | `ink.whis.Whis` |
| VLC | `org.videolan.VLC` |
| Moonlight | `com.moonlight_stream.Moonlight` |
| Signal | `org.signal.Signal` |
| Syncthing GTK | — |

### GNOME Shell Extensions

| Extension | UUID |
|---|---|
| GSConnect | `gsconnect@andyholmes.github.io` |
| Just Perfection | `just-perfection-desktop@just-perfection` |
| Caffeine | `caffeine@patapon.info` |
| Space Bar | `space-bar@luchrioh` |
| Vitals | `Vitals@CoreCoding.com` |
| Rectangle | `rectangle@acristoffers.me` |
| Hot Edge | — |
| Display Brightness (ddcutil) | — |

### Homebrew CLI Tools

mise, ripgrep, fd, lazygit, tree-sitter, stow, starship

### Firefox

arkenfox `user.js` + overrides: blank new tab, session restore, compact UI, no Pocket.
Manual installs: uBlock Origin, Bitwarden, Dark Reader, Vimium-FF.

### rpm-ostree Layers

Ghostty (COPR), ddcutil, gcc/make (for treesitter)

</details>

---

## Manual Follow-Up

- **Display resolution** — hardware-specific, set via Settings
- **Firefox extensions** — install from addons.mozilla.org
- **Extension dconf keys** — capture with `dconf dump /org/gnome/shell/extensions/` once configured

---

## Philosophy

Follows the same principles as [Universal Blue](https://universal-blue.org) / [Bazzite](https://bazzite.gg) / [Bluefin](https://projectbluefin.io): treat the OS as immutable infrastructure, keep it clean.

1. **Flatpak** — GUI apps (sandboxed, no system impact)
2. **Homebrew** — CLI tools (installs to `/home/linuxbrew/`, outside the OS)
3. **mise** — language runtimes (lighter alternative to Distrobox for version management)
4. **rpm-ostree** — last resort (drivers, kernel modules only)

The goal: each layer updates independently (`flatpak update`, `brew upgrade`, `rpm-ostree upgrade`), and the system stays clean over time.
