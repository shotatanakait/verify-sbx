#!/usr/bin/env bash
set -euo pipefail

REDIS_HOST="${REDIS_HOST:-127.0.0.1}"
REDIS_PORT="${REDIS_PORT:-6379}"

if ! redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ping > /dev/null 2>&1; then
    echo "Error: Redis is not running at ${REDIS_HOST}:${REDIS_PORT}" >&2
    exit 1
fi

redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" CONFIG SET maxmemory 256mb > /dev/null
redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" CONFIG SET maxmemory-policy allkeys-lru > /dev/null

redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" SETNX nlp:config:ratelimit_max 100 > /dev/null
redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" SETNX nlp:config:cache_ttl 300 > /dev/null
redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" SETNX nlp:config:maintenance 0 > /dev/null

echo "Redis setup completed (${REDIS_HOST}:${REDIS_PORT})"
