#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

if [ -f "$PROJECT_DIR/.env" ]; then
    set -a
    # shellcheck disable=SC1091
    source "$PROJECT_DIR/.env"
    set +a
fi

if [ "${NGINX_ENV:-dev}" = "production" ]; then
    CONF="nginx/nginx.conf"
else
    CONF="nginx/nginx.dev.conf"
fi
