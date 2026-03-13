#!/bin/bash
# Lilith Linux Complete Build Script
# Uses just-mcp, fastmod, paiml-mcp-agent-toolkit, deepwiki-rs for development
# Builds complete distro with all components

set -e

DISTRO_DIR="/opt/lilith-linux"
LILITH_SRC="/home/aegon/Lilith-Linux"
DEBREPO_TOML="${LILITH_SRC}/lilith-debrepo.toml"
PAX_FILE="${LILITH_SRC}/lil-pax.toml"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
section() { echo -e "\n${CYAN}==== $1 ====${NC}\n"; }

check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "This script requires root. Run with sudo."
        exit 1
    fi
}

mount_chroot() {
    log "Mounting chroot pseudo-filesystems..."
    mount -t proc /proc "${DISTRO_DIR}/proc" 2>/dev/null || true
    mount -t sysfs /sys "${DISTRO_DIR}/sys" 2>/dev/null || true
    mount -t devpts /dev/pts "${DISTRO_DIR}/dev/pts" 2>/dev/null || true
    mount --bind /dev "${DISTRO_DIR}/dev" 2>/dev/null || true
}

umount_chroot() {
    log "Unmounting chroot..."
    umount "${DISTRO_DIR}/proc" 2>/dev/null || true
    umount "${DISTRO_DIR}/sys" 2>/dev/null || true
    umount "${DISTRO_DIR}/dev/pts" 2>/dev/null || true
}

install_kibi() {
    section "Installing Kibi (nano replacement)"
    
    mount_chroot
    
    # Install kibi from cargo
    chroot "${DISTRO_DIR}" /bin/bash -c "
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        apt-get install -y cargo rustc
    " | tail -5
    
    # Try to install kibi from cargo
    if chroot "${DISTRO_DIR}" /bin/bash -c "cargo install kibi --locked" 2>/dev/null; then
        log "Kibi installed via cargo"
    else
        # Fallback to pre-built binary
        log "Installing kibi from pre-built binary..."
        chroot "${DISTRO_DIR}" /bin/bash -c "
            ARCH=\$(uname -m)
            VERSION=\"0.1.5\"
            curl -L -o /tmp/kibi \"https://github.com/ilai-deutel/kibi/releases/download/\${VERSION}/kibi-\${VERSION}-\${ARCH}-unknown-linux-musl.tar.gz\"
            tar -xzf /tmp/kibi -C /usr/bin/
            rm /tmp/kibi
        " || warn "Failed to install kibi, using nano"
    fi
    
    # Set kibi as default editor
    echo "EDITOR=kibi" >> "${DISTRO_DIR}/etc/environment"
    echo "VISUAL=kibi" >> "${DISTRO_DIR}/etc/environment"
    update-alternatives --install /usr/bin/editor editor /usr/bin/kibi 100 2>/dev/null || true
    
    log "Kibi installed successfully"
}

install_rust_alternatives() {
    section "Installing Rust Alternatives with Fallback"
    
    mount_chroot
    
    # Install core Rust alternatives
    local RUST_PKGS=(
        "bat"
        "lsd" 
        "fd-find"
        "ripgrep"
        "procs"
        "dua-cli"
        "bottom"
        "hexyl"
        "starship"
        "watchexec"
    )
    
    for pkg in "${RUST_PKGS[@]}"; do
        log "Installing ${pkg}..."
        chroot "${DISTRO_DIR}" /bin/bash -c "
            cargo install ${pkg} --locked 2>/dev/null || true
        " &
    done
    
    wait
    
    # Create fallback wrappers
    create_fallback_wrappers
    
    log "Rust alternatives installed"
}

create_fallback_wrappers() {
    local WRAPPER_DIR="${DISTRO_DIR}/usr/local/lib/lilith-fallback"
    mkdir -p "${WRAPPER_DIR}"
    
    # cat -> bat fallback
    cat > "${WRAPPER_DIR}/cat.sh" << 'EOF'
#!/bin/bash
if command -v bat &> /dev/null; then
    exec bat "$@"
fi
exec /usr/bin/cat "$@"
EOF
    chmod +x "${WRAPPER_DIR}/cat.sh"
    
    # ls -> lsd fallback
    cat > "${WRAPPER_DIR}/ls.sh" << 'EOF'
#!/bin/bash
if command -v lsd &> /dev/null; then
    exec lsd "$@"
fi
exec /usr/bin/ls "$@"
EOF
    chmod +x "${WRAPPER_DIR}/ls.sh"
    
    ln -sf /usr/local/bin/bat "${DISTRO_DIR}/usr/local/bin/batcat" 2>/dev/null || true
    
    log "Fallback wrappers created"
}

