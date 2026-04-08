# fedora-kinoite-setup

Automated first-time desktop setup for Fedora Kinoite (KDE Plasma on ostree).
Modular scripts in `install/`, orchestrated by `install.sh`.

Installs: Homebrew, mise, starship, dotfiles (stow), Nerd Font, Flatpak apps, KDE Plasma settings, NVIDIA drivers + SecureBoot signing (if detected), TPM2 LUKS auto-unlock.

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
