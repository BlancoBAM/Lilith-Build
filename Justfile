# Lilith Linux Justfile
# Usage: just <recipe>

set dotenv-load := true

# Default recipe
default:
    @just --list

# =============================================================================
# BUILD RECIPES
# =============================================================================

# Create base chroot
chroot:
    #!/usr/bin/env bash
    set -e
    echo "Creating Lilith Linux base chroot..."
    sudo mkdir -p /opt/lilith
    sudo debootstrap --variant=minbase noble /opt/lilith http://archive.ubuntu.com/ubuntu
    echo "Base chroot created at /opt/lilith"

# Install base packages in chroot
install-base:
    #!/usr/bin/env bash
    set -e
    echo "Installing base packages..."
    
    # Mount chroot
    sudo mount -t proc /proc /opt/lilith/proc
    sudo mount -t sysfs /sys /opt/lilith/sys
    sudo mount -t devpts /dev/pts /opt/lilith/dev/pts
    
    # Update and install
    sudo chroot /opt/lilith /bin/bash -c "apt update"
    sudo chroot /opt/lilith /bin/bash -c "DEBIAN_FRONTEND=noninteractive apt install -y \
        linux-image-generic initramfs-tools live-boot \
        systemd systemd-sysv sudo adduser vim curl wget gnupg2 ca-certificates \
        xorg openbox lightdm xterm network-manager network-manager-gnome \
        thunar ristretto mousepad xfce4-terminal policykit-1"
    
    echo "Base packages installed"

# Configure Lilith branding
branding:
    #!/usr/bin/env bash
    set -e
    echo "Configuring Lilith branding..."
    
    # OS Release
    sudo tee /opt/lilith/etc/os-release > /dev/null << 'EOF'
NAME="Lilith Linux"
VERSION="1.0 Resolute Raccoon"
ID=lilith
ID_LIKE=ubuntu
PRETTY_NAME="Lilith Linux 1.0 Resolute Raccoon"
VERSION_ID="1.0"
VERSION_CODENAME=resolute
EOF

    # Issue
    sudo tee /opt/lilith/etc/issue > /dev/null << 'EOF'
Lilith Linux 1.0 Resolute Raccoon
Kernel \r on an \m
EOF

    # LightDM
    sudo mkdir -p /opt/lilith/etc/lightdm/lightdm.conf.d
    sudo tee /opt/lilith/etc/lightdm/lightdm.conf.d/50-lilith.conf > /dev/null << 'EOF'
[LightDM]
autologin-user=lilith
autologin-user-timeout=0
user-session=openbox
[Seat:*]
allow-guest=false
EOF

    # Add user
    sudo chroot /opt/lilith /bin/bash -c "useradd -m -s /bin/bash lilith && echo 'lilith:lilith' | chpasswd"

    echo "Lilith branding configured"

# Install Rust tools
rust-tools:
    #!/usr/bin/env bash
    set -e
    echo "Installing Rust and Rust tools..."
    
    # Install Rust
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    
    # Install tools
    source ~/.cargo/env
    cargo install bat lsd fd-find ripgrep dust procs broot hexy

    # Create aliases
    echo 'alias cat=bat' | sudo tee -a /opt/lilith/etc/bash.bashrc
    echo 'alias ls=lsd' | sudo tee -a /opt/lilith/etc/bash.bashrc

    echo "Rust tools installed"

# Build ISO
iso:
    #!/usr/bin/env bash
    set -e
    echo "Building Lilith Linux ISO..."
    
    # Clean chroot
    sudo chroot /opt/lilith /bin/bash -c "apt clean && rm -rf /var/cache/apt/archives/*"
    
    # Create ISO directory
    mkdir -p /tmp/lilith-iso/{boot,casper,boot/grub}
    
    # Copy kernel and initrd
    sudo cp /opt/lilith/boot/vmlinuz /tmp/lilith-iso/boot/
    sudo cp /opt/lilith/boot/initrd.img /tmp/lilith-iso/boot/
    
    # Create squashfs
    sudo mksquashfs /opt/lilith /tmp/lilith-iso/casper/filesystem.squashfs \
        -noappend -no-recovery -comp xz -b 1M \
        -e proc -e sys -e dev -e run -e tmp -e var/cache -e var/log
    
    # GRUB config
    cat > /tmp/lilith-iso/boot/grub/grub.cfg << 'EOF'
set default=0
set timeout=10

menuentry "Lilith Linux 1.0 (Live)" {
    linux /boot/vmlinuz boot=casper iso-scan/filename=/casper/filesystem.squashfs quiet splash --
    initrd /boot/initrd.img
}
EOF

    # Create ISO
    sudo grub-mkrescue -o /home/aegon/lilith-linux-1.0-just.iso /tmp/lilith-iso
    
    echo "ISO created: /home/aegon/lilith-linux-1.0-just.iso"

# Full build (runs all recipes)
build: chroot install-base branding rust-tools iso
    @echo "Lilith Linux build complete!"
    @echo "ISO: /home/aegon/lilith-linux-1.0-just.iso"

# =============================================================================
# DEVELOPMENT RECIPES
# =============================================================================

# Shell into chroot
shell:
    sudo chroot /opt/lilith /bin/bash

# Clean build artifacts
clean:
    sudo rm -rf /opt/lilith
    rm -f /home/aegon/lilith-linux-1.0-just.iso
    rm -rf /tmp/lilith-iso

# =============================================================================
# REPOSITORY RECIPES
# =============================================================================

# Sync from upstream (uses lilith-debrep.toml)
sync:
    cd /home/aegon/Lilith-Build/repo && ./build-repo.sh sync

# Build repository
repo-build:
    cd /home/aegon/Lilith-Build/repo && ./build-repo.sh build