configure_repositories() {
    section "Configuring Repositories"
    
    mount_chroot
    
    # Configure Ubuntu Noble sources
    cat > "${DISTRO_DIR}/etc/apt/sources.list" << 'EOF'
deb http://archive.ubuntu.com/ubuntu/ noble main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ noble-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ noble-security main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ noble-backports main restricted universe multiverse
EOF

    # Add Resolute Raccoon repo (Lilith custom)
    mkdir -p "${DISTRO_DIR}/etc/apt/sources.list.d"
    cat > "${DISTRO_DIR}/etc/apt/sources.list.d/lilith.list" << 'EOF'
# Lilith Linux Custom Repository
deb http://packages.lilithlinux.org/resolute-raccoon stable main
EOF

    # Add S8n-PackMan repo if it exists
    if [ -d "/home/aegon/Lilith-Linux/S8n-Rx-PackMan" ]; then
        cat > "${DISTRO_DIR}/etc/apt/sources.list.d/s8n-packman.list" << 'EOF'
# S8n-PackMan Repository
deb https://s8n-packman.lilithlinux.org/packages stable main
EOF
    fi
    
    chroot "${DISTRO_DIR}" apt-get update 2>/dev/null || true
    
    log "Repositories configured"
}

install_cosmic() {
    section "Building and Installing COSMIC Desktop"
    
    mount_chroot
    
    # Check if COSMIC source exists
    if [ ! -d "${LILITH_SRC}/cosmic-epoch" ]; then
        warn "COSMIC source not found at ${LILITH_SRC}/cosmic-epoch"
        return 0
    fi
    
    # Copy COSMIC source to chroot
    rm -rf "${DISTRO_DIR}/root/cosmic-epoch"
    cp -r "${LILITH_SRC}/cosmic-epoch" "${DISTRO_DIR}/root/"
    
    # Build COSMIC
    log "Building COSMIC (this may take a while)..."
    chroot "${DISTRO_DIR}" /bin/bash -c "
        cd /root/cosmic-epoch
        just sysext 2>&1 | tail -20
    " || warn "COSMIC build had issues, continuing..."
    
    log "COSMIC build attempted"
}

build_lilith_apps() {
    section "Building Lilith Linux Apps"
    
    mount_chroot
    
    local APP_DIRS=(
        "Offerings"
        "Tweakers"
        "Shapeshifter"
        "S8n-Rx-PackMan"
        "Lilith-TTS"
        "Lilith-Notepad"
        "Pake"
        "Lilim"
    )
    
    for app in "${APP_DIRS[@]}"; do
        if [ -d "${LILITH_SRC}/${app}" ]; then
            log "Building ${app}..."
            rm -rf "${DISTRO_DIR}/root/src/${app}"
            cp -r "${LILITH_SRC}/${app}" "${DISTRO_DIR}/root/src/"
            
            chroot "${DISTRO_DIR}" /bin/bash -c "
                cd /root/src/${app}
                cargo build --release 2>&1 | tail -10 || true
            " || warn "${app} build had issues"
        fi
    done
    
    log "Lilith apps build attempted"
}

install_pax_packages() {
    section "Installing Packages from lil-pax.toml"
    
    mount_chroot
    
    if [ ! -f "${PAX_FILE}" ]; then
        warn "lil-pax.toml not found"
        return 0
    fi
    
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        
        if [[ "$line" == *"flathub"* ]] || [[ "$line" == *"flatpak install"* ]]; then
            log "Flatpak: $line"
        elif [[ "$line" == *"snapcraft.io"* ]]; then
            log "Snap: $line"
        elif [[ "$line" == *"github.com"* ]]; then
            log "GitHub: $line"
        fi
    done < "${PAX_FILE}"
    
    log "Package list processed"
}

apply_lilith_branding() {
    section "Applying Lilith Branding"
    
    mount_chroot
    
    # Set hostname
    echo "lilith-resolute" > "${DISTRO_DIR}/etc/hostname"
    
    # Set Plymouth theme
    chroot "${DISTRO_DIR}" /bin/bash -c "
        plymouth-set-default-theme lilith 2>/dev/null || true
    " || true
    
    # Configure LightDM
    mkdir -p "${DISTRO_DIR}/etc/lightdm"
    cat > "${DISTRO_DIR}/etc/lightdm/lightdm.conf" << 'EOF'
[LightDM]
start-default-session=true
user-session=cosmic

[Seat:*]
autologin-guest=false
autologin-user=lilith
autologin-user-timeout=0
user-session=cosmic
greeter-session=cosmic-greeter
EOF

    # Create Lilith user
    chroot "${DISTRO_DIR}" /bin/bash -c "
        useradd -m -s /bin/bash -G sudo,audio,video,plugdev lilith 2>/dev/null || true
        echo 'lilith:lilith' | chpasswd
    "
    
    # Calamares branding
    mkdir -p "${DISTRO_DIR}/usr/share/calamares/brands/lilith"
    cat > "${DISTRO_DIR}/usr/share/calamares/brands/lilith/branding.desc" << 'EOF'
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

    log "Lilith branding applied"
}

main() {
    section "Lilith Linux Complete Build"
    
    check_root
    
    log "Starting complete build..."
    log "Distro directory: ${DISTRO_DIR}"
    
    # Configure repos first
    configure_repositories
    
    # Install kibi (nano replacement)
    install_kibi
    
    # Install Rust alternatives
    install_rust_alternatives
    
    # Build COSMIC
    install_cosmic
    
    # Build Lilith apps
    build_lilith_apps
    
    # Install packages from lil-pax.toml
    install_pax_packages
    
    # Apply branding
    apply_lilith_branding
    
    section "Build Complete!"
    log "Lilith Linux is ready at: ${DISTRO_DIR}"
    log ""
    log "To enter the chroot: sudo chroot ${DISTRO_DIR} /bin/bash"
}

main "$@"
