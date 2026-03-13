FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LILITH_ROOT=/opt/lilith-linux

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    rustup \
    libwayland-dev \
    libseat-dev \
    libxkbcommon-dev \
    libinput-dev \
    libdisplay-info-dev \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    libssl-dev \
    dbus \
    udev \
    libpam0g-dev \
    libpixman-1-dev \
    libglvnd-dev \
    libclang-dev \
    libexpat1-dev \
    libfontconfig-dev \
    libfreetype-dev \
    libgbm-dev \
    libpipewire-0.3-dev \
    libpulse-dev \
    libsystemd-dev \
    lld \
    mold \
    just \
    git \
    curl \
    wget \
    cmake \
    pkg-config \
    libflatpak-dev \
    flatpak \
    plymouth \
    plymouth-theme-libinput \
    debootstrap \
    arch-fix-chroot \
    squashfs-tools \
    genisoimage \
    calamares \
    && rm -rf /var/lib/apt/lists/*

# Install Rust
RUN rustup toolchain install stable
RUN rustup default stable
RUN cargo install just

# Clone Lilith Linux source
WORKDIR /root
COPY Lilith-Linux /root/Lilith-Linux

# Build Lilith Apps
RUN cd /root/Lilith-Linux/Tweakers && cargo build --release
RUN cp /root/Lilith-Linux/Tweakers/target/release/tweakers /usr/local/bin/

RUN cd /root/Lilith-Linux/Shapeshifter && cargo build --release
RUN cp /root/Lilith-Linux/Shapeshifter/target/release/shapeshifter /usr/local/bin/

RUN cd /root/Lilith-Linux/S8n-Rx-PackMan && cargo build --release
RUN cp /root/Lilith-Linux/S8n-Rx-PackMan/target/release/s8n /usr/local/bin/

RUN cd /root/Lilith-Linux/Lilith-TTS && cargo build --release
RUN cp /root/Lilith-Linux/Lilith-TTS/target/release/lilith-tts /usr/local/bin/

# Build COSMIC (optional - takes long time)
# RUN git clone --recurse-submodules https://github.com/pop-os/cosmic-epoch
# RUN cd cosmic-epoch && just sysext

# Setup boot splash
RUN mkdir -p /usr/share/plymouth/themes/lilith
COPY Lilith-Linux/Lilith-Splash/Lilith.mp4 /usr/local/share/lilith-splash.mp4

# Create Plymouth theme
RUN cat > /usr/share/plymouth/themes/lilith/lilith.plymouth << 'EOF'
[Plymouth Theme]
Name=Lilith Linux
ModuleName=script
EOF

RUN cat > /usr/share/plymouth/themes/lilith/lilith.script << 'EOF'
wallpaper = Image("lilith-splash.png");
wallpaper = wallpaper.Scale(Window.GetWidth(), Window.GetHeight());
wallpaper = wallpaper.BlendOntoRoot(0, 0);
EOF

# Setup Calamares branding
RUN mkdir -p /usr/share/calamares/branding/lilith
RUN cat > /usr/share/calamares/branding/lilith/branding.desc << 'EOF'
---
productName: Lilith Linux
productVersion: 1.0
version: 1.0.0
variant: Lilith
variantId: lilith
shortProductName: Lilith
homepage: https://lilithlinux.org
bootloaderEntryName: Lilith
EOF

# Final setup
RUN plymouth-set-default-theme lilith

CMD ["/bin/bash"]
