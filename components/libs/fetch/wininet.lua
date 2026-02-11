-- Copyright 2025 Elloramir.
-- All rights over the MIT license.

local ffi = require("ffi")
local wininet = ffi.load("wininet")

ffi.cdef[[
typedef void* HINTERNET;
typedef unsigned long DWORD;
typedef DWORD DWORD_PTR;
typedef const char* LPCSTR;
typedef char* LPSTR;
typedef void* LPVOID;
typedef int BOOL;

HINTERNET InternetOpenA(
  LPCSTR lpszAgent,
  DWORD dwAccessType,
  LPCSTR lpszProxy,
  LPCSTR lpszProxyBypass,
  DWORD dwFlags
);

HINTERNET InternetConnectA(
  HINTERNET hInternet,
  LPCSTR lpszServerName,
  DWORD nServerPort,
  LPCSTR lpszUsername,
  LPCSTR lpszPassword,
  DWORD dwService,
  DWORD dwFlags,
  DWORD_PTR dwContext
);

HINTERNET HttpOpenRequestA(
  HINTERNET hConnect,
  LPCSTR lpszVerb,
  LPCSTR lpszObjectName,
  LPCSTR lpszVersion,
  LPCSTR lpszReferer,
  LPCSTR* lplpszAcceptTypes,
  DWORD dwFlags,
  DWORD_PTR dwContext
);

BOOL HttpSendRequestA(
  HINTERNET hRequest,
  LPCSTR lpszHeaders,
  DWORD dwHeadersLength,
  LPVOID lpOptional,
  DWORD dwOptionalLength
);

BOOL InternetReadFile(
  HINTERNET hFile,
  LPVOID lpBuffer,
  DWORD dwNumberOfBytesToRead,
  DWORD* lpdwNumberOfBytesRead
);

BOOL InternetCloseHandle(
  HINTERNET hInternet
);

BOOL HttpQueryInfoA(
  HINTERNET hRequest,
  DWORD dwInfoLevel,
  LPVOID lpBuffer,
  DWORD* lpdwBufferLength,
  DWORD* lpdwIndex
);

DWORD GetLastError();
]]

local INTERNET_OPEN_TYPE_DIRECT    = 1
local INTERNET_SERVICE_HTTP        = 3
local INTERNET_FLAG_SECURE         = 0x00800000  -- SSL/TLS
local HTTP_QUERY_STATUS_CODE       = 19
local HTTP_QUERY_RAW_HEADERS_CRLF  = 22

-- Function to perform an HTTP or HTTPS request, using the given port
local function httpsRequest(host, path, port, method, headers, data)
    method  = method or "GET"
    headers = headers or ""

    -- Initialize WinINet session
    local hInternet = wininet.InternetOpenA(
        "LuaJIT/WinINet Client",
        INTERNET_OPEN_TYPE_DIRECT,
        nil, nil, 0
    )
    if hInternet == nil then
        return nil, "InternetOpenA failed", nil
    end

    -- Connect to the server on the specified port
    local hConnect = wininet.InternetConnectA(
        hInternet,
        host,
        port,
        nil, nil,
        INTERNET_SERVICE_HTTP,
        0,
        0
    )
    if hConnect == nil then
        wininet.InternetCloseHandle(hInternet)
        return nil, "InternetConnectA failed", nil
    end

    -- Determine flags: use secure flag only if port is 443
    local flags = (port == 443) and INTERNET_FLAG_SECURE or 0

    -- Open the HTTP request
    local hRequest = wininet.HttpOpenRequestA(
        hConnect,
        method,
        path,
        nil,
        nil,
        nil,
        flags,
        0
    )
    if hRequest == nil then
        wininet.InternetCloseHandle(hConnect)
        wininet.InternetCloseHandle(hInternet)
        return nil, "HttpOpenRequestA failed", nil
    end

    -- Prepare optional data buffer
    local dataPtr, dataLen = nil, 0
    if data and #data > 0 then
        dataLen = #data
        dataPtr = ffi.new("char[?]", dataLen)
        ffi.copy(dataPtr, data, dataLen)
    end

    -- Send the request
    local ok = wininet.HttpSendRequestA(
        hRequest,
        headers,
        #headers,
        dataPtr,
        dataLen
    )
    if ok == 0 then
        local err = ffi.C.GetLastError()
        wininet.InternetCloseHandle(hRequest)
        wininet.InternetCloseHandle(hConnect)
        wininet.InternetCloseHandle(hInternet)
        return nil, "HttpSendRequestA failed (Error "..err..")", nil
    end

    -- Query status code
    local statusBuf   = ffi.new("char[16]")
    local statusLen   = ffi.new("DWORD[1]", 16)
    local statusIndex = ffi.new("DWORD[1]", 0)
    ok = wininet.HttpQueryInfoA(
        hRequest,
        HTTP_QUERY_STATUS_CODE,
        statusBuf,
        statusLen,
        statusIndex
    )
    local status = ok ~= 0 and tonumber(ffi.string(statusBuf, statusLen[0])) or nil

    -- Query raw headers
    local headersBuf   = ffi.new("char[4096]")
    local headersLen   = ffi.new("DWORD[1]", 4096)
    ok = wininet.HttpQueryInfoA(
        hRequest,
        HTTP_QUERY_RAW_HEADERS_CRLF,
        headersBuf,
        headersLen,
        statusIndex
    )
    local rawHeaders = ok ~= 0 and ffi.string(headersBuf, headersLen[0]) or nil

    -- Read response body
    local body = ""
    local buf  = ffi.new("char[4096]")
    local read = ffi.new("DWORD[1]")
    while wininet.InternetReadFile(hRequest, buf, 4096, read) ~= 0 and read[0] > 0 do
        body = body .. ffi.string(buf, read[0])
    end

    -- Close handles
    wininet.InternetCloseHandle(hRequest)
    wininet.InternetCloseHandle(hConnect)
    wininet.InternetCloseHandle(hInternet)

    return status, body, rawHeaders
end

return httpsRequest
