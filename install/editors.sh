#!/usr/bin/env bash
# editors.sh — Install developer editors and container tooling
#
# - Distrobox: installed via the official curl installer to ~/.local (no rpm-ostree)
# - VSCode: installed via Homebrew using the ublue-os tap
#   - Dev Containers extension configured to use podman (daemonless, no socket needed)
#   - vscode-distrobox helper for attaching VSCode to a distrobox container
#   - vscode-container-config helper to generate per-container nameConfig JSON
#     (with corrected capsh args for toolbx: adds --login and uses "bash" as $0)
# - Zed: installed as a Flatpak from Flathub
#   - Flatpak sandbox configured to allow host command execution
#   - zed-distrobox / zed-toolbx helpers for entering containers

# ---------------------------------------------------------------------------
# Distrobox — container-based CLI environment manager
# Install to ~/.local so no root is needed and the binary survives OS updates
# ---------------------------------------------------------------------------
if command -v distrobox &>/dev/null; then
  echo "Distrobox already installed, skipping."
else
  echo "Installing Distrobox to ~/.local..."
  curl -s https://raw.githubusercontent.com/89luca89/distrobox/main/install \
    | sh -s -- --prefix ~/.local
  echo "Distrobox installed."
fi

# ---------------------------------------------------------------------------
# VSCode — via ublue-os Homebrew tap
# https://github.com/ublue-os/homebrew-tap
# ---------------------------------------------------------------------------
if ! command -v brew &>/dev/null; then
  echo "ERROR: brew not found. Run install/brew.sh first."
  return 1
fi

if brew list --cask code &>/dev/null || brew list code &>/dev/null; then
  echo "VSCode already installed via Homebrew, skipping."
else
  echo "Tapping ublue-os/tap..."
  brew tap ublue-os/tap

  echo "Installing VSCode via Homebrew (ublue-os/tap)..."
  brew install ublue-os/tap/code
fi

# ---------------------------------------------------------------------------
# VSCode Dev Containers extension + podman configuration
# ---------------------------------------------------------------------------

# Install Dev Containers extension
if command -v code &>/dev/null; then
  echo "Installing VSCode Dev Containers extension..."
  code --install-extension ms-vscode-remote.remote-containers --force
else
  echo "WARNING: 'code' binary not found; skipping Dev Containers extension install"
fi

# Configure dev.containers.dockerPath = podman in VSCode settings.json
VSCODE_SETTINGS_DIR="$HOME/.config/Code/User"
VSCODE_SETTINGS_FILE="$VSCODE_SETTINGS_DIR/settings.json"
mkdir -p "$VSCODE_SETTINGS_DIR"

if [ -f "$VSCODE_SETTINGS_FILE" ]; then
  if ! grep -q '"dev.containers.dockerPath"' "$VSCODE_SETTINGS_FILE"; then
    python3 - "$VSCODE_SETTINGS_FILE" <<'PYEOF'
import json, sys
path = sys.argv[1]
try:
    with open(path) as f:
        settings = json.load(f)
    settings["dev.containers.dockerPath"] = "podman"
    with open(path, "w") as f:
        json.dump(settings, f, indent=2)
        f.write("\n")
    print("Added dev.containers.dockerPath = podman to VSCode settings.")
except json.JSONDecodeError:
    print("WARNING: VSCode settings.json contains comments or is not valid JSON.")
    print('  Manually add: "dev.containers.dockerPath": "podman"')
PYEOF
  else
    echo "VSCode dev.containers.dockerPath already configured, skipping."
  fi
else
  echo "Creating VSCode settings.json..."
  cat > "$VSCODE_SETTINGS_FILE" << 'EOF'
{
  "dev.containers.dockerPath": "podman"
}
EOF
fi

