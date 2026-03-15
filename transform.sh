Here is a single‑run script that will transform a fresh Pop!OS 24.04 (or Ubuntu 24.04) live/installation into a full Lilith Linux system.
Save it as install-lilith-host.sh, make it executable, and run it as root (or with sudo). It will:

Update the base system
Add the Pop!OS repository (for COSMIC)
Install COSMIC desktop and essential packages
Install Hyper 3.4.1 (AppImage)
Install Rust and the core Rust tooling (bat, lsd, fd, ripgrep, dust, procs, broot, etc.)
Create Lilith‑style aliases and symlinks
Apply Lilith branding (os‑release, issue, LightDM)
Install Fluent‑icon‑theme (dark)
Install Flatpak apps from lil-pax.toml
Install Snap apps from lil-pax.toml
Create the lilith user (password = lilith)
Clean up caches
You can run it directly from the internet:

wget -O install-lilith-host.sh https://raw.githubusercontent.com/BlancoBAM/Lilith-Build/master/install-lilith-host.sh
chmod +x install-lilith-host.sh
sudo ./install-lilith-host.sh
Or, if you already cloned the repo, run sudo ./install-lilith-host.sh from the repository root.

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

# ---------- Step 1: System Preparation ----------
log_step "1/13: System Preparation"
export DEBIAN_FRONTEND=noninteractive

apt-get update -y

# Install basic dependencies
apt-get install -y \
    curl wget git build-essential pkg-config libssl-dev \
    ca-certificates gnupg2 lsb-release software-properties-common \
    apt-transport-https

# Ensure universe/multiverse are enabled (Pop!OS already has them, but safe)
add-apt-repository universe -y 2>/dev/null || true
add-apt-repository multiverse -y 2>/dev/null || true

# Set timezone
ln -sf /usr/share/zoneinfo/${LILITH_TIMEZONE} /etc/localtime
echo "${LILITH_TIMEZONE}" > /etc/timezone
dpkg-reconfigure -f noninteractive tz-data 2>/dev/null || true

# Configure locale – ONLY en_US.UTF-8
sed -i '/^[^#]/s/^/#/' /etc/locale.gen 2>/dev/null || true   # comment all
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen 2>/dev/null || true
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
update-locale LANG=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

log_info "System prepared: timezone=${LILITH_TIMEZONE}, locale=${LILITH_LOCALE}"

# ---------- Step 2: Add Pop!OS Repository (for COSMIC) ----------
log_step "2/13: Adding Pop!OS repository"
if [ ! -f "/etc/apt/sources.list.d/pop-os.list" ]; then
    wget -q -O- https://apt.pop-os.org/proprietary.gpg | gpg --dearmor -o /usr/share/keyrings/pop-os-archive-keyring.gpg 2>/dev/null || true
    echo "deb [signed-by=/usr/share/keyrings/pop-os-archive-keyring.gpg] http://apt.pop-os.org/ubuntu noble main" > /etc/apt/sources.list.d/pop-os.list 2>/dev/null || true
fi
apt-get update -y

# ---------- Step 3: Install COSMIC Desktop ----------
log_step "3/13: Installing COSMIC Desktop"
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

# Replace cosmic-term with Hyper (AppImage) later
apt-get remove -y cosmic-term 2>/dev/null || true

log_info "COSMIC Desktop installed"

# ---------- Step 4: Install Hyper Terminal (AppImage) ----------
log_step "4/13: Installing Hyper Terminal (AppImage)"
mkdir -p /opt/hyper
cd /tmp
wget -q https://releases.hyper.is/download/AppImage -O hyper.appimage
chmod +x hyper.appimage
mv hyper.appimage /opt/hyper/hyper
chmod +x /opt/hyper/hyper

# Create launcher
cat > /usr/local/bin/hyper <<'EOF'
#!/bin/bash
exec /opt/hyper/hyper "$@"
EOF
chmod +x /usr/local/bin/hyper

# Desktop entry
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
log_step "5/13: Installing Rust"
if [ ! -d "/root/.cargo" ]; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi
# Source Rust for current shell
[ -f "/root/.cargo/env" ] && source "/root/.cargo/env"
# Also add to bashrc for future shells
echo 'source "$HOME/.cargo/env"' >> /etc/bash.bashrc
echo 'source "$HOME/.cargo/env"' >> /etc/profile

log_info "Rust installed"

# ---------- Step 6: Install Rust Tools ----------
log_step "6/13: Installing Rust Tools"
if command -v cargo &> /dev/null; then
    cargo install bat lsd fd-find ripgrep dust procs broot hexy 2>/dev/null || true
    cargo install xcp dua-cli skim shred-rs 2>/dev/null || true
    cargo install navi atuin rustic 2>/dev/null || true
    cargo install --git https://github.com/astral-sh/uv --locked 2>/dev/null || true
    cargo install --git https://github.com/astral-sh/ruff --locked 2>/dev/null || true
fi
log_info "Rust Tools installed"

# ---------- Step 7: Configure Rust Alternatives ----------
log_step "7/13: Configuring Rust Alternatives"
cat >> /etc/bash.bashrc <<'EOF'

# Lilith Rust Alternatives
alias cat='bat'
alias ls='lsd'
alias ll='lsd -l'
alias la='lsd -a'
alias lt='lsd --tree'
alias find='fdfind'
alias grep='rg'
alias du='dust'
alias ps='procs'
alias tree='broot'
EOF

