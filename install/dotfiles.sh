#!/usr/bin/env bash
# dotfiles.sh — Clone dotfiles repo and stow packages

DOTFILES_REPO="https://github.com/johnelliott/dotfiles"
DOTFILES_DIR="$HOME/code/dotfiles"

# Ensure ~/code exists
mkdir -p "$HOME/code"

# Ensure stow is available
if ! command -v stow &>/dev/null; then
  if command -v brew &>/dev/null; then
    echo "Installing stow via brew..."
    brew install stow
  else
    echo "ERROR: stow not found and brew is not available."
    echo "  Install stow manually: sudo dnf install stow  (or via brew)"
    exit 1
  fi
fi

# Clone dotfiles
if [ -d "$DOTFILES_DIR/.git" ]; then
  echo "Dotfiles already cloned, pulling latest..."
  git -C "$DOTFILES_DIR" pull --ff-only
else
  echo "Cloning dotfiles from $DOTFILES_REPO..."
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

# Stow packages
cd "$DOTFILES_DIR"

STOW_PACKAGES=(
  nvim
  # Add more stow packages here as needed, e.g.:
  # git
  # zsh
  # tmux
)

for pkg in "${STOW_PACKAGES[@]}"; do
  if [ -d "$pkg" ]; then
    echo "Stowing $pkg..."
    stow --restow "$pkg"
  else
    echo "  WARNING: stow package '$pkg' not found in $DOTFILES_DIR — skipping"
  fi
done

echo "Dotfiles setup complete."
