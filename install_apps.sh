#!/bin/bash
# Lilith Linux Application Installer
# Installs apps from lil-pax.toml and lil-staRS.toml

set -e

LILITH_ROOT="${1:-/opt/lilith-linux}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

if [ "$EUID" -ne 0 ]; then
    error "Run with sudo"
    exit 1
fi

log "Installing Lilith Linux applications..."

# Install Flatpak
log "Setting up Flatpak..."
apt-get install -y flatpak 2>/dev/null || true
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

# Install Snap
log "Setting up Snap..."
apt-get install -y snapd 2>/dev/null || true
systemctl enable --now snapd.socket 2>/dev/null || true

# Install Rust alternatives (lil-staRS.toml)
log "Installing Rust alternatives..."
apt-get install -y \
    bat \
    lsd \
    fd-find \
    ripgrep \
    2>/dev/null || true

# Install dev tools with cargo
log "Installing Rust cargo tools..."
for crate in dust procs broot navi starship zoxide just; do
    if ! command -v "$crate" &>/dev/null; then
        log "  Installing $crate..."
        cargo install "$crate" 2>/dev/null || true
    fi
done

# Install Flatpak apps (lil-pax.toml)
log "Installing Flatpak applications..."
FLATPAK_APPS=(
    "com.matthiasn.lotti"
    "io.github.shonebinu.Brief"
    "com.tominlab.wonderpen"
    "io.github.touche_app"
    "app.tintero.Tintero"
    "org.tabos.saldo"
    "page.codeberg.JakobDev.jdSystemMonitor"
    "io.github.thiefmd.themegenerator"
    "org.kde.digikam"
    "io.github.sitraorg.sitra"
)

for app in "${FLATPAK_APPS[@]}"; do
    log "  Installing $app..."
    flatpak install -y flathub "$app" 2>/dev/null || true
done

# Install Snap apps (lil-pax.toml)
log "Installing Snap applications..."
SNAP_APPS=(
    "journal"
    "proton-pass"
)

for app in "${SNAP_APPS[@]}"; do
    log "  Installing $app..."
    snap install "$app" 2>/dev/null || true
done

# Install apt packages (lil-pax.toml)
log "Installing system packages..."
apt-get install -y \
    digikam \
    htop \
    neofetch \
    curl \
    wget \
    git \
    vim \
    git \
    build-essential \
    2>/dev/null || true

# Install GitHub apps (lil-pax.toml)
log "Installing GitHub applications..."

# Nushell
if ! command -v nushell &>/dev/null; then
    log "  Installing Nushell..."
    # Add nushell repo or install from binary
    curl -s https://github.com/nushell/nushell/releases/latest/download/nushell-*.deb -o /tmp/nushell.deb 2>/dev/null || true
    dpkg -i /tmp/nushell.deb 2>/dev/null || true
fi

# Spacedrive
log "  Spacedrive (install via Flatpak or AppImage)"

# Install Lilith custom apps
log "Installing Lilith custom applications..."

# Copy Offerings
if [ -f "/home/aegon/Lilith-Linux/Offerings/target/release/offerings" ]; then
    cp /home/aegon/Lilith-Linux/Offerings/target/release/offerings "${LILITH_ROOT}/usr/local/bin/"
    log "  Offerings installed"
fi

# Copy Tweakers
if [ -f "/home/aegon/Lilith-Linux/Tweakers/target/release/tweakers" ]; then
    cp /home/aegon/Lilith-Linux/Tweakers/target/release/tweakers "${LILITH_ROOT}/usr/local/bin/"
    log "  Tweakers installed"
fi

# Copy Shapeshifter
if [ -f "/home/aegon/Lilith-Linux/Shapeshifter/target/release/shapeshifter" ]; then
    cp /home/aegon/Lilith-Linux/Shapeshifter/target/release/shapeshifter "${LILITH_ROOT}/usr/local/bin/"
    log "  Shapeshifter installed"
fi

