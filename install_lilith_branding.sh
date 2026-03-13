#!/bin/bash
# Lilith Linux Branding Installation Script
# Installs Lilith Linux branding

set -e

LILITH_ROOT="${1:-/opt/lilith-linux}"
ASSETS_DIR="/home/aegon/Lilith-Linux/assets"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

if [ "$EUID" -ne 0 ]; then
    warn "Run with sudo for full effect"
fi

log "Installing Lilith Linux branding..."

# Create Lilith directories
mkdir -p "${LILITH_ROOT}/usr/share/lilith"
mkdir -p "${LILITH_ROOT}/usr/share/pixmaps/lilith"
mkdir -p "${LILITH_ROOT}/usr/share/backgrounds/lilith"
mkdir -p "${LILITH_ROOT}/usr/share/icons/lilith"
mkdir -p "${LILITH_ROOT}/usr/share/plymouth/themes/lilith"

# Create issue file
cat > "${LILITH_ROOT}/etc/issue" << 'EOF'
Lilith Linux 1.0 "Resolute Raccoon"
Kernel \r on an \m

EOF

# Create issue.net
cat > "${LILITH_ROOT}/etc/issue.net" << 'EOF'
Lilith Linux 1.0
EOF

# Create os-release
cat > "${LILITH_ROOT}/etc/os-release" << 'EOF'
NAME="Lilith Linux"
VERSION="1.0 \"Resolute Raccoon\""
ID=lilith
ID_LIKE=ubuntu
PRETTY_NAME="Lilith Linux 1.0"
VERSION_ID="1.0"
HOME_URL="https://lilithlinux.org"
SUPPORT_URL="https://github.com/BlancoBAM/Lilith-Linux"
BUG_REPORT_URL="https://github.com/BlancoBAM/Lilith-Linux/issues"
PRIVACY_POLICY_URL="https://lilithlinux.org/privacy"
VERSION_CODENAME=resolvable
UBUNTU_CODENAME=noble
EOF

# Create ls-release
cat > "${LILITH_ROOT}/etc/lsb-release" << 'EOF'
DISTRIB_ID=Lilith Linux
DISTRIB_RELEASE=1.0
DISTRIB_CODENAME=resolvable
DISTRIB_DESCRIPTION="Lilith Linux 1.0"
EOF

# Create lightdm config
mkdir -p "${LILITH_ROOT}/etc/lightdm"
cat > "${LILITH_ROOT}/etc/lightdm/lightdm.conf" << 'EOF'
[LightDM]
start-default-session=true
guest-session=false

[Seat:*]
autologin-user=lilith
user-session=cosmic
greeter-session=cosmic-greeter
allow-guest=false

[VNCServer]
enabled=false
EOF

log "Lilith Linux branding installed"
