#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

openresty -p "$PROJECT_DIR" -c "$CONF" -s stop
echo "Server stopped"