# Copy S8n
if [ -f "/home/aegon/Lilith-Linux/S8n-Rx-PackMan/target/release/s8n" ]; then
    cp /home/aegon/Lilith-Linux/S8n-Rx-PackMan/target/release/s8n "${LILITH_ROOT}/usr/local/bin/"
    log "  S8n installed"
fi

# Configure Lilith-TTS
if [ -f "/home/aegon/Lilith-Linux/Lilith-TTS/target/release/lilith-tts" ]; then
    cp /home/aegon/Lilith-Linux/Lilith-TTS/target/release/lilith-tts "${LILITH_ROOT}/usr/local/bin/"
    log "  Lilith-TTS installed"
fi

# Install Lilim AI
log "  Lilim AI (install from source or package)"

# Install Lilith-Notepad
if [ -f "/home/aegon/Lilith-Linux/Lilith-Notepad/src-tauri/target/release/lilith-notepad" ]; then
    cp /home/aegon/Lilith-Linux/Lilith-Notepad/src-tauri/target/release/lilith-notepad "${LILITH_ROOT}/usr/local/bin/"
    log "  Lilith-Notepad installed"
fi

# Install Lilith-Virtual-Keyboard
if [ -d "/home/aegon/Lilith-Linux/Lilith-Virtual-Keyboard" ]; then
    cp -r /home/aegon/Lilith-Linux/Lilith-Virtual-Keyboard "${LILITH_ROOT}/opt/"
    ln -sf "/opt/Lilith-Virtual-Keyboard/lilith-virtual-keyboard" "${LILITH_ROOT}/usr/local/bin/"
    log "  Lilith-Virtual-Keyboard installed"
fi

# Install Pake
if [ -d "/home/aegon/Lilith-Linux/Pake" ]; then
    cp -r /home/aegon/Lilith-Linux/Pake "${LILITH_ROOT}/opt/"
    log "  Pake installed"
fi

# Configure topgrade for Lilith
mkdir -p "${LILITH_ROOT}/etc"
cp /home/aegon/Lilith-Build/config/topgrade.toml "${LILITH_ROOT}/etc/topgrade.toml" 2>/dev/null || true

# Create app menu entries
mkdir -p "${LILITH_ROOT}/usr/share/applications/lilith"
mkdir -p "${LILITH_ROOT}/usr/share/applications/lilith-extra"

# Create desktop entries for Lilith apps
cat > "${LILITH_ROOT}/usr/share/applications/lilith/offerings.desktop" << 'EOF'
[Desktop Entry]
Name=Offerings
Comment=Unified Package Manager
Exec=/usr/local/bin/offerings
Icon=system-software-install
Terminal=false
Type=Application
Categories=System;Settings;PackageManager;
EOF

cat > "${LILITH_ROOT}/usr/share/applications/lilith/tweakers.desktop" << 'EOF'
[Desktop Entry]
Name=Tweakers
Comment=System Optimization
Exec=/usr/local/bin/tweakers
Icon=system-optimization
Terminal=false
Type=Application
Categories=System;Settings;
EOF

cat > "${LILITH_ROOT}/usr/share/applications/lilith/shapeshifter.desktop" << 'EOF'
[Desktop Entry]
Name=Shapeshifter
Comment=Profile Manager
Exec=/usr/local/bin/shapeshifter
Icon=preferences-desktop
Terminal=false
Type=Application
Categories=System;Settings;
EOF

cat > "${LILITH_ROOT}/usr/share/applications/lilith/lilim.desktop" << 'EOF'
[Desktop Entry]
Name=Lilim
Comment=AI Assistant
Exec=/usr/local/bin/lilim
Icon=chat
Terminal=false
Type=Application
Categories=Utility;AI;
EOF

log "All applications installed"

echo ""
log "Summary:"
echo "  - Rust alternatives: bat, lsd, fd-find, ripgrep"
echo "  - Rust cargo tools: dust, procs, broot, navi, starship, zoxide, just"
echo "  - Flatpak apps: Lotti, Brief, WonderPen, etc."
echo "  - Snap apps: Journal, ProtonPass"
echo "  - Lilith apps: Offerings, Tweakers, Shapeshifter, S8n, Lilith-TTS"
echo "  - Topgrade configured"
