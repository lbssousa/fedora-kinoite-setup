#!/usr/bin/env bash
# flatpaks.sh — Add Flathub remote and install GUI applications

# Ensure Flathub is available (--user avoids polkit system-operation restrictions)
flatpak remote-add --user --if-not-exists flathub \
  https://dl.flathub.org/repo/flathub.flatpakrepo

echo "Flathub remote configured."

# ---------------------------------------------------------------------------
# Application list
# ---------------------------------------------------------------------------

FLATPAKS=(
  # Bazaar — app browser / store UI
  "io.github.kolunmi.Bazaar"

  # GNOME Extension Manager
  "com.mattjakeman.ExtensionManager"

  # Blanket — ambient sound / focus app
  "com.rafaelmardojai.Blanket"

  # dconf Editor — low-level settings editor
  "ca.desrt.dconf-editor"

  # Deskflow — KVM / keyboard+mouse sharing
  "org.deskflow.deskflow"

  # LocalSend — local file transfer
  # TODO: verify app ID — org.localsend.localsend_app vs org.localsend.LocalSend
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

  # Syncthing GTK — file sync GUI
  "me.kozec.syncthingtk"

  # Flatseal — manage Flatpak permissions
  "com.github.tchx84.Flatseal"

  # Warehouse — Flatpak app manager (batch uninstall, data cleanup, etc.)
  "io.github.flattool.Warehouse"

  # Ignition — manage apps that launch at startup
  "io.github.flattool.Ignition"

  # Apostrophe — distraction-free markdown editor
  "org.gnome.gitlab.somas.Apostrophe"
)

echo "Installing flatpaks..."
for app in "${FLATPAKS[@]}"; do
  echo "  Installing $app"
  flatpak install --user --noninteractive flathub "$app" || \
    echo "  WARNING: failed to install $app — check the app ID"
done

echo "Flatpak installation complete."
