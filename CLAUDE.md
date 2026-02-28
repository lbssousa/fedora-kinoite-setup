# silverblue-setup

Automated first-time desktop setup for Fedora Silverblue. Modular scripts in `install/`, orchestrated by `install.sh`.

## Repo structure

- `install.sh` — main entry point, runs scripts in tiered order
- `install/*.sh` — individual modules (brew, gnome, flatpaks, firefox, etc.)
- `configs/` — config files deployed by the install scripts (firefox policies, user-overrides.js)
- `ascii.sh` — banner art

## Companion repo

Dotfiles live at `~/code/dotfiles` (github.com/johnelliott/dotfiles). That repo uses GNU Stow. This repo's `install/dotfiles.sh` clones and runs it.

## Key conventions

- Scripts use `return` (not `exit`) for errors because they're sourced by `install.sh`
- GNOME settings go in `install/gnome.sh` via `gsettings set`
- Extension dconf prefs go in `install/extension-prefs.sh` via `dconf write`
- Flatpak IDs go in `install/flatpaks.sh`
- Shell hooks (brew, starship, mise) are appended to `~/.bashrc` by `brew.sh` and `dev-tools.sh`
- Firefox uses enterprise policies at `/etc/firefox/policies/policies.json` (needs sudo) for things like default search engine, and `user.js` overrides in the profile for arkenfox settings

## Platform

- Fedora Silverblue (immutable, rpm-ostree based)
- `/usr/` is read-only — use `/etc/` for system config, home dir for user config
- Homebrew installs to `/home/linuxbrew/.linuxbrew`
- GNOME on Wayland
