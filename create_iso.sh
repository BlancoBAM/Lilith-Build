#!/bin/bash
# Lilith Linux ISO Creation with penguins-eggs
# Run this AFTER building apps with build_lilith.sh on Pop!OS/COSMIC

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }

###############################################################################
# Prerequisites Check
###############################################################################
check_prereqs() {
    log "Checking prerequisites..."

    # Check for root
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}This script requires root. Run with sudo${NC}"
        exit 1
    fi

    # Check for penguins-eggs
    if ! command -v eggs &> /dev/null; then
        log "Installing penguins-eggs..."
        apt update
        wget -q https://packages.penguins-eggs.net/releases/gpg/key -O- | apt-key add -
        echo "deb https://packages.penguins-eggs.net/releases/$(lsb_release -si|tr[:upper:] [:lower:])/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/penguins-eggs.list
        apt update
        apt install -y penguins-eggs
    fi

    # Check for required apps
    local missing=()
    [ ! -f /usr/local/bin/offerings ] && missing+=("offerings")
    [ ! -f /usr/local/bin/tweakers ] && missing+=("tweakers")
    [ ! -f /usr/local/bin/shapeshifter ] && missing+=("shapeshifter")
    [ ! -f /usr/local/bin/s8n ] && missing+=("s8n")
    [ ! -f /usr/local/bin/lilith-tts ] && missing+=("lilith-tts")

    if [ ${#missing[@]} -gt 0 ]; then
        log "Building missing applications..."
        # Call the build script
        /home/aegon/Lilith-Build/build_lilith.sh --all
    fi
}

###############################################################################
# Configure System for ISO
###############################################################################
configure_system() {
    log "Configuring system for ISO creation..."

    # Set hostname
    echo "lilith" > /etc/hostname

    # Configure display manager for COSMIC
    # (Pop!OS should already have this configured)

    # Copy Lilith branding to Calamares
    mkdir -p /usr/share/calamares/brands/lilith
    cat > /usr/share/calamares/brands/lilith/branding.desc << 'EOF'
---
productName: Lilith Linux
productVersion: 1.0.0
version: 1.0.0
variant: Lilith
variantId: lilith
shortProductName: Lilith
homepage: https://lilithlinux.org
bootloaderEntryName: Lilith
EOF

    # Set Plymouth theme
    if [ -f /usr/share/plymouth/themes/lilith/lilith.plymouth ]; then
        plymouth-set-default-theme lilith
    fi

    log "System configured!"
}

###############################################################################
# Create ISO
###############################################################################
create_iso() {
    log "Creating Lilith Linux ISO..."

    local iso_name="${1:-lilith-linux}"

    # Using penguins-eggs to produce ISO
    # The --kiosk flag makes it non-interactive
    eggs produce --kiosk --hostname lilith --domain localdomain

    log "ISO created successfully!"
    log "ISO location: /home/${SUDO_USER}/.local/share/eggs/"
}

###############################################################################
# Main
###############################################################################
main() {
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}Lilith Linux ISO Creator${NC}"
    echo -e "${BLUE}==========================================${NC}\n"

    check_prereqs
    configure_system
    create_iso "$@"

    echo -e "\n${GREEN}Done!${NC}"
    echo "Your Lilith Linux ISO is ready!"
    echo ""
    echo "To burn to USB:"
    echo "  sudo dd if=/path/to/lilith-linux.iso of=/dev/sdX bs=4M status=progress"
}

main "$@"
