#!/usr/bin/env bash
# extensions.sh — Install GNOME Shell extensions by UUID

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_EXT="$SCRIPT_DIR/../bin/install-gnome-extension"

if [ ! -x "$INSTALL_EXT" ]; then
  chmod +x "$INSTALL_EXT"
fi

# ---------------------------------------------------------------------------
# Extension UUIDs
# ---------------------------------------------------------------------------

EXTENSIONS=(
  # GSConnect — Android/desktop integration (KDE Connect protocol)
  "gsconnect@andyholmes.github.io"

  # Just Perfection — GNOME shell tweaks (hide panel elements, animations)
  "just-perfection-desktop@just-perfection"

  # Caffeine — prevent screen lock / suspend
  "caffeine@patapon.info"

  # Space Bar — workspaces shown in top bar as named spaces
  "space-bar@luchrioh"

  # Vitals — system stats in top bar (CPU, RAM, temp)
  "Vitals@CoreCoding.com"

  # TODO: confirm UUID for a tiling/window management extension.
  # Options:
  #   "tiling-assistant@leleat-on-github"   — Tiling Assistant (recommended)
  #   "gTile@vibou"                          — gTile
  #   "WinTile@nowsci.com"                   — WinTile
  # Uncomment your choice:
  # "tiling-assistant@leleat-on-github"

  # TODO: confirm UUID for Hot Edges (hot corners with configurable actions).
  # Options:
  #   "hotedge@jonathan.jdoda.ca"            — Hot Edge
  #   "custom-hot-corners-extended@G-dH.github.com"
  # Uncomment your choice:
  # "hotedge@jonathan.jdoda.ca"
)

echo "Installing GNOME extensions..."
for uuid in "${EXTENSIONS[@]}"; do
  "$INSTALL_EXT" "$uuid" || echo "  WARNING: failed to install $uuid"
done

echo "Extensions installation complete."
echo "You may need to log out and back in, then enable extensions via Extension Manager."
