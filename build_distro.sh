#!/bin/bash
# Lilith Linux Distro Build Script
# Creates Lilith Linux based on Ubuntu with COSMIC desktop
# 
# Usage: sudo ./build_distro.sh [options]
#
# Options:
#   --base-only      Only create base system, don't install apps
#   --cosmic-only    Only install COSMIC desktop
#   --apps-only      Only install applications
#   --iso            Create ISO after building
#   --help           Show this help

set -e

# Configuration
DISTRO_NAME="Lilith Linux"
DISTRO_VERSION="1.0"
CODENAME="resolute-raccoon"  # Ubuntu 24.04 Noble derivative
BASE_DIR="/opt/lilith-distro"
LILITH_SRC="/home/aegon/Lilith-Linux"
PAX_FILE="/home/aegon/Lilith-Linux/lil-pax.toml"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
section() { echo -e "\n${CYAN}=== $1 ===${NC}\n"; }

# Check root
if [ "$EUID" -ne 0 ]; then
    error "This script requires root. Run with sudo."
    exit 1
fi

###############################################################################
# Parse Arguments
###############################################################################
BASE_ONLY=false
COSMIC_ONLY=false
APPS_ONLY=false
CREATE_ISO=false

while [ $# -gt 0 ]; do
    case "$1" in
        --base-only) BASE_ONLY=true ;;
        --cosmic-only) COSMIC_ONLY=true ;;
        --apps-only) APPS_ONLY=true ;;
        --iso) CREATE_ISO=true ;;
        --help|-h)
            echo "Lilith Linux Distro Build Script"
            echo "Usage: sudo $0 [options]"
            echo ""
            echo "Options:"
            echo "  --base-only    Only create base system"
            echo "  --cosmic-only  Only install COSMIC desktop"
            echo "  --apps-only    Only install applications"
            echo "  --iso          Create ISO after building"
            exit 0
            ;;
        *) error "Unknown option: $1" ;;
    esac
    shift
done

###############################################################################
# Base System Setup
###############################################################################
setup_base() {
    section "Setting up Ubuntu Base System"
    
    # Create base directory
    mkdir -p "${BASE_DIR}"
    
    # Check if already bootstrapped
    if [ -d "${BASE_DIR}/etc" ]; then
        warn "Base system already exists at ${BASE_DIR}"
        read -p "Rebootstrap? (y/N): " confirm
        if [ "$confirm" = "y" ]; then
            rm -rf "${BASE_DIR}"
            mkdir -p "${BASE_DIR}"
        else
            return 0
        fi
    fi
    
    # Bootstrap Ubuntu Noble (24.04)
    log "Bootstrapping Ubuntu 24.04 (Noble)..."
    debootstrap --arch amd64 noble "${BASE_DIR}" http://archive.ubuntu.com/ubuntu/
    
    # Copy DNS config
    cp /etc/resolv.conf "${BASE_DIR}/etc/"
    
    # Mount pseudo-filesystems
    mount -t proc /proc "${BASE_DIR}/proc"
    mount -t sysfs /sys "${BASE_DIR}/sys"
    mount -t devpts /dev/pts "${BASE_DIR}/dev/pts"
    
    # Configure apt sources
    cat > "${BASE_DIR}/etc/apt/sources.list" << 'EOF'
deb http://archive.ubuntu.com/ubuntu/ noble main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ noble-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ noble-security main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ noble-backports main restricted universe multiverse
EOF

    # Add universe multiverse for COSMIC
    echo 'APT::Default-Release "noble";' > "${BASE_DIR}/etc/apt/apt.conf.d/99default-release"

    # Update package lists
    chroot "${BASE_DIR}" /bin/bash -c "export DEBIAN_FRONTEND=noninteractive && apt update"
    
    log "Base system created successfully!"
}

