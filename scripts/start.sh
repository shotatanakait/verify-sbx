#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

mkdir -p "$PROJECT_DIR/logs" "$PROJECT_DIR/temp"

openresty -p "$PROJECT_DIR" -c "$CONF" -t
openresty -p "$PROJECT_DIR" -c "$CONF"
echo "Server started on port 8080 (NGINX_ENV=${NGINX_ENV:-dev})"
