--extract from 7-zip

--not even ffi is present?
if not ffi then return end

_, lib7z = pcall(ffi.load, "7z")

--doesn't have a dll for 7z
if not lib7z then return end

Lib7z = {} --cannot be 7z

print(lib7z)

ffi.cdef[[

]]