#!/usr/bin/env bash
# dev-tools.sh — Developer toolchain: mise, Node.js, Neovim dependencies

# Ensure brew is available
if ! command -v brew &>/dev/null; then
  echo "ERROR: brew not found. Run install/brew.sh first."
  return 1
fi

# ---------------------------------------------------------------------------
# mise — polyglot runtime version manager
# ---------------------------------------------------------------------------
if command -v mise &>/dev/null; then
  echo "mise already installed."
else
  brew install mise
fi

# Add mise shell hook to ~/.bashrc
if ! grep -q 'mise activate' ~/.bashrc 2>/dev/null; then
  echo "" >> ~/.bashrc
  echo "# mise" >> ~/.bashrc
  echo 'eval "$(mise activate bash)"' >> ~/.bashrc
  echo "Added mise hook to ~/.bashrc"
fi

# Add mise shell hook to ~/.zshrc if present
if [ -f ~/.zshrc ]; then
  if ! grep -q 'mise activate' ~/.zshrc; then
    echo "" >> ~/.zshrc
    echo "# mise" >> ~/.zshrc
    echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
    echo "Added mise hook to ~/.zshrc"
  fi
fi

# ---------------------------------------------------------------------------
# Node.js via mise
# ---------------------------------------------------------------------------
if ! command -v node &>/dev/null; then
  eval "$(mise activate bash)"
  mise install node@lts
  mise use --global node@lts
  echo "Node.js (LTS) installed via mise."
else
  echo "Node.js already available."
fi

# ---------------------------------------------------------------------------
# Neovim dependencies (for dotfiles / LazyVim / etc.)
# ---------------------------------------------------------------------------
BREW_TOOLS=(
  ripgrep   # telescope / fzf live grep
  fd        # telescope file finder
  lazygit   # git UI used by many nvim configs
  tree-sitter
)

echo "Installing Neovim dependencies via brew..."
for tool in "${BREW_TOOLS[@]}"; do
  if brew list "$tool" &>/dev/null; then
    echo "  $tool already installed."
  else
    brew install "$tool"
  fi
done

# gnu-stow — needed by dotfiles.sh
if ! command -v stow &>/dev/null; then
  brew install stow
fi

echo "Developer tools setup complete."
