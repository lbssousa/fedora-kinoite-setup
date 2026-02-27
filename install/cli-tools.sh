#!/usr/bin/env bash
# cli-tools.sh — Miscellaneous CLI tools

# rivalcfg — SteelSeries mouse configuration
echo "Installing rivalcfg..."
if command -v pip3 &>/dev/null || command -v pip &>/dev/null; then
  PIP=$(command -v pip3 || command -v pip)
  "$PIP" install --user rivalcfg
  echo "rivalcfg installed."
else
  echo "WARNING: pip not found — skipping rivalcfg."
  echo "  Install manually: pip install --user rivalcfg"
  echo "  See: https://github.com/flozz/rivalcfg"
fi

echo "CLI tools setup complete."
