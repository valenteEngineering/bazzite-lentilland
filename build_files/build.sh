#!/usr/bin/bash
# =======================================================================================
# Build script for bazzite-lentilland. Runs inside the image build (NOT on your device).
# =======================================================================================
set -euxo pipefail

### 1. Packages -------------------------------------------------------------------------
# Hyprland + the tools the lentilLand configs expect. These all live in the Fedora repos
# on F43 (avoids the COPR Qt-version conflicts). foot/mako/waybar/hyprpaper/pavucontrol/
# brightnessctl/ddcutil/jq/bc already ship on the base image; listed for completeness.
dnf5 install -y \
    hyprland \
    hyprlock \
    hypridle \
    hyprpaper \
    hyprland-qtutils \
    xdg-desktop-portal-hyprland \
    waybar \
    wofi \
    kitty \
    foot \
    dolphin \
    mako \
    pavucontrol \
    brightnessctl \
    ddcutil \
    jq \
    bc \
    unzip \
    polkit-gnome

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
