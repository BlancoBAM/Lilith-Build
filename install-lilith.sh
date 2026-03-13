#!/bin/bash
# =============================================================================
# Lilith Linux Complete Installation Script
# =============================================================================
# This script runs entirely inside the Lilith Linux chroot
# It installs COSMIC desktop, Lilith apps, branding, and configures the system
#
# Usage:
#   curl -fsSL http://HOST_IP:8080/install-lilith.sh | bash
#   OR download and run locally:
#   wget -O- http://HOST_IP:8080/install-lilith.sh | bash
# =============================================================================

set -e

# =============================================================================
# CONFIGURATION
# =============================================================================
LILITH_VERSION="1.0"
LILITH_CODENAME="Resolute Raccoon"
LILITH_TIMEZONE="America/New_York"
LILITH_LOCALE="en_US.UTF-8"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Detect if running in chroot
if [ "$(stat -c %d /)" -eq "$(stat -c %d /proc/1)" ]; then
    log_warn "Not running in chroot - some features may not work correctly"
fi

# =============================================================================
# SERVER CONFIGURATION
# =============================================================================
# Set this to your host IP or use default
LILITH_SERVER="${LILITH_SERVER:-http://localhost:8080}"

# =============================================================================
# STEP 1: System Preparation
# =============================================================================
step_system_prep() {
    log_step "1/12: System Preparation"
    
    export DEBIAN_FRONTEND=noninteractive
    
    # Skip apt-get update - Pop!OS sources are already configured
    log_info "Skipping apt-get update - Pop!OS sources pre-configured"
    
    # Install basic dependencies
    apt-get install -y \
        curl \
        wget \
        git \
        build-essential \
        pkg-config \
        libssl-dev \
        ca-certificates \
        gnupg2 \
        lsb-release \
        software-properties-common \
        apt-transport-https
    
    # Pop!OS already has universe/multiverse - skip adding
    
    # Set timezone
    ln -sf /usr/share/zoneinfo/${LILITH_TIMEZONE} /etc/localtime
    echo "${LILITH_TIMEZONE}" > /etc/timezone
    dpkg-reconfigure -f noninteractive tz-data 2>/dev/null || true
    
    # Configure locale - DO NOT REGENERATE - just use existing and set environment
    # Skip locale-gen entirely - Pop!OS already has locales
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
    echo "LANG=en_US.UTF-8" > /etc/default/locale
    
    log_info "System prepared: timezone=${LILITH_TIMEZONE}, locale=${LILITH_LOCALE}"
}

# =============================================================================
# STEP 2: Install COSMIC Desktop
# =============================================================================
step_cosmic_desktop() {
    log_step "2/12: Installing COSMIC Desktop"
    
    # Pop!OS sources already exist - run apt-get update with error handling
    apt-get update 2>/dev/null || apt-get update --allow-insecure-repositories || true
    
    # Install COSMIC desktop
    apt-get install -y \
        pop-desktop \
        cosmic-session \
        cosmic-applets \
        cosmic-edit \
        cosmic-files \
        cosmic-store \
        cosmic-launcher \
        cosmic-panel \
        cosmic-greeter \
        cosmic-settings \
        cosmic-notifications \
        pop-theme \
        lightdm
    
    log_info "COSMIC Desktop installed"
}

# =============================================================================
# STEP 3: Install Hyper Terminal
# =============================================================================
step_hyper_terminal() {
    log_step "3/12: Installing Hyper Terminal"
    
    # Download Hyper AppImage
    cd /tmp
    wget -q https://releases.hyper.is/download/AppImage -O hyper.appimage
    chmod +x hyper.appimage
    
    # Install to /opt
    mkdir -p /opt/hyper
    mv hyper.appimage /opt/hyper/hyper
    chmod +x /opt/hyper/hyper
    
    # Create launcher
    cat > /usr/local/bin/hyper << 'EOF'
#!/bin/bash
exec /opt/hyper/hyper "$@"
EOF
    chmod +x /usr/local/bin/hyper
    
    # Desktop entry
    mkdir -p /usr/share/applications
    cat > /usr/share/applications/hyper.desktop << 'EOF'
[Desktop Entry]
Name=Hyper
Comment=Hyper Terminal
Exec=/usr/local/bin/hyper
Icon=hyper
Type=Application
Categories=System;TerminalEmulator;
EOF
    
    log_info "Hyper Terminal installed"
}

