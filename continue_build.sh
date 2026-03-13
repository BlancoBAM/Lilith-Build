#!/bin/bash
# Lilith Linux Complete Build Script
# Run this to continue from where we left off

set -e

LILITH_ROOT="/opt/lilith-linux"

echo "=== Lilith Linux Build Script ==="

# Mount filesystems if not already mounted
mount -t proc /proc ${LILITH_ROOT}/proc 2>/dev/null || true
mount -t sysfs /sys ${LILITH_ROOT}/sys 2>/dev/null || true
mount -t devpts /dev/pts ${LILITH_ROOT}/dev/pts 2>/dev/null || true

# Continue COSMIC build if not running
if ! pgrep -f "just sysext" > /dev/null; then
    echo "Continuing COSMIC build..."
    chroot ${LILITH_ROOT} /bin/bash -c 'cd /root/src/cosmic-epoch && source /root/.cargo/env && just sysext 2>&1' | tail -20
fi

# Check build progress
echo ""
echo "Build log (last 30 lines):"
tail -30 ${LILITH_ROOT}/root/cosmic-build.log 2>/dev/null || echo "No log yet"

echo ""
echo "COSMIC build is running in background."
echo "To monitor: tail -f ${LILITH_ROOT}/root/cosmic-build.log"
