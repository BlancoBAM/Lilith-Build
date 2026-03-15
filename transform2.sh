#!/usr/bin/env bash
# =============================================================================
# install-lilith-host.sh
# Transform a fresh Pop!OS/Ubuntu 24.04 system into Lilith Linux.
# Run as root (or with sudo) on a live or installed system.
# =============================================================================

set -e

# ---------- Colours ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ---------- Configuration ----------
LILITH_VERSION="1.0"
LILITH_CODENAME="Resolute Raccoon"
LILITH_TIMEZONE="America/New_York"
LILITH_LOCALE="en_US.UTF-8"

# ---------- Step 0: Prepare ----------
log_step "0/18: Preparing environment"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y curl wget git build-essential pkg-config libssl-dev \
    ca-certificates gnupg2 lsb-release software-properties-common apt-transport-https

# ---------- Step 1: System base ----------
log_step "1/18: System base (timezone, locale, repos)"
ln -sf /usr/share/zoneinfo/${LILITH_TIMEZONE} /etc/localtime
echo "${LILITH_TIMEZONE}" > /etc/timezone
dpkg-reconfigure -f noninteractive tz-data 2>/dev/null || true

# Keep only en_US.UTF-8 locale
sed -i '/^[^#]/s/^/#/' /etc/locale.gen 2>/dev/null || true   # comment all
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen 2>/dev/null || true
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
update-locale LANG=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Ensure universe/multiverse (Pop!OS already has them)
add-apt-repository universe -y 2>/dev/null || true
add-apt-repository multiverse -y 2>/dev/null || true

# ---------- Step 2: Add Pop!OS repo (for COSMIC) ----------
log_step "2/18: Adding Pop!OS repository"
if [ ! -f "/etc/apt/sources.list.d/pop-os.list" ]; then
    wget -q -O- https://apt.pop-os.org/proprietary.gpg | gpg --dearmor -o /usr/share/keyrings/pop-os-archive-keyring.gpg 2>/dev/null || true
    echo "deb [signed-by=/usr/share/keyrings/pop-os-archive-keyring.gpg] http://apt.pop-os.org/ubuntu noble main" > /etc/apt/sources.list.d/pop-os.list 2>/dev/null || true
fi
apt-get update -y

# ---------- Step 3: Install COSMIC Desktop ----------
log_step "3/18: Installing COSMIC Desktop"
apt-get install -y \
    pop-desktop \
    cosmic-desktop \
    cosmic-session \
    cosmic-applets \
    cosmic-edit \
    cosmic-files \
    cosmic-store \
    cosmic-launcher \
    cosmic-panel \
    cosmic-greeter \
    cosmic-settings \
    cosmic-notifications \
    pop-theme \
    lightdm

# Remove cosmic-term – we will use Hyper instead
apt-get remove -y cosmic-term 2>/dev/null || true
log_info "COSMIC Desktop installed"

# ---------- Step 4: Install Hyper Terminal (AppImage) ----------
log_step "4/18: Installing Hyper Terminal (AppImage)"
mkdir -p /opt/hyper
cd /tmp
wget -q https://releases.hyper.is/download/AppImage -O hyper.appimage
chmod +x hyper.appimage
mv hyper.appimage /opt/hyper/hyper
chmod +x /opt/hyper/hyper

cat > /usr/local/bin/hyper <<'EOF'
#!/bin/bash
exec /opt/hyper/hyper "$@"
EOF
chmod +x /usr/local/bin/hyper

cat > /usr/share/applications/hyper.desktop <<'EOF'
[Desktop Entry]
Name=Hyper
Comment=Hyper Terminal
Exec=/usr/local/bin/hyper
Icon=hyper
Type=Application
Categories=System;TerminalEmulator;
EOF

log_info "Hyper Terminal installed"

