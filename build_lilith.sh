#!/bin/bash
# Lilith Linux Build Script for Pop!OS / COSMIC Desktop
# Run this on Pop!OS with COSMIC desktop to build all Lilith Linux apps
#
# Usage: ./build_lilith.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LILITH_SRC="${SCRIPT_DIR}/Lilith-Linux"
OFFERINGS_SRC="${SCRIPT_DIR}/Offerings"
INSTALL_DIR="/usr/local/bin"
LOG_DIR="${HOME}/lilith-build-logs"

# Create log directory
mkdir -p "${LOG_DIR}"

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

section() {
    echo -e "\n${BLUE}==========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}==========================================${NC}\n"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    IS_ROOT=true
else
    IS_ROOT=false
fi

###############################################################################
# System Dependencies
###############################################################################
install_system_deps() {
    section "Installing System Dependencies"

    local deps=(
        # Build tools
        build-essential
        cmake
        pkg-config
        git
        curl
        wget
        
        # COSMIC/Graphics deps
        libwayland-dev
        libxkbcommon-dev
        libinput-dev
        libgstreamer1.0-dev
        libgstreamer-plugins-base1.0-dev
        libssl-dev
        dbus
        udev
        libglvnd-dev
        libgbm-dev
        libpixman-1-dev
        
        # Audio
        libpipewire-0.3-dev
        libpulse-dev
        
        # Font rendering
        libfontconfig-dev
        libfreetype-dev
        
        # Flatpak
        flatpak
        libflatpak-dev
        
        # Plymouth
        plymouth
        plymouth-theme-libinput
        
        # TTS deps
        libclang-dev
        espeak-ng
        
        # Other
        libpam0g-dev
        libexpat1-dev
        libsystemd-dev
    )

    if [ "$IS_ROOT" = true ]; then
        apt update
        apt install -y "${deps[@]}"
    else
        echo "Running without root - please install manually:"
        echo "sudo apt install ${deps[*]}"
    fi
}

###############################################################################
# Rust Installation
###############################################################################
install_rust() {
    section "Installing Rust"

    if command -v rustc &> /dev/null; then
        log "Rust already installed: $(rustc --version)"
    else
        log "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi

    # Ensure cargo is in path
    if [ -f "$HOME/.cargo/env" ]; then
        source "$HOME/.cargo/env"
    fi

    # Install just
    if ! command -v just &> /dev/null; then
        log "Installing just..."
        cargo install just
    else
        log "just already installed: $(just --version)"
    fi

    # Install Cargo components for Slint
    log "Ensuring Rust toolchain is up to date..."
    rustup update stable
}

###############################################################################
# Lilith-TTS Dependencies
###############################################################################
install_tts_deps() {
    section "Installing TTS Dependencies"

    local tts_deps=(
        espeak-ng
        libclang-dev
    )

    if [ "$IS_ROOT" = true ]; then
        apt install -y "${tts_deps[@]}"
    else
        echo "sudo apt install ${tts_deps[*]}"
    fi
}

###############################################################################
# Build Offerings (Package Manager)
###############################################################################
build_offerings() {
    section "Building Offerings"

    if [ ! -d "${OFFERINGS_SRC}" ]; then
        error "Offerings source not found at ${OFFERINGS_SRC}"
        return 1
    fi

    cd "${OFFERINGS_SRC}"

    log "Building Offerings..."
    cargo build --release 2>&1 | tee "${LOG_DIR}/offerings-build.log"

    if [ -f "target/release/offerings" ]; then
        if [ "$IS_ROOT" = true ]; then
            cp target/release/offerings "${INSTALL_DIR}/"
            chmod +x "${INSTALL_DIR}/offerings"
        else
            cp target/release/offerings "${HOME}/.local/bin/"
            chmod +x "${HOME}/.local/bin/offerings"
        fi
        log "Offerings installed successfully!"
    else
        error "Offerings build failed. Check ${LOG_DIR}/offerings-build.log"
    fi
}

###############################################################################
# Build Tweakers
###############################################################################
build_tweakers() {
    section "Building Tweakers"

    if [ ! -d "${LILITH_SRC}/Tweakers" ]; then
        error "Tweakers source not found"
        return 1
    fi

    cd "${LILITH_SRC}/Tweakers"

    log "Building Tweakers..."
    cargo build --release 2>&1 | tee "${LOG_DIR}/tweakers-build.log"

    if [ -f "target/release/tweakers" ]; then
        if [ "$IS_ROOT" = true ]; then
            cp target/release/tweakers "${INSTALL_DIR}/"
            chmod +x "${INSTALL_DIR}/tweakers"
        else
            cp target/release/tweakers "${HOME}/.local/bin/"
            chmod +x "${HOME}/.local/bin/tweakers"
        fi
        log "Tweakers installed successfully!"
    else
        warn "Tweakers build failed. Check ${LOG_DIR}/tweakers-build.log"
    fi
}

###############################################################################
# Build Shapeshifter
###############################################################################
build_shapeshifter() {
    section "Building Shapeshifter"

    if [ ! -d "${LILITH_SRC}/Shapeshifter" ]; then
        error "Shapeshifter source not found"
        return 1
    fi

    cd "${LILITH_SRC}/Shapeshifter"

    log "Building Shapeshifter..."
    cargo build --release 2>&1 | tee "${LOG_DIR}/shapeshifter-build.log"

    if [ -f "target/release/shapeshifter" ]; then
        if [ "$IS_ROOT" = true ]; then
            cp target/release/shapeshifter "${INSTALL_DIR}/"
            chmod +x "${INSTALL_DIR}/shapeshifter"
        else
            cp target/release/shapeshifter "${HOME}/.local/bin/"
            chmod +x "${HOME}/.local/bin/shapeshifter"
        fi
        log "Shapeshifter installed successfully!"
    else
        warn "Shapeshifter build failed. Check ${LOG_DIR}/shapeshifter-build.log"
    fi
}

###############################################################################
# Build S8n-Rx-PackMan
###############################################################################
build_s8n() {
    section "Building S8n-Rx-PackMan"

    if [ ! -d "${LILITH_SRC}/S8n-Rx-PackMan" ]; then
        error "S8n-Rx-PackMan source not found"
        return 1
    fi

    cd "${LILITH_SRC}/S8n-Rx-PackMan"

    log "Building S8n..."
    cargo build --release 2>&1 | tee "${LOG_DIR}/s8n-build.log"

    if [ -f "target/release/s8n" ]; then
        if [ "$IS_ROOT" = true ]; then
            cp target/release/s8n "${INSTALL_DIR}/"
            chmod +x "${INSTALL_DIR}/s8n"
        else
            cp target/release/s8n "${HOME}/.local/bin/"
            chmod +x "${HOME}/.local/bin/s8n"
        fi
        log "S8n installed successfully!"
    else
        warn "S8n build failed. Check ${LOG_DIR}/s8n-build.log"
    fi
}

###############################################################################
# Build Lilith-TTS
###############################################################################
build_lilith_tts() {
    section "Building Lilith-TTS"

    if [ ! -d "${LILITH_SRC}/Lilith-TTS" ]; then
        error "Lilith-TTS source not found"
        return 1
    fi

    cd "${LILITH_SRC}/Lilith-TTS"

    log "Building Lilith-TTS (this may take a while due to llama.cpp)..."
    cargo build --release 2>&1 | tee "${LOG_DIR}/lilith-tts-build.log"

    if [ -f "target/release/lilith-tts" ]; then
        if [ "$IS_ROOT" = true ]; then
            cp target/release/lilith-tts "${INSTALL_DIR}/"
            chmod +x "${INSTALL_DIR}/lilith-tts"
        else
            cp target/release/lilith-tts "${HOME}/.local/bin/"
            chmod +x "${HOME}/.local/bin/lilith-tts"
        fi
        log "Lilith-TTS installed successfully!"
    else
        warn "Lilith-TTS build failed. Check ${LOG_DIR}/lilith-tts-build.log"
    fi
}

###############################################################################
# Setup Boot Splash
###############################################################################
setup_splash() {
    section "Setting up Lilith Boot Splash"

    if [ ! -d "${LILITH_SRC}/Lilith-Splash" ]; then
        error "Lilith-Splash not found"
        return 1
    fi

    cd "${LILITH_SRC}/Lilith-Splash"

    if [ "$IS_ROOT" = true ]; then
        chmod +x install_splash.sh
        ./install_splash.sh
    else
        warn "Run as root to install boot splash: sudo ${0}"
    fi
}

###############################################################################
# Setup Plymouth Theme
###############################################################################
setup_plymouth() {
    section "Setting up Plymouth Theme"

    if [ "$IS_ROOT" = true ]; then
        mkdir -p /usr/share/plymouth/themes/lilith
        
        cat > /usr/share/plymouth/themes/lilith/lilith.plymouth << 'EOF'
[Plymouth Theme]
Name=Lilith Linux
ModuleName=script
EOF

        cat > /usr/share/plymouth/themes/lilith/lilith.script << 'EOF'
wallpaper = Image("lilith-splash.png");
wallpaper = wallpaper.Scale(Window.GetWidth(), Window.GetHeight());
wallpaper = wallpaper.BlendOntoRoot(0, 0);
EOF

        plymouth-set-default-theme lilith
        log "Plymouth theme configured!"
    else
        warn "Run as root to install Plymouth theme: sudo ${0}"
    fi
}

###############################################################################
# Setup Calamares Branding
###############################################################################
setup_calamares() {
    section "Setting up Calamares Branding"

    if [ "$IS_ROOT" = true ]; then
        mkdir -p /usr/share/calamares/brands/lilith
        
        cat > /usr/share/calamares/brands/lilith/branding.desc << 'EOF'
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

        log "Calamares branding configured!"
    else
        warn "Run as root to install Calamares branding: sudo ${0}"
    fi
}

###############################################################################
# Install penguins-eggs
###############################################################################
install_penguins_eggs() {
    section "Installing penguins-eggs"

    if command -v eggs &> /dev/null; then
        log "penguins-eggs already installed: $(eggs --version)"
        return 0
    fi

    if [ "$IS_ROOT" = true ]; then
        # Add repository and install
        wget -q https://packages.penguins-eggs.net/releases/gpg/key -O- | apt-key add -
        echo "deb https://packages.penguins-eggs.net/releases/$(lsb_release -si|tr[:upper:] [:lower:])/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/penguins-eggs.list
        apt update
        apt install -y penguins-eggs
    else
        log "penguins-eggs needs root. Install manually or run with sudo."
    fi
}

###############################################################################
# Main Menu
###############################################################################
show_menu() {
    section "Lilith Linux Build System"
    
    echo "Available options:"
    echo ""
    echo "  1. Install all system dependencies"
    echo "  2. Install Rust and build tools"
    echo "  3. Build ALL applications"
    echo "  4. Build only Offerings (package manager)"
    echo "  5. Build Tweakers"
    echo "  6. Build Shapeshifter"
    echo "  7. Build S8n (CLI package manager)"
    echo "  8. Build Lilith-TTS"
    echo "  9. Setup boot splash (requires root)"
    echo " 10. Setup Plymouth theme (requires root)"
    echo " 11. Setup Calamares branding (requires root)"
    echo " 12. Install penguins-eggs (requires root)"
    echo " 13. FULL INSTALL (everything, requires root)"
    echo ""
    echo "  0. Exit"
    echo ""
    read -p "Select option: " choice
}

###############################################################################
# Full Install
###############################################################################
full_install() {
    if [ "$IS_ROOT" = false ]; then
        error "Full install requires root. Run: sudo ${0}"
        return 1
    fi

    section "Running Full Installation"

    install_system_deps
    install_rust
    install_tts_deps
    
    build_offerings
    build_tweakers
    build_shapeshifter
    build_s8n
    build_lilith_tts
    
    setup_splash
    setup_plymouth
    setup_calamares
    
    install_penguins_eggs

    section "Installation Complete!"
    
    echo "Installed applications:"
    [ -f "${INSTALL_DIR}/offerings" ] && echo "  ✓ Offerings (Package Manager)"
    [ -f "${INSTALL_DIR}/tweakers" ] && echo "  ✓ Tweakers (System Optimizer)"
    [ -f "${INSTALL_DIR}/shapeshifter" ] && echo "  ✓ Shapeshifter (Profile Manager)"
    [ -f "${INSTALL_DIR}/s8n" ] && echo "  ✓ S8n (CLI Package Manager)"
    [ -f "${INSTALL_DIR}/lilith-tts" ] && echo "  ✓ Lilith-TTS (Text-to-Speech)"
    echo ""
    echo "To create your Lilith Linux ISO with penguins-eggs:"
    echo "  sudo eggs produce"
    echo ""
}

###############################################################################
# Main
###############################################################################
main() {
    if [ $# -eq 0 ]; then
        # No arguments - show menu
        show_menu
        return 0
    fi

    # Parse arguments
    case "$1" in
        --deps|-d)
            install_system_deps
            ;;
        --rust|-r)
            install_rust
            ;;
        --all|-a)
            if [ "$IS_ROOT" = true ]; then
                full_install
            else
                error "Full install requires root: sudo ${0} --all"
            fi
            ;;
        --offerings)
            build_offerings
            ;;
        --tweakers)
            build_tweakers
            ;;
        --shapeshifter)
            build_shapeshifter
            ;;
        --s8n)
            build_s8n
            ;;
        --tts)
            build_lilith_tts
            ;;
        --splash)
            setup_splash
            ;;
        --plymouth)
            setup_plymouth
            ;;
        --calamares)
            setup_calamares
            ;;
        --eggs)
            install_penguins_eggs
            ;;
        --help|-h)
            echo "Lilith Linux Build Script"
            echo ""
            echo "Usage: ${0} [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --deps, -d       Install system dependencies"
            echo "  --rust, -r       Install Rust and build tools"
            echo "  --all, -a        Full installation (requires root)"
            echo "  --offerings      Build Offerings package manager"
            echo "  --tweakers       Build Tweakers"
            echo "  --shapeshifter   Build Shapeshifter"
            echo "  --s8n            Build S8n CLI package manager"
            echo "  --tts            Build Lilith-TTS"
            echo "  --splash         Setup boot splash (root)"
            echo "  --plymouth       Setup Plymouth theme (root)"
            echo "  --calamares      Setup Calamares branding (root)"
            echo "  --eggs           Install penguins-eggs (root)"
            echo "  --help, -h       Show this help"
            ;;
        *)
            error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
}

# Run main with all arguments
main "$@"
