#!/usr/bin/env bash
# fonts.sh — Install Meslo LGS DZ Nerd Font from GitHub releases
#
# Homebrew Cask font installs are macOS-only; on Linux we download directly
# from the Nerd Fonts releases and install to ~/.local/share/fonts.

FONT_DIR="$HOME/.local/share/fonts"
FONT_NAME="Meslo"

# Check if already installed (look for any MesloLGSDZ Nerd Font file)
if fc-list | grep -qi "MesloLGSDZ.*Nerd"; then
  echo "Meslo LGS DZ Nerd Font already installed."
  exit 0
fi

echo "Fetching latest Nerd Fonts release tag..."
LATEST=$(curl -fsSL "https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest" \
  | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')

if [ -z "$LATEST" ]; then
  echo "ERROR: Could not determine latest Nerd Fonts release."
  exit 1
fi

echo "Downloading ${FONT_NAME}.zip (${LATEST})..."
TMP_ZIP="$(mktemp /tmp/NerdFont-XXXXXX.zip)"
curl -fsSL \
  "https://github.com/ryanoasis/nerd-fonts/releases/download/${LATEST}/${FONT_NAME}.zip" \
  -o "$TMP_ZIP"

mkdir -p "$FONT_DIR"
echo "Extracting to ${FONT_DIR}..."
unzip -qo "$TMP_ZIP" -d "$FONT_DIR"
rm -f "$TMP_ZIP"

echo "Refreshing font cache..."
fc-cache -f "$FONT_DIR"

echo "Meslo Nerd Font installed."
