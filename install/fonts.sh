#!/usr/bin/env bash
# fonts.sh — Install Meslo LGS DZ Nerd Font from GitHub releases
#
# Homebrew Cask font installs are macOS-only; on Linux we download directly
# from the Nerd Fonts releases and install to ~/.local/share/fonts.
# Same approach used by Omakub.

FONT_DIR="$HOME/.local/share/fonts"

# Check if already installed
if fc-list | grep -qi "MesloLGSDZ.*Nerd"; then
  echo "Meslo LGS DZ Nerd Font already installed."
  exit 0
fi

echo "Downloading Meslo Nerd Font..."
mkdir -p "$FONT_DIR"
curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip" \
  -o /tmp/Meslo.zip
unzip -qo /tmp/Meslo.zip -d "$FONT_DIR"
rm -f /tmp/Meslo.zip

echo "Refreshing font cache..."
fc-cache -f "$FONT_DIR"
echo "Meslo Nerd Font installed."
