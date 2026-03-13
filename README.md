# Lilith Linux Build System

Build scripts for creating Lilith Linux - an Ubuntu-based distro with COSMIC desktop.

## Quick Start

### On Pop!OS/COSMIC (Recommended)

1. Copy this directory to your Pop!OS system
2. Run:
```bash
cd ~/Lilith-Build
sudo ./build_lilith.sh --all
```

## Available Scripts

| Script | Purpose |
|--------|---------|
| `build_lilith.sh` | Build all Lilith Linux apps on existing Pop!OS |
| `setup_lilith_distro.sh` | Configure existing chroot for Lilith Linux |
| `build_distro.sh` | Create new Ubuntu base + configure (full rebuild) |
| `create_iso.sh` | Create ISO using penguins-eggs |

## Distro Configuration

- **Base**: Ubuntu 24.04 (Noble/"Resolute Raccoon")
- **Desktop**: COSMIC Desktop Environment
- **Apps**: Lilith-Linux custom applications
- **Packages**: From `lil-pax.toml` (Flatpak/Snap/GitHub)

## What's Included

### Desktop Environment
- COSMIC (from Pop!OS)
- LightDM display manager
- Custom Lilith Plymouth theme

### Custom Applications
- **Offerings** - Package Manager GUI
- **Tweakers** - System Optimizer
- **Shapeshifter** - Profile Manager
- **S8n** - CLI Package Manager
- **Lilith-TTS** - Text-to-Speech

### Packages from lil-pax.toml
- Flatpak apps (from Flathub)
- Snap apps
- GitHub applications

## Usage Examples

### Option 1: Build on existing Pop!OS

```bash
# Full install
sudo ./build_lilith.sh --all

# Just build apps
./build_lilith.sh --offerings
```

### Option 2: Configure existing chroot

```bash
# Configure existing /opt/lilith-linux
sudo ./setup_lilith_distro.sh /opt/lilith-linux
```

### Option 3: Create from scratch

```bash
# Full distro build (warning: slow)
sudo ./build_distro.sh
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
├── build_lilith.sh        # Main build script for apps
├── setup_lilith_distro.sh # Configure chroot for distro
├── build_distro.sh        # Create from scratch
├── create_iso.sh          # Create ISO
├── README.md
├── Lilith-Linux/          # Symlink to source
└── Offerings/             # Symlink to package manager
```

## Files

- `/home/aegon/Lilith-Linux/` - Custom Lilith Linux apps
- `/home/aegon/Lilith-Linux/lil-pax.toml` - Additional packages list
- `/home/aegon/Offerings/` - Package manager GUI
- `/opt/lilith-linux/` - Bootstrap Ubuntu base (~16GB)

## lil-pax.toml Packages

The distro includes packages from `lil-pax.toml`:
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
- CoreUtils
- Spacedrive
- Nushell
- Bat
- Xcp
- Dua-CLI
- Fd
- Skim
- LSD
- Procs
- Shred-Rust
- Navi
- Atuin
- Rustic
- Linuxbrew
- HomePage
- Webi
