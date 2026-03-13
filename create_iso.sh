#!/bin/bash
# Lilith Linux ISO Creation Script
# Creates ISO from the built chroot

set -e

LILITH_ROOT="/opt/lilith-linux"
OUTPUT_DIR="/run/media/aegon/692f77f2-a75c-4e8e-b56c-14329a88dead/build-workspace/iso"
WORK_DIR="/run/media/aegon/692f77f2-a75c-4e8e-b56c-14329a88dead/build-workspace/iso-build"
KERNEL_PATH="/run/media/aegon/692f77f2-a75c-4e8e-b56c-14329a88dead/build-workspace/vmlinuz"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

if [ "$EUID" -ne 0 ]; then
    error "This script requires root. Run with sudo"
    exit 1
fi

log "Starting Lilith Linux ISO creation..."

# Create directories
mkdir -p "$OUTPUT_DIR"
mkdir -p "$WORK_DIR"

# Check available space
log "Checking disk space..."
AVAIL=$(df -BG "$OUTPUT_DIR" | tail -1 | awk '{print $4}' | tr -d 'G')
if [ "$AVAIL" -lt 50 ]; then
    warn "Low disk space: ${AVAIL}GB available"
fi

# Step 1: Prepare chroot
log "Preparing chroot for ISO..."
cp /home/aegon/Lilith-Build/config/topgrade.toml "$LILITH_ROOT/etc/topgrade.toml" 2>/dev/null || true
cp /home/aegon/Lilith-Build/install_apps.sh "$LILITH_ROOT/root/" 2>/dev/null || true

# Step 2: Clean up unnecessary files
log "Cleaning up for ISO..."
chroot "$LILITH_ROOT" /bin/bash -c "
    apt-get clean
    rm -rf /var/cache/apt/archives/*
    rm -rf /tmp/*
    rm -rf /root/.cache/*
" 2>/dev/null || true

# Step 3: Create squashfs
log "Creating squashfs..."
SQUASHFS="$WORK_DIR/lilithfs.squashfs"

# Mount chroot
mount -t proc /proc "$LILITH_ROOT/proc" 2>/dev/null || true
mount -t sysfs /sys "$LILITH_ROOT/sys" 2>/dev/null || true  
mount -t devpts /dev/pts "$LILITH_ROOT/dev/pts" 2>/dev/null || true

# Create squashfs excluding some directories
mksquashfs "$LILITH_ROOT" "$SQUASHFS" \
    -noappend \
    -no-recovery \
    -comp xz \
    -b 1M \
    -e proc \
    -e sys \
    -e dev \
    -e run \
    -e tmp \
    -e var/cache \
    -e var/log \
    2>&1 | tail -10

log "Squashfs created: $(du -h $SQUASHFS)"

# Step 4: Create ISO directory structure
log "Creating ISO structure..."
ISO_DIR="$WORK_DIR/iso"
mkdir -p "$ISO_DIR/casper"
mkdir -p "$ISO_DIR/boot"
mkdir -p "$ISO_DIR/.disk"

# Copy squashfs
cp "$SQUASHFS" "$ISO_DIR/casper/filesystem.squashfs"

# Create manifest
log "Creating manifest..."
du -sx "$LILITH_ROOT" | cut -f1 > "$ISO_DIR/casper/filesystem.size"

# Create GRUB bootloader
log "Setting up bootloader..."

# Copy kernel (from external location or chroot)
if [ -f "$KERNEL_PATH" ]; then
    cp "$KERNEL_PATH" "$ISO_DIR/boot/vmlinuz"
    log "Using external kernel from $KERNEL_PATH"
elif [ -f "$LILITH_ROOT/boot/vmlinuz" ]; then
    cp "$LILITH_ROOT/boot/vmlinuz" "$ISO_DIR/boot/vmlinuz"
fi

# Try to get initrd from external location or generate minimal one
INITRD_PATH="/run/media/aegon/692f77f2-a75c-4e8e-b56c-14329a88dead/build-workspace/initrd.img"
if [ -f "$INITRD_PATH" ]; then
    cp "$INITRD_PATH" "$ISO_DIR/boot/initrd.img"
elif [ -f "$LILITH_ROOT/boot/initrd.img" ]; then
    cp "$LILITH_ROOT/boot/initrd.img" "$ISO_DIR/boot/initrd.img"
else
    warn "No initrd found - creating minimal initrd"
    # Create minimal initrd with busybox for boot
    mkdir -p /tmp/initrd/bin /tmp/initrd/scripts
    cp /bin/busybox /tmp/initrd/bin/ 2>/dev/null || true
    echo '#!/bin/sh
mount -t proc /proc /proc
mount -t sysfs /sys /sys
mount -t devpts /dev/pts /dev/pts 2>/dev/null
exec /bin/sh' > /tmp/initrd/init
    chmod +x /tmp/initrd/init
    cd /tmp/initrd && find . -print | cpio -o -H newc 2>/dev/null | xz > "$ISO_DIR/boot/initrd.img" 2>/dev/null || true
fi

# Create disk info
echo "Lilith Linux 1.0" > "$ISO_DIR/.disk/info"
echo "amd64" > "$ISO_DIR/.disk/architecture"
date +"%Y-%m-%d" > "$ISO_DIR/.disk/date"

# Step 5: Create ISO
log "Creating ISO image..."
ISO_NAME="lilith-linux-1.0-live.iso"

# Create a simple bootable ISO
grub-mkrescue -o "$OUTPUT_DIR/$ISO_NAME" "$ISO_DIR" 2>&1 | tail -10 || {
    warn "GRUB mkrescue failed, trying xorriso..."
    
    # Fallback: create ISO with xorriso
    xorriso -as mkisofs \
        -r \
        -o "$OUTPUT_DIR/$ISO_NAME" \
        -J \
        -boot-info-table \
        "$ISO_DIR" 2>&1 | tail -10
}

# Verify ISO
if [ -f "$OUTPUT_DIR/$ISO_NAME" ]; then
    log "ISO created successfully!"
    log "Location: $OUTPUT_DIR/$ISO_NAME"
    log "Size: $(du -h $OUTPUT_DIR/$ISO_NAME)"
else
    error "ISO creation failed"
    exit 1
fi

# Cleanup
log "Cleaning up..."
umount "$LILITH_ROOT/proc" 2>/dev/null || true
umount "$LILITH_ROOT/sys" 2>/dev/null || true
umount "$LILITH_ROOT/dev/pts" 2>/dev/null || true

log "ISO creation complete!"
echo ""
echo "=== Lilith Linux ISO Created ==="
echo "File: $OUTPUT_DIR/$ISO_NAME"
echo "Size: $(du -h $OUTPUT_DIR/$ISO_NAME | cut -f1)"
echo ""
echo "To write to USB:"
echo "  sudo dd if=$OUTPUT_DIR/$ISO_NAME of=/dev/sdX bs=4M status=progress"
