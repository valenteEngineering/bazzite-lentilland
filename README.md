# bazzite-lentilland

A thin, self-maintaining [Bazzite](https://bazzite.gg) image that adds **Hyprland** (plus
Waybar, wofi, kitty, dolphin, hyprlock/hypridle, JetBrainsMono Nerd Font) on top of the
official `bazzite-deck-gnome` handheld image — built for a **Lenovo Legion Go 2 (AMD)**.

It is a *layer*, not a fork: it builds `FROM ghcr.io/ublue-os/bazzite-deck-gnome:stable`, so
every Bazzite update flows through automatically. Steam Gaming Mode is untouched — you get a
clean round-trip between **Hyprland** (dev/desktop) and **Gaming Mode**.

Your dotfiles are **not** baked in — they live in your `lentilLandConfigs` repo and are
cloned into `~/.config`, so you can edit them on the fly.

---

## One-time setup

### 1. Push this repo to GitHub
```bash
cd ~/bazzite-lentilland
git init && git add -A && git commit -m "Initial bazzite-lentilland image"
git branch -M main
git remote add origin git@github.com:valenteEngineering/bazzite-lentilland.git
git push -u origin main
```
The GitHub Action builds and pushes `ghcr.io/valenteengineering/bazzite-lentilland:latest`.
Watch it under the repo's **Actions** tab (first build ~15–20 min). When it's green, make the
package **public**: GitHub → your profile → Packages → `bazzite-lentilland` → Package settings
→ Change visibility → Public.

### 2. Rebase your handheld onto it
```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/valenteengineering/bazzite-lentilland:latest
systemctl reboot
```
After reboot you'll auto-login into **Hyprland**.

### 3. Pull in your configs (first boot)
```bash
ujust lentilland-configs
```
This clones `lentilLandConfigs` to `~/.local/share/lentilLandConfigs` and symlinks
`~/.config/hypr` and `~/.config/waybar` to it. Edit there, `git push`, done.
> Expected repo layout: `hypr/` and `waybar/` directories at the repo root.

---

## Switching sessions

| From | Action | Lands in |
|------|--------|----------|
| Hyprland | `SUPER`+`CTRL`+`G`  (or `ujust return-to-gaming`) | Gaming Mode |
| Gaming Mode | Steam → power → **Switch to Desktop** | Hyprland |
| anywhere (terminal) | `ujust boot-to-hyprland` / `return-to-gaming` / `boot-to-gnome` | chosen session |

Each switch restarts SDDM and auto-logs into the chosen session — no password, no picker.

---

## Updates

Nothing to do. The handheld auto-updates (bootc) from your image, and the GitHub Action
rebuilds daily on top of the newest Bazzite. If an upstream change ever collides with this
layer, the **build fails in CI** (red X) instead of breaking your device — fix `build.sh`
when convenient; the handheld keeps running the last good image.

## Rollback
```bash
rpm-ostree rollback && systemctl reboot          # previous deployment
# or fully back to stock:
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/ublue-os/bazzite-deck-gnome:stable
```

## What's inside
- `Containerfile` — `FROM bazzite-deck-gnome:stable`, runs the build layer.
- `build_files/build.sh` — installs packages + Nerd Font, lays down session switching.
- `build_files/steamos-session-select` — adds a `hyprland` target (keeps gamescope/gnome).
- `build_files/zz-lentilland-autologin.conf` — default boot = Hyprland.
- `build_files/just/lentilland.just` — `ujust` helper recipes.
- `.github/workflows/build.yml` — daily + on-push build to GHCR.
