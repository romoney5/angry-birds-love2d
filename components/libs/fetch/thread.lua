-- Copyright 2025 Elloramir.
-- All rights over the MIT license.

local cwd = ...
local sys = require("love.system")
local options = { ["Windows"] = "wininet", ["Linux"] = "curl" }
local adapter = (options[sys.getOS()] or "socket")
local httpsRequest = require(cwd .. adapter)

local requestChannel = love.thread.getChannel("fetch_request")
local responseChannel = love.thread.getChannel("fetch_response")

local function hostFromURL(url)
    local host = url:match("^https?://([^/]+)") or url:match("^[^/]+")
    return host
end

local function pathFromURL(url)
    local path = url:match("^https?://[^/]+(/.*)$") or "/"
    return path
end

local function portFromURL(url)
    if url:sub(1, 5):lower() == "https" then
        return 443
    end
    return 80
end

local function encodeHeader(headers)
    headers = headers or {}
    local headerStr = ""
    for key, value in pairs(headers) do
        headerStr = headerStr .. key .. ": " .. value .. "\r\n"
    end
    return headerStr
end

local function parseHeaders(rawHeaders)
    local headers = { }
    for line in rawHeaders:gmatch("([^\n]+)\n") do
        local k, v = line:match("^([^:]+):%s*(.+)$")
        if k and v then headers[k] = v end
    end
    return headers
end

while true do
    local message = requestChannel:demand()
    local url = message.address
    local options = message.options or {}
    
    -- Extract host and path from the URL
    local host = hostFromURL(url)
    local path = pathFromURL(url)
    local port = portFromURL(url)

    local method = (options.method or "GET"):upper()
    local headers = encodeHeader(options.headers)
    local data = options.data or ""

    -- Perform the request
    local status, body, responseHeaders = httpsRequest(host, path, port, method, headers, data)
    local parsedHeaders = parseHeaders(responseHeaders or "")
    
    -- Once done, send the response back to the channel
    responseChannel:push({
        id = message.id,
        code = status,
        body = body,
        adapter = adapter,
        headers = parsedHeaders,
    })
end
