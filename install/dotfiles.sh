#!/usr/bin/env bash
# dotfiles.sh — Clone dotfiles and run their install script

DOTFILES_REPO="https://github.com/johnelliott/dotfiles"
DOTFILES_DIR="$HOME/code/dotfiles"

mkdir -p "$HOME/code"

# Clone dotfiles
if [ -d "$DOTFILES_DIR/.git" ]; then
  echo "Dotfiles already cloned, skipping clone."
else
  echo "Cloning dotfiles from $DOTFILES_REPO..."
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

# Run the dotfiles install script — handles brew bundle + all stow packages
echo "Running dotfiles install..."
(
  cd "$DOTFILES_DIR"
  bash install.sh
)

echo "Dotfiles setup complete."
