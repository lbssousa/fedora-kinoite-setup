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