# =============================================================================
# STEP 4: Install Lilith Apps from lil-pax.toml
# =============================================================================
step_lilith_apps() {
    log_step "4/12: Installing Lilith Apps"
    
    # Install Flatpak
    apt-get install -y flatpak gnome-software-plugin-flatpak
    
    # Add Flathub
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
    
    # Install Flatpak apps from lil-pax
    flatpak install -y --noninteractive flathub \
        org.kde.digikam \
        io.github.schwarzen.colormydesktop \
        dev.khcrysalis.PlumeImpactor \
        com.tominlab.wonderpen \
        com.github.joseexposito.touche \
        app.tintero.Tintero \
        org.tabos.saldo \
        page.codeberg.JakobDev.jdSystemMonitor \
        io.github.thiefmd.themegenerator \
        io.github.sitraorg.sitra 2>/dev/null || true
    
    # Install Snaps
    apt-get install -y snapd
    snap install journal 2>/dev/null || true
    
    # Install system utilities
    apt-get install -y \
        ristretto \
        mousepad \
        thunar \
        thunar-archive-plugin \
        xarchiver
    
    log_info "Lilith Apps installed"
}

# =============================================================================
# STEP 5: Install Rust & Rust Tools from lil-staRS.toml
# =============================================================================
step_rust_tools() {
    log_step "5/12: Installing Rust & Rust Tools"
    
    # Mount necessary filesystems for Rust installer
    mount -t proc /proc /proc 2>/dev/null || true
    mount -t sysfs /sys /sys 2>/dev/null || true
    mount -t devpts /dev/pts /dev/pts 2>/dev/null || true
    
    # Install Rust
    if [ ! -d "/root/.cargo" ]; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    fi
    
    # Unmount filesystems (optional, but clean)
    umount /dev/pts 2>/dev/null || true
    umount /sys 2>/dev/null || true
    umount /proc 2>/dev/null || true
    
    # Source Rust
    [ -f "/root/.cargo/env" ] && source "/root/.cargo/env"
    
    # Install Rust tools
    if command -v cargo &> /dev/null; then
        cargo install bat lsd fd-find ripgrep dust procs broot hexy 2>/dev/null || true
        cargo install xcp dua-cli skim shred-rs 2>/dev/null || true
        cargo install navi atuin rustic 2>/dev/null || true
        cargo install --git https://github.com/astral-sh/uv --locked 2>/dev/null || true
        cargo install --git https://github.com/astral-sh/ruff --locked 2>/dev/null || true
    fi
    
    log_info "Rust Tools installed"
}

# =============================================================================
# STEP 6: Configure Rust Alternatives
# =============================================================================
step_rust_alternatives() {
    log_step "6/12: Configuring Rust Alternatives"
    
    # Add aliases
    cat >> /etc/bash.bashrc << 'EOF'

# Lilith Rust Alternatives
alias cat='bat'
alias ls='lsd'
alias ll='lsd -l'
alias la='lsd -a'
alias lt='lsd --tree'
alias find='fdfind'
alias grep='rg'
alias du='dust'
alias ps='procs'
alias tree='broot'
EOF

    # Create symlinks
    if [ -d "/root/.cargo/bin" ]; then
        ln -sf /root/.cargo/bin/bat /usr/local/bin/cat 2>/dev/null || true
        ln -sf /root/.cargo/bin/lsd /usr/local/bin/ls 2>/dev/null || true
        ln -sf /root/.cargo/bin/fd /usr/local/bin/find 2>/dev/null || true
        ln -sf /root/.cargo/bin/ripgrep /usr/local/bin/grep 2>/dev/null || true
        ln -sf /root/.cargo/bin/dust /usr/local/bin/du 2>/dev/null || true
        ln -sf /root/.cargo/bin/procs /usr/local/bin/ps 2>/dev/null || true
        ln -sf /root/.cargo/bin/broot /usr/local/bin/tree 2>/dev/null || true
    fi
    
    log_info "Rust Alternatives configured"
}

# =============================================================================
# STEP 7: Apply Lilith Branding
# =============================================================================
step_lilith_branding() {
    log_step "7/12: Applying Lilith Branding"
    
    # OS Release
    cat > /etc/os-release << 'EOF'
NAME="Lilith Linux"
VERSION="1.0 Resolute Raccoon"
ID=lilith
ID_LIKE="ubuntu pop"
PRETTY_NAME="Lilith Linux 1.0 Resolute Raccoon"
VERSION_ID="1.0"
VERSION_CODENAME="resolute"
UBUNTU_CODENAME="noble"
HOME_URL="https://lilithlinux.org"
SUPPORT_URL="https://lilithlinux.org/support"
BUG_REPORT_URL="https://bugs.lilithlinux.org"
PRIVACY_POLICY_URL="https://lilithlinux.org/privacy"
EOF

    # Issue
    cat > /etc/issue << 'EOF'
Lilith Linux 1.0 Resolute Raccoon
Kernel \r on an \m
EOF

    cat > /etc/issue.net << 'EOF'
Lilith Linux 1.0 Resolute Raccoon
EOF

    # lsb-release
    apt-get install -y lsb-release 2>/dev/null || true
    cat > /etc/lsb-release << 'EOF'
DISTRIB_ID=Lilith Linux
DISTRIB_RELEASE=1.0
DISTRIB_CODENAME=resolute
DISTRIB_DESCRIPTION="Lilith Linux 1.0 Resolute Raccoon"
EOF

    log_info "Lilith Branding applied"
}

