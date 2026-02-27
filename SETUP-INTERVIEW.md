# Setup Interview

Questions to capture your preferences before finalizing the scripts.
Work through these once, answer inline or in a separate doc, then update the relevant scripts.

---

## 1. Flatpak App IDs

A few apps need their exact Flathub IDs confirmed.

- **Pods (Bazaar)**: Is the app you want `com.github.marhkb.Pods`? Or is it a different container/image browser — e.g. Bazaar (`io.github.nickvdyck.bazaar`)? What do you actually call it / use it for?
- **Deskflow**: Is `io.github.deskflow.deskflow` the right ID, or is there a different KVM tool you prefer (Barrier, Input Leap)?
- **LocalSend**: Is `org.localsend.localsend_app` correct? (The trailing `_app` is unusual — worth checking on Flathub.)
- **Any other GUI apps** to add or remove from the flatpaks list?

---

## 2. GNOME Extensions

Several extension choices need your input.

- **Tiling / window management**: Which do you want?
  - *Tiling Assistant* (`tiling-assistant@leleat-on-github`) — closest to macOS snapping
  - *gTile* (`gTile@vibou`) — grid-based manual tiling
  - *WinTile* (`WinTile@nowsci.com`) — basic quarter/half tiling
  - Something else?

- **Hot Edge / Hot Corners**: Which do you want?
  - *Hot Edge* (`hotedge@jonathan.jdoda.ca`) — triggers overview at screen edge
  - *Custom Hot Corners Extended* — more configurable
  - None — you don't use hot corners?

- **Any other extensions** you want added (e.g. AppIndicator, Blur My Shell, Media Controls)?

---

## 3. Extension Preferences

Once extensions are installed and you've configured them manually, the dconf keys need to be captured. For now:

- **Just Perfection**: Are the defaults here okay (hide Activities button, hide app menu, minimal animation)? Any other elements to hide?
- **Vitals**: Which sensors do you want visible in the top bar? (CPU %, CPU temp, RAM, network, storage, fan?)
- **Space Bar**: Do you want empty workspaces shown? Any color/style preferences?

> **Action**: After your first live install, run `dconf dump /org/gnome/shell/extensions/` and paste the output — I'll fill in the `extension-prefs.sh` stubs.

---

## 4. Firefox Extensions

Firefox can't auto-install extensions for personal profiles. The four currently documented for manual install are:

1. uBlock Origin
2. Bitwarden
3. Dark Reader
4. Vimium-FF

- Is this your actual set? Anything to add or remove?
- Do you want to explore the `policies.json` approach for a managed Firefox install instead of manual steps?

---

## 5. Firefox / Arkenfox Overrides

The current `user-overrides.js` restores session, enables compact UI, disables Pocket. Review:

- **Session restore on startup** — keep or prefer a blank start?
- **Browsing history** — arkenfox default clears it on shutdown. Want to keep history between sessions?
- **Password manager** — using Bitwarden (keep Firefox passwords disabled) or want Firefox's built-in saver?
- **Any other privacy vs. convenience trade-offs** you've made in Firefox that should be captured here?

---

## 6. Dotfiles / Stow Packages

Currently only `stow nvim`. Do you stow any other packages from your dotfiles repo?

- git config?
- zsh / bash configs?
- tmux?
- Any other tool configs that live in dotfiles?

Also: should `dotfiles.sh` run any post-stow commands (e.g. install Neovim plugin manager, run `:Lazy sync`)?

---

## 7. Developer Tools

- **Node.js**: Install via `mise` (current plan) or via `brew install node` directly? Any preference on the version (LTS vs latest)?
- **Python**: Do you want a managed Python version via mise too (e.g. `mise install python@3.12`)?
- **Any other runtimes** managed by mise (Go, Rust, Ruby)?
- **Any other brew CLI tools** not in the current list?

---

## 8. rivalcfg / SteelSeries Mouse

- Which SteelSeries mouse model(s) do you have? (rivalcfg supports many but config commands differ by model.)
- Do you want a post-install script that actually applies your preferred DPI / button config, or just having rivalcfg installed is enough?

---

## 9. Kasa Smart Plugs

- Any specific `kasa` CLI commands you run regularly that should be scripted or aliased?
- Should any aliases be added to `~/.bashrc` / `~/.zshrc`?

---

## 10. GNOME Appearance

- **Fonts**: Any preference for system font, monospace font, or document font beyond the defaults?
- **Icons / cursor theme**: Do you use a custom icon set (e.g. Papirus) or GTK theme?
- **Wallpaper**: Should the setup script set a wallpaper? (Path or URL?)
- **Fractional scaling**: Do you use HiDPI or fractional scaling? If so, what factor?

---

## 11. NVIDIA

- Do you have an NVIDIA GPU in this machine? (NVIDIA setup is already opt-in via `--nvidia` flag.)
- If yes: do you use GPU in containers / Podman today? (Affects whether nvidia-container-toolkit is worth the extra rpm-ostree layer.)
- Any CUDA toolkit preferences (full CUDA vs. just driver)?

---

## 12. Shell

- Do you use bash, zsh, or fish as your primary shell?
  - Current scripts add hooks to `~/.bashrc` and `~/.zshrc` (if present). Anything else needed for fish?
- Any shell plugins or frameworks (oh-my-zsh, starship prompt, etc.) that should be part of the setup?

---

## 13. Other Apps / Tools

- Any **productivity apps** missing from the flatpak list (e.g. Obsidian, Notion, Slack, Signal, Telegram, Spotify)?
- Any **creative tools** (GIMP, Inkscape, Blender, Darktable)?
- Any **communication apps** (Thunderbird, Evolution, Discord)?
- Any **development IDEs** beyond Neovim (VS Code, JetBrains)?

---

## 14. General

- Should `install.sh` prompt before each module ("Press Enter to continue...") or run silently end-to-end?
- Should any modules be skippable with a flag (e.g. `--skip-nvidia`, `--skip-firefox`)?
- Is there a machine name / hostname you always set on fresh installs?