###############################################################################
# Install Core Packages
###############################################################################
install_core() {
    section "Installing Core Packages"
    
    mount -t proc /proc "${BASE_DIR}/proc" 2>/dev/null || true
    mount -t sysfs /sys "${BASE_DIR}/sys" 2>/dev/null || true
    mount -t devpts /dev/pts "${BASE_DIR}/dev/pts" 2>/dev/null || true
    
    chroot "${BASE_DIR}" /bin/bash -c "export DEBIAN_FRONTEND=noninteractive && apt install -y \
        adduser \
        apt \
        apt-transport-https \
        base-files \
        base-passwd \
        bash \
        bsdutils \
        coreutils \
        dash \
        debconf \
        debianutils \
        diffutils \
        dpkg \
        e2fsprogs \
        fdisk \
        findutils \
        gcc-14-base \
        grep \
        gzip \
        hostname \
        init-system-helpers \
        libacl1 \
        libattr1 \
        libaudit-common \
        libaudit1 \
        libblkid1 \
        libbz2-1.0 \
        libc-bin \
        libcap2-bin \
        libcom-err2 \
        libcrypt1 \
        libdb5.3 \
        libdebconfclient0 \
        libext2fs2 \
        libgcc-s1 \
        libgcrypt20 \
        libgmp10 \
        libgnutls40 \
        libgpg-error0 \
        liblz4-1 \
        liblzma5 \
        libmount1 \
        libncurses6 \
        libpam0g \
        libpam-modules \
        libpam-modules-bin \
        libpam-runtime \
        libpcre3 \
        libselinux1 \
        libsmartcols1 \
        libss2 \
        libstdc++6 \
        libsystemd0 \
        libtinfo6 \
        libtool \
        libudev1 \
        libuuid1 \
        libzstd1 \
        login \
        logsave \
        lsb-base \
        mawk \
        mount \
        ncurses-base \
        ncurses-bin \
        passwd \
        perl-base \
        sed \
        sensible-utils \
        sysvinit-utils \
        tar \
        tzdata \
        ubuntu-keyring \
        ubuntu-release-upgrader-core \
        util-linux \
        zlib1g \
        systemd \
        systemd-sysv \
        sudo \
        vim-common \
        vim-tiny \
        wget \
        curl \
        git \
        network-manager \
        network-manager-gnome \
        gnome-control-center \
        gnome-terminal \
        firefox \
        gedit \
        nautilus \
        file-roller \
        gnome-screenshot \
        gnome-system-monitor \
        gnome-disks \
        gnome-calendar \
        gnome-contacts \
        gnome-calculator \
        gnome-text-editor \
        eog \
        evolution \
        thunderbird \
        2>&1" | tail -20
    
    log "Core packages installed!"
}

###############################################################################
# Install COSMIC Desktop
###############################################################################
install_cosmic() {
    section "Installing COSMIC Desktop Environment"
    
    mount -t proc /proc "${BASE_DIR}/proc" 2>/dev/null || true
    mount -t sysfs /sys "${BASE_DIR}/sys" 2>/dev/null || true
    mount -t devpts /dev/pts "${BASE_DIR}/dev/pts" 2>/dev/null || true
    
    # Add Pop!OS repository for COSMIC
    chroot "${BASE_DIR}" /bin/bash -c "export DEBIAN_FRONTEND=noninteractive && apt install -y wget gnupg"
    wget -q -O- http://apt.pop-os.org/proprietary.gpg | chroot "${BASE_DIR}" apt-key add -
    echo "deb http://apt.pop-os.org/ubuntu noble main" > "${BASE_DIR}/etc/apt/sources.list.d/pop-os.list"
    
    # Install COSMIC
    chroot "${BASE_DIR}" /bin/bash -c "export DEBIAN_FRONTEND=noninteractive && apt update"
    
    # Install COSMIC meta-package
    chroot "${BASE_DIR}" /bin/bash -c "export DEBIAN_FRONTEND=noninteractive && apt install -y \
        pop-desktop \
        cosmic-desktop \
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
        cosmic-osd \
        cosmic-randr \
        cosmic-screenshot \
        cosmic-bg \
        cosmic-wallpapers \
        pop-theme \
        lightdm \
        lightdm-gtk-greeter \
        2>&1" | tail -30
    
    log "COSMIC Desktop installed!"
}

