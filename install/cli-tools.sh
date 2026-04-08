#!/usr/bin/env bash
# cli-tools.sh — Miscellaneous CLI tools

# ---------------------------------------------------------------------------
# Bash — case-insensitive tab completion
# ---------------------------------------------------------------------------
INPUTRC="$HOME/.inputrc"
if ! grep -q 'completion-ignore-case' "$INPUTRC" 2>/dev/null; then
  echo "" >> "$INPUTRC"
  echo "# Case-insensitive tab completion" >> "$INPUTRC"
  echo "set completion-ignore-case on" >> "$INPUTRC"
  echo "Added case-insensitive completion to $INPUTRC"
fi

# ---------------------------------------------------------------------------
# Rust-based CLI utilities (via Homebrew)
# ---------------------------------------------------------------------------
if ! command -v brew &>/dev/null; then
  echo "ERROR: brew not found. Run install/brew.sh first."
  return 1
fi

# List of Rust-rewrite tools to install via brew
RUST_TOOLS=(
  eza      # ls
  bat      # cat
  ripgrep  # grep
  fd       # find
  dust     # du
  procs    # ps
  bottom   # top/htop
  zoxide   # cd
  git-delta # git diff pager
  sd       # sed
)

echo "Installing Rust-based CLI utilities..."
for tool in "${RUST_TOOLS[@]}"; do
  if brew list "$tool" &>/dev/null; then
    echo "  $tool already installed, skipping."
  else
    echo "  Installing $tool..."
    brew install "$tool"
  fi
done

# ---------------------------------------------------------------------------
# Shell aliases for Rust utilities → ~/.bashrc
# ---------------------------------------------------------------------------
ALIASES_MARKER='# Rust CLI aliases'
if ! grep -q "$ALIASES_MARKER" ~/.bashrc 2>/dev/null; then
  cat >> ~/.bashrc << 'EOF'

# Rust CLI aliases (interactive shell only — do not remove system tools)
alias ls='eza'
alias ll='eza -l'
alias la='eza -la'
alias lt='eza --tree'
alias cat='bat'
alias grep='rg'
alias du='dust'
alias ps='procs'
alias top='btm'
alias diff='delta'
EOF
  echo "Added Rust CLI aliases to ~/.bashrc"
fi

# ---------------------------------------------------------------------------
# zoxide shell hook
# ---------------------------------------------------------------------------
if ! grep -q 'zoxide init' ~/.bashrc 2>/dev/null; then
  echo "" >> ~/.bashrc
  echo "# zoxide (smart cd)" >> ~/.bashrc
  echo 'eval "$(zoxide init bash)"' >> ~/.bashrc
  echo "Added zoxide hook to ~/.bashrc"
fi

# ---------------------------------------------------------------------------
# rivalcfg — SteelSeries mouse configuration
# Use pipx to avoid PEP 668 externally-managed-environment restrictions
# ---------------------------------------------------------------------------
echo "Installing rivalcfg..."
if command -v pipx &>/dev/null; then
  pipx install rivalcfg
  echo "rivalcfg installed."
else
  echo "WARNING: pipx not found — skipping rivalcfg."
  echo "  Install manually: pipx install rivalcfg"
  echo "  See: https://github.com/flozz/rivalcfg"
fi

echo "CLI tools setup complete."
