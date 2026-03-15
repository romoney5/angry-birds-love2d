--functions for reading data types like int, float, etc

--read 8-bit (1 byte) signed int
function read8Int(data, index)
	return love.data.unpack(">i1", data, index)
end

--read 16-bit (2 byte) signed int in big-endian, primarily used in ka3d
function readInt(data, index)
	return love.data.unpack(">i2", data, index)
end

--read 32-bit (4 byte) signed int big-endian
function read32Int(data, index)
	return love.data.unpack(">i4", data, index)
end

--used by rvio composprites
function readFloat(data, index)
	return love.data.unpack("<f", data, index)
end

--used by rvio composprites
function readBool(data, index)
	return data:byte(index) == 0x01
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
function skip(length)
	pos = pos + length
end