# Create ~/.config/containers/containers.conf for podman/Dev Containers compatibility
# Sets BUILDAH_FORMAT=docker, disables SELinux labels, and uses keep-id userns
# so Dev Container images work with rootless podman.
CONTAINERS_CONF="$HOME/.config/containers/containers.conf"
mkdir -p "$(dirname "$CONTAINERS_CONF")"
if [ ! -f "$CONTAINERS_CONF" ]; then
  echo "Creating $CONTAINERS_CONF..."
  cat > "$CONTAINERS_CONF" << 'EOF'
[containers]
env = ["BUILDAH_FORMAT=docker"]
label = false
userns = "keep-id"
EOF
fi

# ---------------------------------------------------------------------------
# VSCode container helpers
# ---------------------------------------------------------------------------
mkdir -p "$HOME/.local/bin"

# vscode-distrobox: opens VSCode attached to a named distrobox container
if [ ! -f "$HOME/.local/bin/vscode-distrobox" ]; then
  echo "Installing vscode-distrobox helper..."
  curl -s https://raw.githubusercontent.com/89luca89/distrobox/main/extras/vscode-distrobox \
    -o "$HOME/.local/bin/vscode-distrobox"
  chmod +x "$HOME/.local/bin/vscode-distrobox"
fi

# vscode-container-config: generates a VSCode Dev Containers nameConfig JSON for
# a given distrobox or toolbx container.
#
# The toolbx terminal profile uses the exact capsh invocation that toolbx itself
# uses internally (constructCapShArgs with useLoginShell=true from toolbx source):
#   capsh --caps= -- --login -c "exec \"$@\"" bash <shell> -l
#
# Common mistake (per lbssousa/bb081e35d483520928033b2797133d5e): the --login
# flag was missing and "/bin/sh" was used as $0 instead of "bash".
VSCODE_CONTAINER_CONFIG="$HOME/.local/bin/vscode-container-config"
if [ ! -f "$VSCODE_CONTAINER_CONFIG" ]; then
  echo "Installing vscode-container-config helper..."
  cat > "$VSCODE_CONTAINER_CONFIG" << 'PYEOF'
#!/usr/bin/env python3
"""vscode-container-config — Create a VSCode Dev Containers nameConfig file
for attaching to a distrobox or toolbx container.

Usage: vscode-container-config <container-name> [distrobox|toolbx]
"""
import json, os, pathlib, sys


