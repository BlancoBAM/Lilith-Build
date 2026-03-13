# Lilith Linux Build System

Build scripts for creating Lilith Linux - an Ubuntu-based distro with COSMIC desktop and Rust alternatives.

## Quick Start

### On Ubuntu 24.04 (Recommended)

1. Copy this directory to your Ubuntu system
2. Run:
```bash
cd ~/Lilith-Build
sudo ./setup_lilith_distro.sh
```

## Available Scripts

| Script | Purpose |
|--------|---------|
| `build_lilith.sh` | Build all Lilith Linux apps on existing Pop!OS |
| `setup_lilith_distro.sh` | Configure existing chroot for Lilith Linux |
| `build_distro.sh` | Create new Ubuntu base + configure (full rebuild) |
| `create_iso.sh` | Create ISO using penguins-eggs |
| `continue_build.sh` | Resume build from last checkpoint |
| `sync-repo.sh` | Sync packages from upstream sources |
| `install_rust_alternatives.sh` | Install Rust alternatives with GNU fallback |
| `install_dev_tools.sh` | Install development tools |
| `repo/build-repo.sh` | Build Lilith Linux package repository |
| `build-state.sh` | Track build state and progress |

## Upstream Integration

Lilith Linux automatically syncs with upstream sources:

### Sync Commands

```bash
# Full sync from all sources
sudo ./sync-repo.sh sync

# Show sync status
sudo ./sync-repo.sh status

# Sync specific sources
sudo ./sync-repo.sh cosmic    # Pop!OS COSMIC
sudo ./sync-repo.sh apps       # Lilith apps
sudo ./sync-repo.sh ubuntu    # Ubuntu packages
sudo ./sync-repo.sh flatpak   # Flatpak apps
sudo ./sync-repo.sh crates    # Rust crates
```

### Upstream Sources