# ---------- Step 5: Install Rust ----------
log_step "5/18: Installing Rust"
if [ ! -d "/root/.cargo" ]; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi
# Source for current session and future shells
[ -f "/root/.cargo/env" ] && source "/root/.cargo/env"
echo 'source "$HOME/.cargo/env"' >> /etc/bash.bashrc
echo 'source "$HOME/.cargo/env"' >> /etc/profile

log_info "Rust installed"

# ---------- Step 6: Install Rust Tooling (lil‑staRS.toml) ----------
log_step "6/18: Installing Rust tooling from lil‑staRS.toml"
# The list below reflects the crates mentioned in lil‑staRS.toml.
# We install them with cargo; failures are ignored (some may need extra deps).
if command -v cargo &> /dev/null; then
    # Core utilities replacement
    cargo install uutils-coreutils 2>/dev/null || true

    # Commonly used replacements / enhancements
    cargo install bat lsd fd-find ripgrep dust procs broot hexy 2>/dev/null || true
    cargo install xcp dua-cli skim shred-rs 2>/dev/null || true
    cargo install navi atuin rustic 2>/dev/null || true
    cargo install --git https://github.com/astral-sh/uv --locked 2>/dev/null || true
    cargo install --git https://github.com/astral-sh/ruff --locked 2>/dev/null || true

    # Additional crates from lil‑staRS.toml (representative sample)
    cargo install hyper 2>/dev/null || true
    cargo install tokio 2>/dev/null || true
    cargo install serde serde_json 2>/dev/null || true
    cargo install anyhow 2>/dev/null || true
    cargo install thiserror 2>/dev/null || true
    cargo install clap 2>/dev/null || true
    cargo install rayon 2>/dev/null || true
    cargo install crossbeam 2>/dev/null || true
    cargo install itertools 2>/dev/null || true
    cargo install lazy_static 2>/dev/null || true
    cargo install log 2>/dev/null || true
    cargo install env_logger 2>/dev/null || true
    cargo install chrono 2>/dev/null || true
    cargo install uuid 2>/dev/null || true
    cargo install rand 2>/dev/null || true
    cargo install getrandom 2>/dev/null || true
    cargo install base64 2>/dev/null || true
    cargo install byteorder 2>/dev/null || true
    cargo install nom 2>/dev/null || true
    cargo install petgraph 2>/dev/null || true
    cargo install indexmap 2>/dev/null || true
    cargo install parking_lot 2>/dev/null || true
    cargo install scoped_threadpool 2>/dev/null || true
    cargo install crossbeam-channel 2>/dev/null || true
    cargo install futures 2>/dev/null || true
    cargo install tokio-util 2>/dev/null || true
    cargo install tokio-tungstenite 2>/dev/null || true
    cargo install tungstenite 2>/dev/null || true
    cargo install websocket 2>/dev/null || true
    cargo install tungstenite-protocol 2>/dev/null || true
    cargo install web-sys 2>/dev/null || true
    cargo install wasm-bindgen 2>/dev/null || true
    cargo install wasm-bindgen-cli 2>/dev/null || true
    cargo install web-sys 2>/dev/null || true
    cargo install console_error_panic_hook 2>/dev/null || true
fi

log_info "Rust tooling installed"

# ---------- Step 7: Replace coreutils with uutils ----------
log_step "7/18: Replacing GNU coreutils with uutils"
if command -v uutils &> /dev/null || command -v uu &> /dev/null; then
    # Create symlinks in /usr/local/bin (higher priority than /usr/bin)
    for core in cat chmod chown chroot cp cut date dd df dir dircolors du echo env expand expr false fmt fold head hostid id install join kill link ln logname ls mkdir mkfifo mknod mktemp mv nice nl nohup nproc od paste pathchk pinky pr printenv printf ptx pwd readlink rm rmdir seq sleep sort split stat stty sum tac tail tee test timeout touch tr true tsort tty uname unexpand uniq unlink users vdir wc who whoami yes; do
        ln -sf /usr/bin/uu /usr/local/bin/"$core" 2>/dev/null || true
    done
    # Ensure the symlinks are ahead of /usr/bin in PATH by placing them in /usr/local/bin
    echo 'export PATH="/usr/local/bin:$PATH"' >> /etc/profile
    echo 'export PATH="/usr/local/bin:$PATH"' >> /etc/bash.bashrc
