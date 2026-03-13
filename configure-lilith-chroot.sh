#!/bin/bash
# =============================================================================
# Lilith Linux Chroot Configuration Script
# =============================================================================
# This script runs entirely inside the Lilith Linux chroot
# It does NOT modify the host system in any way
#
# Usage:
#   1. Copy this script to the chroot:
#      cp configure-lilith-chroot.sh /path/to/chroot/root/
#   2. Enter chroot:
#      sudo chroot /path/to/chroot
#   3. Run:
#      cd / && chmod +x configure-lilith-chroot.sh && ./configure-lilith-chroot.sh
# =============================================================================

set -e

echo "=========================================="
echo "Lilith Linux Configuration"
echo "Running inside chroot: $(cat /etc/os-release | grep PRETTY_NAME)"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# =============================================================================
# STEP 1: System Update
# =============================================================================
log_info "Step 1: Updating package lists..."
export DEBIAN_FRONTEND=noninteractive
apt-get update

log_info "Step 2: Upgrading system..."
apt-get upgrade -y

# =============================================================================
# STEP 2: Install Core Dependencies
# =============================================================================
log_info "Step 3: Installing core dependencies..."

apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    pkg-config \
    libssl-dev \
    ca-certificates \
    fuse \
    libfuse2 \
    libglib2.0-0 \
    libcairo2 \
    libgdk-pixbuf2.0-0 \
    dbus-x11 \
    x11-apps \
    x11-utils \
    x11-xserver-utils

# =============================================================================
# STEP 3: Install Desktop Environment & Apps
# =============================================================================
log_info "Step 4: Installing desktop environment and applications..."

apt-get install -y \
    openbox \
    lightdm \
    lightdm-gtk-greeter \
    xorg \
    xterm \
    thunar \
    thunar-archive-plugin \
    thunar-volman \
    ristretto \
    mousepad \
    xfce4-terminal \
    network-manager \
    network-manager-gnome \
    wpasupplicant \
    policykit-1 \
    gnome-system-tools \
    gvfs-backends \
    gvfs-fuse \
    file-roller \
    ufw \
    pciutils \
    usbutils \
    kbd \
    manpages \
    man-db \
    info

# =============================================================================
# STEP 4: Install Flatpak & Apps
# =============================================================================
log_info "Step 5: Installing Flatpak and Flatpak applications..."

# Install Flatpak
apt-get install -y flatpak gnome-software-plugin-flatpak

# Add Flathub
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true

# Install Flatpak apps
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

# =============================================================================
# STEP 5: Install Snap & Apps
# =============================================================================
log_info "Step 6: Installing Snap and Snap applications..."

# Install Snapd
apt-get install -y snapd

# Enable Snap
systemctl enable snapd.apparmor || true
systemctl start snapd.apparmor || true

# Install Snap apps
snap install journal 2>/dev/null || true

# =============================================================================
# STEP 6: Install Rust & Rust Tools
# =============================================================================
log_info "Step 7: Installing Rust and Rust tools..."

# Install Rust
if [ ! -d "/root/.cargo" ]; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

# Source Rust environment
if [ -f "/root/.cargo/env" ]; then
    source /root/.cargo/env
fi

# Install Rust tools (only if cargo is available)
if command -v cargo &> /dev/null; then
    log_info "Installing Rust binaries..."
    
    # Core utilities
    cargo install bat lsd fd-find ripgrep dust procs broot hexy 2>/dev/null || true
    
    # Additional tools
    cargo install xcp dua-cli skim shred-rs 2>/dev/null || true
    cargo install navi atuin rustic 2>/dev/null || true
    
    # Install uv and ruff
    cargo install --git https://github.com/astral-sh/uv --locked 2>/dev/null || true
    cargo install --git https://github.com/astral-sh/ruff --locked 2>/dev/null || true
fi

# =============================================================================
# STEP 7: Configure Rust Alternatives (Aliases)
# =============================================================================
log_info "Step 8: Configuring Rust alternatives..."

# Add aliases to bashrc
cat >> /etc/bash.bashrc << 'RUST_ALIASES'

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
RUST_ALIASES

# Add to profile
cat >> /etc/profile << 'RUST_ALIASES'

# Lilith Rust Alternatives
alias cat='bat'
alias ls='lsd'
alias ll='lsd -l'
alias la='lsd -a'
alias find='fdfind'
alias grep='rg'
alias du='dust'
alias ps='procs'
alias tree='broot'
RUST_ALIASES