def main():
    if len(sys.argv) < 2:
        print(
            "Usage: vscode-container-config <container-name> [distrobox|toolbx]",
            file=sys.stderr,
        )
        sys.exit(1)

    container_name = sys.argv[1]
    container_type = sys.argv[2] if len(sys.argv) > 2 else "distrobox"

    nameconfigs_dir = (
        pathlib.Path.home()
        / ".config"
        / "Code"
        / "User"
        / "globalStorage"
        / "ms-vscode-remote.remote-containers"
        / "nameConfigs"
    )
    nameconfigs_dir.mkdir(parents=True, exist_ok=True)

    config_file = nameconfigs_dir / f"{container_name}.json"
    if config_file.exists():
        print(f"Config already exists: {config_file}")
        print("Remove it first to regenerate.")
        sys.exit(0)

    user = os.environ.get("USER", os.environ.get("LOGNAME", ""))

    if container_type == "toolbx":
        # Matches constructCapShArgs(command, useLoginShell=true) in toolbx source
        # (github.com/containers/toolbox src/cmd/run.go):
        #   capsh --caps= -- --login -c "exec \"$@\"" bash <shell> -l
        profile_name = "toolbx"
        terminal_path = "/usr/sbin/capsh"
        terminal_args = [
            "--caps=", "--", "--login",
            "-c", 'exec "$@"',
            "bash",
            "${localEnv:SHELL}", "-l",
        ]
    else:
        profile_name = "distrobox"
        terminal_path = "${localEnv:SHELL}"
        terminal_args = ["-l"]

    config = {
        "remoteUser": user,
        "settings": {
            "dev.containers.copyGitConfig": False,
            "dev.containers.gitCredentialHelperConfigLocation": "none",
        },
        "terminal.integrated.profiles.linux": {
            profile_name: {
                "path": terminal_path,
                "args": terminal_args,
            }
        },
        "terminal.integrated.defaultProfile.linux": profile_name,
        "remoteEnv": {
            "COLORTERM": "${localEnv:COLORTERM}",
            "DBUS_SESSION_BUS_ADDRESS": "${localEnv:DBUS_SESSION_BUS_ADDRESS}",
            "DESKTOP_SESSION": "${localEnv:DESKTOP_SESSION}",
            "DISPLAY": "${localEnv:DISPLAY}",
            "LANG": "${localEnv:LANG}",
            "SHELL": "${localEnv:SHELL}",
            "SSH_AUTH_SOCK": "${localEnv:SSH_AUTH_SOCK}",
            "TERM": "${localEnv:TERM}",
            "VTE_VERSION": "${localEnv:VTE_VERSION}",
            "XDG_CURRENT_DESKTOP": "${localEnv:XDG_CURRENT_DESKTOP}",
            "XDG_DATA_DIRS": "${localEnv:XDG_DATA_DIRS}",
            "XDG_MENU_PREFIX": "${localEnv:XDG_MENU_PREFIX}",
            "XDG_RUNTIME_DIR": "${localEnv:XDG_RUNTIME_DIR}",
            "XDG_SESSION_DESKTOP": "${localEnv:XDG_SESSION_DESKTOP}",
            "XDG_SESSION_TYPE": "${localEnv:XDG_SESSION_TYPE}",
        },
    }

    config_file.write_text(json.dumps(config, indent=2) + "\n")
    print(f"Created: {config_file}")
    print(
        f"Restart VSCode and use Dev Containers: Attach to Running Container "
        f"to attach to '{container_name}'."
    )
    print()
    print("NOTE: Before attaching for the first time, prepare the container:")
    if container_type == "toolbx":
        print(f"  toolbox run --container {container_name} sudo mkdir -p /.vscode-server")
        print(f"  toolbox run --container {container_name} sudo chown $USER:$USER /.vscode-server")
        print(f"  toolbox run --container {container_name} -- sh -c 'ln -sf /.vscode-server ~/.vscode-server'")
    else:
        print(f"  distrobox enter {container_name} -- sudo mkdir -p /.vscode-server")
        print(f"  distrobox enter {container_name} -- sudo chown $USER:$USER /.vscode-server")
        print(f"  distrobox enter {container_name} -- sh -c 'ln -sf /.vscode-server ~/.vscode-server'")


if __name__ == "__main__":
    main()
PYEOF
  chmod +x "$VSCODE_CONTAINER_CONFIG"
fi

# ---------------------------------------------------------------------------
# Zed — code editor Flatpak
# ---------------------------------------------------------------------------
if flatpak list --app 2>/dev/null | grep -q "dev.zed.Zed"; then
  echo "Zed already installed, skipping."
else
  echo "Installing Zed (Flatpak)..."
  flatpak install --user --noninteractive flathub dev.zed.Zed || \
    echo "WARNING: failed to install Zed — check the app ID or Flathub availability"
fi

# ---------------------------------------------------------------------------
# Zed container integration
# ---------------------------------------------------------------------------

# Allow Zed Flatpak to spawn host commands (distrobox, toolbox, etc.) via
# host-spawn, which is bundled inside the Zed Flatpak at /app/bin/host-spawn.
# ZED_FLATPAK_NO_ESCAPE=1 (the Flatpak default) prevents this; set it to 0
# to allow Zed to run host-side tools directly from its terminal and tasks.
echo "Configuring Zed Flatpak for host command access..."
flatpak --user override --env=ZED_FLATPAK_NO_ESCAPE=0 dev.zed.Zed 2>/dev/null || \
  echo "WARNING: failed to override ZED_FLATPAK_NO_ESCAPE — distrobox/toolbox may not work from Zed terminal"

