--spritesheets

function readSprt(fileData)
	data = {sprites = {}}
	--length of filename
	local filenameLength = readInt(fileData, pos)
	data.filename = readString(fileData, pos+2, filenameLength)
	skip(filenameLength+4)

	while pos <= #fileData do
		local spritenameLength = readInt(fileData, pos)
		skip(2)

		local spritename = readString(fileData, pos, spritenameLength)
		-- print(spritenameLength)
		data.sprites[spritename] = {}
		skip(spritenameLength)

		data.sprites[spritename].x = readInt(fileData, pos)
		data.sprites[spritename].y = readInt(fileData, pos + 2)
		data.sprites[spritename].width = readInt(fileData, pos + 4)
		data.sprites[spritename].height = readInt(fileData, pos + 6)
		skip(8)

		data.sprites[spritename].pivotX = readInt(fileData, pos)
		data.sprites[spritename].pivotY = readInt(fileData, pos+2)

		skip(4)

		-- print(pos,#fileData)
	end
	return data
end