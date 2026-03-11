#!/usr/bin/env bash
# brew.sh — Install Homebrew (Linuxbrew) and configure shell integration

if command -v brew &>/dev/null; then
  echo "Homebrew already installed, skipping install."
else
  # brew needs curl and git at minimum
  for cmd in curl git; do
    if ! command -v "$cmd" &>/dev/null; then
      echo "ERROR: '$cmd' is required to install Homebrew but was not found."
      return 1
    fi
  done

  # The Homebrew installer needs sudo to create /home/linuxbrew/.linuxbrew
  # and install build dependencies. Verify sudo works before starting.
  echo "Checking sudo access (required by Homebrew installer)..."
  if ! sudo -v 2>/dev/null; then
    echo "ERROR: sudo access is required to install Homebrew."
    echo "  Ensure your user is in the 'wheel' group and try again:"
    echo "    sudo usermod -aG wheel \$USER"
    return 1
  fi

  echo "Installing Homebrew (non-interactive)..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # The installer doesn't add brew to PATH in the current session, so do it
  # now before the command -v check below.
  if [ -d /home/linuxbrew/.linuxbrew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  elif [ -d "$HOME/.linuxbrew" ]; then
    eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
  fi

  if ! command -v brew &>/dev/null; then
    echo "ERROR: Homebrew install script ran but 'brew' is still not on PATH."
    return 1
  fi
fi

# Determine brew prefix (differs on ARM vs x86)
BREW_PREFIX="$(brew --prefix)"

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