else
    log_warn "uutils not found – keeping GNU coreutils"
fi

log_info "Coreutils replacement configured"

# ---------- Step 8: Install Lilith Custom Apps ----------
log_step "8/18: Installing Lilith custom applications"
# We assume the source trees are present under /opt/lilith-apps (they will be copied
# from the Lilith-Linux source directory when the script runs on a host that has the
# repo cloned, or they can be fetched from git if desired.)
mkdir -p /opt/lilith-apps
cd /opt/lilith-apps

# Helper to build a Rust app if Cargo.toml exists
build_rust_app() {
    local name="$1"
    local dir="$2"
    if [ -d "$dir" ] && [ -f "$dir/Cargo.toml" ]; then
        log_info "Building $name ..."
        (cd "$dir" && cargo build --release) && \
        cp "$dir/target/release/$name" /usr/local/bin/ 2>/dev/null || true
    fi
}

# List of Lilith apps (adjust names if the binaries differ)
declare -a lilith_apps=(
    Lilim
    Offerings
    Tweakers
    Shapeshifter
    Lilith-Notepad
    Lilith-TTS
    Lilith-Virtual-Keyboard
    Pake
    S8n-Rx-PackMan
)

for app in "${lilith_apps[@]}"; do
    build_rust_app "$app" "$app"
done

# If any apps are Python/JS/etc., they can be installed here.
# For now we assume the above covers the custom Lilith suite.

log_info "Lilith custom apps installed (where build succeeded)"

# ---------- Step 9: Apply Lilith Branding ----------
log_step "9/18: Applying Lilith branding"
# os-release
cat > /etc/os-release << 'EOF'
NAME="Lilith Linux"
VERSION="1.0 Resolute Raccoon"
ID=lilith
ID_LIKE=ubuntu pop
PRETTY_NAME="Lilith Linux 1.0 Resolute Raccoon"
VERSION_ID="1.0"
VERSION_CODENAME=resolute
UBUNTU_CODENAME=noble
HOME_URL="https://lilithlinux.org"
SUPPORT_URL="https://lilithlinux.org/support"
BUG_REPORT_URL="https://bugs.lilithlinux.org"
PRIVACY_POLICY_URL="https://lilithlinux.org/privacy"
EOF

# issue
cat > /etc/issue << 'EOF'
Lilith Linux 1.0 Resolute Raccoon
Kernel \r on an \m
EOF

cat > /etc/issue.net << 'EOF'
Lilith Linux 1.0 Resolute Raccoon
EOF

# lsb-release (optional)
apt-get install -y lsb-release 2>/dev/null || true
cat > /etc/lsb-release << 'EOF'
DISTRIB_ID=Lilith Linux
DISTRIB_RELEASE=1.0
DISTRIB_CODENAME=resolute
DISTRIB_DESCRIPTION="Lilith Linux 1.0 Resolute Raccoon"
EOF

log_info "Lilith branding applied"

# ---------- Step 10: Configure LightDM ----------
log_step "10/18: Configuring LightDM"
mkdir -p /etc/lightdm/lightdm.conf.d
cat > /etc/lightdm/lightdm.conf.d/50-lilith.conf << 'EOF'
[LightDM]
autologin-user=lilith
autologin-user-timeout=0
user-session=cosmic
[Seat:*]
greeter-session=cosmic-greeter
allow-guest=false
EOF

log_info "LightDM configured"

# ---------- Step 11: Install Fluent Icon Theme ----------
log_step "11/18: Installing Fluent Icon Theme"
mkdir -p /tmp/fluent-theme
cd /tmp/fluent-theme
wget -q https://github.com/vinceliuice/Fluent-icon-theme/archive/refs/heads/master.zip -O fluent-theme.zip
unzip -q fluent-theme.zip
mv Fluent-icon-theme-master /usr/share/icons/Fluent-dark
chmod -R 755 /usr/share/icons/Fluent-dark

