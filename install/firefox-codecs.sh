#!/usr/bin/env bash
# firefox-codecs.sh — Install video/audio codecs for the system Firefox
#
# The system Firefox (not Flatpak) requires codec libraries to play H.264,
# AAC, MP3, and other proprietary formats. These are provided by ffmpeg and
# the RPM Fusion GStreamer plugins.
#
# All changes require a reboot to take effect.

if [ "${SILVERBLUE:-false}" != "true" ]; then
  echo "WARNING: Not running on Silverblue — rpm-ostree commands may not work."
  echo "  On plain Fedora, use: sudo dnf install ffmpeg-libs gstreamer1-plugins-bad-freeworld gstreamer1-plugins-ugly gstreamer1-plugin-libav"
fi

# ---------------------------------------------------------------------------
# Enable RPM Fusion repositories (required for ffmpeg and codec packages)
# ---------------------------------------------------------------------------
FEDORA_VERSION=$(rpm -E %fedora)
RPM_FUSION_FREE="rpmfusion-free-release"
RPM_FUSION_NONFREE="rpmfusion-nonfree-release"

if rpm -q "$RPM_FUSION_FREE" &>/dev/null && rpm -q "$RPM_FUSION_NONFREE" &>/dev/null; then
  echo "RPM Fusion repositories already enabled."
else
  echo "Enabling RPM Fusion free and nonfree repositories..."
  sudo rpm-ostree install \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VERSION}.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VERSION}.noarch.rpm" \
    || echo "WARNING: RPM Fusion repos may already be staged — continuing."
fi

# ---------------------------------------------------------------------------
# Install codec packages
#
# - ffmpeg-libs: H.264, AAC, MP3, and other format support used by Firefox
# - gstreamer1-plugins-bad-freeworld: additional patented-format GStreamer plugins
# - gstreamer1-plugins-ugly: MP3, DVD (CSS) and other widely-used formats
# - gstreamer1-plugin-libav: ffmpeg-backed GStreamer plugin (bridges libav/ffmpeg)
# ---------------------------------------------------------------------------
CODEC_PACKAGES=(
  ffmpeg-libs
  gstreamer1-plugins-bad-freeworld
  gstreamer1-plugins-ugly
  gstreamer1-plugin-libav
)

MISSING_PACKAGES=()
for pkg in "${CODEC_PACKAGES[@]}"; do
  if rpm -q "$pkg" &>/dev/null; then
    echo "$pkg already installed."
  else
    MISSING_PACKAGES+=("$pkg")
  fi
done

if [ ${#MISSING_PACKAGES[@]} -eq 0 ]; then
  echo "All Firefox codec packages already installed."
else
  echo "Staging codec packages via rpm-ostree: ${MISSING_PACKAGES[*]}"
  sudo rpm-ostree install "${MISSING_PACKAGES[@]}"
  echo ""
  echo "Firefox codec packages staged. Reboot to apply."
fi
