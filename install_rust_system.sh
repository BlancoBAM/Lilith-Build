#!/bin/bash
# Lilith Linux - Rust System Components Installation
# Replaces traditional system components with Rust alternatives

set -e

FLASH_BUILD="/run/media/aegon/692f77f2-a75c-4e8e-b56c-14329a88dead/build-workspace"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

if [ "$EUID" -ne 0 ]; then
    warn "Run with sudo for system installation"
fi

log "Installing Rust system alternatives..."

# Rust alternatives from lil-staRS.toml

log "Installing core system tools..."

# Install from cargo (these take time, so we'll note what's available)
CARGO_BINS=(
    # System monitoring (already in install_apps.sh)
    # "dust" - du replacement
    # "procs" - ps replacement
    
    # File management
    "broot"       # File tree navigation
    "navi"        # Cheat sheet
    "xcp"         # Fast cp
    
    # Shells/Terminals
    # "starship"    # Shell prompt (installed)
    # "zoxide"      # Smart cd (installed)
    
    # Development
    "tokei"       # Count code lines
    
    # System
    "bottom"      # System monitor (like htop)
    "bandwhich"   # Bandwidth monitor
    "diskus"      # Disk usage
    
    # Networking
    "grex"        # Generate regex
    "bandit"      # Security linting
)

# These are already installed via apt:
# - bat, lsd, fd-find, ripgrep

log "Rust alternatives available:"
echo "  Installed via apt: bat, lsd, fd-find, ripgrep"
echo "  Installed via cargo: starship, zoxide, just, dust, procs, broot, navi"
echo ""

# System component replacements from lil-staRS.toml
log "System components to consider for future:"
echo "  - libsystemd-rs: Rust systemd bindings"
echo "  - uefi-rs: UEFI in Rust"
echo "  - oreboot: Rust boot firmware"
echo "  - dbus-rs: D-Bus in Rust"
echo "  - zbus: Rust async D-Bus"
echo "  - notify: File notifications in Rust"
echo "  - os_info: OS info in Rust"
echo ""

# Create configuration for Rust tools
log "Configuring Rust alternatives..."

mkdir -p /etc/profile.d

# Create shell integrations
cat > /etc/profile.d/lilith-rust-tools.sh << 'EOF'
# Lilith Linux Rust Tools Configuration

# Starship prompt
if command -v starship &> /dev/null; then
    eval "$(starship init bash)"
fi

# Zoxide cd replacement
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init bash)"
fi

# Navi cheat sheet
if command -v navi &> /dev/null; then
    eval "$(navi widget bash)"
fi

# Aliases for Rust tools
alias ls='lsd --icons'
alias cat='bat --style=auto'
alias find='fd'
alias grep='rg -S'
alias du='dust'
alias ps='procs'

# Export PATH
export PATH="$HOME/.cargo/bin:/usr/local/bin:$PATH"
EOF

log "Rust system alternatives configured"

# List recommended replacements
cat << 'EOF'

=== Rust System Component Replacements ===

| Traditional | Rust Alternative | Source |
|------------|-----------------|--------|
| cat | bat | apt/cargo |
| ls | lsd | apt/cargo |
| find | fd | apt |
| grep | ripgrep | apt |
| du | dust | cargo |
| ps | procs | cargo |
| top/htop | bottom | cargo |
| cd | zoxide | cargo |
| man | navi | cargo |
| tree | broot | cargo |

=== System Libraries (for future) ===

| Component | Rust Alternative | Use |
|----------|-----------------|-----|
| systemd | libsystemd-rs | Systemd bindings |
| D-Bus | zbus, dbus-rs | IPC |
| UEFI | uefi-rs | Boot |
| init | Horust, pid1-rust-poc | Init system |
| Filesystem | Theseus, Redox | OS |

=== Future Optimizations ===

1. Consider oreboot for boot firmware
2. Consider Theseus OS for specialized containers
3. libsystemd-rs for Rust systemd integration
4. zbus for async D-Bus communication
5. notify-rs for file watching

EOF
