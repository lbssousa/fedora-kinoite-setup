#!/usr/bin/env bash
# system.sh — Basic system setup: sshd, skip GNOME welcome tour

# Skip GNOME initial setup / welcome tour
touch ~/.config/gnome-initial-setup-done

gsettings set org.gnome.shell welcome-dialog-last-shown-version "9999"

echo "GNOME welcome tour disabled."
