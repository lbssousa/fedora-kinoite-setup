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
# gcc + make — required by neovim treesitter to compile parsers
#
# Homebrew installs gcc as gcc-{version} (e.g. gcc-15) without a bare "gcc"
# symlink. Treesitter checks $CC first, so we export that in the shell profile
# to point at brew's versioned gcc.
# ---------------------------------------------------------------------------
BREW_PREFIX="$(brew --prefix)"

if ! brew list gcc &>/dev/null; then
  echo "Installing gcc (needed by neovim treesitter)..."
  brew install gcc
fi

if ! brew list make &>/dev/null; then
  echo "Installing make (needed by neovim treesitter)..."
  brew install make
fi

# Point CC at brew's versioned gcc so treesitter can find it
if ! grep -q 'export CC=' ~/.bashrc 2>/dev/null; then
  BREW_GCC="$(ls "$BREW_PREFIX/bin"/gcc-[0-9]* 2>/dev/null | grep -v '\-ar\|\-nm\|\-ranlib' | sort -V | tail -1)"
  if [ -n "$BREW_GCC" ]; then
    echo "" >> ~/.bashrc
    echo "# C compiler (brew gcc for neovim treesitter)" >> ~/.bashrc
    echo "export CC=\"$BREW_GCC\"" >> ~/.bashrc
    echo "Set CC=$BREW_GCC in ~/.bashrc"
  fi
fi

# ---------------------------------------------------------------------------
# starship — install if not present, write shell hook
# ---------------------------------------------------------------------------
if ! command -v starship &>/dev/null; then
  echo "Installing starship..."
  brew install starship
fi

if ! grep -q 'starship init bash' ~/.bashrc 2>/dev/null; then
  echo "" >> ~/.bashrc
  echo "# starship prompt" >> ~/.bashrc
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
