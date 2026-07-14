# =======================================================================================
# bazzite-lentilland — Hyprland on top of Bazzite, Legion Go 2 (AMD) handheld
# Thin layer over the official deck-gnome image: adds Hyprland + tools + session switching.
# Configs themselves live in your lentilLandConfigs repo (cloned into ~/.config), NOT here.
# =======================================================================================

# ---------------------------------------------------------------------------------------
# Stage 1: build the hyprgrass touch-gesture plugin on PLAIN Fedora.
# Why a separate stage: hyprland-devel requires pkgconfig(xwayland), but Bazzite replaces
# Fedora's Xwayland with its own build and ships no -devel, so the dep can't resolve inside
# the Bazzite image. Plain Fedora has Xwayland-devel, so it builds cleanly here. We pull the
# SAME mbaldessari Hyprland 0.54.3 as the final image, so the plugin's ABI hash matches.
#
# VERSION COUPLING: HYPRGRASS_TAG must match the mbaldessari COPR's Hyprland version
# (see build_files/build.sh). If the COPR rolls to 0.55.x, bump this to the matching
# hl-0.55.x AND expect a hyprlang->lua config migration.
# ---------------------------------------------------------------------------------------
FROM registry.fedoraproject.org/fedora:43 AS hyprgrass-builder
ARG HYPRGRASS_TAG=hl-0.54.3
RUN dnf install -y dnf5-plugins && \
    dnf -y copr enable mbaldessari/hyprland && \
    dnf install -y \
        hyprland-devel 'pkgconfig(xwayland)' \
        glm-devel meson ninja-build gcc-c++ git pkgconf-pkg-config \
        pixman-devel wayland-devel libdrm-devel && \
    git clone --depth 1 -b "${HYPRGRASS_TAG}" \
        https://github.com/horriblename/hyprgrass /src && \
    meson setup /src/build /src && \
    ninja -C /src/build && \
    test -f /src/build/src/libhyprgrass.so

# ---------------------------------------------------------------------------------------
# Stage 2: the actual image.
# ---------------------------------------------------------------------------------------
FROM ghcr.io/ublue-os/bazzite-deck-gnome:stable

# Baked-in hyprgrass plugin from the builder stage (loaded via hyprland.conf exec-once).
COPY --from=hyprgrass-builder /src/build/src/libhyprgrass.so \
    /usr/lib/hyprland/plugins/libhyprgrass.so

# Everything else the build does lives in build_files/ and runs in one layer.
COPY build_files /tmp/build_files

RUN --mount=type=cache,dst=/var/cache/dnf \
    /tmp/build_files/build.sh && \
    rm -rf /tmp/build_files && \
    ostree container commit
