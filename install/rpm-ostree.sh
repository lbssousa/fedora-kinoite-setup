#!/usr/bin/env bash
# rpm-ostree.sh — Layer packages that have no Flatpak/brew equivalent
#
# All changes here require a reboot to take effect.

if [ "${SILVERBLUE:-false}" != "true" ]; then
  echo "WARNING: Not running on Silverblue — rpm-ostree commands may not work."
  echo "  On plain Fedora, use: sudo dnf install <package>"
fi

# ---------------------------------------------------------------------------
# Ghostty terminal emulator
# No Flatpak available — official Silverblue method is COPR + rpm-ostree.
# https://ghostty.org/docs/install/binary
# ---------------------------------------------------------------------------
if rpm -q ghostty &>/dev/null; then
  echo "ghostty already installed."
else
  echo "Adding Ghostty COPR repository..."
  . /etc/os-release
  curl -fsSL \
    "https://copr.fedorainfracloud.org/coprs/scottames/ghostty/repo/fedora-${VERSION_ID}/scottames-ghostty-fedora-${VERSION_ID}.repo" \
    | sudo tee /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:scottames:ghostty.repo > /dev/null

  echo "Staging ghostty via rpm-ostree..."
  sudo rpm-ostree install ghostty
fi
