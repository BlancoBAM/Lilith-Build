#!/bin/bash
# Lilith Linux Build System - No Root Required for Setup
# This creates the build environment and generates instructions

set -e

BUILD_DIR="/home/aegon/Lilith-Build"
LILITH_DIR="/home/aegon/Lilith-Linux"

echo "=========================================="
echo "Lilith Linux Build System"
echo "=========================================="

mkdir -p "${BUILD_DIR}"

# Create the main bootstrap script (requires sudo)
cat > "${BUILD_DIR}/01-bootstrap.sh" << 'SCRIPT'
#!/bin/bash
# Step 1: Bootstrap Ubuntu - REQUIRES ROOT
set -e

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root: sudo $0"
    exit 1
fi

LILITH_ROOT="${1:-/opt/lilith-linux}"
UBUNTU_RELEASE="noble"

echo "Bootstrapping Ubuntu ${UBUNTU_RELEASE} to ${LILITH_ROOT}..."
mkdir -p "${LILITH_ROOT}"
debootstrap --arch amd64 ${UBUNTU_RELEASE} ${LILITH_ROOT} http://archive.ubuntu.com/ubuntu/

# Copy DNS config
cp /etc/resolv.conf ${LILITH_ROOT}/etc/

echo "Bootstrap complete!"
echo "Next: Run 02-install-deps.sh"
SCRIPT

# Create dependency installation script
cat > "${BUILD_DIR}/02-install-deps.sh" << 'SCRIPT'
#!/bin/bash
# Step 2: Install Dependencies - REQUIRES ROOT
set -e

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root: sudo $0"
    exit 1
fi

LILITH_ROOT="${1:-/opt/lilith-linux}"

# Mount pseudo-filesystems
mount -t proc /proc ${LILITH_ROOT}/proc
mount -t sysfs /sys ${LILITH_ROOT}/sys
mount -t devpts /dev/pts ${LILITH_ROOT}/dev/pts

# Install dependencies in chroot
chroot ${LILITH_ROOT} /bin/bash << 'EOF'
set -e
export DEBIAN_FRONTEND=noninteractive

# Update
apt update
apt upgrade -y

# Install COSMIC build dependencies
apt install -y \
    build-essential \
    rustup \
    libwayland-dev \
    libseat-dev \
    libxkbcommon-dev \
    libinput-dev \
    libdisplay-info-dev \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    libssl-dev \
    dbus \
    udev \
    libpam0g-dev \
    libpixman-1-dev \
    libglvnd-dev \
    libclang-dev \
    libexpat1-dev \
    libfontconfig-dev \
    libfreetype-dev \
    libgbm-dev \
    libpipewire-0.3-dev \
    libpulse-dev \
    libsystemd-dev \
    lld \
    mold \
    just \
    git \
    curl \
    wget \
    cmake \
    pkg-config \
    libflatpak-dev \
    flatpak \
    pacstall \
    plymouth \
    plymouth-theme-libinput

# Install Rust
rustup toolchain install stable
rustup default stable
cargo install just

echo "Dependencies installed!"
EOF

# Unmount
umount ${LILITH_ROOT}/proc || true
umount ${LILITH_ROOT}/sys || true
umount ${LILITH_ROOT}/dev/pts || true

echo "Dependencies installed!"
echo "Next: Run 03-build-cosmic.sh"
SCRIPT

# Create COSMIC build script
cat > "${BUILD_DIR}/03-build-cosmic.sh" << 'SCRIPT'
#!/bin/bash
# Step 3: Build COSMIC Desktop - REQUIRES ROOT
set -e

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root: sudo $0"
    exit 1
fi

LILITH_ROOT="${1:-/opt/lilith-linux}"

# Mount
mount -t proc /proc ${LILITH_ROOT}/proc
mount -t sysfs /sys ${LILITH_ROOT}/sys
mount -t devpts /dev/pts ${LILITH_ROOT}/dev/pts

# Build COSMIC
chroot ${LILITH_ROOT} /bin/bash << 'EOF'
set -e
cd /root

# Clone COSMIC
git clone --recurse-submodules https://github.com/pop-os/cosmic-epoch
cd cosmic-epoch

# Build system extension
just sysext

echo "COSMIC built! System extension: cosmic-sysext/"
EOF

# Unmount
umount ${LILITH_ROOT}/proc || true
umount ${LILITH_ROOT}/sys || true
umount ${LILITH_ROOT}/dev/pts || true

echo "COSMIC Desktop built!"
echo "Next: Run 04-install-apps.sh"
SCRIPT

# Create Lilith apps installation script
cat > "${BUILD_DIR}/04-install-apps.sh" << 'SCRIPT'
#!/bin/bash
# Step 4: Install Lilith Linux Apps - REQUIRES ROOT
set -e

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root: sudo $0"
    exit 1
fi

LILITH_ROOT="${1:-/opt/lilith-linux}"
LILITH_SRC="${2:-/home/aegon/Lilith-Linux}"

