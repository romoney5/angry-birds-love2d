-- Copyright 2025 Elloramir.
-- All rights reserved under the MIT license.

local ffi = require("ffi")
local curl = ffi.load("curl")

ffi.cdef[[
typedef void CURL;
typedef int CURLcode;

CURL* curl_easy_init();
CURLcode curl_easy_setopt(CURL* curl, int option, ...);
CURLcode curl_easy_perform(CURL* curl);
void curl_easy_cleanup(CURL* curl);
CURLcode curl_easy_getinfo(CURL* curl, int info, ...);

typedef size_t (*curl_write_callback)(char *ptr, size_t size, size_t nmemb, void *userdata);

enum {
    CURLOPT_URL = 10002,
    CURLOPT_PORT = 10000 + 3,
    CURLOPT_CUSTOMREQUEST = 10036,
    CURLOPT_HTTPHEADER = 10023,
    CURLOPT_POSTFIELDS = 10015,
    CURLOPT_WRITEFUNCTION = 20011,
    CURLOPT_WRITEDATA = 10001,
    CURLOPT_HEADERFUNCTION = 20079,
    CURLOPT_HEADERDATA = 10029,

    CURLINFO_RESPONSE_CODE = 0x200002
};

struct curl_slist {
    char *data;
    struct curl_slist *next;
};

struct curl_slist* curl_slist_append(struct curl_slist *list, const char *string);
void curl_slist_free_all(struct curl_slist *list);
]]

-- Writer for response body or headers
local function stringWriter()
    local buffer = {}
    local callback = ffi.cast("curl_write_callback", function(ptr, size, nmemb, userdata)
        local len = size * nmemb
        local str = ffi.string(ptr, len)
        table.insert(buffer, str)
        return len
    end)
    return buffer, callback
end

-- Main function
local function httpsRequest(host, path, port, method, headers, data)
    local url = string.format("https://%s:%d%s", host, port or 443, path or "/")
    local curlHandle = curl.curl_easy_init()
    if curlHandle == nil then
        error("Failed to initialize curl")
    end

    local bodyBuffer, bodyCallback = stringWriter()
    local headerBuffer, headerCallback = stringWriter()

    curl.curl_easy_setopt(curlHandle, ffi.C.CURLOPT_URL, url)
    curl.curl_easy_setopt(curlHandle, ffi.C.CURLOPT_PORT, port or 443)
    curl.curl_easy_setopt(curlHandle, ffi.C.CURLOPT_CUSTOMREQUEST, method or "GET")
    curl.curl_easy_setopt(curlHandle, ffi.C.CURLOPT_WRITEFUNCTION, bodyCallback)
    curl.curl_easy_setopt(curlHandle, ffi.C.CURLOPT_WRITEDATA, nil)
    curl.curl_easy_setopt(curlHandle, ffi.C.CURLOPT_HEADERFUNCTION, headerCallback)
    curl.curl_easy_setopt(curlHandle, ffi.C.CURLOPT_HEADERDATA, nil)

    -- Process user headers
    local slist = nil
    if headers then
        for line in headers:gmatch("[^\r\n]+") do
            slist = curl.curl_slist_append(slist, line)
        end
        curl.curl_easy_setopt(curlHandle, ffi.C.CURLOPT_HTTPHEADER, slist)
    end

    if data then
        curl.curl_easy_setopt(curlHandle, ffi.C.CURLOPT_POSTFIELDS, data)
    end

    local result = curl.curl_easy_perform(curlHandle)

    -- Get HTTP status code
    local statusCode = ffi.new("long[1]")
    curl.curl_easy_getinfo(curlHandle, ffi.C.CURLINFO_RESPONSE_CODE, statusCode)

    curl.curl_easy_cleanup(curlHandle)
    if slist then curl.curl_slist_free_all(slist) end
    bodyCallback:free()
    headerCallback:free()

    if result ~= 0 then
        error("CURL request failed with code: " .. tonumber(result))
    end

    local code = tonumber(statusCode[0])
    local body = table.concat(bodyBuffer)
    local responseHeaders = table.concat(headerBuffer)

    return code, body, responseHeaders
end

return httpsRequest
