# ujust recipes for bazzite-lentilland.  Run e.g.:  ujust boot-to-hyprland

# Switch the next boot into Hyprland (your desktop)
boot-to-hyprland:
    steamos-session-select hyprland

# Switch into Steam Gaming Mode
return-to-gaming:
    steamos-session-select gamescope

# Fallback: boot into stock GNOME
boot-to-gnome:
    steamos-session-select gnome

# Clone (or update) your lentilLandConfigs and link them into ~/.config.
# Repo layout expected:  hypr/   waybar/   at the repo root.
lentilland-configs:
    #!/usr/bin/bash
    set -euo pipefail
    REPO="git@github.com:valenteEngineering/lentilLandConfigs.git"
    BRANCH="handheld"
    DEST="${HOME}/.local/share/lentilLandConfigs"
    if [ -d "${DEST}/.git" ]; then
        git -C "${DEST}" fetch origin "${BRANCH}"
        git -C "${DEST}" checkout "${BRANCH}"
        git -C "${DEST}" pull --ff-only origin "${BRANCH}"
    else
        git clone -b "${BRANCH}" "${REPO}" "${DEST}"
    fi
    mkdir -p "${HOME}/.config"
    ln -sfn "${DEST}/hypr"   "${HOME}/.config/hypr"
    ln -sfn "${DEST}/waybar" "${HOME}/.config/waybar"
    echo "Linked ~/.config/hypr and ~/.config/waybar -> ${DEST}"
