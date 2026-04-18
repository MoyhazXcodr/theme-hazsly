#!/usr/bin/env bash
set -euo pipefail

PANEL_DIR="${PANEL_DIR:-/var/www/pterodactyl}"
WEB_USER="${WEB_USER:-www-data}"
BRANCH="${BRANCH:-main}"
REPO_URL="${REPO_URL:-}"
THEME_CSS="hazsly-prism.css"
APP_FILE="$PANEL_DIR/resources/scripts/components/App.tsx"
TARGET_CSS_DIR="$PANEL_DIR/resources/scripts/assets/css"
TARGET_CSS_FILE="$TARGET_CSS_DIR/$THEME_CSS"
TARGET_PUBLIC_DIR="$PANEL_DIR/public/themes/hazsly-prism"
BACKUP_DIR="$PANEL_DIR/.hazsly-prism-backup/$(date +%Y%m%d-%H%M%S)"
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR=""

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "[ERR] Required command not found: $1" >&2
    exit 1
  }
}

cleanup() {
  if [[ -n "$WORK_DIR" && -d "$WORK_DIR" ]]; then
    rm -rf "$WORK_DIR"
  fi
}
trap cleanup EXIT

need php
need git
need perl

if [[ ! -d "$PANEL_DIR" ]]; then
  echo "[ERR] PANEL_DIR does not exist: $PANEL_DIR" >&2
  exit 1
fi

if [[ ! -f "$APP_FILE" ]]; then
  echo "[ERR] App.tsx was not found at: $APP_FILE" >&2
  exit 1
fi

resolve_source() {
  if [[ -f "$SELF_DIR/theme/$THEME_CSS" ]]; then
    echo "$SELF_DIR"
    return 0
  fi

  if [[ -n "$REPO_URL" ]]; then
    need mktemp
    WORK_DIR="$(mktemp -d)"
    echo "[INFO] Cloning theme repo..."
    git clone --depth=1 --branch "$BRANCH" "$REPO_URL" "$WORK_DIR/repo" >/dev/null 2>&1
    echo "$WORK_DIR/repo"
    return 0
  fi

  echo "[ERR] Theme source not found. Run inside the repo or set REPO_URL." >&2
  exit 1
}

SOURCE_DIR="$(resolve_source)"
SOURCE_CSS="$SOURCE_DIR/theme/$THEME_CSS"
SOURCE_PUBLIC_DIR="$SOURCE_DIR/theme/public"

if [[ ! -f "$SOURCE_CSS" ]]; then
  echo "[ERR] Theme CSS file missing: $SOURCE_CSS" >&2
  exit 1
fi

need npm
need yarn

mkdir -p "$BACKUP_DIR"
mkdir -p "$TARGET_CSS_DIR"
mkdir -p "$TARGET_PUBLIC_DIR"

cd "$PANEL_DIR"

echo "[INFO] Entering maintenance mode..."
php artisan down || true

echo "[INFO] Backing up current files..."
cp "$APP_FILE" "$BACKUP_DIR/App.tsx"
[[ -f "$TARGET_CSS_FILE" ]] && cp "$TARGET_CSS_FILE" "$BACKUP_DIR/$THEME_CSS" || true

echo "[INFO] Copying theme assets..."
cp "$SOURCE_CSS" "$TARGET_CSS_FILE"
if [[ -d "$SOURCE_PUBLIC_DIR" ]]; then
  mkdir -p "$TARGET_PUBLIC_DIR"
  cp -R "$SOURCE_PUBLIC_DIR"/. "$TARGET_PUBLIC_DIR"/
fi

echo "[INFO] Injecting CSS import into App.tsx..."
if ! grep -q "@/assets/css/$THEME_CSS" "$APP_FILE"; then
  perl -0pi -e "s#import '@/assets/tailwind\\.css';#import '@/assets/tailwind.css';\nimport '@/assets/css/$THEME_CSS';#" "$APP_FILE"
fi

echo "[INFO] Wrapping app with hazsly-theme scope..."
if ! grep -q 'className="hazsly-theme"' "$APP_FILE"; then
  perl -0pi -e 's#return \(\s*<>#return (\n        <div className="hazsly-theme">\n            <>#s' "$APP_FILE"
  perl -0pi -e 's#</>\s*\);#</>\n        </div>\n    );#s' "$APP_FILE"
fi

echo "[INFO] Installing JS dependencies if needed..."
yarn install --frozen-lockfile >/dev/null 2>&1 || yarn install

echo "[INFO] Building panel assets..."
export NODE_OPTIONS=--openssl-legacy-provider
yarn build:production

echo "[INFO] Clearing Laravel caches..."
php artisan view:clear
php artisan config:clear

echo "[INFO] Restoring ownership..."
chown -R "$WEB_USER:$WEB_USER" "$PANEL_DIR"

echo "[INFO] Restarting queue worker..."
php artisan queue:restart || true

echo "[INFO] Leaving maintenance mode..."
php artisan up || true

echo

echo "[DONE] Hazsly Prism theme installed."
echo "[NOTE] Backup stored at: $BACKUP_DIR"
