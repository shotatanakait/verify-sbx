local ngx = ngx
local cjson = require "cjson"

local M = {}

local routes = {}

local function health_handler()
    ngx.status = ngx.HTTP_OK
    ngx.header["Content-Type"] = "application/json"
    ngx.say(cjson.encode({ status = "ok" }))
    ngx.exit(ngx.HTTP_OK)
end

local function json_error(status, message)
    ngx.status = status
    ngx.header["Content-Type"] = "application/json"
    ngx.say(cjson.encode({ error = message }))
    ngx.exit(status)
end

routes["/health"] = { method = "GET", handler = health_handler }

function M.get(path, handler)
    routes[path] = { method = "GET", handler = handler }
end

function M.post(path, handler)
    routes[path] = { method = "POST", handler = handler }
end

function M.dispatch()
    local uri    = ngx.var.uri
    local method = ngx.req.get_method()

    local route = routes[uri]
    if route then
        if route.method ~= method then
            return json_error(ngx.HTTP_NOT_ALLOWED, "method not allowed")
        end
        return route.handler()
    end

    return json_error(ngx.HTTP_NOT_FOUND, "not_found")
end

return M