###############################################################################
# Remove GNOME Components (Optional Cleanup)
###############################################################################
remove_gnome() {
    section "Removing Unnecessary GNOME Components"
    
    mount -t proc /proc "${BASE_DIR}/proc" 2>/dev/null || true
    mount -t sysfs /sys "${BASE_DIR}/sys" 2>/dev/null || true
    mount -t devpts /dev/pts "${BASE_DIR}/dev/pts" 2>/dev/null || true
    
    # Remove GNOME (keep essentials for COSMIC compatibility)
    chroot "${BASE_DIR}" /bin/bash -c "export DEBIAN_FRONTEND=noninteractive && apt remove -y \
        gnome-shell \
        gnome-session \
        gnome-settings-daemon \
        gnome-power-manager \
        gnome-screensaver \
        gnome-weather \
        gnome-logs \
        gnome-characters \
        gnome-logs \
        gnome-maps \
        gnome-news \
        gnome-getting-started-docs \
        gnome-user-docs \
        yaru-theme-gnome-shell \
        yaru-gtk-theme \
        yaru-icon-theme \
        chrome-gnome-shell \
        gnome-software \
        gnome-initial-setup \
        2>&1" | tail -10 || true
    
    # Auto remove
    chroot "${BASE_DIR}" /bin/bash -c "export DEBIAN_FRONTEND=noninteractive && apt autoremove -y" | tail -5 || true
    
    log "GNOME cleanup complete!"
}

###############################################################################
# Install Build Tools and Dependencies
###############################################################################
install_build_deps() {
    section "Installing Build Tools and Dependencies"
    
    mount -t proc /proc "${BASE_DIR}/proc" 2>/dev/null || true
    mount -t sysfs /sys "${BASE_DIR}/sys" 2>/dev/null || true
    mount -t devpts /dev/pts "${BASE_DIR}/dev/pts" 2>/dev/null || true
    
    chroot "${BASE_DIR}" /bin/bash -c "export DEBIAN_FRONTEND=noninteractive && apt install -y \
        build-essential \
        rustup \
        cargo \
        libwayland-dev \
        libseat-dev \
        libxkbcommon-dev \
        libinput-dev \
        libgstreamer1.0-dev \
        libgstreamer-plugins-base1.0-dev \
        libssl-dev \
        dbus \
        udev \
        libglvnd-dev \
        libgbm-dev \
        libpixman-1-dev \
        libpipewire-0.3-dev \
        libpulse-dev \
        libfontconfig-dev \
        libfreetype-dev \
        libclang-dev \
        libexpat1-dev \
        libsystemd-dev \
        cmake \
        pkg-config \
        git \
        curl \
        wget \
        just \
        flatpak \
        snapd \
        plymouth \
        plymouth-theme \
        2>&1" | tail -20
    
    # Install Rust stable
    chroot "${BASE_DIR}" /bin/bash -c "rustup toolchain install stable && rustup default stable"
    
    # Install Cargo just
    chroot "${BASE_DIR}" /bin/bash -c "cargo install just"
    
    log "Build tools installed!"
}