| Source | URL | Sync |
|--------|-----|------|
| Ubuntu Noble | archive.ubuntu.com/ubuntu | Daily |
| Pop!OS COSMIC | github.com/pop-os/cosmic-epoch | Weekly |
| Lilith Apps | github.com/BlancoBAM/* | Weekly |
| Flathub | flathub.org | Daily |
| Crates.io | crates.io | Weekly |

See `lilith-debrep.toml` for full configuration.

## Distro Configuration

- **Base**: Ubuntu 24.04 (Noble/"Resolute Raccoon")
- **Desktop**: COSMIC Desktop Environment
- **Apps**: Lilith-Linux custom applications
- **Rust Alternatives**: uutils with GNU fallback
- **Packages**: From `lil-pax.toml` (Flatpak/Snap/GitHub)

## What's Included

### Desktop Environment
- COSMIC (from Pop!OS)
- LightDM display manager
- Custom Lilith Plymouth theme

### Rust Alternatives (with GNU fallback)
- **lsd** → ls (with fallback)
- **bat** → cat (with fallback)
- **fd** → find (with fallback)
- **ripgrep** → grep (with fallback)
- **dust** → du (with fallback)
- **procs** → ps (with fallback)

### Custom Applications
- **Offerings** - Package Manager GUI
- **Tweakers** - System Optimizer
- **Shapeshifter** - Profile Manager
- **S8n** - CLI Package Manager
- **Lilim** - AI Assistant (Candle-based inference)

### Packages from lil-pax.toml
- Flatpak apps (from Flathub)
- Snap apps
- GitHub applications
- Rust alternatives

## Usage Examples

### Option 1: Configure existing chroot

```bash
# Configure existing /opt/lilith-linux
sudo ./setup_lilith_distro.sh /opt/lilith-linux
```

### Option 2: Create from scratch

```bash
# Full distro build (warning: slow)
sudo ./build_distro.sh
```

### Option 3: Resume build after interruption

```bash
# Check status
sudo ./continue_build.sh status

# Continue from last checkpoint
sudo ./continue_build.sh continue
```

### Option 4: Sync from upstream

```bash
# Sync all sources
sudo ./sync-repo.sh sync
```

### Option 5: Install Rust alternatives

```bash
# Install Rust alternatives with fallback
sudo ./install_rust_alternatives.sh

# Install development tools
sudo ./install_dev_tools.sh
```

### Option 6: Build package repository

```bash
# Initialize repo structure
./repo/build-repo.sh init

# Add packages
./repo/build-repo.sh add /path/to/package.deb main

# Build indexes
./repo/build-repo.sh build
./repo/build-repo.sh release
```

## Creating the ISO

After building, create the ISO:

```bash
# Using penguins-eggs
sudo chroot /opt/lilith-linux
eggs produce --kiosk --hostname lilith

# Or use the ISO creation script
sudo ./create_iso.sh
```

## Directory Structure

```
Lilith-Build/
├── build_lilith.sh           # Main build script for apps
├── setup_lilith_distro.sh   # Configure chroot for distro
├── build_distro.sh          # Create from scratch
├── create_iso.sh            # Create ISO
├── continue_build.sh        # Resume from checkpoint
├── sync-repo.sh             # Sync from upstream
├── build-state.sh           # State tracking utility
├── install_rust_alternatives.sh  # Rust alternatives
├── install_dev_tools.sh     # Development tools
├── lilith-debrep.toml      # Repository specification
├── repo/
│   ├── build-repo.sh        # Package repository builder
│   └── packages.list        # Package list
├── build-logs/              # Build logs
├── build-state.json         # Current build state
├── BUILD_PROGRESS.md        # Build progress documentation
├── RUST_ALTERNATIVES.md      # Rust alternatives docs
└── README.md
```

## Files

- `/home/aegon/Lilith-Linux/` - Custom Lilith Linux apps
- `/home/aegon/Lilith-Linux/lil-pax.toml` - Additional packages list
- `/home/aegon/Lilith-Linux/lil-staRS.toml` - Rust alternatives and components
- `/home/aegon/Offerings/` - Package manager GUI
- `/opt/lilith-linux/` - Bootstrap Ubuntu base (~16GB)

## lil-pax.toml Packages

The distro includes packages from `lil-pax.toml`:

### Core Applications
- Espanso GUI
- Lotti
- Brief
- ColorMyDesktop
- PlumeImpactor
- WonderPen
- Touche
- Tintero
- Saldo
- SystemMonitor
- TheMegenerator
- Journal
- DigiKam
- Sitra
- ProtonPass
- HellFire
- WinApps

### Rust System Tools
- uutils/coreutils
- spacedrive
- nushell
- bat
- xcp
- dua-cli
- fd
- skim
- lsd
- procs
- shred-rust
- navi
- atuin
- rustic

### Boot & Firmware (Reference)
- oreboot
- uefi-rs
- r-efi

### Additional Rust Tools
- hexyl
- uv
- ruff
- ripgrep
- tar-rs
- dearchiver
- publish-crates

## lil-staRS.toml Components

Components used for building and optimizing the distro:

### OS & Boot
- Theseus OS
- Redox OS
- Kerla (Linux-compatible Rust OS)
- rCore
- Arceos
- oreboot, uefi-rs

### Desktop (COSMIC)
- libcosmic
- cosmic-utils
- Dioxus
- Floem

### AI/ML (for Lilim)
- Crane (LLM inference)
- Candle (ML framework)
- vllm.rs
- candle-vllm

### System Tools
- uutils (util-linux, procps, hostname, etc.)
- bootandy/dust
- lsd-rs/lsd
- sharkdp/bat, fd, ripgrep
- broot
- procs
- navi
- starship
- zoxide

## Hardware Support

Optimized for Intel i3-1115G4 (2 cores, 4 threads, 8GB RAM):
- COSMIC desktop with Intel GPU support
- Candle-based local inference (no GPU required)
- Rust alternatives for performance
- Memory-efficient system components

## Localization

- **Default Language**: English (en_US.UTF-8)
- **Timezone**: US Eastern (America/New_York)
- **Keyboard**: US Layout

To change:
```bash
sudo dpkg-reconfigure tzdata
sudo dpkg-reconfigure keyboard-configuration
```
