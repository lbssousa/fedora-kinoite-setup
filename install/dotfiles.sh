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
    return 1
  fi
fi

# Clone dotfiles
if [ -d "$DOTFILES_DIR/.git" ]; then
  echo "Dotfiles already cloned, skipping clone."
  # Don't pull — avoids failing on non-fast-forward or local changes.
  # Run 'git -C ~/code/dotfiles pull' manually to update.
else
  echo "Cloning dotfiles from $DOTFILES_REPO..."
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

# Stow packages — run in a subshell so cd doesn't affect the parent shell
STOW_PACKAGES=(
  nvim
  # Add more stow packages here as needed, e.g.:
  # git
  # zsh
  # tmux
)

(
  cd "$DOTFILES_DIR"
  for pkg in "${STOW_PACKAGES[@]}"; do
    if [ -d "$pkg" ]; then
      echo "Stowing $pkg..."
      stow --restow "$pkg"
    else
      echo "  WARNING: stow package '$pkg' not found in $DOTFILES_DIR — skipping"
    fi
  done
)

echo "Dotfiles setup complete."