###############################################################################
# Install Lilith Linux Custom Apps
###############################################################################
install_lilith_apps() {
    section "Installing Lilith Linux Custom Applications"
    
    mount -t proc /proc "${BASE_DIR}/proc" 2>/dev/null || true
    mount -t sysfs /sys "${BASE_DIR}/sys" 2>/dev/null || true
    mount -t devpts /dev/pts "${BASE_DIR}/dev/pts" 2>/dev/null || true
    
    # Copy source files
    cp -r "${LILITH_SRC}" "${BASE_DIR}/root/Lilith-Linux"
    cp -r /home/aegon/Offerings "${BASE_DIR}/root/"
    
    # Build Offerings
    log "Building Offerings..."
    chroot "${BASE_DIR}" /bin/bash -c "cd /root/Offerings && cargo build --release" | tail -10
    cp "${BASE_DIR}/root/Offerings/target/release/offerings" "${BASE_DIR}/usr/local/bin/"
    
    # Build other apps (if they compile)
    for app in Tweakers Shapeshifter S8n-Rx-PackMan Lilith-TTS; do
        if [ -d "${BASE_DIR}/root/Lilith-Linux/${app}" ]; then
            log "Building ${app}..."
            chroot "${BASE_DIR}" /bin/bash -c "cd /root/Lilith-Linux/${app} && cargo build --release" 2>&1 | tail -5 || warn "${app} build failed, skipping"
            if [ -f "${BASE_DIR}/root/Lilith-Linux/${app}/target/release/${app,,}" ]; then
                cp "${BASE_DIR}/root/Lilith-Linux/${app}/target/release/${app,,}" "${BASE_DIR}/usr/local/bin/"
            fi
        fi
    done
    
    # Install Lilith Splash
    if [ -f "${BASE_DIR}/root/Lilith-Linux/Lilith-Splash/install_splash.sh" ]; then
        chmod +x "${BASE_DIR}/root/Lilith-Linux/Lilith-Splash/install_splash.sh"
        chroot "${BASE_DIR}" /bin/bash -c "cd /root/Lilith-Linux/Lilith-Splash && ./install_splash.sh" 2>&1 | tail -10
    fi
    
    log "Lilith apps installed!"
}

###############################################################################
# Install Packages from lil-pax.toml
###############################################################################
install_pax_packages() {
    section "Installing Packages from lil-pax.toml"
    
    mount -t proc /proc "${BASE_DIR}/proc" 2>/dev/null || true
    mount -t sysfs /sys "${BASE_DIR}/sys" 2>/dev/null || true
    mount -t devpts /dev/pts "${BASE_DIR}/dev/pts" 2>/dev/null || true
    
    if [ ! -f "${PAX_FILE}" ]; then
        warn "lil-pax.toml not found, skipping extra packages"
        return 0
    fi
    
    # Install Flatpak packages
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        
        if [[ "$line" == *"flathub"* ]] || [[ "$line" == *"flatpak"* ]]; then
            log "Installing Flatpak: $line"
            # Extract app ID
            app_id=$(echo "$line" | grep -oP 'flathub.*/\K[^/]+' | head -1)
            if [ -n "$app_id" ]; then
                chroot "${BASE_DIR}" /bin/bash -c "flatpak install -y flathub ${app_id}" 2>&1 | tail -5 || true
            fi
        elif [[ "$line" == *"snapcraft.io"* ]]; then
            log "Installing Snap: $line"
            # Extract snap name
            snap_name=$(echo "$line" | grep -oP 'snapcraft.io/\K[^/]+' | head -1)
            if [ -n "$snap_name" ]; then
                chroot "${BASE_DIR}" /bin/bash -c "snap install ${snap_name}" 2>&1 | tail -5 || true
            fi
        elif [[ "$line" == *"github.com"* ]]; then
            log "Cloning GitHub repo: $line"
            repo_name=$(echo "$line" | grep -oP 'github.com/\K[^/]+/[^/]+' | head -1)
            if [ -n "$repo_name" ]; then
                chroot "${BASE_DIR}" /bin/bash -c "git clone https://github.com/${repo_name}.git /root/src/${repo_name}" 2>&1 | tail -5 || true
            fi
        fi
    done < "${PAX_FILE}"
    
    log "Extra packages processed!"
}

