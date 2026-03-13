#!/bin/bash
# Lilith Linux Repository Sync Script
# Syncs packages from upstream sources defined in lilith-debrep.toml

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOML_FILE="${SCRIPT_DIR}/lilith-debrep.toml"
REPO_ROOT="${SCRIPT_DIR}/repo"
LOG_DIR="${SCRIPT_DIR}/build-logs"
STATE_FILE="${SCRIPT_DIR}/build-state.json"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Create log directory
mkdir -p "$LOG_DIR"

# Get current timestamp
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG_FILE="${LOG_DIR}/sync-${TIMESTAMP}.log"

# Function to parse TOML (basic parsing)
get_toml_value() {
    local key="$1"
    grep -A1 "^${key} " "$TOML_FILE" | grep -oP '(?<== ).*' | tr -d ' "'
}

# Sync Ubuntu packages
sync_ubuntu() {
    log "Syncing Ubuntu packages..."
    
    # Update apt cache
    apt-get update -qq 2>&1 | tee -a "$LOG_FILE"
    
    # Download packages
    local packages=(
        "bat lsd fd-find ripgrep"
        "build-essential cargo rustc"
        "libwayland-dev libseat-dev libxkbcommon-dev"
        "libgtk-3-dev libfontconfig1-dev"
    )
    
    for pkg in "${packages[@]}"; do
        apt-get install -y --download-only $pkg 2>&1 | tee -a "$LOG_FILE" || true
    done
    
    log "Ubuntu packages synced"
}

# Sync from GitHub
sync_github() {
    local repo="$1"
    local output_dir="$2"
    
    log "Syncing GitHub repo: $repo"
    
    if [ -d "$output_dir/.git" ]; then
        cd "$output_dir"
        git fetch origin 2>&1 | tee -a "$LOG_FILE"
        git pull origin main 2>&1 | tee -a "$LOG_FILE"
        cd - > /dev/null
    else
        git clone "https://github.com/${repo}.git" "$output_dir" 2>&1 | tee -a "$LOG_FILE"
    fi
}

# Sync COSMIC from Pop!OS
sync_cosmic() {
    log "Syncing COSMIC from Pop!OS..."
    
    local cosmic_dir="/home/aegon/Lilith-Linux/cosmic-epoch"
    
    if [ -d "$cosmic_dir/.git" ]; then
        cd "$cosmic_dir"
        git fetch origin 2>&1 | tee -a "$LOG_FILE"
        
        # Check for updates
        LOCAL=$(git rev-parse HEAD)
        ORIGIN=$(git rev-parse origin/alpha)
        
        if [ "$LOCAL" != "$ORIGIN" ]; then
            log "COSMIC has updates, pulling..."
            git pull origin alpha 2>&1 | tee -a "$LOG_FILE"
            git submodule update --init --recursive 2>&1 | tee -a "$LOG_FILE"
        else
            log "COSMIC already up to date"
        fi
        
        cd - > /dev/null
    else
        warn "COSMIC source not found at $cosmic_dir"
    fi
}

# Sync Lilith apps
sync_lilith_apps() {
    log "Syncing Lilith apps from GitHub..."
    
    local apps=(
        "BlancoBAM/Offerings:/home/aegon/Offerings"
        "BlancoBAM/Lilith-Linux:/home/aegon/Lilith-Linux"
        "BlancoBAM/S8n-Rx-PackMan:/home/aegon/Lilith-Linux/S8n-Rx-PackMan"
        "BlancoBAM/Lilim:/home/aegon/Lilith-Linux/Lilim"
        "BlancoBAM/Lilith-TTS:/home/aegon/Lilith-Linux/Lilith-TTS"
    )
    
    for app in "${apps[@]}"; do
        IFS=':' read -r repo dir <<< "$app"
        
        if [ -d "$dir/.git" ]; then
            log "Updating $repo..."
            cd "$dir"
            git fetch origin 2>&1 | tee -a "$LOG_FILE"
            git pull origin main 2>&1 | tee -a "$LOG_FILE" || true
            cd - > /dev/null
        else
            warn "Source not found: $dir"
        fi
    done
}

# Update Flatpak apps
sync_flatpak() {
    log "Syncing Flatpak remotes..."
    
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>&1 | tee -a "$LOG_FILE" || true
    flatpak update --noninteractive 2>&1 | tee -a "$LOG_FILE" || true
}

# Update Rust crates
sync_rust_crates() {
    log "Checking Rust crate updates..."
    
    # Check for cargo audit
    if command -v cargo-audit &> /dev/null; then
        cargo audit 2>&1 | tee -a "$LOG_FILE" || true
    fi
    
    # Check for cargo outdated
    if command -v cargo-outdated &> /dev/null; then
        cargo outdated --exit-code 0 2>&1 | tee -a "$LOG_FILE" || true
    fi
}

# Update build state
update_state() {
    local last_sync=$(date -Iseconds)
    
    if [ -f "$STATE_FILE" ]; then
        python3 << PYEOF
import json
from datetime import datetime

with open("$STATE_FILE", "r") as f:
    state = json.load(f)

state["last_sync"] = "$last_sync"
state["sync_log"] = "$LOG_FILE"

with open("$STATE_FILE", "w") as f:
    json.dump(state, f, indent=2)
PYEOF
    fi
}

# Full sync
full_sync() {
    log "Starting full repository sync..."
    echo "=== Lilith Linux Repository Sync ===" > "$LOG_FILE"
    echo "Started: $(date)" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    
    sync_ubuntu
    sync_cosmic
    sync_lilith_apps
    sync_flatpak
    sync_rust_crates
    
    echo "" >> "$LOG_FILE"
    echo "Completed: $(date)" >> "$LOG_FILE"
    
    update_state
    
    log "Sync complete. Log: $LOG_FILE"
}

# Show sync status
sync_status() {
    log "Repository Sync Status"
    echo ""
    
    echo "Last sync: $(python3 -c "import json; s=json.load(open('$STATE_FILE')); print(s.get('last_sync', 'Never'))" 2>/dev/null || echo "Never")"
    echo ""
    
    echo "Upstream sources:"
    echo "  - Ubuntu Noble: $(apt-get update 2>&1 | grep -c 'Hit\|Get' ) packages"
    echo "  - Pop!OS COSMIC: $([ -d /home/aegon/Lilith-Linux/cosmic-epoch/.git ] && cd /home/aegon/Lilith-Linux/cosmic-epoch && git log -1 --oneline 2>/dev/null || echo "Not cloned")"
    echo "  - Flathub: $(flatpak list 2>/dev/null | wc -l) apps installed"
}

# Main
case "${1:-}" in
    sync)
        full_sync
        ;;
    status)
        sync_status
        ;;
    cosmic)
        sync_cosmic
        ;;
    apps)
        sync_lilith_apps
        ;;
    ubuntu)
        sync_ubuntu
        ;;
    flatpak)
        sync_flatpak
        ;;
    crates)
        sync_rust_crates
        ;;
    *)
        echo "Lilith Linux Repository Sync"
        echo ""
        echo "Usage: $0 <command>"
        echo ""
        echo "Commands:"
        echo "  sync    - Full sync from all upstream sources"
        echo "  status  - Show sync status"
        echo "  cosmic  - Sync COSMIC from Pop!OS"
        echo "  apps    - Sync Lilith apps from GitHub"
        echo "  ubuntu  - Sync Ubuntu packages"
        echo "  flatpak - Sync Flatpak apps"
        echo "  crates  - Check Rust crate updates"
        ;;
esac
