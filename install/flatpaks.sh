#!/usr/bin/env bash
# flatpaks.sh — Add Flathub remote and install GUI applications

# Ensure Flathub is available
flatpak remote-add --if-not-exists flathub \
  https://dl.flathub.org/repo/flathub.flatpakrepo

echo "Flathub remote configured."

# ---------------------------------------------------------------------------
# Remove pre-installed Fedora Kinoite flatpaks that are unwanted
# ---------------------------------------------------------------------------
REMOVE_FLATPAKS=(
  "org.kde.kmahjongg"
  "org.kde.kmines"
  "org.kde.kpat"
)

INSTALLED_FLATPAKS=$(flatpak list --columns=application 2>/dev/null)

for app in "${REMOVE_FLATPAKS[@]}"; do
  if echo "$INSTALLED_FLATPAKS" | grep -q "^${app}$"; then
    echo "  Removing pre-installed flatpak: $app"
    flatpak remove --noninteractive "$app" 2>/dev/null || \
      echo "  WARNING: could not remove $app"
  fi
done

# ---------------------------------------------------------------------------
# Application list
# ---------------------------------------------------------------------------

FLATPAKS=(
  # Bazaar — app browser / store UI
  "io.github.kolunmi.Bazaar"

  # Blanket — ambient sound / focus app
  "com.rafaelmardojai.Blanket"

  # Deskflow — KVM / keyboard+mouse sharing
  "org.deskflow.deskflow"

  # LocalSend — local file transfer
  "org.localsend.localsend_app"

  # Whis — speech-to-text
  "ink.whis.Whis"

  # VLC — media player
  "org.videolan.VLC"

  # Moonlight — game streaming client
  "com.moonlight_stream.Moonlight"

  # Signal — encrypted messaging
  # NOTE: not available on aarch64 via Flathub; will skip gracefully on ARM
  "org.signal.Signal"

  # Syncthing — file sync (Qt/KDE-friendly GUI)
  "com.github.zocker_160.SyncThingy"

  # Flatseal — manage Flatpak permissions
  "com.github.tchx84.Flatseal"

  # Warehouse — Flatpak app manager (batch uninstall, data cleanup, etc.)
  "io.github.flattool.Warehouse"

  # Ignition — manage apps that launch at startup
  "io.github.flattool.Ignition"

  # Mission Center — system monitor (KDE-friendly)
  "io.missioncenter.MissionCenter"

  # Haruna — media player (KDE-native, built on libmpv)
  "org.kde.haruna"
)

echo "Installing flatpaks..."
for app in "${FLATPAKS[@]}"; do
  echo "  Installing $app"
  flatpak install --noninteractive flathub "$app" || \
    echo "  WARNING: failed to install $app — check the app ID"
done

echo "Flatpak installation complete."
