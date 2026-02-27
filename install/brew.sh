#!/usr/bin/env bash
# brew.sh — Install Homebrew (Linuxbrew) and configure shell integration

if command -v brew &>/dev/null; then
  echo "Homebrew already installed, skipping install."
else
  echo "Installing Homebrew (non-interactive)..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Determine brew prefix (differs on ARM vs x86, must check after install)
if [ -d /home/linuxbrew/.linuxbrew ]; then
  BREW_PREFIX="/home/linuxbrew/.linuxbrew"
elif [ -d "$HOME/.linuxbrew" ]; then
  BREW_PREFIX="$HOME/.linuxbrew"
elif command -v brew &>/dev/null; then
  BREW_PREFIX="$(brew --prefix)"
else
  echo "ERROR: Homebrew install appears to have failed — brew not found."
  return 1
fi

BREW_SHELLENV="eval \"\$(${BREW_PREFIX}/bin/brew shellenv)\""

# Add brew to ~/.bashrc
if ! grep -q 'brew shellenv' ~/.bashrc 2>/dev/null; then
  echo "" >> ~/.bashrc
  echo "# Homebrew" >> ~/.bashrc
  echo "$BREW_SHELLENV" >> ~/.bashrc
  echo "Added brew shellenv to ~/.bashrc"
fi

# Add brew to ~/.zshrc if zsh is present
if [ -f ~/.zshrc ]; then
  if ! grep -q 'brew shellenv' ~/.zshrc; then
    echo "" >> ~/.zshrc
    echo "# Homebrew" >> ~/.zshrc
    echo "$BREW_SHELLENV" >> ~/.zshrc
    echo "Added brew shellenv to ~/.zshrc"
  fi
fi

# Load brew into current session
eval "$("${BREW_PREFIX}/bin/brew" shellenv)"

brew update

echo "Homebrew setup complete."
