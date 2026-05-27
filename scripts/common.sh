#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

if [ "${NGINX_ENV:-dev}" = "production" ]; then
    CONF="nginx/nginx.conf"
else
    CONF="nginx/nginx.dev.conf"
fi
