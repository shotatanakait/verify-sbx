local ngx = ngx
local cjson = require "cjson"

local M = {}

local LIMIT_PER_MINUTE = 100
local rate_limit_dict  = ngx.shared.rate_limit

local function json_error(status, message, headers)
    ngx.status = status
    ngx.header["Content-Type"] = "application/json"
    if headers then
        for k, v in pairs(headers) do
            ngx.header[k] = v
        end
    end
    ngx.say(cjson.encode({ error = message }))
    ngx.exit(status)
end

function M.check()
    local ip  = ngx.var.remote_addr
    local key = "rl:" .. ip

    local count, err = rate_limit_dict:incr(key, 1, 0, 60)
    if err then
        ngx.log(ngx.ERR, "rate_limit incr error: ", err)
        return
    end

    local reset_time = ngx.time() + 60
    ngx.header["X-RateLimit-Limit"]     = LIMIT_PER_MINUTE
    ngx.header["X-RateLimit-Remaining"] = math.max(0, LIMIT_PER_MINUTE - count)
    ngx.header["X-RateLimit-Reset"]     = reset_time

    if count > LIMIT_PER_MINUTE then
        return json_error(429, "too_many_requests", {
            ["Retry-After"] = 60,
        })
    end
end

return M
