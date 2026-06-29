#!/usr/bin/bash
# =======================================================================================
# Build script for bazzite-lentilland. Runs inside the image build (NOT on your device).
# =======================================================================================
set -euxo pipefail

### 0. Enable the Hyprland COPR --------------------------------------------------------
# Hyprland & friends are NOT in Fedora's official repos — they live in this COPR.
dnf5 install -y dnf5-plugins
dnf5 -y copr enable solopasha/hyprland

### 1. Required packages ---------------------------------------------------------------
# hypr* come from the COPR; the rest are in the Fedora repos on the base image.
dnf5 install -y \
    hyprland \
    hyprlock \
    hypridle \
    hyprpaper \
    xdg-desktop-portal-hyprland \
    waybar \
    wofi \
    kitty \
    foot \
    dolphin \
    mako \
    pavucontrol \
    swaybg \
    brightnessctl \
    ddcutil \
    jq \
    bc \
    unzip

# Best-effort — qtutils (Qt-version sensitive on Bazzite) + a polkit agent. Skip any that
# aren't available rather than failing the build; the config probes for whichever landed.
dnf5 install -y --skip-unavailable \
    hyprland-qtutils \
    mate-polkit \
    polkit-gnome \
    hyprpolkitagent

### 2. JetBrainsMono Nerd Font (waybar glyphs) ------------------------------------------
NERD_VER="v3.4.0"
FONT_DIR="/usr/share/fonts/jetbrains-mono-nerd"
mkdir -p "${FONT_DIR}"
curl -fsSL -o /tmp/JBM.zip \
    "https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_VER}/JetBrainsMono.zip"
unzip -o /tmp/JBM.zip -d "${FONT_DIR}"
rm -f /tmp/JBM.zip
fc-cache -f "${FONT_DIR}" || true

### 3. Session switching: add a Hyprland target to steamos-session-select ----------------
# Replaces the stock script with one that knows about hyprland (and keeps gamescope/gnome).
install -Dm0755 /tmp/build_files/steamos-session-select /usr/bin/steamos-session-select

### 4. Default autologin session = Hyprland --------------------------------------------
# First boot after rebase lands in Hyprland. steamos-session-select rewrites this at runtime.
install -Dm0644 /tmp/build_files/zz-lentilland-autologin.conf \
    /etc/sddm.conf.d/zz-steamos-autologin.conf

### 5. ujust helper recipes ------------------------------------------------------------
install -Dm0644 /tmp/build_files/just/lentilland.just \
    /usr/share/ublue-os/just/65-lentilland.just

echo "bazzite-lentilland build complete."
