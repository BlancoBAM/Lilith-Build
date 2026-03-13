#!/bin/bash
# Lilith Linux Live/Distro Builder Script
# Uses existing chroot at /opt/lilith-linux and configures for live ISO
#
# This script:
# 1. Configures existing chroot for Lilith Linux
# 2. Removes GNOME, keeps COSMIC
# 3. Installs packages from lil-pax.toml
# 4. Sets up for ISO creation with penguins-eggs
#
# Usage: sudo ./setup_lilith_distro.sh

set -e

LILITH_ROOT="${1:-/opt/lilith-linux}"
LILITH_SRC="/home/aegon/Lilith-Linux"
PAX_FILE="/home/aegon/Lilith-Linux/lil-pax.toml"

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

# Mount filesystems
mount -t proc /proc "${LILITH_ROOT}/proc" 2>/dev/null || true
mount -t sysfs /sys "${LILITH_ROOT}/sys" 2>/dev/null || true
mount -t devpts /dev/pts "${LILITH_ROOT}/dev/pts" 2>/dev/null || true

log "=== Configuring Lilith Linux Distro ==="

###############################################################################
# 1. Configure Ubuntu Sources
###############################################################################
log "Configuring apt sources..."

cat > "${LILITH_ROOT}/etc/apt/sources.list" << 'EOF'
deb http://archive.ubuntu.com/ubuntu/ noble main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ noble-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ noble-security main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ noble-backports main restricted universe multiverse
EOF

# Add universe/multiverse for COSMIC
chroot "${LILITH_ROOT}" /bin/bash -c "add-apt-repository universe -y" 2>/dev/null || true
chroot "${LILITH_ROOT}" /bin/bash -c "add-apt-repository multiverse -y" 2>/dev/null || true
chroot "${LILITH_ROOT}" /bin/bash -c "export DEBIAN_FRONTEND=noninteractive && apt update" 2>&1 | tail -5

###############################################################################
# 2. Install COSMIC Desktop
###############################################################################
log "Installing COSMIC Desktop..."

# Add Pop!OS repo
chroot "${LILITH_ROOT}" /bin/bash -c "wget -q -O- http://apt.pop-os.org/proprietary.gpg | gpg --dearmor -o /usr/share/keyrings/pop-os-archive-keyring.gpg" 2>/dev/null || true
echo "deb [signed-by=/usr/share/keyrings/pop-os-archive-keyring.gpg] http://apt.pop-os.org/ubuntu noble main" > "${LILITH_ROOT}/etc/apt/sources.list.d/pop-os.list"

chroot "${LILITH_ROOT}" /bin/bash -c "export DEBIAN_FRONTEND=noninteractive && apt update" 2>&1 | tail -5

# Install COSMIC
chroot "${LILITH_ROOT}" /bin/bash -c "export DEBIAN_FRONTEND=noninteractive && apt install -y \
    pop-desktop \
    cosmic-desktop \
    cosmic-session \
    cosmic-applets \
    cosmic-edit \
    cosmic-files \
    cosmic-term \
    cosmic-store \
    cosmic-launcher \
    cosmic-panel \
    cosmic-greeter \
    cosmic-settings \
    cosmic-notifications \
    pop-theme \
    lightdm \
    2>&1" | tail -30

###############################################################################
# 3. Remove GNOME Components
###############################################################################
log "Removing unnecessary GNOME components..."

chroot "${LILITH_ROOT}" /bin/bash -c "export DEBIAN_FRONTEND=noninteractive && apt remove -y \
    gnome-shell \
    gnome-session \
    gnome-settings-daemon \
    gnome-power-manager \
    gnome-screensaver \
    gnome-weather \
    gnome-logs \
    gnome-maps \
    gnome-software \
    gnome-initial-setup \
    yaru-theme-gnome-shell \
    yaru-gtk-theme \
    yaru-icon-theme \
    2>&1" | tail -10 || true

chroot "${LILITH_ROOT}" /bin/bash -c "export DEBIAN_FRONTEND=noninteractive && apt autoremove -y" 2>&1 | tail -5 || true

###############################################################################
# 4. Install Lilith Custom Apps
###############################################################################
log "Installing Lilith Linux custom applications..."

# Ensure Lilith-Linux source is in chroot
if [ ! -d "${LILITH_ROOT}/root/Lilith-Linux" ]; then
    cp -r "${LILITH_SRC}" "${LILITH_ROOT}/root/"
fi

# Ensure Offerings is in chroot  
if [ ! -d "${LILITH_ROOT}/root/Offerings" ]; then
    cp -r /home/aegon/Offerings "${LILITH_ROOT}/root/"
fi

