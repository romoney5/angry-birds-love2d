--fonts

function readFont(fileData)
	--length of filename
	local filenameLength = readInt(fileData, pos)
	data = {filename = readString(fileData, pos+2, filenameLength), chars = {}, height = 0, maxascending = 0, maxdescending = 0}
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

		data.maxascending = math.max(data.maxascending, data.chars[char].pivotY)
		data.maxdescending = math.max(data.maxdescending, -data.chars[char].pivotY + data.chars[char].height)

		skip(10)
	end
	
	--height = max ascending + max descending
	data.height = data.maxascending + data.maxdescending

	return data
end