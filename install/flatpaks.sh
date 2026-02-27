#!/usr/bin/env bash
# flatpaks.sh — Add Flathub remote and install GUI applications

# Ensure Flathub is available
flatpak remote-add --if-not-exists flathub \
  https://dl.flathub.org/repo/flathub.flatpakrepo

echo "Flathub remote configured."

# ---------------------------------------------------------------------------
# Application list
# ---------------------------------------------------------------------------

FLATPAKS=(
  # Pods — container management UI
  # TODO: verify app ID — confirm it hasn't changed on Flathub
  "com.github.marhkb.Pods"

  # GNOME Extension Manager
  "com.mattjakeman.ExtensionManager"

  # Blanket — ambient sound / focus app
  "com.rafaelmardojai.Blanket"

  # dconf Editor — low-level settings editor
  "ca.desrt.dconf-editor"

  # Deskflow — KVM / keyboard+mouse sharing
  # TODO: verify app ID on Flathub (may be io.github.deskflow.deskflow)
  "io.github.deskflow.deskflow"

  # LocalSend — local file transfer
  # TODO: verify app ID on Flathub (may be org.localsend.LocalSend)
  "org.localsend.localsend_app"

  # Whis — speech-to-text
  "ink.whis.Whis"
)

echo "Installing flatpaks..."
for app in "${FLATPAKS[@]}"; do
  echo "  Installing $app"
  flatpak install --noninteractive flathub "$app" || \
    echo "  WARNING: failed to install $app — check the app ID"
done

echo "Flatpak installation complete."
