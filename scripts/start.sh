#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

mkdir -p "$PROJECT_DIR/logs" "$PROJECT_DIR/temp"

if [ -f "$PROJECT_DIR/logs/nginx.pid" ] && kill -0 "$(cat "$PROJECT_DIR/logs/nginx.pid")" 2>/dev/null; then
    echo "Server is already running (PID $(cat "$PROJECT_DIR/logs/nginx.pid"))" >&2
    exit 1
fi

"$SCRIPT_DIR/setup_redis.sh" 2>> "$PROJECT_DIR/logs/error.log" || {
    echo "setup_redis.sh failed. See logs/error.log" >&2
    exit 1
}

openresty -p "$PROJECT_DIR" -c "$CONF" -t
openresty -p "$PROJECT_DIR" -c "$CONF"
echo "Server started on port 8080 (NGINX_ENV=${NGINX_ENV:-dev})"
