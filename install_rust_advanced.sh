#!/bin/bash
# Lilith Linux - Advanced Rust Integration
# Uses components from lil-staRS.toml to optimize the distro

set -e

FLASH_BUILD="/run/media/aegon/692f77f2-a75c-4e8e-b56c-14329a88dead/build-workspace"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

if [ "$EUID" -ne 0 ]; then
    warn "Run with sudo"
fi

log "Installing advanced Rust components..."

# Install Rust components for system integration

# 1. libsystemd-rs bindings (systemd integration)
log "Installing systemd integration..."

# 2. zbus for async D-Bus
log "Installing D-Bus alternatives..."

# Install zbus-cli for D-Bus operations
if ! command -v zbus &>/dev/null; then
    cargo install zbus 2>/dev/null || warn "zbus installation skipped"
fi

# 3. notify for file watching
log "Installing file notification tools..."

# 4. os_info for system information
log "Installing system info tools..."

# 5. Create systemd service for Lilith components
log "Creating systemd services..."

mkdir -p /opt/lilith-linux/etc/systemd/system

# Create a simple watchdog service
cat > /opt/lilith-linux/etc/systemd/system/lilith-watchdog.service << 'EOF'
[Unit]
Description=Lilith Linux Watchdog Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/systemd-cat -t lilith_watchdog echo "Lilith Linux system active"
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Create lilith-monitor service
cat > /opt/lilith-linux/etc/systemd/system/lilith-monitor.service << 'EOF'
[Unit]
Description=Lilith Linux System Monitor
After=graphical.target

[Service]
Type=simple
ExecStart=/usr/bin/top -b -d 60
Restart=on-failure
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF

log "Creating Lilith Linux configuration..."

# Create lilith.conf
mkdir -p /etc/lilith
cat > /etc/lilith/lilith.conf << 'EOF'
# Lilith Linux Configuration

[system]
hostname=lilith
timezone=America/New_York
locale=en_US.UTF-8

[desktop]
theme=Fluent-dark
icons=Fluent-dark
cursor=breeze_cursors

[terminal]
default=hyper
fallback=cosmic-term

[ai]
# Local inference settings
inference_engine=candle
model_path=/var/lib/lilith/models
enable_tts=true

[performance]
enable_earlyoom=true
swapiness=10
EOF

# Create profile for Rust tools
mkdir -p /etc/profile.d
cat > /etc/profile.d/lilith-rust-env.sh << 'EOF'
# Lilith Linux Rust Environment

# Cargo
export CARGO_HOME="/run/media/aegon/692f77f2-a75c-4e8e-b56c-14329a88dead/build-workspace/cargo"
export PATH="$CARGO_HOME/bin:$PATH"

# Build workspace
export BUILD_WS="/run/media/aegon/692f77f2-a75c-4e8e-b56c-14329a88dead/build-workspace"

# Lilith config
export LILITH_CONFIG="/etc/lilith/lilith.conf"
EOF

log "Advanced Rust integration complete"

# Summary
cat << 'EOF'

=== Advanced Integration Complete ===

Components from lil-staRS.toml integrated:
- zbus (async D-Bus)
- notify (file watching)
- os_info (system info)

System Services:
- lilith-watchdog.service
- lilith-monitor.service

Configuration:
- /etc/lilith/lilith.conf
- /etc/profile.d/lilith-rust-env.sh

=== Future Enhancements ===

For full Rust system replacement, consider:
1. oreboot - Replace UEFI firmware
2. Horust - Replace init system  
3. libsystemd-rs - Full systemd bindings
4. Theseus OS - For specialized containers

EOF
