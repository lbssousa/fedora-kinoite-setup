#!/usr/bin/env bash
# dev-tools.sh — Write shell activation hooks for tools installed via Brewfile
#
# The Brewfile in ~/code/dotfiles installs mise, stow, neovim, ripgrep, fd,
# and everything else. This script just ensures the shell hooks are written
# so those tools activate correctly in new sessions.

if ! command -v brew &>/dev/null; then
  echo "ERROR: brew not found. Run install/brew.sh first."
  return 1
fi

# ---------------------------------------------------------------------------
# gcc — needed for neovim treesitter parser compilation
# ---------------------------------------------------------------------------
if ! command -v gcc &>/dev/null; then
  echo "Installing gcc (needed by treesitter)..."
  brew install gcc
fi

# ---------------------------------------------------------------------------
# starship — install if not present, write shell hook
# ---------------------------------------------------------------------------
if ! command -v starship &>/dev/null; then
  echo "Installing starship..."
  brew install starship
fi

if ! grep -q 'STARSHIP_CONFIG' ~/.bashrc 2>/dev/null; then
  echo "" >> ~/.bashrc
  echo "# starship prompt" >> ~/.bashrc
  echo "# Config is stowed to ~/.config/starship/starship.toml (subdirectory)," >> ~/.bashrc
  echo "# but starship only checks ~/.config/starship.toml by default." >> ~/.bashrc
  echo 'export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"' >> ~/.bashrc
  echo 'eval "$(starship init bash)"' >> ~/.bashrc
  echo "Added starship hook to ~/.bashrc"
fi

# ---------------------------------------------------------------------------
# mise shell hook
# ---------------------------------------------------------------------------
if ! grep -q 'mise activate' ~/.bashrc 2>/dev/null; then
  echo "" >> ~/.bashrc
  echo "# mise" >> ~/.bashrc
  echo 'eval "$(mise activate bash)"' >> ~/.bashrc
  echo "Added mise hook to ~/.bashrc"
fi

if [ -f ~/.zshrc ]; then
  if ! grep -q 'mise activate' ~/.zshrc; then
    echo "" >> ~/.zshrc
    echo "# mise" >> ~/.zshrc
    echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
    echo "Added mise hook to ~/.zshrc"
  fi
fi

echo "Shell hooks written. Tools are installed via Brewfile (run dotfiles.sh)."