# Configure Zed settings.json (Flatpak config location)
ZED_SETTINGS_DIR="$HOME/.var/app/dev.zed.Zed/config/zed"
ZED_SETTINGS_FILE="$ZED_SETTINGS_DIR/settings.json"
mkdir -p "$ZED_SETTINGS_DIR"

if [ -f "$ZED_SETTINGS_FILE" ]; then
  if ! grep -q '"terminal"' "$ZED_SETTINGS_FILE"; then
    python3 - "$ZED_SETTINGS_FILE" <<'PYEOF'
import json, sys
path = sys.argv[1]
try:
    with open(path) as f:
        settings = json.load(f)
    settings.setdefault("terminal", {})["shell"] = {
        "program": "bash",
        "args": ["-l"],
    }
    with open(path, "w") as f:
        json.dump(settings, f, indent=2)
        f.write("\n")
    print("Added terminal shell settings to Zed settings.json.")
except json.JSONDecodeError:
    print("WARNING: Zed settings.json is not valid JSON; skipping terminal config.")
PYEOF
  else
    echo "Zed terminal settings already configured, skipping."
  fi
else
  echo "Creating Zed settings.json..."
  cat > "$ZED_SETTINGS_FILE" << 'EOF'
{
  "terminal": {
    "shell": {
      "program": "bash",
      "args": ["-l"]
    }
  }
}
EOF
fi

# zed-distrobox: enter a distrobox container; run `zed <path>` inside if the
# zed CLI is available there, otherwise just enter the container.
ZED_DISTROBOX="$HOME/.local/bin/zed-distrobox"
if [ ! -f "$ZED_DISTROBOX" ]; then
  echo "Installing zed-distrobox helper..."
  cat > "$ZED_DISTROBOX" << 'SCRIPT'
#!/usr/bin/env bash
# zed-distrobox — Enter a distrobox container and open a path in Zed.
# If the `zed` CLI is present inside the container it is used; otherwise
# the script just enters the container so you can work from its shell.
#
# Usage: zed-distrobox <container-name> [path]
set -euo pipefail

CONTAINER="${1:?Usage: zed-distrobox <container-name> [path]}"
TARGET_PATH="$(realpath "${2:-.}")"

if distrobox enter "$CONTAINER" -- command -v zed &>/dev/null; then
  exec distrobox enter "$CONTAINER" -- zed "$TARGET_PATH"
else
  echo "Note: 'zed' CLI not found inside '$CONTAINER'."
  echo "Install it inside the container, or open the path directly from the host Zed: $TARGET_PATH"
  exec distrobox enter "$CONTAINER"
fi
SCRIPT
  chmod +x "$ZED_DISTROBOX"
fi

# zed-toolbx: same idea for toolbx (toolbox) containers.
ZED_TOOLBX="$HOME/.local/bin/zed-toolbx"
if [ ! -f "$ZED_TOOLBX" ]; then
  echo "Installing zed-toolbx helper..."
  cat > "$ZED_TOOLBX" << 'SCRIPT'
#!/usr/bin/env bash
# zed-toolbx — Enter a toolbx container and open a path in Zed.
# If the `zed` CLI is present inside the container it is used; otherwise
# the script just enters the container so you can work from its shell.
#
# Usage: zed-toolbx <container-name> [path]
set -euo pipefail

CONTAINER="${1:?Usage: zed-toolbx <container-name> [path]}"
TARGET_PATH="$(realpath "${2:-.}")"

if toolbox run --container "$CONTAINER" command -v zed &>/dev/null; then
  exec toolbox run --container "$CONTAINER" zed "$TARGET_PATH"
else
  echo "Note: 'zed' CLI not found inside '$CONTAINER'."
  echo "Install it inside the container, or open the path directly from the host Zed: $TARGET_PATH"
  exec toolbox enter --container "$CONTAINER"
fi
SCRIPT
  chmod +x "$ZED_TOOLBX"
fi

echo "Editors setup complete."
