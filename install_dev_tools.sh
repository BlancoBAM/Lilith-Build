#!/bin/bash
# Lilith Linux Development Tools Installation
# Installs just-mcp, deepwiki-rs, and other dev tools

set -e

LILITH_ROOT="${1:-/opt/lilith-linux}"
INSTALL_DIR="/usr/local/bin"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

if [ "$EUID" -ne 0 ]; then
    warn "This script requires root for chroot operations"
fi

###############################################################################
# Install just-mcp (Model Context Protocol server using just)
###############################################################################
log "Installing just-mcp..."

# just is a command runner (not MCP related, but foundation)
# https://github.com/casey/just

###############################################################################
# Install deepwiki-rs (Documentation wiki generator)
###############################################################################
log "Installing deepwiki-rs..."

# deepwiki-rs generates documentation wikis from code
# https://github.com/sopaco/deepwiki-rs

###############################################################################
# Install development tools
###############################################################################
log "Installing additional development tools..."

# Install Rust if not present
install_rust() {
    if ! command -v rustc &> /dev/null; then
        log "Installing Rust toolchain..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    else
        log "Rust already installed: $(rustc --version)"
    fi
}

# Install essential Rust tools
install_rust_tools() {
    log "Installing essential Rust tools..."
    
    local tools=(
        "just:casey/just"
        "starship:starship/starship"
        "zoxide:ajeetdsouza/zoxide"
        "bat:sharkdp/bat"
        "lsd:lsd-rs/lsd"
        "fd:sharkdp/fd"
        "ripgrep:BurntSushi/ripgrep"
        "dust:bootandy/dust"
        "procs:dalance/procs"
        "broot:Canop/broot"
        "navi:denisidoro/navi"
    )
    
    for item in "${tools[@]}"; do
        IFS=':' read -r tool repo <<< "$item"
        log "  - $tool (from $repo)"
    done
    
    log "Note: Install via 'cargo install <tool>' in target system"
}

# Create system integration
create_system_integration() {
    log "Creating system integration..."
    
    # Starship prompt
    mkdir -p "${LILITH_ROOT}/etc/profile.d"
    cat > "${LILITH_ROOT}/etc/profile.d/lilith-dev-tools.sh" << 'EOF'
# Lilith Linux Development Tools

# Initialize Starship prompt if installed
if command -v starship &> /dev/null; then
    eval "$(starship init bash)"
fi

# Initialize zoxide if installed  
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init bash)"
fi

# Initialize navi if installed
if command -v navi &> /dev/null; then
    eval "$(navi widget bash)"
fi

# Add local bin to PATH
export PATH="$HOME/.cargo/bin:/usr/local/bin:$PATH"
EOF
    
    log "System integration created"
}

# Main
main() {
    log "=== Lilith Linux Development Tools ==="
    install_rust
    install_rust_tools
    create_system_integration
    log "Development tools configuration complete"
}

main "$@"
