--functions for reading data types like int, float, etc

hasffi,ffi = pcall(require,"ffi")
--read 16-bit signed int in big-endian, which is what ka3d uses
function readInt(data, index)
	local b1, b2 = data:byte(index, index + 1)
	local unsigned = (b1 * 256) + b2
	if hasffi then
		local buffer = ffi.new("int16_t[1]")
		buffer[0] = ffi.cast("int16_t", unsigned)

		return buffer[0]
	else
		return unsigned - (unsigned>32767 and 65536 or 0)
	end
end

--read 8 bit signed int? old fonts
function read8Int(data, index)
	local b1 = data:byte(index)
	if hasffi then
		local buffer = ffi.new("int8_t[1]")
		buffer[0] = ffi.cast("int8_t", b1)
		
		return buffer[0]
	else
		return b1 - (b1>127 and 256 or 0)
	end
end

--read 32 bit signed int?! old fonts
function read32Int(data, index)
	local b1,b2,b3,b4 = data:byte(index,index+3)
	local unsigned = (b1 * 16777216) + (b2 * 65536) + (b3 * 256) + b4
	if hasffi then
		local buffer = ffi.new("int32_t[1]")
		buffer[0] = ffi.cast("int32_t", unsigned)

		return buffer[0]
	else
		return unsigned - (unsigned > 2147483647 and 4294967296 or 0)
	end
end

--used by rvio composprites
function readFloat(data, index)
	local b1, b2, b3, b4 = data:byte(index, index + 3)

	local unsigned = bit.bor(
		bit.lshift(b1, 24),
		bit.lshift(b2, 16),
		bit.lshift(b3, 8),
		b4
	)

	local buffer = ffi.new("uint8_t[4]", {
		bit.band(bit.rshift(unsigned, 24), 0xFF),
		bit.band(bit.rshift(unsigned, 16), 0xFF),
		bit.band(bit.rshift(unsigned, 8), 0xFF),
		bit.band(unsigned, 0xFF),
	})

	local float_ptr = ffi.cast("float*", buffer)
	return float_ptr[0]
end

--used by rvio composprites
function readBool(data, index)
	return data:byte(index)==0x01
end

--this reads a string
--crazy right?
function readString(data, index, length)
	return data:sub(index, index + length - 1)
end

--convert byte value to hex
function bytesToHex(data, index)
	local b1, b2 = data:byte(index, index + 1)
	return string.format("%02x%02x", b1, b2)
end


--skip bytes
function skip(length)pos = pos + length end