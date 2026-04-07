#!/usr/bin/env bash
# setup-vm.sh — Automated Fedora Silverblue VM provisioning for UTM on macOS
set -euo pipefail

##############################
# Configuration
##############################
VM_NAME="${1:-silverblue-work}"
FEDORA_VERSION="43"
FEDORA_BUILD="1.6"
ISO_FILENAME="Fedora-Silverblue-ostree-aarch64-${FEDORA_VERSION}-${FEDORA_BUILD}.iso"
ISO_URL="https://download.fedoraproject.org/pub/fedora/linux/releases/${FEDORA_VERSION}/Silverblue/aarch64/iso/${ISO_FILENAME}"
ISO_SHA256="4c14f1d7475cd716eba037fbfe9c0e52f09e6ccf7544514e068273f8ac8ff208"
SHARE_DIR="$HOME/UTM-share"
ISO_CACHE="$SHARE_DIR/.cache"
RAM_MB=16384      # 16 GB
DISK_MB=65536     # 64 GB

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_NAME="$(basename "$REPO_ROOT")"

##############################
# Helpers
##############################
info()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33m==> WARNING:\033[0m %s\n' "$*"; }
error() { printf '\033[1;31m==> ERROR:\033[0m %s\n' "$*" >&2; exit 1; }

verify_checksum() {
    local file="$1" expected="$2"
    local actual
    actual=$(shasum -a 256 "$file" | awk '{print $1}')
    [ "$actual" = "$expected" ]
}

##############################
# Input validation
##############################
if [[ ! "$VM_NAME" =~ ^[a-zA-Z0-9._-]+$ ]]; then
    error "VM name must contain only alphanumeric characters, dots, hyphens, and underscores"
fi

##############################
# Step 1: Check / install UTM
##############################
install_utm() {
    info "Checking for UTM..."
    if [ -d "/Applications/UTM.app" ]; then
        local ver
        ver=$(utmctl version 2>/dev/null || echo "unknown")
        info "UTM $ver already installed"
    else
        info "Installing UTM via Homebrew..."
        command -v brew &>/dev/null || error "Homebrew not found. Install it first: https://brew.sh"
        brew install --cask utm
    fi

    if ! command -v utmctl &>/dev/null; then
        info "Installing utmctl via Homebrew..."
        brew install utmctl
    fi
}

##############################
# Step 2: Create shared directory
##############################
create_share_dir() {
    info "Creating shared directory at $SHARE_DIR"
    mkdir -p "$SHARE_DIR"
    mkdir -p "$ISO_CACHE"
}

##############################
# Step 3: Download Fedora ISO
##############################
download_iso() {
    local iso_path="$ISO_CACHE/$ISO_FILENAME"

    if [ -f "$iso_path" ]; then
        info "ISO already downloaded, verifying checksum..."
        if verify_checksum "$iso_path" "$ISO_SHA256"; then
            info "Checksum OK, skipping download"
            return
        fi
        warn "Checksum mismatch, re-downloading"
        rm -f "$iso_path"
    fi

    # Check disk space (~4 GB needed for ISO + headroom)
    local avail_mb
    avail_mb=$(df -m "$ISO_CACHE" | awk 'NR==2 {print $4}')
    if [ "$avail_mb" -lt 4000 ]; then
        error "Insufficient disk space: ${avail_mb}MB available, need at least 4GB"
    fi

    info "Downloading Fedora Silverblue $FEDORA_VERSION ($ISO_FILENAME)..."
    info "This is ~2.8 GB — may take a while"
    curl -fL --retry 3 --retry-delay 5 -C - --progress-bar -o "$iso_path.part" "$ISO_URL"
    mv "$iso_path.part" "$iso_path"

    info "Verifying checksum..."
    if ! verify_checksum "$iso_path" "$ISO_SHA256"; then
        local actual
        actual=$(shasum -a 256 "$iso_path" | awk '{print $1}')
        rm -f "$iso_path"
        error "Checksum mismatch: expected $ISO_SHA256, got $actual"
    fi
    info "Checksum OK"
}

##############################
# Step 4: Sync repo into share
##############################
sync_repo_to_share() {
    local dest="$SHARE_DIR/$REPO_NAME"

    info "Syncing repository into $dest"
    mkdir -p "$dest"
    rsync -a --delete \
        --exclude='.git' \
        --exclude='.DS_Store' \
        "$REPO_ROOT/" "$dest/"
    info "Repository synced"
}

##############################
# Step 5: Create the VM
##############################
create_vm() {
    local iso_path="$ISO_CACHE/$ISO_FILENAME"

    # Check if VM name is already taken
    if utmctl status "$VM_NAME" &>/dev/null; then
        error "VM '$VM_NAME' already exists. Delete it first or choose a different name:
  utmctl delete '$VM_NAME'
  # or pass a name: ./utm/setup-vm.sh my-vm-name"
    fi

    info "Creating VM '$VM_NAME' via AppleScript (this launches UTM)..."

    # Escape double quotes in variables for safe AppleScript interpolation
    local safe_name="${VM_NAME//\"/\\\"}"
    local safe_iso="${iso_path//\"/\\\"}"

    osascript <<EOF
tell application "UTM"
    set iso to POSIX file "$safe_iso"
    set vm to make new virtual machine with properties {backend:qemu, configuration:{ ¬
        name:"$safe_name", ¬
        architecture:"aarch64", ¬
        memory:$RAM_MB, ¬
        displays:{{hardware:"virtio-gpu-gl-pci", dynamic resolution:true}}, ¬
        network interfaces:{{hardware:"virtio-net-pci", mode:shared}}, ¬
        directory share mode:VirtFS, ¬
        drives:{{removable:true, source:iso}, {guest size:$DISK_MB}} ¬
    }}
end tell
EOF

    info "VM '$VM_NAME' created"
}

##############################
# Step 6: Patch config for sound
##############################
patch_vm_config() {
    local plist=""
    local search_paths=(
        "$HOME/Library/Containers/com.utmapp.UTM/Data/Documents/${VM_NAME}.utm/config.plist"
        "$HOME/Library/Application Support/UTM/${VM_NAME}.utm/config.plist"
    )

    # Wait for UTM to write the config file (AppleScript returns before disk write completes)
    info "Waiting for UTM to write VM configuration..."
    local attempts=30
    while [ $attempts -gt 0 ]; do
        for path in "${search_paths[@]}"; do
            if [ -f "$path" ]; then
                plist="$path"
                break 2
            fi
        done
        sleep 1
        ((attempts--))
    done

    if [ -z "$plist" ]; then
        warn "Could not locate config.plist after 30s — add sound device manually in UTM settings"
        return
    fi

    info "Patching config: adding sound device (intel-hda)"
    local out
    out=$(/usr/libexec/PlistBuddy -c 'Add :Sound array' "$plist" 2>&1) || {
        if [[ "$out" != *"Entry Already Exists"* ]]; then
            warn "Failed to add Sound array: $out"
            return
        fi
    }
    out=$(/usr/libexec/PlistBuddy -c 'Add :Sound:0 dict' "$plist" 2>&1) || {
        if [[ "$out" != *"Entry Already Exists"* ]]; then
            warn "Failed to add Sound dict: $out"
            return
        fi
    }
    out=$(/usr/libexec/PlistBuddy -c 'Add :Sound:0:Hardware string intel-hda' "$plist" 2>&1) || {
        if [[ "$out" != *"Entry Already Exists"* ]]; then
            warn "Failed to add Sound hardware: $out"
            return
        fi
    }
}

##############################
# Step 7: Create guest helper script
##############################
create_guest_helper() {
    local helper="$SHARE_DIR/run-setup.sh"
    local repo_name="$REPO_NAME"
    cat > "$helper" <<GUEST
#!/usr/bin/env bash
# run-setup.sh — Run this inside the Fedora Silverblue VM after first boot
# It mounts the UTM shared folder and launches the setup script.
set -euo pipefail

MOUNT_POINT="/mnt/utm-share"
SETUP_SCRIPT="\$MOUNT_POINT/$repo_name/install.sh"

echo "==> Mounting UTM shared folder..."
sudo mkdir -p "\$MOUNT_POINT"
sudo mount -t virtiofs share "\$MOUNT_POINT" || {
    echo "==> virtiofs mount failed, trying 9p..."
    sudo mount -t 9p -o trans=virtio share "\$MOUNT_POINT" || {
        echo "==> ERROR: Could not mount shared folder."
        echo "    Make sure you configured the shared directory in UTM:"
        echo "    Right-click the VM > Edit > Sharing > set directory to ~/UTM-share"
        exit 1
    }
}

echo "==> Shared folder mounted at \$MOUNT_POINT"

if [ -f "\$SETUP_SCRIPT" ]; then
    echo "==> Running $repo_name/install.sh..."
    echo ""
    exec bash "\$SETUP_SCRIPT"
else
    echo "==> ERROR: Setup script not found at \$SETUP_SCRIPT"
    echo "    Contents of \$MOUNT_POINT:"
    ls -la "\$MOUNT_POINT"
    exit 1
fi
GUEST
    chmod +x "$helper"
    info "Created guest helper script at $helper"
}

##############################
# Step 8: Print next steps
##############################
print_instructions() {
    local bold='\033[1m'
    local reset='\033[0m'
    local cyan='\033[1;36m'

    echo ""
    echo "============================================================"
    printf "${bold}  VM '%s' is ready${reset}\n" "$VM_NAME"
    echo "============================================================"
    echo ""
    printf "${cyan}MANUAL STEP — Set the shared directory:${reset}\n"
    printf "  1. In UTM, right-click '%s' > Edit\n" "$VM_NAME"
    echo "  2. Go to Sharing"
    printf "  3. Set shared directory to: %s\n" "$SHARE_DIR"
    echo ""
    printf "${cyan}BOOT & INSTALL FEDORA:${reset}\n"
    echo "  1. Start the VM (boots from Fedora ISO)"
    echo "  2. Complete the Fedora Silverblue installer"
    echo "  3. Reboot into the installed system"
    echo ""
    printf "${cyan}AFTER FIRST BOOT — run this in the VM terminal:${reset}\n"
    echo ""
    echo "  sudo mkdir -p /mnt/utm-share && sudo mount -t virtiofs share /mnt/utm-share && /mnt/utm-share/run-setup.sh"
    echo ""
    printf "${cyan}OPTIONAL — persist the mount across reboots:${reset}\n"
    echo "  echo 'share /mnt/utm-share virtiofs defaults 0 0' | sudo tee -a /etc/fstab"
    echo ""
    echo "============================================================"
}

##############################
# Main
##############################
main() {
    echo ""
    info "UTM Fedora Silverblue VM Setup"
    info "VM name: $VM_NAME"
    echo ""

    install_utm
    create_share_dir
    download_iso
    sync_repo_to_share
    create_vm
    patch_vm_config
    create_guest_helper
    print_instructions
}

main "$@"
