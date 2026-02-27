# Setup Interview

All questions resolved. This file is kept as a record of decisions made.

---

## 1. Flatpak App IDs — RESOLVED
- Bazaar: `io.github.kolunmi.Bazaar` ✓ (confirmed from live machine)
- Deskflow: `org.deskflow.deskflow` ✓ (confirmed from live machine)
- LocalSend: `org.localsend.localsend_app` — keeping, user confirmed they want it
- Added: VLC, Moonlight, Signal

## 2. GNOME Extensions — RESOLVED
- Tiling: Rectangle (`rectangle@acristoffers.me`) ✓ confirmed on EGO, GNOME 49
- Hot corners: skipped — user doesn't use them

## 3. Extension Preferences — ACTION ITEM
After first live install, configure extensions manually then run:
```bash
dconf dump /org/gnome/shell/extensions/ > extension-settings.dconf
```
Paste output to fill in stubs in `install/extension-prefs.sh`.

## 4. Firefox Extensions — RESOLVED
Manual install list in `install/firefox.sh`:
1. uBlock Origin
2. 1Password
3. Firefox Multi-Account Containers
4. Facebook Container
5. Privacy Badger (maybe)

## 5. Firefox / Arkenfox Overrides — RESOLVED
Using arkenfox defaults. Overrides in `configs/firefox/user-overrides.js`:
- Blank new tab page
- Restore previous session on startup
- Pocket disabled
Password saving stays disabled (arkenfox default) — using 1Password.

## 6. Dotfiles / Stow Packages — RESOLVED
`dotfiles.sh` clones the repo and runs `dotfiles/install.sh` directly,
which handles `brew bundle` + all stow packages correctly.

## 7. Developer Tools — RESOLVED
Brewfile in dotfiles repo is the source of truth. `dev-tools.sh` only
writes the mise shell hook.

## 8. rivalcfg — RESOLVED
Install only, no config script. Handled in `install/cli-tools.sh`.

## 9. Kasa — RESOLVED
Removed entirely.

## 10. GNOME Appearance — RESOLVED
Use GNOME defaults. No custom fonts, icons, wallpaper, or scaling.

## 11. NVIDIA — RESOLVED
gum prompts in `install/choices.sh` handle this at runtime based on
hardware detection (NVIDIA, AMD, VM, multi-GPU).

## 12. Shell — RESOLVED
Bash — whatever Silverblue ships with.

## 13. Other Apps — RESOLVED
Added: Signal, VLC, Moonlight, Ghostty.
Skipped: Spotify, Discord, Obsidian, Wireshark.

## 14. General — RESOLVED

**Hostname:** Low priority. Set via `MACHINE_NAME` env var if needed
(not currently implemented — add to system.sh when wanted).

**Silent vs prompted:** Already resolved by design. The script is
silent end-to-end *except* for `install/choices.sh` which asks 2-3
hardware questions (Ghostty, NVIDIA drivers, container toolkit). Those
prompts are unavoidable — they're why gum was added. You explicitly
asked for hardware detection + user choice rather than hardcoded flags.
Everything else (flatpaks, extensions, Firefox, dotfiles) runs without
any pauses.
