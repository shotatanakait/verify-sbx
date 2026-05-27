local redis  = require "resty.redis"
local config = require "config"

local M = {}

local CONNECT_TIMEOUT   = 1000
local KEEPALIVE_TIMEOUT = 10000
local KEEPALIVE_SIZE    = 100

-- Returns a connected Redis client, optionally selecting db (0=prod, 1=test).
-- Caller must call M.release(red) when done.
function M.new(db)
    local red = redis:new()
    red:set_timeout(CONNECT_TIMEOUT)

    local ok, err = red:connect(config.redis.host, config.redis.port)
    if not ok then
        return nil, "failed to connect to Redis: " .. err
    end

    local target_db = db ~= nil and db or config.redis.db
    if target_db ~= 0 then
        local res
        res, err = red:select(target_db)
        if not res then
            red:close()
            return nil, "failed to select Redis DB " .. target_db .. ": " .. err
        end
    end

    return red
end

function M.release(red)
    local ok, err = red:set_keepalive(KEEPALIVE_TIMEOUT, KEEPALIVE_SIZE)
    if not ok then
        ngx.log(ngx.WARN, "redis keepalive failed: ", err)
        red:close()
    end
end

return M
