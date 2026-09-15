--convert a pvr image into ImageData

--TODO: switch to getTextureFormats() when love 12 releases
local support = love.graphics.getImageFormats()
local headerSize = 52

local assert = assert

function convertImagePVR(data, filename)
	assert(data)

	pos = 1
	local w, h = 1, 1
	local format = 0
	local mipmaps = 0
	local imagedata
	local rawdata
	local metadatasize = 0
	local bitrate = 0

	if love.data.unpack("<i4", data, pos) == headerSize then --1.6.3
		skip(4)
		h = love.data.unpack("<i4", data, pos)
		skip(4)
		w = love.data.unpack("<i4", data, pos)
		skip(4)
		mipmaps = love.data.unpack("<i4", data, pos) + 1
		skip(4)
		format = love.data.unpack("<i1", data, pos)
		skip(1)
		skip(3) --flags
		skip(4) --surface size
		bitrate = love.data.unpack("<i4", data, pos)

		local headerSize = headerSize + metadatasize

		if format == 16 and support.rgba4 then --r4 g4 b4 a4
			local expectedSize = w * h * 2 + headerSize
			assert(data:len() >= expectedSize, "wrong pvr size for \""..filename.."\"; expected "..expectedSize.." ("..metadatasize.."), got "..data:len())

			rawdata = string.sub(data, headerSize + 1, 1 + expectedSize - 1)
			imagedata = love.image.newImageData(w, h, "rgba4", rawdata)
		elseif format == 19 and support.rgb565 then --r5 g6 b5
			local expectedSize = w * h * 2 + headerSize
			assert(data:len() == expectedSize, "wrong pvr size for \""..filename.."\"; expected "..expectedSize.." ("..metadatasize.."), got "..data:len())
			
			rawdata = string.sub(data, headerSize + 1, headerSize + 1 + expectedSize - 1)
			imagedata = love.image.newImageData(w, h, "rgb565", rawdata)
		elseif format == 25 then --pvrtc 4bpp rgba
			--usually unsupported for most devices, but there is a way out
			
			if support.PVR1rgba4 then
				rawdata = string.sub(data, headerSize + 1)
				imagedata = love.image.newImageData(w, h, "PVR1rgba4", rawdata)
			elseif support.rgba8 and pvr then --everything has support for rgba8, right?
				--use luajit (without external libs) to decompress the pvr
				local input_data = data:sub(headerSize + 1)
				local output_length = w * h * 4
				local input_buffer = ffi.cast("uint8_t *", ffi.new("const char *", input_data))
				local result = ffi.new("uint8_t[?]", w * h * 2 * 2)
				
				local _ = pvr.PVRTDecompressPVRTC(input_buffer, 2, w, h, result)
				
				local rawdata = ffi.string(result, output_length)
				imagedata = love.image.newImageData(w, h, "rgba8", rawdata)
			end
		elseif format == 54 and support.ETC1 then --etc1 compressed, 4bpp
			--TODO: also port ETC1 decompression? (love2d 12's vulkan backend doesn't support etc1)

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
		-- 	error("convertImagePVR: unsupported pvr2 pixel format for \""..filename.."\": "..tostring(format))
		end
	elseif love.data.unpack(">i4", data, 1) == 0x50565203 then --pvr v3 header, nearly everything in 4.0.0
		skip(4) --PVR
		skip(4) --flags
		format = data:sub(pos, pos + 3) --pixel format
		bitrate = data:sub(pos + 4, pos + 3 + 4)
		skip(8)
		skip(4) --color space
		skip(4) --channel type
		h = love.data.unpack("<i4", data, pos)
		skip(4)
		w = love.data.unpack("<i4", data, pos)
		skip(4)
		skip(4) --depth
		skip(4) --num surfaces
		skip(4) --num faces
		mipmaps = love.data.unpack("<i4", data, pos) --and NOW we have our mipmaps
		skip(4)
		metadatasize = love.data.unpack("<i4", data, pos) --size of metadata

		local headerSize = headerSize + metadatasize

		if format == "rgba" and bitrate == "\04\04\04\04" and support.rgba4 then --rgba 4444
			local expectedSize = w * h * 2 + headerSize
			assert(data:len() == expectedSize, "wrong pvr size for \""..filename.."\"; expected "..expectedSize.." ("..metadatasize.."), got "..data:len())

			rawdata = string.sub(data, headerSize + 1)
			imagedata = love.image.newImageData(w, h, "rgba4", rawdata)
		elseif format == "rgba" and bitrate == "\08\08\08\08" then --rgba 8888
			local expectedSize = w * h * 4 + headerSize
			assert(data:len() == expectedSize, "wrong pvr size for \""..filename.."\"; expected "..expectedSize.." ("..metadatasize.."), got "..data:len())

			rawdata = string.sub(data, headerSize + 1)
			imagedata = love.image.newImageData(w, h, "rgba8", rawdata)
		elseif format == "rgb\00" and bitrate == "\05\06\05\00" then --rgb 565
			rawdata = string.sub(data, headerSize + 1)
			imagedata = love.image.newImageData(w, h, "rgb565", rawdata)
		elseif format == "\06\00\00\00" and support.ETC1 then --etc1
			local filedata = love.filesystem.newFileData(data, "")
			imagedata = love.image.newCompressedData(filedata)
		elseif format == "\03\00\00\00" --[[and support.PVR1rgba4]] then --pvrtc1
			--use luajit (without external libs) to decompress the pvr
			local input_data = data:sub(headerSize + 1)
			local output_length = w * h * 4
			local input_buffer = ffi.cast("uint8_t *", ffi.new("const char *", input_data))
			local result = ffi.new("uint8_t[?]", w * h * 2 * 2)
			
			local _ = pvr.PVRTDecompressPVRTC(input_buffer, 2, w, h, result)
			
			local rawdata = ffi.string(result, output_length)
			imagedata = love.image.newImageData(w, h, "rgba8", rawdata)
		else
			print("convertImagePVR: unsupported pvr3 pixel format for \""..filename.."\": "..tostring(format)..", "..tostring(bitrate:byte()))
		end
	else
		print("convertImagePVR: unsupported pvr header format for \""..filename.."\"")
	end

	--shucks! guess an empty image will do
	imagedata = imagedata or love.image.newImageData(w, h, nil, nil)

	return imagedata, w, h
end
