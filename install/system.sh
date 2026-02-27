#!/usr/bin/env bash
# system.sh — Basic system setup: sshd, skip GNOME welcome tour

# Skip GNOME initial setup / welcome tour
touch ~/.config/gnome-initial-setup-done

gsettings set org.gnome.shell welcome-dialog-last-shown-version "9999"

echo "GNOME welcome tour disabled."

# Enable SSH daemon
if command -v systemctl &>/dev/null; then
  sudo systemctl enable --now sshd
  echo "sshd enabled and started."
else
  echo "WARNING: systemctl not found — skipping sshd setup."
fi