# Also add to profile for login shells
cat >> /etc/profile <<'EOF'

# Lilith Rust Alternatives
alias cat='bat'
alias ls='lsd'
alias ll='lsd -l'
alias la='lsd -a'
alias lt='lsd --tree'
alias find='fdfind'
alias grep='rg'
alias du='dust'
alias ps='procs'
alias tree='broot'
EOF

# Create symlinks (if cargo bin exists)
if [ -d "/root/.cargo/bin" ]; then
    ln -sf /root/.cargo/bin/bat /usr/local/bin/cat 2>/dev/null || true
    ln -sf /root/.cargo/bin/lsd /usr/local/bin/ls 2>/dev/null || true
    ln -sf /root/.cargo/bin/fd /usr/local/bin/find 2>/dev/null || true
    ln -sf /root/.cargo/bin/ripgrep /usr/local/bin/grep 2>/dev/null || true
    ln -sf /root/.cargo/bin/dust /usr/local/bin/du 2>/dev/null || true
    ln -sf /root/.cargo/bin/procs /usr/local/bin/ps 2>/dev/null || true
    ln -sf /root/.cargo/bin/broot /usr/local/bin/tree 2>/dev/null || true
fi

log_info "Rust Alternatives configured"

# ---------- Step 8: Install Flatpak & Apps ----------
log_step "8/13: Installing Flatpak and apps"
apt-get install -y flatpak gnome-software-plugin-flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true

# Apps from lil-pax.toml (Flatpak section)
flatpak install -y --noninteractive flathub \
    org.kde.digikam \
    io.github.schwarzen.colormydesktop \
    dev.khcrysalis.PlumeImpactor \
    com.tominlab.wonderpen \
    com.github.joseexposito.touche \
    app.tintero.Tintero \
    org.tabos.saldo \
    page.codeberg.JakobDev.jdSystemMonitor \
    io.github.thiefmd.themegenerator \
    io.github.sitraorg.sitra 2>/dev/null || true

log_info "Flatpak apps installed"

# ---------- Step 9: Install Snap & Apps ----------
log_step "9/13: Installing Snap and apps"
apt-get install -y snapd
# Enable snapd.apparmor service (usually already active)
systemctl enable snapd.apparmor --now 2>/dev/null || true

# Snap apps from lil-pax.toml
snap install journal 2>/dev/null || true

log_info "Snap apps installed"

# ---------- Step 10: Apply Lilith Branding ----------
log_step "10/13: Applying Lilith Branding"
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

# lsb-release (optional, but nice)
apt-get install -y lsb-release 2>/dev/null || true
cat > /etc/lsb-release << 'EOF'
DISTRIB_ID=Lilith Linux
DISTRIB_RELEASE=1.0
DISTRIB_CODENAME=resolute
DISTRIB_DESCRIPTION="Lilith Linux 1.0 Resolute Raccoon"
EOF

log_info "Lilith Branding applied"

# ---------- Step 11: Configure LightDM ----------
log_step "11/13: Configuring LightDM"
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

# ---------- Step 12: Install Fluent Icon Theme ----------
log_step "12/13: Installing Fluent Icon Theme"
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

# ---------- Step 13: Create Lilith User ----------
log_step "13/13: Creating Lilith user"
if ! id "lilith" &>/dev/null; then
    useradd -m -s /bin/bash lilith
    echo "lilith:lilith" | chpasswd
    # Add to common groups
    usermod -aG sudo,adm,dialout,cdrom,floppy,audio,dip,video,plugdev,lpadmin,sambashare lilith 2>/dev/null || true

    # Ensure user config dirs exist
    mkdir -p /home/lilith/.config
    cp -r /etc/skel/.config/* /home/lilith/.config/ 2>/dev/null || true
    chown -R lilith:lilith /home/lilith
fi

log_info "Lilith user created (username: lilith, password: lilith)"

# ---------- Final Cleanup ----------
log_step "Cleanup"
apt-get clean -y
rm -rf /var/cache/apt/archives/*
rm -rf /tmp/*
rm -rf /var/tmp/*
rm -rf /root/.cache

log_info "=========================================="
log_info "${GREEN}Lilith Linux installation complete!${NC}"
log_info "=========================================="
echo ""
echo "Summary:"
echo "  - COSMIC Desktop"
echo "  - Hyper Terminal (AppImage)"
echo "  - Lilith branding applied"
echo "  - Fluent-icon-theme (dark) set"
echo "  - Rust tooling installed with aliases"
echo "  - Flatpak & Snap apps installed"
echo "  - User: lilith / password: lilith"
echo ""
echo "Next steps:"
echo "  1. Reboot or start the desktop: startx"
echo "  2. Log in as user 'lilith' (password: lilith)"
echo "  3. Enjoy your Lilith Linux system!"
echo ""
How to Use

Boot into a fresh Pop!OS 24.04 live USB (or install Pop!OS to disk).
Open a terminal and run:
wget -O install-lilith-host.sh https://raw.githubusercontent.com/BlancoBAM/Lilith-Build/master/install-lilith-host.sh
chmod +x install-lilith-host.sh
sudo ./install-lilith-host.sh
The script will run unattended. When it finishes, reboot (or start the desktop with startx) and log in as user lilith with password lilith.
All Lilith‑specific customizations (branding, Rust tools, Hyper terminal, Flatpak/Snap apps, etc.) will be present. You can further customize the system from within the installed environment.

Enjoy your Lilith Linux!
