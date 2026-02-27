#!/usr/bin/env bash
# cli-tools.sh — Miscellaneous CLI tools

# rivalcfg — SteelSeries mouse configuration
# Use pipx to avoid PEP 668 externally-managed-environment restrictions
echo "Installing rivalcfg..."
if command -v pipx &>/dev/null; then
  pipx install rivalcfg
  echo "rivalcfg installed."
else
  echo "WARNING: pipx not found — skipping rivalcfg."
  echo "  Install manually: pipx install rivalcfg"
  echo "  See: https://github.com/flozz/rivalcfg"
fi

echo "CLI tools setup complete."
