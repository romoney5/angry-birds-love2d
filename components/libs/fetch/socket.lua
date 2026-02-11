-- Copyright 2025 Elloramir.
-- All rights over the MIT license.

local socket = require("socket")

local function extractHeaders(con)
    local headers = ""
    while true do
        local line = con:receive("*l")
        if not line or line == "" then break end
        headers = headers .. line .. "\n"
    end
    return headers
end

local function extractContent(con, headers)
    local len = tonumber(headers["Content-Length"]) or 0
    local body = ""
    if len > 0 then
        body = assert(con:receive(len))
    end
    return body
end

local function extractCode(con)
    local line = assert(con:receive("*l"))
    local code = tonumber(line:match("(%d%d%d)"))

    return code
end

local function httpRequest(host, path, port, method, headers, data)
    method = method or "GET"
    data = data or ""
    headers = headers or ""

    local req
    local con = assert(socket.tcp());con:settimeout(5)
    local ok, err = con:connect(host, port)

    if not ok then
        return nil, err, nil
    end

    req = method .. " " .. path .. " HTTP/1.1\r\n"
    req = req .. "Host: " .. host .. "\r\n"
    req = req .. headers
    req = req .. "Connection: close\r\n"
    req = req .. "Content-Length: " .. #data .. "\r\n"
    req = req .. "\r\n" .. data

    ok, err = con:send(req)

    if not ok then
        return nil, err, nil
    end

    local code = extractCode(con)
    local responseHeaders = extractHeaders(con)
    local body = extractContent(con, responseHeaders)

    con:close()

    return code, body, responseHeaders
end

return httpRequest