###############################################################################
# Configure System
###############################################################################
configure_system() {
    section "Configuring Lilith Linux System"
    
    mount -t proc /proc "${BASE_DIR}/proc" 2>/dev/null || true
    mount -t sysfs /sys "${BASE_DIR}/sys" 2>/dev/null || true
    mount -t devpts /dev/pts "${BASE_DIR}/dev/pts" 2>/dev/null || true
    
    # Set hostname
    echo "lilith" > "${BASE_DIR}/etc/hostname"
    
    # Set timezone
    ln -sf /usr/share/zoneinfo/UTC "${BASE_DIR}/etc/localtime"
    
    # Configure locales
    echo "en_US.UTF-8 UTF-8" > "${BASE_DIR}/etc/locale.gen"
    chroot "${BASE_DIR}" locale-gen
    
    # Configure LightDM for COSMIC
    cat > "${BASE_DIR}/etc/lightdm/lightdm.conf" << 'EOF'
[LightDM]
start-default-session=true
guest-session=session
logind-check-graphical=true

[Seat:*]
autologin-guest=false
autologin-user=
autologin-user-timeout=0
user-session=cosmic
greeter-session=cosmic-greeter
EOF
    
    # Set Plymouth theme
    chroot "${BASE_DIR}" /bin/bash -c "plymouth-set-default-theme lilith" 2>&1 || true
    
    # Create Lilith user
    chroot "${BASE_DIR}" /bin/bash -c "useradd -m -s /bin/bash -G sudo,audio,video,plugdev lilith || true"
    chroot "${BASE_DIR}" /bin/bash -c "echo 'lilith:lilith' | chpasswd" || true
    
    # Copy Lilith branding
    mkdir -p "${BASE_DIR}/usr/share/calamares/brands/lilith"
    cat > "${BASE_DIR}/usr/share/calamares/brands/lilith/branding.desc" << 'EOF'
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

    log "System configured!"
}

###############################################################################
# Cleanup
###############################################################################
cleanup() {
    section "Cleaning up"
    
    umount "${BASE_DIR}/proc" 2>/dev/null || true
    umount "${BASE_DIR}/sys" 2>/dev/null || true
    umount "${BASE_DIR}/dev/pts" 2>/dev/null || true
    
    # Clean apt cache
    rm -rf "${BASE_DIR}/var/cache/apt/archives"/*
    rm -rf "${BASE_DIR}/root"
    rm -rf "${BASE_DIR}/tmp"/*
    
    log "Cleanup complete!"
}

###############################################################################
# Create ISO (Placeholder - requires additional tools)
###############################################################################
create_iso() {
    section "Creating ISO"
    
    warn "ISO creation requires additional setup with penguins-eggs or calamares"
    log "Base system is ready at: ${BASE_DIR}"
    log ""
    log "To create ISO, you can:"
    log "1. Use penguins-eggs: sudo eggs produce"
    log "2. Use Calamares directly"
    log "3. Use Ubuntu's build tools"
}

###############################################################################
# Main
###############################################################################
main() {
    section "Lilith Linux Distro Builder"
    
    log "Building ${DISTRO_NAME} ${DISTRO_VERSION} (${CODENAME})"
    log "Base directory: ${BASE_DIR}"
    log ""
    
    if [ "$BASE_ONLY" = true ]; then
        setup_base
        install_core
        configure_system
    elif [ "$COSMIC_ONLY" = true ]; then
        install_cosmic
    elif [ "$APPS_ONLY" = true ]; then
        install_build_deps
        install_lilith_apps
        install_pax_packages
    else
        # Full build
        setup_base
        install_core
        install_cosmic
        remove_gnome
        install_build_deps
        install_lilith_apps
        install_pax_packages
        configure_system
    fi
    
    cleanup
    
    if [ "$CREATE_ISO" = true ]; then
        create_iso
    fi
    
    section "Build Complete!"
    log "Lilith Linux base system ready at: ${BASE_DIR}"
    log ""
    log "To enter the chroot:"
    log "  sudo chroot ${BASE_DIR} /bin/bash"
    log ""
    log "To create ISO, install penguins-eggs and run:"
    log "  sudo eggs produce"
}

main "$@"
