#!/usr/bin/env bash
# editors.sh — Install developer editors and container tooling
#
# - Distrobox: installed via the official curl installer to ~/.local (no rpm-ostree)
# - VSCode: installed via Homebrew using the ublue-os tap
# - Zed: installed as a Flatpak from Flathub

# ---------------------------------------------------------------------------
# Distrobox — container-based CLI environment manager
# Install to ~/.local so no root is needed and the binary survives OS updates
# ---------------------------------------------------------------------------
if command -v distrobox &>/dev/null; then
  echo "Distrobox already installed, skipping."
else
  echo "Installing Distrobox to ~/.local..."
  curl -s https://raw.githubusercontent.com/89luca89/distrobox/main/install \
    | sh -s -- --prefix ~/.local
  echo "Distrobox installed."
fi

# ---------------------------------------------------------------------------
# VSCode — via ublue-os Homebrew tap
# https://github.com/ublue-os/homebrew-tap
# ---------------------------------------------------------------------------
if ! command -v brew &>/dev/null; then
  echo "ERROR: brew not found. Run install/brew.sh first."
  return 1
fi

if brew list --cask code &>/dev/null || brew list code &>/dev/null; then
  echo "VSCode already installed via Homebrew, skipping."
else
  echo "Tapping ublue-os/tap..."
  brew tap ublue-os/tap

  echo "Installing VSCode via Homebrew (ublue-os/tap)..."
  brew install ublue-os/tap/code
fi

# ---------------------------------------------------------------------------
# Zed — code editor Flatpak
# ---------------------------------------------------------------------------
if flatpak list --app 2>/dev/null | grep -q "dev.zed.Zed"; then
  echo "Zed already installed, skipping."
else
  echo "Installing Zed (Flatpak)..."
  flatpak install --user --noninteractive flathub dev.zed.Zed || \
    echo "WARNING: failed to install Zed — check the app ID or Flathub availability"
fi

echo "Editors setup complete."
