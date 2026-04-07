# silverblue-setup

Automated first-time desktop setup for Fedora Silverblue.
Modular scripts in `install/`, orchestrated by `install.sh`.

Installs: Homebrew, mise, starship, dotfiles (stow), Nerd Font, Flatpak apps, GNOME shell extensions, arkenfox Firefox, Ghostty (COPR), NVIDIA drivers (if detected).

Each script can also be run standalone: `bash install/gnome.sh`

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

One reboot at the end.

---

## Starting from a Mac (UTM)

If you're running Fedora Silverblue in a UTM virtual machine on Apple Silicon, see [`utm/README.md`](utm/README.md). The setup script creates the VM, downloads the ISO, and syncs this repo into a shared folder so the guest can run `install.sh` automatically.

```bash
./utm/setup-vm.sh
```

---

## Manual Follow-Up

- **Display resolution** — hardware-specific, set via Settings
- **Firefox extensions** — install from addons.mozilla.org
- **Extension dconf keys** — capture with `dconf dump /org/gnome/shell/extensions/` once configured

---

Follows the [Universal Blue](https://universal-blue.org) philosophy: Flatpak for GUI apps, Homebrew for CLI tools, rpm-ostree only for drivers. Each layer updates independently and the system stays clean.