# Mount
mount -t proc /proc ${LILITH_ROOT}/proc
mount -t sysfs /sys ${LILITH_ROOT}/sys
mount -t devpts /dev/pts ${LILITH_ROOT}/dev/pts

# Copy Lilith source
mkdir -p ${LILITH_ROOT}/root/src
cp -r ${LILITH_SRC}/* ${LILITH_ROOT}/root/src/

# Install apps
chroot ${LILITH_ROOT} /bin/bash << 'EOF'
set -e
cd /root/src

# Build Tweakers
cd Tweakers
cargo build --release
cp target/release/tweakers /usr/local/bin/
cd ..

# Build Shapeshifter
cd Shapeshifter
cargo build --release
cp target/release/shapeshifter /usr/local/bin/
cd ..

# Build S8n
cd S8n-Rx-PackMan
cargo build --release
cp target/release/s8n /usr/local/bin/
cd ..

# Build Lilith-TTS
cd Lilith-TTS
cargo build --release
cp target/release/lilith-tts /usr/local/bin/
cd ..

# Build Offerings
cd ../Offerings
cargo build --release
cp target/release/offerings /usr/local/bin/

echo "Lilith Apps installed!"
EOF

# Unmount
umount ${LILITH_ROOT}/proc || true
umount ${LILITH_ROOT}/sys || true
umount ${LILITH_ROOT}/dev/pts || true

echo "Lilith Apps installed!"
echo "Next: Run 05-setup-branding.sh"
SCRIPT

# Create branding setup script
cat > "${BUILD_DIR}/05-setup-branding.sh" << 'SCRIPT'
#!/bin/bash
# Step 5: Setup Branding and Boot Animation - REQUIRES ROOT
set -e

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root: sudo $0"
    exit 1
fi

LILITH_ROOT="${1:-/opt/lilith-linux}"
LILITH_SRC="${2:-/home/aegon/Lilith-Linux}"

# Mount
mount -t proc /proc ${LILITH_ROOT}/proc
mount -t sysfs /sys ${LILITH_ROOT}/sys
mount -t devpts /dev/pts ${LILITH_ROOT}/dev/pts

# Copy splash files
mkdir -p ${LILITH_ROOT}/root/src/Lilith-Splash
cp -r ${LILITH_SRC}/Lilith-Splash/* ${LILITH_ROOT}/root/src/Lilith-Splash/

# Setup boot splash
chroot ${LILITH_ROOT} /bin/bash << 'EOF'
set -e

# Install Lilith Splash Video
cd /root/src/Lilith-Splash
chmod +x install_splash.sh
./install_splash.sh

# Create Plymouth theme
mkdir -p /usr/share/plymouth/themes/lilith
cat > /usr/share/plymouth/themes/lilith/lilith.plymouth << 'PLY'
[Plymouth Theme]
Name=Lilith Linux
ModuleName=script
PLY

cat > /usr/share/plymouth/themes/lilith/lilith.script << 'SCRIPT'
wallpaper = Image("lilith-splash.png");
wallpaper = wallpaper.Scale(Window.GetWidth(), Window.GetHeight());
wallpaper = wallpaper.BlendOntoRoot(0, 0);
SCRIPT

# Set Plymouth theme
plymouth-set-default-theme lilith

# Create Calamares branding
mkdir -p /usr/share/calamares/branding/lilith
cat > /usr/share/calamares/branding/lilith/branding.desc << 'CALAMARES'
---
productName: Lilith Linux
productVersion: 1.0
version: 1.0.0
variant: Lilith
variantId: lilith
shortProductName: Lilith
homepage: https://lilithlinux.org
bootloaderEntryName: Lilith
---

CALAMARES

echo "Branding configured!"
EOF

# Unmount
umount ${LILITH_ROOT}/proc || true
umount ${LILITH_ROOT}/sys || true
umount ${LILITH_ROOT}/dev/pts || true

echo "Branding complete!"
echo "Next: Run 06-create-iso.sh to create final image"
SCRIPT

# Make all scripts executable
chmod +x "${BUILD_DIR}"/*.sh

echo ""
echo "=========================================="
echo "Lilith Linux Build Scripts Created!"
echo "=========================================="
echo ""
echo "Build scripts location: ${BUILD_DIR}"
echo ""
echo "To build Lilith Linux, run these commands:"
echo ""
echo "  sudo ${BUILD_DIR}/01-bootstrap.sh"
echo "  sudo ${BUILD_DIR}/02-install-deps.sh"
echo "  sudo ${BUILD_DIR}/03-build-cosmic.sh"
echo "  sudo ${BUILD_DIR}/04-install-apps.sh"
echo "  sudo ${BUILD_DIR}/05-setup-branding.sh"
echo ""
echo "Or run all at once:"
echo "  for s in ${BUILD_DIR}/*.sh; do sudo \"\$s\"; done"
echo ""
