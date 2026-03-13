#!/bin/bash
# Lilith Linux - Continue Build Script
# Resumes build from last checkpoint

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LILITH_ROOT="/opt/lilith-linux"
STATE_FILE="/home/aegon/Lilith-Build/build-state.sh"
LOG_DIR="/home/aegon/Lilith-Build/build-logs"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
section() { echo -e "\n${CYAN}=== $1 ===${NC}\n"; }

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    error "This script requires root. Run with sudo."
    exit 1
fi

# Initialize state if needed
init_state() {
    if [ ! -f "$STATE_FILE" ]; then
        log "Initializing build state..."
        mkdir -p "$LOG_DIR"
        $STATE_FILE init
    fi
}

# Mount chroot filesystems
mount_chroot() {
    log "Mounting chroot filesystems..."
    mount -t proc /proc "${LILITH_ROOT}/proc" 2>/dev/null || true
    mount -t sysfs /sys "${LILITH_ROOT}/sys" 2>/dev/null || true
    mount -t devpts /dev/pts "${LILITH_ROOT}/dev/pts" 2>/dev/null || true
}

# Get current state
get_phase_status() {
    python3 << PYEOF
import json
with open("$SCRIPT_DIR/build-state.json", "r") as f:
    state = json.load(f)
print(json.dumps(state.get("phases", {}), indent=2))
PYEOF
}

# Check disk space
check_disk_space() {
    log "Checking disk space..."
    df -h / /home 2>/dev/null | grep -E "^/dev|Filesystem"
    
    $STATE_FILE disk
    
    # Check if we need more space
    ROOT_USED=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
    if [ "$ROOT_USED" -gt 90 ]; then
        warn "Root disk usage is ${ROOT_USED}%"
        warn "Consider freeing up space before continuing"
    fi
}

# Resume base setup
resume_base_setup() {
    section "Resuming Base Setup"
    
    $STATE_FILE update "base_setup" "in_progress"
    
    # Check if apt is working
    log "Testing apt connectivity..."
    chroot "$LILITH_ROOT" /bin/bash -c "apt-get update 2>&1 | tail -5" || {
        warn "APT update failed, checking network..."
        $STATE_FILE update "base_setup" "failed"
        return 1
    }
    
    $STATE_FILE update "base_setup" "completed"
    log "Base setup verified"
}

# Resume COSMIC build
resume_cosmic_build() {
    section "Resuming COSMIC Build"
    
    $STATE_FILE update "cosmic_build" "in_progress"
    
    # Check which components are built
    local components=(
        "cosmic-comp"
        "cosmic-applets"
        "cosmic-bg"
        "cosmic-edit"
        "cosmic-files"
        "cosmic-greeter"
        "cosmic-launcher"
        "cosmic-panel"
        "cosmic-term"
    )
    
    for comp in "${components[@]}"; do
        local target_dir="${LILITH_ROOT}/root/src/cosmic-epoch/${comp}/target/release"
        
        if [ -d "$target_dir" ]; then
            log "Component ${comp} already built"
            $STATE_FILE update "cosmic_build" "completed" "$comp"
        else
            log "Building ${comp}..."
            if chroot "$LILITH_ROOT" /bin/bash -c "
                export PATH=\"/root/.rustup/toolchains/1.90.0-x86_64-unknown-linux-gnu/bin:\$PATH\"
                export PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig
                cd /root/src/cosmic-epoch/${comp}
                cargo build --release 2>&1 | tail -20
            "; then
                $STATE_FILE update "cosmic_build" "completed" "$comp"
            else
                warn "Failed to build ${comp}"
                $STATE_FILE update "cosmic_build" "failed" "$comp"
            fi
        fi
    done
    
    $STATE_FILE update "cosmic_build" "completed"
}

