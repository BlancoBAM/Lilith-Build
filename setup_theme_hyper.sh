#!/bin/bash
# Lilith Linux Theme & Terminal Setup Script
# Installs Fluent-icon-theme and configures Hyper terminal

set -e

LILITH_ROOT="${1:-/opt/lilith-linux}"
HYPER_VERSION="3.4.1"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

if [ "$EUID" -ne 0 ]; then
    warn "Run with sudo for full effect"
fi

log "Installing Fluent-icon-theme..."

# Install Fluent-icon-theme dependencies
apt-get install -y git wget 2>/dev/null || true

# Clone and install Fluent-icon-theme
if [ ! -d "/tmp/Fluent-icon-theme" ]; then
    git clone --depth 1 https://github.com/vinceliuice/Fluent-icon-theme.git /tmp/Fluent-icon-theme
fi

# Install the dark variant
cd /tmp/Fluent-icon-theme
./install.sh -d 2>/dev/null || true

log "Installing Hyper terminal..."

# Download Hyper AppImage
HYPER_URL="https://releases.hyper.is/download/AppImage"
HYPER_DIR="${LILITH_ROOT}/opt/hyper"
HYPER_BIN="${HYPER_DIR}/hyper"

mkdir -p "$HYPER_DIR"

if [ ! -f "${HYPER_DIR}/Hyper-${HYPER_VERSION}.AppImage" ]; then
    log "Downloading Hyper ${HYPER_VERSION}..."
    wget -q -O "${HYPER_DIR}/Hyper-${HYPER_VERSION}.AppImage" "$HYPER_URL" || {
        warn "Failed to download Hyper, trying alternative..."
        wget -q -O "${HYPER_DIR}/Hyper.AppImage" "$HYPER_URL" || true
    }
fi

# Make executable
chmod +x "${HYPER_DIR}"/*.AppImage 2>/dev/null || true

# Create symlink
ln -sf "${HYPER_DIR}/Hyper-${HYPER_VERSION}.AppImage" "${HYPER_DIR}/hyper" 2>/dev/null || true
ln -sf "${HYPER_DIR}/Hyper-${HYPER_VERSION}.AppImage" "${LILITH_ROOT}/usr/local/bin/hyper" 2>/dev/null || true

# Configure Hyper as default terminal
mkdir -p "${LILITH_ROOT}/etc/xdg/"
cat > "${LILITH_ROOT}/etc/xdg/mimeapps.list" << 'EOF'
[Default Applications]
x-scheme-handler/terminal=hyper.desktop
x-scheme-handler/http=firefox.desktop
x-scheme-handler/https=firefox.desktop

[Added Associations]
x-scheme-handler/terminal=hyper.desktop;
x-scheme-handler/http=firefox.desktop;
x-scheme-handler/https=firefox.desktop;
EOF

# Create Hyper desktop entry
mkdir -p "${LILITH_ROOT}/usr/share/applications"
cat > "${LILITH_ROOT}/usr/share/applications/hyper.desktop" << 'EOF'
[Desktop Entry]
Name=Hyper Terminal
Comment=Hyper Terminal
Exec=/opt/hyper/Hyper-%u
Icon=hyper
Terminal=false
Type=Application
Categories=System;TerminalEmulator;
MimeType=x-scheme-handler/terminal;
StartupNotify=true
StartupWMClass=Hyper
EOF

# Create XDG terminal symlink for x-scheme-handler
mkdir -p "${LILITH_ROOT}/usr/local/bin"
ln -sf "/opt/hyper/Hyper-${HYPER_VERSION}.AppImage" "${LILITH_ROOT}/usr/local/bin/x-terminal-emulator" 2>/dev/null || true

log "Theme and Hyper terminal configured"

# Print summary
echo ""
log "Summary:"
echo "  - Fluent-icon-theme installed"
echo "  - Hyper ${HYPER_VERSION} installed to ${HYPER_DIR}"
echo "  - Hyper set as default terminal"
echo ""
echo "To switch to dark mode, logout and login, or run:"
echo "  gsettings set org.gnome.desktop.interface gtk-theme 'Fluent-dark'"
echo "  gsettings set org.gnome.desktop.interface icon-theme 'Fluent-dark'"
