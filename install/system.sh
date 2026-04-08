#!/usr/bin/env bash
# system.sh — Basic system setup: skip KDE Plasma welcome screen

# Skip KDE Plasma Welcome screen on first login
if command -v kwriteconfig6 &>/dev/null; then
  kwriteconfig6 --file plasma-welcomerc --group "General" --key "LiveEnvironment" "false"
  echo "KDE Plasma welcome screen disabled."
elif command -v kwriteconfig5 &>/dev/null; then
  kwriteconfig5 --file plasma-welcomerc --group "General" --key "LiveEnvironment" "false"
  echo "KDE Plasma welcome screen disabled."
else
  echo "WARNING: kwriteconfig not found — skipping Plasma welcome screen disable."
fi
