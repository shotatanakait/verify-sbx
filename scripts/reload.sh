#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

if [ "${NGINX_ENV:-dev}" = "production" ]; then
    CONF="nginx/nginx.conf"
else
    CONF="nginx/nginx.dev.conf"
fi

openresty -p "$PROJECT_DIR" -c "$CONF" -s reload
echo "Configuration reloaded"
