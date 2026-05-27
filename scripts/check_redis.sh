#!/usr/bin/env bash
set -euo pipefail

REDIS_HOST="${REDIS_HOST:-127.0.0.1}"
REDIS_PORT="${REDIS_PORT:-6379}"

echo "Checking Redis at ${REDIS_HOST}:${REDIS_PORT}..."

if ! redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ping; then
    echo "Error: Could not connect to Redis" >&2
    exit 1
fi

policy=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" CONFIG GET maxmemory-policy | tail -1)
echo "maxmemory-policy: ${policy}"

echo "nlp:config:ratelimit_max: $(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" GET nlp:config:ratelimit_max)"
echo "nlp:config:cache_ttl:     $(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" GET nlp:config:cache_ttl)"
echo "nlp:config:maintenance:   $(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" GET nlp:config:maintenance)"