# Create symlinks for Rust tools
if [ -d "/root/.cargo/bin" ]; then
    ln -sf /root/.cargo/bin/bat /usr/local/bin/cat 2>/dev/null || true
    ln -sf /root/.cargo/bin/lsd /usr/local/bin/ls 2>/dev/null || true
    ln -sf /root/.cargo/bin/fd /usr/local/bin/find 2>/dev/null || true
    ln -sf /root/.cargo/bin/ripgrep /usr/local/bin/grep 2>/dev/null || true
    ln -sf /root/.cargo/bin/dust /usr/local/bin/du 2>/dev/null || true
    ln -sf /root/.cargo/bin/procs /usr/local/bin/ps 2>/dev/null || true
    ln -sf /root/.cargo/bin/broot /usr/local/bin/tree 2>/dev/null || true
fi

# =============================================================================
# STEP 8: Lilith Branding
# =============================================================================
log_info "Step 9: Configuring Lilith branding..."

# OS Release
cat > /etc/os-release << 'EOF'
NAME="Lilith Linux"
VERSION="1.0 Resolute Raccoon"
ID=lilith
ID_LIKE=ubuntu pop
PRETTY_NAME="Lilith Linux 1.0 Resolute Raccoon"
VERSION_ID="1.0"
VERSION_CODENAME=resolute
UBUNTU_CODENAME=noble
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

# Issue.net
cat > /etc/issue.net << 'EOF'
Lilith Linux 1.0 Resolute Raccoon
EOF

# LightDM Configuration
mkdir -p /etc/lightdm/lightdm.conf.d

cat > /etc/lightdm/lightdm.conf.d/50-lilith.conf << 'EOF'
[LightDM]
autologin-user=lilith
autologin-user-timeout=0
user-session=openbox
[Seat:*]
greeter-session=lightdm-gtk-greeter
allow-guest=false
EOF

# =============================================================================
# STEP 9: Create Lilith User
# =============================================================================
log_info "Step 10: Creating Lilith user..."

if ! id "lilith" &>/dev/null; then
    useradd -m -s /bin/bash lilith
    echo "lilith:lilith" | chpasswd
    # Add to relevant groups
    usermod -aG sudo,adm,dialout,cdrom,floppy,audio,dip,video,plugdev,lpadmin,sambashare lilith 2>/dev/null || true
fi

# =============================================================================
# STEP 10: Install Additional Git Repos (Optional)
# =============================================================================
log_info "Step 11: Cloning additional repositories..."

# Create apps directory
mkdir -p /opt/lilith-apps
cd /opt/lilith-apps

# Clone repositories (shallow, for reference)
# Uncomment as needed:

# Coreutils alternative
# git clone --depth 1 https://github.com/uutils/coreutils.git 2>/dev/null || true

# Nushell
# git clone --depth 1 https://github.com/nushell/nushell.git 2>/dev/null || true

# Homepage
# git clone --depth 1 https://github.com/gethomepage/homepage.git 2>/dev/null || true

# Linuxbrew
# git clone --depth 1 https://github.com/Linuxbrew/brew.git 2>/dev/null || true

# Linuxtoys
# git clone --depth 1 https://github.com/psygreg/linuxtoys.git 2>/dev/null || true

# Rust boot alternatives
# git clone --depth 1 https://github.com/oreboot/oreboot.git 2>/dev/null || true
# git clone --depth 1 https://github.com/rust-osdev/uefi-rs.git 2>/dev/null || true
# git clone --depth 1 https://github.com/r-efi/r-efi.git 2>/dev/null || true

# =============================================================================
# STEP 11: Cleanup
# =============================================================================
log_info "Step 12: Cleaning up..."

apt-get clean
rm -rf /var/cache/apt/archives/*
rm -rf /tmp/*
rm -rf /var/tmp/*
rm -rf /root/.cache

# =============================================================================
# COMPLETE
# =============================================================================
echo ""
echo "=========================================="
echo -e "${GREEN}Lilith Linux Configuration Complete!${NC}"
echo "=========================================="
echo ""
echo "Summary:"
echo "  - Desktop: Openbox + LightDM"
echo "  - Apps: Thunar, Ristretto, Mousepad, XFCE Terminal"
echo "  - Flatpak: DigiKam and other apps"
echo "  - Rust: bat, lsd, fd, ripgrep, dust, procs, broot"
echo "  - User: lilith (password: lilith)"
echo ""
echo "Next steps:"
echo "  1. Exit chroot"
echo "  2. Generate ISO using Cubic or manually"
echo ""
