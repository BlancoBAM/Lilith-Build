#!/bin/bash
# Lilith Linux Bootstrap Script
# This script bootstraps an Ubuntu-based Lilith Linux system with COSMIC Desktop

set -e

# Configuration
LILITH_ROOT="/opt/lilith-linux"
UBUNTU_RELEASE="noble"  # Ubuntu 24.04 LTS
ARCH="amd64"

echo "=========================================="
echo "Lilith Linux Bootstrap Script"
echo "=========================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root: sudo $0"
    exit 1
fi

# Step 1: Bootstrap Ubuntu base system
echo "[1/6] Bootstrapping Ubuntu ${UBUNTU_RELEASE} base system..."
mkdir -p "${LILITH_ROOT}"
debootstrap --arch ${ARCH} ${UBUNTU_RELEASE} ${LILITH_ROOT} http://archive.ubuntu.com/ubuntu/

# Step 2: Configure chroot environment
echo "[2/6] Configuring chroot environment..."

# Copy resolv.conf for network access
cp /etc/resolv.conf ${LILITH_ROOT}/etc/

# Mount pseudo-filesystems
mount -t proc /proc ${LILITH_ROOT}/proc
mount -t sysfs /sys ${LILITH_ROOT}/sys
mount -t devpts /dev/pts ${LILITH_ROOT}/dev/pts

# Step 3: Install base system packages and COSMIC dependencies
echo "[3/6] Installing system packages and COSMIC dependencies..."

cat > ${LILITH_ROOT}/tmp/install-deps.sh << 'EOF'
#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive

# Update package lists
apt update

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
    libflatpak-dev

# Install Rust
rustup toolchain install stable
rustup default stable
cargo install just

# Install pacstall
apt install -y pacstall

# Install other backends
apt install -y \
    flatpak \
    snapd

echo "Dependencies installed successfully!"
EOF

chmod +x ${LILITH_ROOT}/tmp/install-deps.sh
chroot ${LILITH_ROOT} /tmp/install-deps.sh

# Step 4: Clone and build COSMIC Desktop
echo "[4/6] Cloning and building COSMIC Desktop..."

cat > ${LILITH_ROOT}/tmp/build-cosmic.sh << 'EOF'
#!/bin/bash
set -e

# Clone COSMIC epoch
cd /root
git clone --recurse-submodules https://github.com/pop-os/cosmic-epoch
cd cosmic-epoch

# Build system extension (recommended method for testing)
just sysext

# Install COSMIC packages
apt install -y \
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
    cosmic-notifications

echo "COSMIC Desktop built successfully!"
EOF

chmod +x ${LILITH_ROOT}/tmp/build-cosmic.sh
chroot ${LILITH_ROOT} /tmp/build-cosmic.sh

# Step 5: Add Lilith Linux custom applications
echo "[5/6] Adding Lilith Linux custom applications..."

cat > ${LILITH_ROOT}/tmp/install-lilith-apps.sh << 'EOF'
#!/bin/bash
set -e

cd /root

# Clone Lilith Linux applications
git clone https://github.com/BlancoBAM/Lilith-Linux.git

# Install Tweakers
cd Tweakers
cargo build --release
cp target/release/tweakers /usr/local/bin/

# Install Shapeshifter
cd ../Shapeshifter
cargo build --release
cp target/release/shapeshifter /usr/local/bin/

# Install S8n-Rx-PackMan
cd ../S8n-Rx-PackMan
cargo build --release
cp target/release/s8n /usr/local/bin/

# Install Lilith-TTS
cd ../Lilith-TTS
cargo build --release
cp target/release/lilith-tts /usr/local/bin/

# Install Offerings (package manager)
cd ../Offerings
cargo build --release
cp target/release/offerings /usr/local/bin/

# Install Pake
cd ../Pake
npm install
cargo build --release
cp target/release/pake /usr/local/bin/

echo "Lilith Linux applications installed!"
EOF

chmod +x ${LILITH_ROOT}/tmp/install-lilith-apps.sh
chroot ${LILITH_ROOT} /tmp/install-lilith-apps.sh

# Step 6: Set up Lilith Linux branding and boot animation
echo "[6/6] Setting up Lilith Linux branding and boot animation..."

cat > ${LILITH_ROOT}/tmp/setup-branding.sh << 'EOF'
#!/bin/bash
set -e

# Create Lilith Linux plymouth theme
mkdir -p /usr/share/plymouth/themes/lilith
cat > /usr/share/plymouth/themes/lilith/lilith.plymouth << 'PLYMOUTH'
[Plymouth Theme]
Name=Lilith Linux
Description=Lilith Linux Boot Animation
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/lilith
ScriptFile=/usr/share/plymouth/themes/lilith/lilith.script
PLYMOUTH

cat > /usr/share/plymouth/themes/lilith/lilith.script << 'SCRIPT'
# Lilith Linux Plymouth Theme
# Animated logo with progress indicator

# Configuration
window.SetBackgroundTopColor(0.0, 0.0, 0.0);
window.SetBackgroundBottomColor(0.1, 0.0, 0.15);

# Logo
logo_image = Image("lilith-logo.png");
logo = logo_image.Scale(logo_image.GetWidth() / 2, logo_image.GetHeight() / 2);

# Animation
progress = 0;
fun refresh_callback() {
    progress += 0.01;
    if (progress > 1) progress = 1;
    
    # Draw progress bar
    bar_width = 300 * progress;
    bar_x = (Window.GetWidth() - bar_width) / 2;
    bar_y = Window.GetHeight() * 0.7;
    
    # Background
    Rectangle(bar_x - 2, bar_y - 2, bar_width + 4, 24).SetColor(0.2, 0.0, 0.3);
    # Progress
    Rectangle(bar_x, bar_y, bar_width, 20).SetColor(0.8, 0.0, 0.2);
}
Plymouth.SetRefreshFunction(refresh_callback);
SCRIPT

# Copy logo (will be created from the video)
# cp /root/Lilith-Linux/Lilith-Splash/Lilith.mp4 /usr/share/plymouth/themes/lilith/

# Set default theme
plymouth-set-default-theme lilith

# Create Lilith-branding for Calamares
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
defaultCalibration: true
squashfsCompression: 2
kernel: linux-generic
---

CALAMARES

echo "Lilith Linux branding configured!"
EOF

chmod +x ${LILITH_ROOT}/tmp/setup-branding.sh
chroot ${LILITH_ROOT} /tmp/setup-branding.sh

# Cleanup
umount ${LILITH_ROOT}/proc || true
umount ${LILITH_ROOT}/sys || true  
umount ${LILITH_ROOT}/dev/pts || true

echo ""
echo "=========================================="
echo "Lilith Linux Bootstrap Complete!"
echo "=========================================="
echo "Root filesystem: ${LILITH_ROOT}"
echo ""
echo "To enter the chroot:"
echo "  sudo chroot ${LILITH_ROOT} /bin/bash"
echo ""
echo "To create ISO (requires additional setup):"
echo "  Use Calamares or ubuntu-mainbuilder scripts"