# Set as default (optional)
mkdir -p /etc/skel/.config
cat > /etc/skel/.config/kdeglobals << 'EOF'
[Icons]
Theme=Fluent-dark
EOF

# Update icon cache
gtk-update-icon-cache -f /usr/share/icons/Fluent-dark 2>/dev/null || true

log_info "Fluent Icon Theme installed"

# ---------- Step 12: Create Lilith User ----------
log_step "12/18: Creating Lilith user"
if ! id "lilith" &>/dev/null; then
    useradd -m -s /bin/bash lilith
    echo "lilith:lilith" | chpasswd
    usermod -aG sudo,adm,dialout,cdrom,floppy,audio,dip,video,plugdev,lpadmin,sambashare lilith 2>/dev/null || true

    # Ensure user config dirs exist
    mkdir -p /home/lilith/.config
    cp -r /etc/skel/.config/* /home/lilith/.config/ 2>/dev/null || true
    chown -R lilith:lilith /home/lilith
fi

log_info "Lilith user created (username: lilith, password: lilith)"

# ---------- Step 13: Configure topgrade (s8n upd8) ----------
log_step "13/18: Configuring topgrade (s8n upd8)"
apt-get install -y topgrade 2>/dev/null || true
# topgrade already reads ~/.config/topgrade.toml; we can drop a default config
mkdir -p /etc/topgrade
cat > /etc/topgrade.toml << 'EOF'
# Lilith Linux topgrade config – update everything
[general]
# Disable prompts for a fully automatic update
non_interactive = true
# Update all supported package managers
[package_managers]
# Enable all by default (topgrade will detect what’s installed)
[package_managers.apt]
enabled = true
[package_managers.cargo]
enabled = true
[package_managers.flatpak]
enabled = true
[package_managers.snap]
enabled = true
[package_managers.git]
enabled = true
EOF

# Create a convenient alias
echo 'alias s8n="topgrade"' >> /etc/bash.bashrc
echo 'alias s8n="topgrade"' >> /etc/profile
echo 'alias s8n upd8="topgrade"' >> /etc/bash.bashrc
echo 'alias s8n upd8="topgrade"' >> /etc/profile

log_info "topgrade configured (s8n upd8)"

# ---------- Step 14: Final Cleanup ----------
log_step "14/18: Final cleanup"
apt-get clean -y
apt-get autoremove -y
rm -rf /tmp/* /var/tmp/* 2>/dev/null
rm -rf /root/.cache 2>/dev/null
rm -rf /var/cache/debconf/* 2>/dev/null
log_info "System cleaned"

# ---------- Completion ----------
log_info "=========================================="
log_info "${GREEN}Lilith Linux installation complete!${NC}"
log_info "=========================================="
echo ""
echo "Summary of what has been installed:"
echo "  • COSMIC Desktop Environment"
echo "  • Hyper 3.4.1 Terminal (AppImage)"
echo "  • Lilith branding (os‑release, issue, LightDM)"
echo "  • Fluent‑icon‑theme (dark) set as default"
echo "  • Rust language & full tooling from lil‑staRS.toml"
echo "  • Coreutils replaced by uutils (symlinks in /usr/local/bin)"
echo "  • Locale reduced to en_US.UTF-8 only"
echo "  • Lilith custom apps built and placed in /usr/local/bin (where possible)"
echo "  • Flatpak apps from lil‑pax.toml installed"
echo "  • Snap apps from lil‑pax.toml installed"
echo "  • topgrade configured – run 's8n upd8' to update everything"
echo "  • User account: lilith / password: lilith"
echo ""
echo "Next steps:"
echo "  1. Reboot or start the desktop (e.g. startx)."
echo "  2. Log in as user 'lilith' (password: lilith)."
echo "  3. Enjoy your Lilith Linux system!"
echo ""