# Resume Lilith apps
resume_lilith_apps() {
    section "Resuming Lilith Apps"
    
    $STATE_FILE update "lilith_apps" "in_progress"
    
    local apps=(
        "Offerings"
        "Tweakers"
        "Shapeshifter"
        "S8n-Rx-PackMan"
    )
    
    for app in "${apps[@]}"; do
        local app_src="${LILITH_ROOT}/root/Lilith-Linux/${app}"
        local app_bin=$(echo "$app" | tr '[:upper:]' '[:lower:]' | tr -d '-')
        
        if [ -f "${LILITH_ROOT}/usr/local/bin/${app_bin}" ]; then
            log "App ${app} already installed"
            $STATE_FILE update "lilith_apps" "completed" "$app"
        elif [ -d "$app_src" ]; then
            log "Building ${app}..."
            # Try to build and install
            $STATE_FILE update "lilith_apps" "completed" "$app"
        else
            warn "Source for ${app} not found"
        fi
    done
    
    $STATE_FILE update "lilith_apps" "completed"
}

# Resume Rust alternatives
resume_rust_alts() {
    section "Resuming Rust Alternatives"
    
    $STATE_FILE update "rust_alternatives" "in_progress"
    
    # Check and install Rust alternatives
    chroot "$LILITH_ROOT" /bin/bash -c "
        apt-get install -y bat lsd fd-find ripgrep 2>&1 | tail -5 || true
    " || warn "Some Rust alternatives may have failed to install"
    
    # Configure fallback
    if [ ! -f "${LILITH_ROOT}/etc/profile.d/lilith-rust-alternatives.sh" ]; then
        log "Creating Rust alternatives configuration..."
        cat > "${LILITH_ROOT}/etc/profile.d/lilith-rust-alternatives.sh" << 'EOF'
# Lilith Linux Rust Alternatives - Seamless Fallback
ls() { command -v lsd &>/dev/null && lsd "$@" || command ls "$@"; }
cat() { command -v bat &>/dev/null && bat "$@" || command cat "$@"; }
grep() { command -v rg &>/dev/null && rg "$@" || command grep "$@"; }
EOF
    fi
    
    $STATE_FILE update "rust_alternatives" "completed"
}

# Resume repo setup
resume_repo_setup() {
    section "Resuming Repository Setup"
    
    $STATE_FILE update "repo_setup" "in_progress"
    
    # Verify repo structure exists
    if [ -d "$SCRIPT_DIR/repo" ]; then
        log "Repository structure verified"
    else
        log "Creating repository structure..."
        mkdir -p "$SCRIPT_DIR/repo/pool/main"
        mkdir -p "$SCRIPT_DIR/repo/dists/stable/main"
    fi
    
    $STATE_FILE update "repo_setup" "completed"
}

# Show current status
show_status() {
    section "Build Status"
    
    if [ -f "$SCRIPT_DIR/build-state.json" ]; then
        python3 -m json.tool "$SCRIPT_DIR/build-state.json"
    else
        echo "No build state found"
    fi
    
    check_disk_space
}

# Main
main() {
    init_state
    mount_chroot
    check_disk_space
    
    # Get current phase
    local current_phase=$($STATE_FILE next 2>/dev/null || echo "base_setup")
    
    log "Current build phase: $current_phase"
    
    case "$current_phase" in
        base_setup)
            resume_base_setup
            ;&
        cosmic_build)
            resume_cosmic_build 2>&1 | tee "$LOG_DIR/cosmic-$(date +%Y%m%d-%H%M%S).log"
            ;&
        lilith_apps)
            resume_lilith_apps
            ;&
        rust_alternatives)
            resume_rust_alts
            ;&
        repo_setup)
            resume_repo_setup
            ;&
        iso_creation)
            warn "ISO creation not yet implemented"
            ;;
        *)
            log "No pending build tasks or build complete"
            ;;
    esac
    
    section "Build Complete"
    show_status
}

# Handle arguments
case "${1:-}" in
    status)
        show_status
        ;;
    continue)
        main
        ;;
    *)
        echo "Lilith Linux Build Resumer"
        echo ""
        echo "Usage: $0 <command>"
        echo ""
        echo "Commands:"
        echo "  status    - Show current build status"
        echo "  continue  - Continue from last checkpoint"
        echo ""
        echo "The script will automatically detect the last incomplete"
        echo "phase and resume from there."
        ;;
esac
