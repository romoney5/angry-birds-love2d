-- Copyright 2025 Elloramir.
-- All rights over the MIT license.

local fetch = {}

local cwd = (...):gsub('%.init$', '') .. "."
local path = cwd:gsub("[.]", "/")
local requestChannel = love.thread.getChannel("fetch_request")
local responseChannel = love.thread.getChannel("fetch_response")

local thread = nil
local threadReady = false
local requestPool = {}

local function generateId()
    return love.timer.getTime()
end

function fetch.call(address, options, callback)
    if not threadReady then
        thread = love.thread.newThread(path .. "thread.lua")
        thread:start(cwd)
        threadReady = true
    end
    
    local id = generateId()
    requestPool[id] = callback
    
    requestChannel:push({
        id = id,
        address = address,
        options = options or {}
    })
    
    return id
end

-- Process fetch finished requests on the
-- main thread. If there is not new message on the 
-- stack we should just ignore it and wait for the next frames...
function fetch.update()
    local message = responseChannel:pop()
    
    if message then
        local callback = requestPool[message.id]
        if callback then
            callback(message)
            requestPool[message.id] = nil
        end
    end
    
    return message ~= nil
end

-- Not necessary step, but to looks like the javascript
-- fetch we should be able to call fetch module as a function
return setmetatable(fetch, {
    __call = function(t, address, options, callback)
        return t.call(address, options, callback)
    end
})