# Install each app
for app_dir in Tweakers Shapeshifter S8n-Rx-PackMan; do
    app_src="${LILITH_ROOT}/root/Lilith-Linux/${app_dir}"
    app_bin=$(echo "$app_dir" | tr '[:upper:]' '[:lower:]' | tr -d '-')
    
    if [ -d "$app_src" ]; then
        log "Building ${app_dir}..."
        if [ -f "$app_src/target/release/$app_bin" ]; then
            cp "$app_src/target/release/$app_bin" "${LILITH_ROOT}/usr/local/bin/" 2>/dev/null || true
        fi
    fi
done

# Ensure Offerings is installed
if [ -f "${LILITH_ROOT}/root/Offerings/target/release/offerings" ]; then
    cp "${LILITH_ROOT}/root/Offerings/target/release/offerings" "${LILITH_ROOT}/usr/local/bin/"
fi

# Install boot splash
if [ -f "${LILITH_ROOT}/root/Lilith-Linux/Lilith-Splash/install_splash.sh" ]; then
    log "Setting up boot splash..."
    chmod +x "${LILITH_ROOT}/root/Lilith-Linux/Lilith-Splash/install_splash.sh"
fi

###############################################################################
# 5. Install Packages from lil-pax.toml
###############################################################################
log "Installing packages from lil-pax.toml..."

# Ensure flatpak is available
chroot "${LILITH_ROOT}" /bin/bash -c "flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo" 2>/dev/null || true

if [ -f "${PAX_FILE}" ]; then
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        
        # Flatpak apps
        if [[ "$line" == *"flathub"* ]]; then
            app_id=$(echo "$line" | grep -oP 'flathub.org/en/apps/\K[^/]+' | head -1)
            if [ -n "$app_id" ]; then
                log "Installing Flatpak: $app_id"
                chroot "${LILITH_ROOT}" /bin/bash -c "flatpak install -y flathub ${app_id}" 2>/dev/null || true
            fi
        fi
        
        # Snap apps
        if [[ "$line" == *"snapcraft.io"* ]]; then
            snap_name=$(echo "$line" | grep -oP 'snapcraft.io/\K[^/]+' | head -1)
            if [ -n "$snap_name" ]; then
                log "Installing Snap: $snap_name"
                chroot "${LILITH_ROOT}" /bin/bash -c "snap install ${snap_name}" 2>/dev/null || true
            fi
        fi
        
    done < "${PAX_FILE}"
fi

###############################################################################
# 6. Configure System
###############################################################################
log "Configuring system..."

# Hostname
echo "lilith" > "${LILITH_ROOT}/etc/hostname"

# LightDM for COSMIC
mkdir -p "${LILITH_ROOT}/etc/lightdm"
cat > "${LILITH_ROOT}/etc/lightdm/lightdm.conf" << 'EOF'
[LightDM]
start-default-session=true

[Seat:*]
autologin-user=lilith
user-session=cosmic
greeter-session=cosmic-greeter
EOF

# Calamares branding
mkdir -p "${LILITH_ROOT}/usr/share/calamares/brands/lilith"
cat > "${LILITH_ROOT}/usr/share/calamares/brands/lilith/branding.desc" << 'EOF'
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

# Lilith user
chroot "${LILITH_ROOT}" /bin/bash -c "useradd -m -s /bin/bash -G sudo,audio,video,plugdev lilith 2>/dev/null || true"
chroot "${LILITH_ROOT}" /bin/bash -c "echo 'lilith:lilith' | chpasswd" 2>/dev/null || true

###############################################################################
# 7. Install penguins-eggs
###############################################################################
log "Installing penguins-eggs..."

chroot "${LILITH_ROOT}" /bin/bash -c "wget -q https://packages.penguins-eggs.net/releases/gpg/key -O- | apt-key add -" 2>/dev/null || true
echo "deb https://packages.penguins-eggs.net/releases/ubuntu noble main" > "${LILITH_ROOT}/etc/apt/sources.list.d/penguins-eggs.list"
chroot "${LILITH_ROOT}" /bin/bash -c "export DEBIAN_FRONTEND=noninteractive && apt update" 2>&1 | tail -3
chroot "${LILITH_ROOT}" /bin/bash -c "export DEBIAN_FRONTEND=noninteractive && apt install -y penguins-eggs" 2>&1 | tail -10

###############################################################################
# Cleanup
###############################################################################
umount "${LILITH_ROOT}/proc" 2>/dev/null || true
umount "${LILITH_ROOT}/sys" 2>/dev/null || true
umount "${LILITH_ROOT}/dev/pts" 2>/dev/null || true

log "=== Lilith Linux Distro Configuration Complete ==="
log ""
log "Lilith Linux is configured at: ${LILITH_ROOT}"
log ""
log "To create ISO:"
log "  sudo chroot ${LILITH_ROOT}"
log "  eggs produce"
log ""
log "Installed components:"
log "  - COSMIC Desktop Environment"
log "  - Lilith custom apps (Offerings, Tweakers, etc.)"
log "  - Packages from lil-pax.toml"
log "  - penguins-eggs for ISO creation"
