--convert a pvr image into ImageData

local support = love.graphics.getImageFormats()
local headerSize = 52

function convertImagePVR(data, filename)
	assert(data)

	pos = 1
	local w, h = 1, 1
	local format = 0
	local mipmaps = 0
	local imagedata
	local rawdata

	if love.data.unpack("<i4", data, pos) == headerSize then --1.6.3
		skip(4)
		h = love.data.unpack("<i4", data, pos)
		skip(4)
		w = love.data.unpack("<i4", data, pos)
		skip(4)
		mipmaps = love.data.unpack("<i4", data, pos) + 1
		skip(4)
		format = love.data.unpack("<i1", data, pos)

		-- print("convertImagePVR: pvr file "..tostring(filename).." has w:"..w.." h:"..h.." format:"..format.."")
		if format == 16 and support.rgba4 then --r4 g4 b4 a4
			local expectedSize = w * h * 2 + headerSize
			assert(data:len() == expectedSize, "wrong pvr size for \""..filename.."\"; expected "..expectedSize..", got "..data:len())

			rawdata = string.sub(data, headerSize + 1)
			imagedata = love.image.newImageData(w, h, "rgba4", rawdata)
		elseif format == 19 and support.rgb565 then --r5 g6 b5
			local expectedSize = w * h * 2 + headerSize
			assert(data:len() == expectedSize, "wrong pvr size for \""..filename.."\"; expected "..expectedSize..", got "..data:len())
			
			rawdata = string.sub(data, headerSize + 1)
			imagedata = love.image.newImageData(w, h, "rgb565", rawdata)
		elseif format == 54 and support.ETC1 then --etc1 compressed, 4bpp
			-- local expectedSize = w * h / 2 + 52
			-- assert(data:len() == expectedSize, "wrong pvr size for \""..filename.."\"; expected "..expectedSize..", got "..data:len())

			--just rebuild the header, sometimes (1 mipmap?) love just bails trying to convert a pvr header
			local head = ""
			head = head..love.data.pack("string", "<i4", 0x50565203) --PVR
			head = head..love.data.pack("string", ">i4", 0) --flags (0)
			head = head..love.data.pack("string", ">i8", 6) --pixel format (etc1)
			head = head..love.data.pack("string", ">i4", 0) --color space (linear)
			head = head..love.data.pack("string", ">i4", 4) --channel type (unsigned short normalized)
			head = head..love.data.pack("string", ">i4", h) --height
			head = head..love.data.pack("string", ">i4", w) --width
			head = head..love.data.pack("string", ">i4", 1) --depth (love only supports 1)
			head = head..love.data.pack("string", ">i4", 1) --num surfaces
			head = head..love.data.pack("string", ">i4", 1) --num faces
			head = head..love.data.pack("string", ">i4", mipmaps) --num mipmaps
			head = head..love.data.pack("string", ">i4", 0) --metadata size

			--now swap in the header
			data = head..data:sub(headerSize + 1)

			local filedata = love.filesystem.newFileData(data, "")
			imagedata = love.image.newCompressedData(filedata)
		-- else
		-- 	error("wrong pvr format for \""..filename.."\"")
		end
	else
		error("convertImagePVR: wrong pvr format for \""..filename.."\"")
	end

	--shucks! guess an empty image will do
	imagedata = imagedata or love.image.newImageData(w, h, nil, nil)

	return imagedata
end