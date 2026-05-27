local ngx = ngx
local cjson = require "cjson"

local M = {}

local PUBLIC_PATHS = {
    ["/health"]     = true,
    ["/auth/token"] = true,
}

local function json_error(status, message)
    ngx.status = status
    ngx.header["Content-Type"] = "application/json"
    ngx.say(cjson.encode({ error = message }))
    ngx.exit(status)
end

function M.check()
    if PUBLIC_PATHS[ngx.var.uri] then
        return
    end

    local auth_header = ngx.req.get_headers()["Authorization"]
    if not auth_header then
        return json_error(ngx.HTTP_UNAUTHORIZED, "unauthorized")
    end

    local token = auth_header:match("^Bearer%s+(.+)$")
    if not token then
        return json_error(ngx.HTTP_UNAUTHORIZED, "unauthorized")
    end

    -- TODO: validate JWT token via lua-resty-jwt
    ngx.ctx.auth_token = token
end

return M