# =============================================================================
# STEP 8: Configure LightDM
# =============================================================================
step_configure_lightdm() {
    log_step "8/12: Configuring LightDM"
    
    mkdir -p /etc/lightdm/lightdm.conf.d
    
    cat > /etc/lightdm/lightdm.conf.d/50-lilith.conf << 'EOF'
[LightDM]
autologin-user=lilith
autologin-user-timeout=0
user-session=cosmic
[Seat:*]
greeter-session=cosmic-greeter
allow-guest=false
EOF

    log_info "LightDM configured"
}

# =============================================================================
# STEP 9: Install Fluent Icon Theme
# =============================================================================
step_fluent_theme() {
    log_step "9/12: Installing Fluent Icon Theme"
    
    # Download Fluent-icon-theme (skip if fails)
    cd /tmp
    wget -q https://github.com/vinceliuice/Fluent-icon-theme/archive/refs/heads/master.zip -O fluent-theme.zip 2>/dev/null || true
    if [ -f "fluent-theme.zip" ]; then
        unzip -q fluent-theme.zip 2>/dev/null || true
        if [ -d "Fluent-icon-theme-master" ]; then
            mkdir -p /usr/share/icons
            mv Fluent-icon-theme-master /usr/share/icons/Fluent-dark
            chmod -R 755 /usr/share/icons/Fluent-dark
            
            # Set as default
            mkdir -p /etc/skel/.config
            cat > /etc/skel/.config/kdeglobals << 'EOF'
[Icons]
Theme=Fluent-dark
EOF

            # Update icon cache
            gtk-update-icon-cache -f /usr/share/icons/Fluent-dark 2>/dev/null || true
        fi
    fi
    
    log_info "Fluent Theme installed (or skipped)"
}

# =============================================================================
# STEP 10: Create Lilith User
# =============================================================================
step_create_user() {
    log_step "10/12: Creating Lilith User"
    
    if ! id "lilith" &>/dev/null; then
        useradd -m -s /bin/bash lilith
        echo "lilith:lilith" | chpasswd
        usermod -aG sudo,adm,dialout,cdrom,floppy,audio,dip,video,plugdev,lpadmin,sambashare lilith 2>/dev/null || true
        
        # Create user config directories
        mkdir -p /home/lilith/.config
        cp -r /etc/skel/.config/* /home/lilith/.config/ 2>/dev/null || true
        chown -R lilith:lilith /home/lilith
    fi
    
    log_info "Lilith user created"
}

# =============================================================================
# STEP 11: Install Lilith Custom Apps
# =============================================================================
step_custom_apps() {
    log_step "11/12: Installing Lilith Custom Apps"
    
    # Create Lilith apps directory
    mkdir -p /opt/lilith-apps
    cd /opt/lilith-apps
    
    # Clone Lilim (AI Assistant)
    if [ -d "/home/aegon/Lilith-Linux/Lilim" ]; then
        cp -r /home/aegon/Lilith-Linux/Lilim /opt/lilith-apps/
    fi
    
    # Clone Offerings (Package Manager)
    if [ -d "/home/aegon/Offerings" ]; then
        cp -r /home/aegon/Offerings /opt/lilith-apps/
    fi
    
    log_info "Lilith Custom Apps installed"
}

# =============================================================================
# STEP 12: Cleanup
# =============================================================================
step_cleanup() {
    log_step "12/12: Cleanup"
    
    apt-get clean
    rm -rf /var/cache/apt/archives/*
    rm -rf /tmp/*
    rm -rf /var/tmp/*
    rm -rf /root/.cache
    rm -rf /root/.cargo/registry/cache 2>/dev/null || true
    
    log_info "Cleanup complete"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================
main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║         Lilith Linux Complete Installation                ║"
    echo "║         Version ${LILITH_VERSION} \"${LILITH_CODENAME}\"                    ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    
    log_info "Starting installation..."
    log_info "Server: ${LILITH_SERVER}"
    echo ""
    
    # Run all steps
    step_system_prep
    step_cosmic_desktop
    step_hyper_terminal
    step_lilith_apps
    step_rust_tools
    step_rust_alternatives
    step_lilith_branding
    step_configure_lightdm
    step_fluent_theme
    step_create_user
    step_custom_apps
    step_cleanup
    
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo -e "║         ${GREEN}Installation Complete!${NC}                             ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Summary:"
    echo "  - COSMIC Desktop"
    echo "  - Hyper Terminal"
    echo "  - Lilith Apps (Flatpak + Snap)"
    echo "  - Rust Tools (bat, lsd, fd, ripgrep, dust, procs, broot)"
    echo "  - Fluent Icon Theme"
    echo "  - Lilith Branding"
    echo "  - User: lilith (password: lilith)"
    echo ""
    echo "Next steps:"
    echo "  1. Exit chroot"
    echo "  2. Generate ISO"
    echo ""
}

# Run main
main "$@"
