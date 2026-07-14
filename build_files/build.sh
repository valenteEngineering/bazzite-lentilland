#!/usr/bin/bash
# =======================================================================================
# Build script for bazzite-lentilland. Runs inside the image build (NOT on your device).
# =======================================================================================
set -euxo pipefail

### 0. Enable the Hyprland COPR --------------------------------------------------------
# Hyprland & friends are NOT in Fedora's official repos — they live in a COPR.
# Switched solopasha/hyprland -> mbaldessari/hyprland: solopasha is stale at 0.51.1, and
# the hyprgrass touch-gesture plugin needs Hyprland >= 0.52.2. mbaldessari ships a matched
# 0.54.3 stack (core + hyprlock/hypridle/hyprpaper/portal) for Fedora 43 — the last
# hyprlang-native release (0.55 deprecates hyprlang for Lua), so our configs stay as-is.
dnf5 install -y dnf5-plugins
dnf5 -y copr enable mbaldessari/hyprland

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

### 1c. hyprgrass — touchscreen gesture plugin (Legion Go 2 touch workspace switching) --
# The plugin's libhyprgrass.so is NOT built here: it is compiled in the `hyprgrass-builder`
# stage of the Containerfile (plain Fedora, where Fedora's Xwayland-devel is installable —
# Bazzite excludes Fedora's Xwayland and ships no -devel, so hyprland-devel can't resolve
# `pkgconfig(xwayland)` inside this Bazzite image) and COPY'd into /usr/lib/hyprland/plugins/.
# The builder stage pulls the SAME mbaldessari Hyprland 0.54.3, so the plugin ABI matches.
# Gives 3-finger swipe-from-anywhere -> workspace switch. See ~/.config/hypr/hyprland.conf.
# VERSION COUPLING lives on the ARG HYPRGRASS_TAG in the Containerfile — keep it matched to
# the COPR's Hyprland version.

### 1b. Google Chrome ------------------------------------------------------------------
# Add Google's official RPM repo and install the stable channel, so Chrome is baked into
# the image and tracks upstream updates on every rebuild (no loose RPM to re-layer).
cat > /etc/yum.repos.d/google-chrome.repo <<'EOF'
[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF
dnf5 install -y google-chrome-stable

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

### 3b. Fix live Hyprland -> gamescope switch (black-screen loop) -----------------------
# Hyprland leaks WAYLAND_DISPLAY into the systemd user env; the gamescope user service
# inherits it, tries to nest into the dead socket, and black-screen loops. This drop-in
# strips those vars from the service so gamescope always comes up on DRM.
install -Dm0644 /tmp/build_files/gamescope-unset-env.conf \
    /usr/lib/systemd/user/gamescope-session-plus@.service.d/10-unset-leaked-wayland-env.conf

### 4. Default autologin session = Hyprland --------------------------------------------
# First boot after rebase lands in Hyprland. steamos-session-select rewrites this at runtime.
install -Dm0644 /tmp/build_files/zz-lentilland-autologin.conf \
    /etc/sddm.conf.d/zz-steamos-autologin.conf

### 5. ujust helper recipes ------------------------------------------------------------
install -Dm0644 /tmp/build_files/just/lentilland.just \
    /usr/share/ublue-os/just/65-lentilland.just

echo "bazzite-lentilland build complete."
