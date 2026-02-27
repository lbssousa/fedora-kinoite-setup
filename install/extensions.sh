#!/usr/bin/env bash
# extensions.sh — Install GNOME Shell extensions via gnome-extensions-cli (gext)

# ---------------------------------------------------------------------------
# Ensure gext is available
# ---------------------------------------------------------------------------
if ! command -v gext &>/dev/null; then
  if ! command -v pipx &>/dev/null; then
    echo "Installing pipx via brew..."
    brew install pipx
    pipx ensurepath
  fi
  echo "Installing gnome-extensions-cli..."
  pipx install gnome-extensions-cli --system-site-packages
fi

# Make sure gext is on PATH (pipx installs to ~/.local/bin)
export PATH="$HOME/.local/bin:$PATH"

if ! command -v gext &>/dev/null; then
  echo "ERROR: gext not found after install — check pipx PATH"
  return 1
fi

# ---------------------------------------------------------------------------
# Extension list
# ---------------------------------------------------------------------------

EXTENSIONS=(
  "gsconnect@andyholmes.github.io"          # Android/desktop integration
  "just-perfection-desktop@just-perfection" # Shell tweaks, animation control
  "caffeine@patapon.info"                   # Prevent screen lock / suspend
  "space-bar@luchrioh"                      # Named workspaces in top bar
  "Vitals@CoreCoding.com"                   # CPU/RAM/temp in top bar
  "rectangle@acristoffers.me"              # Window snapping (like macOS Rectangle)
)

echo "Installing GNOME extensions via gext..."
for uuid in "${EXTENSIONS[@]}"; do
  echo "  Installing $uuid"
  gext install "$uuid" || echo "  WARNING: failed to install $uuid"
done

echo ""
echo "Extensions installed. Enable them in Extension Manager, then log out"
echo "and back in for them to take effect."
