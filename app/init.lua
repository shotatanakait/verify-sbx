local os = os

local redis_host = os.getenv("REDIS_HOST") or "127.0.0.1"
local redis_port = tonumber(os.getenv("REDIS_PORT")) or 6379
local redis_db   = tonumber(os.getenv("REDIS_DB")) or 0

package.loaded["config"] = {
    redis = {
        host = redis_host,
        port = redis_port,
        db   = redis_db,
    },
}
