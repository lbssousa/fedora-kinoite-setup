#!/usr/bin/env bash
# rpm-ostree.sh — Layer packages that have no Flatpak/brew equivalent
#
# All changes here require a reboot to take effect.

if [ "${SILVERBLUE:-false}" != "true" ]; then
  echo "WARNING: Not running on Silverblue — rpm-ostree commands may not work."
  echo "  On plain Fedora, use: sudo dnf install <package>"
fi

# ---------------------------------------------------------------------------
# gcc + make — required by neovim treesitter to compile parsers
# Homebrew's gcc lacks system libc headers (no glibc-devel on Silverblue).
# Layering the system gcc gives a fully working toolchain with headers.
# ---------------------------------------------------------------------------
if rpm -q gcc &>/dev/null && rpm -q make &>/dev/null; then
  echo "gcc + make already installed."
else
  echo "Staging gcc + make via rpm-ostree (needed by neovim treesitter)..."
  sudo rpm-ostree install gcc make
fi

