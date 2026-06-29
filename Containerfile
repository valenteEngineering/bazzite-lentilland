# =======================================================================================
# bazzite-lentilland — Hyprland on top of Bazzite, Legion Go 2 (AMD) handheld
# Thin layer over the official deck-gnome image: adds Hyprland + tools + session switching.
# Configs themselves live in your lentilLandConfigs repo (cloned into ~/.config), NOT here.
# =======================================================================================

FROM ghcr.io/ublue-os/bazzite-deck-gnome:stable

# Everything the build does lives in build_files/ and runs in one layer.
COPY build_files /tmp/build_files

RUN --mount=type=cache,dst=/var/cache/dnf \
    /tmp/build_files/build.sh && \
    rm -rf /tmp/build_files && \
    ostree container commit
