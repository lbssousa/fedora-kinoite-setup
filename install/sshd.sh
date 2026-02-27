#!/usr/bin/env bash
# sshd.sh — Enable SSH daemon (requires sudo)
#
# Runs last so a skipped or failed password prompt doesn't block anything else.

if ! command -v systemctl &>/dev/null; then
  echo "WARNING: systemctl not found — skipping sshd setup."
  return 0
fi

echo "Enabling sshd (sudo password required)..."
sudo systemctl enable --now sshd && echo "sshd enabled and started." || \
  echo "WARNING: sshd not enabled — run 'sudo systemctl enable --now sshd' manually."
