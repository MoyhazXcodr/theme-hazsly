# Hazsly Prism Theme for Pterodactyl

A dark premium glassmorphism-style theme layer for Pterodactyl Panel 1.x with subtle motion.

## What it does
- Adds a custom CSS layer to the React panel.
- Wraps the app in a `hazsly-theme` root class for scoped styling.
- Rebuilds panel assets.
- Clears Laravel caches and restores permissions.

## Tested target
Designed for Pterodactyl Panel 1.x layouts. Best fit: 1.11/1.12.

## Repo structure
- `install.sh` — installs or updates the theme on the panel host.
- `uninstall.sh` — removes the theme import and CSS file.
- `theme/hazsly-prism.css` — the theme stylesheet.
- `theme/public/hazsly-prism-mark.svg` — optional branding asset.

## Quick install from a VPS
```bash
export REPO_URL="https://github.com/YOURNAME/hazsly-prism-theme.git"
curl -fsSL https://raw.githubusercontent.com/YOURNAME/hazsly-prism-theme/main/install.sh | bash
```

## Manual install
```bash
git clone https://github.com/YOURNAME/hazsly-prism-theme.git
cd hazsly-prism-theme
bash install.sh
```

## Optional environment variables
- `PANEL_DIR` default: `/var/www/pterodactyl`
- `WEB_USER` default: `www-data`
- `BRANCH` default: `main`
- `REPO_URL` required only when piping installer from `curl | bash`

## Uninstall
```bash
bash uninstall.sh
```

## Notes
- Make a server snapshot or panel backup first.
- If your panel source has already been heavily edited, review the import patch step in `install.sh` before running it.
