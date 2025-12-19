--fonts

function readFont(fileData)
	--length of filename
	local filenameLength = readInt(fileData, pos)
	data = {filename = readString(fileData, pos+2, filenameLength), chars = {}, height = 0, mbaseline = 0}
	skip(filenameLength+4)

	data.leading = readInt(fileData,pos-2)
	data.tracking = readInt(fileData,pos)
	skip(4)

	--loop through all the characters
	while pos <= #fileData do
		local char = bytesToHex(readString(fileData,pos,2),1)
		data.chars[char] = {}
		skip(2)

		data.chars[char].x = readInt(fileData,pos)
		data.chars[char].y = readInt(fileData,pos+2)
		data.chars[char].width = readInt(fileData,pos+4)
		data.chars[char].height = readInt(fileData,pos+6)
		data.chars[char].pivotY = readInt(fileData,pos+8)
		data.height = math.max(data.chars[char].height,data.height)
		data.mbaseline = math.min(data.chars[char].pivotY,data.mbaseline)

		skip(10)
	end
	return data
end