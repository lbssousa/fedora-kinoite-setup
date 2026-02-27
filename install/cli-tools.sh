#!/usr/bin/env bash
# cli-tools.sh — Miscellaneous CLI tools

# ---------------------------------------------------------------------------
# rivalcfg — SteelSeries mouse configuration
# ---------------------------------------------------------------------------
echo "Installing rivalcfg..."
if command -v pip3 &>/dev/null || command -v pip &>/dev/null; then
  PIP=$(command -v pip3 || command -v pip)
  "$PIP" install --user rivalcfg
  echo "rivalcfg installed via pip."
else
  echo "WARNING: pip not found — skipping rivalcfg."
  echo "  Install manually: pip install --user rivalcfg"
  echo "  Or see: https://github.com/flozz/rivalcfg"
fi

# ---------------------------------------------------------------------------
# python-kasa — TP-Link Kasa smart plug / smart home CLI
# ---------------------------------------------------------------------------
echo "Installing python-kasa..."
if command -v pip3 &>/dev/null || command -v pip &>/dev/null; then
  PIP=$(command -v pip3 || command -v pip)
  "$PIP" install --user python-kasa
  echo "python-kasa installed."
  echo "  Usage: kasa discover"
else
  echo "WARNING: pip not found — skipping python-kasa."
  echo "  Install manually: pip install --user python-kasa"
fi

# ---------------------------------------------------------------------------
# Whis — handled in flatpaks.sh (ink.whis.Whis)
# ---------------------------------------------------------------------------
echo "  Note: Whis speech-to-text is installed via flatpaks.sh"

echo "CLI tools setup complete."
