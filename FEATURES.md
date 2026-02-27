# Feature Inventory

Full list of everything this setup installs and configures.

---

## System

- sshd enabled on first boot
- GNOME welcome tour / initial setup wizard suppressed

---

## GNOME Desktop Preferences

- Dark mode (system-wide `prefer-dark`)
- 24-hour clock format
- Show battery percentage in top bar
- Center new windows on screen
- Window title bar buttons: minimize, maximize, close
- Natural scroll on touchpad and mouse
- Tap-to-click on touchpad
- Two-finger scroll on touchpad
- Night light enabled (3700K warm tone)
- RGBA font anti-aliasing, slight hinting
- AC power: no auto-suspend

---

## Flatpak GUI Applications

| App | Flatpak ID | Purpose |
|---|---|---|
| Bazaar | `io.github.kolunmi.Bazaar` | App browser / store UI |
| Extension Manager | `com.mattjakeman.ExtensionManager` | GNOME Shell extension manager |
| Blanket | `com.rafaelmardojai.Blanket` | Ambient sound / focus |
| dconf Editor | `ca.desrt.dconf-editor` | Low-level GNOME settings editor |
| Deskflow | `org.deskflow.deskflow` | KVM / keyboard+mouse sharing |
| LocalSend | `org.localsend.localsend_app` | LAN file transfer |
| Whis | `ink.whis.Whis` | Speech-to-text |

---

## Homebrew (CLI / Dev)

| Tool | Purpose |
|---|---|
| mise | Polyglot runtime version manager |
| Node.js LTS | JavaScript runtime (via mise) |
| ripgrep | Fast grep (used by Neovim telescope) |
| fd | Fast file finder (used by Neovim telescope) |
| lazygit | Terminal git UI |
| tree-sitter | Parser toolkit (Neovim treesitter) |
| stow | Symlink manager for dotfiles |

---

## GNOME Shell Extensions

| Extension | UUID | Purpose |
|---|---|---|
| GSConnect | `gsconnect@andyholmes.github.io` | Android ↔ desktop integration |
| Just Perfection | `just-perfection-desktop@just-perfection` | Shell tweaks, animation control |
| Caffeine | `caffeine@patapon.info` | Prevent screen lock / suspend |
| Space Bar | `space-bar@luchrioh` | Named workspaces in top bar |
| Vitals | `Vitals@CoreCoding.com` | CPU/RAM/temp in top bar |
| _(Tiling — TBD)_ | see `install/extensions.sh` | Window tiling / management |
| _(Hot Edge — TBD)_ | see `install/extensions.sh` | Hot corner / edge actions |

---

## Extension Configuration (dconf)

- Just Perfection: minimal animations, hidden Activities button, hidden app menu
- Vitals: _(keys to be filled after live configuration)_
- Space Bar: _(keys to be filled after live configuration)_
- Caffeine: _(keys to be filled after live configuration)_

---

## Firefox

- arkenfox `user.js` (privacy-hardened baseline)
- Personal overrides (`configs/firefox/user-overrides.js`):
  - Blank new tab + startup page
  - Restore session on startup
  - Compact UI density
  - Smooth scrolling
  - Pocket disabled
  - `userChrome.css` support enabled
- Manual extension installs: uBlock Origin, Bitwarden, Dark Reader, Vimium-FF

---

## Dotfiles

- Clone `https://github.com/johnelliott/dotfiles` → `~/code/dotfiles`
- `stow nvim` → symlinks Neovim config into `~/.config/nvim`

---

## CLI Tools

| Tool | Install method | Purpose |
|---|---|---|
| rivalcfg | pip (user) | SteelSeries mouse configuration |
| python-kasa | pip (user) | TP-Link Kasa smart plug control |
| Whis | Flatpak | Speech-to-text (listed above too) |

---

## NVIDIA (opt-in: `--nvidia` flag)

- RPM Fusion free + nonfree repositories
- `akmod-nvidia` — kernel module (auto-rebuilds on kernel updates)
- `xorg-x11-drv-nvidia` — Xorg driver
- `xorg-x11-drv-nvidia-cuda` — CUDA support
- NVIDIA container toolkit (for GPU in containers / Podman)
- Reboot required after installation
