#!/usr/bin/env bash
set -euo pipefail

PANEL_DIR="${PANEL_DIR:-/var/www/pterodactyl}"
WEB_USER="${WEB_USER:-www-data}"
APP_FILE="$PANEL_DIR/resources/scripts/components/App.tsx"
TARGET_CSS_FILE="$PANEL_DIR/resources/scripts/assets/css/hazsly-prism.css"

command -v php >/dev/null 2>&1 || { echo "[ERR] php not found" >&2; exit 1; }
command -v perl >/dev/null 2>&1 || { echo "[ERR] perl not found" >&2; exit 1; }
command -v yarn >/dev/null 2>&1 || { echo "[ERR] yarn not found" >&2; exit 1; }

cd "$PANEL_DIR"
php artisan down || true

if [[ -f "$APP_FILE" ]]; then
  perl -0pi -e "s#\nimport '@/assets/css/hazsly-prism\\.css';##" "$APP_FILE"
  perl -0pi -e 's#<div className="hazsly-theme">\s*<>#<>#s' "$APP_FILE"
  perl -0pi -e 's#</>\s*</div>\s*\);#</>\n    );#s' "$APP_FILE"
fi

rm -f "$TARGET_CSS_FILE"
rm -rf "$PANEL_DIR/public/themes/hazsly-prism"

export NODE_OPTIONS=--openssl-legacy-provider
yarn build:production
php artisan view:clear
php artisan config:clear
chown -R "$WEB_USER:$WEB_USER" "$PANEL_DIR"
php artisan queue:restart || true
php artisan up || true

echo "[DONE] Hazsly Prism theme removed."
