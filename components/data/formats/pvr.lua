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
	local metadatasize = 0

	if love.data.unpack("<i4", data, pos) == headerSize then --1.6.3
		skip(4)
		h = love.data.unpack("<i4", data, pos)
		skip(4)
		w = love.data.unpack("<i4", data, pos)
		skip(4)
		mipmaps = love.data.unpack("<i4", data, pos) + 1
		skip(4)
		format = love.data.unpack("<i1", data, pos)

		local headerSize = headerSize + metadatasize

		-- print("convertImagePVR: pvr file "..tostring(filename).." has w:"..w.." h:"..h.." format:"..format.."")
		if format == 16 and support.rgba4 then --r4 g4 b4 a4
			local expectedSize = w * h * 2 + headerSize
			assert(data:len() == expectedSize, "wrong pvr size for \""..filename.."\"; expected "..expectedSize.." ("..metadatasize.."), got "..data:len())

			rawdata = string.sub(data, headerSize + 1)
			imagedata = love.image.newImageData(w, h, "rgba4", rawdata)
		elseif format == 19 and support.rgb565 then --r5 g6 b5
			local expectedSize = w * h * 2 + headerSize
			assert(data:len() == expectedSize, "wrong pvr size for \""..filename.."\"; expected "..expectedSize.." ("..metadatasize.."), got "..data:len())
			
			rawdata = string.sub(data, headerSize + 1)
			imagedata = love.image.newImageData(w, h, "rgb565", rawdata)
		elseif format == 25 then --pvrtc 4bpp rgba
			--usually unsupported for most devices
			-- local expectedSize = w * h / 2 + headerSize
			-- assert(data:len() == expectedSize, "wrong pvr size for \""..filename.."\"; expected "..expectedSize.." ("..metadatasize.."), got "..data:len())
			
			if support.PVR1rgba4 then
				rawdata = string.sub(data, headerSize + 1)
				imagedata = love.image.newImageData(w, h, "PVR1rgba4", rawdata)
			elseif support.rgba4 then
				-- print(w, h)
				-- imagedata = love.image.newImageData(w, h, "rgba4", rawdata)
				-- local result = {}
				-- local a, resultstr = PVRTDecompressPVRTC(data:sub(headerSize + 1), 2, w, h, result)
				-- print(filename..", "..a)
				-- print(w, h)
				-- print(resultstr:len())

				-- for i, v in ipairs(result) do
				-- 	resultstr = resultstr..string.char(v.red)..string.char(v.green)..string.char(v.blue)..string.char(v.alpha)
				-- end
				rawdata = string.rep("\xFF", w * h * 16 / 8)--resultstr
				imagedata = love.image.newImageData(w, h, "rgba4", rawdata)
				-- rawdata = resultstr
				-- imagedata = love.image.newImageData(w, h, "rgba8", rawdata)
				-- print(w, h)
			end
		elseif format == 54 and support.ETC1 then --etc1 compressed, 4bpp
			-- local expectedSize = w * h / 2 + 52
			-- assert(data:len() == expectedSize, "wrong pvr size for \""..filename.."\"; expected "..expectedSize.." ("..metadatasize.."), got "..data:len())

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
		-- format = data:sub(pos, pos + 3) --pixel format
		format = love.data.unpack("<i4", data, pos + 4)
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

		if format == 67372036 and support.rgba4 then --04 04 04 04 unorm linear
			local expectedSize = w * h * 2 + headerSize
			assert(data:len() == expectedSize, "wrong pvr size for \""..filename.."\"; expected "..expectedSize.." ("..metadatasize.."), got "..data:len())

			rawdata = string.sub(data, headerSize + 1)
			imagedata = love.image.newImageData(w, h, "rgba4", rawdata)
		elseif format == 134744072 and support.rgba8 then --08 08 08 08 unorm linear
			local expectedSize = w * h * 4 + headerSize
			assert(data:len() == expectedSize, "wrong pvr size for \""..filename.."\"; expected "..expectedSize.." ("..metadatasize.."), got "..data:len())

			rawdata = string.sub(data, headerSize + 1)
			imagedata = love.image.newImageData(w, h, "rgba8", rawdata)
		elseif format == 329221 then --?
			rawdata = string.rep("\xFF", w * h * 16 / 8)
			-- print(w, h)
			imagedata = love.image.newImageData(w, h, "rgba4", rawdata)
		elseif format == 0 and support.ETC1 then --pvrtc1
			--hey.. that's etc1!
			local filedata = love.filesystem.newFileData(data, "")
			imagedata = love.image.newCompressedData(filedata)
			-- print(filename)
			-- local result = {}
			-- -- local resultstr = ""
			-- local a, resultstr = PVRTDecompressPVRTC(data:sub(headerSize + 1), 2, w, h, result)
			-- print(a)

			-- -- for i, v in ipairs(result) do
			-- -- 	resultstr = resultstr..string.char(v.red)..string.char(v.green)..string.char(v.blue)..string.char(v.alpha)
			-- -- end
			-- rawdata = resultstr--string.rep("\xFF", w * h * 16 / 8)
			-- print(w, h)
			-- imagedata = love.image.newImageData(w, h, "rgba8", rawdata)
		-- else
		-- 	error("convertImagePVR: unsupported pvr3 pixel format for \""..filename.."\": "..tostring(format))
		end
	else
		print("convertImagePVR: unsupported pvr header format for \""..filename.."\"")
	end

	--shucks! guess an empty image will do
	imagedata = imagedata or love.image.newImageData(w, h, nil, nil)

	return imagedata
end

--https://github.com/powervr-graphics/Native_SDK/blob/master/framework/PVRCore/texture/PVRTDecompress.cpp
-- namespace pvr {
local
	ETC_MIN_TEXWIDTH,
	ETC_MIN_TEXHEIGHT,
	DXT_MIN_TEXWIDTH,
	DXT_MIN_TEXHEIGHT = 4, 4, 4, 4

-- struct Pixel32
-- {
-- 	uint8_t red, green, blue, alpha;
-- };

-- struct Pixel128S
-- {
-- 	int32_t red, green, blue, alpha;
-- };

-- struct PVRTCWord
-- {
-- 	uint32_t modulationData;
-- 	uint32_t colorData;
-- };

-- struct PVRTCWordIndices
-- {
-- 	int P[2], Q[2], R[2], S[2];
-- };

local function getColorA(colorData)
	local color = {}

	-- Opaque Color Mode - RGB 554
	if (bit.band(colorData, 0x8000) ~= 0) then
		color.red = bit.rshift(bit.band(colorData, 0x7c00), 10); -- 5->5 bits
		color.green = bit.rshift(bit.band(colorData, 0x3e0), 5); -- 5->5 bits
		color.blue = bit.bor(bit.band(colorData, 0x1e), bit.rshift(bit.band(colorData, 0x1e), 4)); -- 4->5 bits
		color.alpha = (0xf); -- 0->4 bits
	-- Transparent Color Mode - ARGB 3443
	else
		color.red = bit.bor(bit.rshift(bit.band(colorData, 0xf00), 7), bit.rshift(bit.band(colorData, 0xf00), 11)); -- 4->5 bits
		color.green = bit.bor(bit.rshift(bit.band(colorData, 0xf0), 3), bit.rshift(bit.band(colorData, 0xf0), 7)); -- 4->5 bits
		color.blue = bit.bor(bit.lshift(bit.band(colorData, 0xe), 1), bit.rshift(bit.band(colorData, 0xe), 2)); -- 3->5 bits
		color.alpha = bit.bor(bit.rshift(bit.band(colorData, 0x7000), 11)); -- 3->4 bits - note 0 at right
	end

	return color;
end

local function getColorB(colorData)
	local color = {}

	-- Opaque Color Mode - RGB 555
	if (bit.band(colorData, 0x80000000) ~= 0) then
		color.red = bit.rshift(bit.band(colorData, 0x7c000000), 26); -- 5->5 bits
		color.green = bit.rshift(bit.band(colorData, 0x3e00000), 21); -- 5->5 bits
		color.blue = bit.rshift(bit.band(colorData, 0x1f0000), 16); -- 5->5 bits
		color.alpha = (0xf); -- 0 bits
	-- Transparent Color Mode - ARGB 3444
	else
		color.red = bit.bor(bit.rshift(bit.band(colorData, 0xf000000), 23), bit.rshift(bit.band(colorData, 0xf000000), 27)); -- 4->5 bits
		color.green = bit.bor(bit.rshift(bit.band(colorData, 0xf00000), 19), bit.rshift(bit.band(colorData, 0xf00000), 23)); -- 4->5 bits
		color.blue = bit.bor(bit.rshift(bit.band(colorData, 0xf0000), 15), bit.rshift(bit.band(colorData, 0xf0000), 19)); -- 4->5 bits
		color.alpha = bit.rshift(bit.band(colorData, 0x70000000), 27); -- 3->4 bits - note 0 at right
	end

	return color;
end

local function interpolateColors(P, Q, R, S, pPixel, bpp)
	local wordWidth = 4;
	local wordHeight = 4;
	if (bpp == 2) then wordWidth = 8; end

	-- Convert to int 32.
	-- Pixel128S hP = { (P.red), (P.green), (P.blue), (P.alpha) };
	-- Pixel128S hQ = { (Q.red), (Q.green), (Q.blue), (Q.alpha) };
	-- Pixel128S hR = { (R.red), (R.green), (R.blue), (R.alpha) };
	-- Pixel128S hS = { (S.red), (S.green), (S.blue), (S.alpha) };
	local hP = { red = P.red, green = P.green, blue = P.blue, alpha = P.alpha };
	local hQ = { red = Q.red, green = Q.green, blue = Q.blue, alpha = Q.alpha };
	local hR = { red = R.red, green = R.green, blue = R.blue, alpha = R.alpha };
	local hS = { red = S.red, green = S.green, blue = S.blue, alpha = S.alpha };

	-- Get vectors.
	-- Pixel128S QminusP = { hQ.red - hP.red, hQ.green - hP.green, hQ.blue - hP.blue, hQ.alpha - hP.alpha };
	-- Pixel128S SminusR = { hS.red - hR.red, hS.green - hR.green, hS.blue - hR.blue, hS.alpha - hR.alpha };
	local QminusP = { red = hQ.red - hP.red, green = hQ.green - hP.green, blue = hQ.blue - hP.blue, alpha = hQ.alpha - hP.alpha };
	local SminusR = { red = hS.red - hR.red, green = hS.green - hR.green, blue = hS.blue - hR.blue, alpha = hS.alpha - hR.alpha };

	-- Multiply colors.
	hP.red = hP.red * wordWidth;
	hP.green = hP.green * wordWidth;
	hP.blue = hP.blue * wordWidth;
	hP.alpha = hP.alpha * wordWidth;
	hR.red = hR.red * wordWidth;
	hR.green = hR.green * wordWidth;
	hR.blue = hR.blue * wordWidth;
	hR.alpha = hR.alpha * wordWidth;

	if (bpp == 2) then
		-- Loop through pixels to achieve results.
		for x = 0, wordWidth - 1 do
			-- Pixel128S result = { 4 * hP.red, 4 * hP.green, 4 * hP.blue, 4 * hP.alpha };
			-- Pixel128S dY = { hR.red - hP.red, hR.green - hP.green, hR.blue - hP.blue, hR.alpha - hP.alpha };
			local result = { red = 4 * hP.red, green = 4 * hP.green, blue = 4 * hP.blue, alpha = 4 * hP.alpha };
			local dY = { red = hR.red - hP.red, green = hR.green - hP.green, blue = hR.blue - hP.blue, alpha = hR.alpha - hP.alpha };

			for y = 0, wordHeight - 1 do
				pPixel[y * wordWidth + x].red = (bit.rshift(result.red, 7) + bit.rshift(result.red, 2));
				pPixel[y * wordWidth + x].green = (bit.rshift(result.green, 7) + bit.rshift(result.green, 2));
				pPixel[y * wordWidth + x].blue = (bit.rshift(result.blue, 7) + bit.rshift(result.blue, 2));
				pPixel[y * wordWidth + x].alpha = (bit.rshift(result.alpha, 5) + bit.rshift(result.alpha, 1));

				result.red = result.red + dY.red;
				result.green = result.green + dY.green;
				result.blue = result.blue + dY.blue;
				result.alpha = result.alpha + dY.alpha;
			end

			hP.red = hP.red + QminusP.red;
			hP.green = hP.green + QminusP.green;
			hP.blue = hP.blue + QminusP.blue;
			hP.alpha = hP.alpha + QminusP.alpha;

			hR.red = hR.red + SminusR.red;
			hR.green = hR.green + SminusR.green;
			hR.blue = hR.blue + SminusR.blue;
			hR.alpha = hR.alpha + SminusR.alpha;
		end
	else
		-- Loop through pixels to achieve results.
		for y = 0, wordHeight - 1 do
			-- Pixel128S result = { 4 * hP.red, 4 * hP.green, 4 * hP.blue, 4 * hP.alpha };
			-- Pixel128S dY = { hR.red - hP.red, hR.green - hP.green, hR.blue - hP.blue, hR.alpha - hP.alpha };
			local result = { red = 4 * hP.red, green = 4 * hP.green, blue = 4 * hP.blue, alpha = 4 * hP.alpha };
			local dY = { red = hR.red - hP.red, green = hR.green - hP.green, blue = hR.blue - hP.blue, alpha = hR.alpha - hP.alpha };

			for x = 0, wordWidth - 1 do
				pPixel[y * wordWidth + x].red = (bit.rshift(result.red, 6) + bit.rshift(result.red, 1));
				pPixel[y * wordWidth + x].green = (bit.rshift(result.green, 6) + bit.rshift(result.green, 1));
				pPixel[y * wordWidth + x].blue = (bit.rshift(result.blue, 6) + bit.rshift(result.blue, 1));
				pPixel[y * wordWidth + x].alpha = (bit.rshift(result.alpha, 4) + (result.alpha));

				result.red = result.red + dY.red;
				result.green = result.green + dY.green;
				result.blue = result.blue + dY.blue;
				result.alpha = result.alpha + dY.alpha;
			end

			hP.red = hP.red + QminusP.red;
			hP.green = hP.green + QminusP.green;
			hP.blue = hP.blue + QminusP.blue;
			hP.alpha = hP.alpha + QminusP.alpha;

			hR.red = hR.red + SminusR.red;
			hR.green = hR.green + SminusR.green;
			hR.blue = hR.blue + SminusR.blue;
			hR.alpha = hR.alpha + SminusR.alpha;
		end
	end
end

local function unpackModulations(word, offsetX, offsetY, modulationValues, modulationModes, bpp)
	local WordModMode = bit.band(word.colorData, 0x1);
	local ModulationBits = word.modulationData;

	-- Unpack differently depending on 2bpp or 4bpp modes.
	if (bpp == 2) then
		if (WordModMode) then
			-- determine which of the three modes are in use:

			-- If this is the either the H-only or V-only interpolation mode...
			if (bit.band(ModulationBits, 0x1) ~= 0) then
				-- look at the "LSB" for the "centre" (V=2,H=4) texel. Its LSB is now
				-- actually used to indicate whether it's the H-only mode or the V-only...

				-- The centre texel data is the at (y==2, x==4) and so its LSB is at bit 20.
				if (bit.band(ModulationBits, bit.lshift(0x1, 20)) ~= 0) then
					-- This is the V-only mode
					WordModMode = 3;
				else
					-- This is the H-only mode
					WordModMode = 2;
				end

				-- Create an extra bit for the centre pixel so that it looks like
				-- we have 2 actual bits for this texel. It makes later coding much easier.
				if (bit.band(ModulationBits, bit.lshift(0x1, 21)) ~= 0) then
					-- set it to produce code for 1.0
					ModulationBits = bit.bor(ModulationBits, bit.lshift(0x1, 20))
				else
					-- clear it to produce 0.0 code
					ModulationBits = bit.band(ModulationBits, bit.bnot(bit.lshift(0x1, 20)))
				end
			end -- end if H-Only or V-Only interpolation mode was chosen

			if (bit.band(ModulationBits, 0x2) ~= 0) then ModulationBits = bit.bor(ModulationBits, 0x1) --set it
			else
				ModulationBits = bit.band(ModulationBits, bit.bnot(0x1)) --clear it
			end

			-- run through all the pixels in the block. Note we can now treat all the
			-- "stored" values as if they have 2bits (even when they didn't!)
			for y = 0, 4 - 1 do
				for x = 0, 8 - 1 do
					modulationModes[x + offsetX][y + offsetY] = WordModMode;

					-- if this is a stored value...
					if (bit.band((x ^ y), 1) == 0) then
						modulationValues[x + offsetX][y + offsetY] = bit.band(ModulationBits, 3);
						ModulationBits = bit.rshift(ModulationBits, 2)
					end
				end
			end -- end for y
		-- else if direct encoded 2bit mode - i.e. 1 mode bit per pixel
		else
			for y = 0, 4 - 1 do
				for x = 0, 8 - 1 do
					modulationModes[x + offsetX][y + offsetY] = WordModMode;

					--[[
					-- double the bits so 0=> 00, and 1=>11
					]]
					if (bit.band(ModulationBits, 1) ~= 0) then modulationValues[x + offsetX][y + offsetY] = 0x3
					else
						modulationValues[x + offsetX][y + offsetY] = 0x0;
					end
					ModulationBits = bit.rshift(ModulationBits, 1)
				end
			end -- end for y
		end
	else
		-- Much simpler than the 2bpp decompression, only two modes, so the n/8 values are set directly.
		-- run through all the pixels in the word.
		if (WordModMode) then
			for y = 0, 4 - 1 do
				for x = 0, 4 - 1 do
					-- print("mod "..(y + offsetY))
					modulationValues[y + offsetY][x + offsetX] = bit.band(ModulationBits, 3);
					-- if (modulationValues==0) {}. We don't need to check 0, 0 = 0/8.
					if (modulationValues[y + offsetY][x + offsetX] == 1) then
						modulationValues[y + offsetY][x + offsetX] = 4
					elseif (modulationValues[y + offsetY][x + offsetX] == 2) then
						modulationValues[y + offsetY][x + offsetX] = 14 --+10 tells the decompressor to punch through alpha.
					elseif (modulationValues[y + offsetY][x + offsetX] == 3) then
						modulationValues[y + offsetY][x + offsetX] = 8
					end
					ModulationBits = bit.rshift(ModulationBits, 2)
				end -- end for x
			end -- end for y
		else
			for y = 0, 4 - 1 do
				for x = 0, 4 - 1 do
					modulationValues[y + offsetY][x + offsetX] = bit.band(ModulationBits, 3);
					modulationValues[y + offsetY][x + offsetX] = modulationValues[y + offsetY][x + offsetX] * 3;
					if (modulationValues[y + offsetY][x + offsetX] > 3) then
						modulationValues[y + offsetY][x + offsetX] = modulationValues[y + offsetY][x + offsetX] - 1 end
					ModulationBits = bit.rshift(ModulationBits, 2)
				end -- end for x
			end -- end for y
		end
	end
end

local function getModulationValues(modulationValues, modulationModes, xPos, yPos, bpp)
	if (bpp == 2) then
		local RepVals0 = { 0, 3, 5, 8 };

		-- extract the modulation value. If a simple encoding
		if (modulationModes[xPos][yPos] == 0) then return RepVals0[modulationValues[xPos][yPos]]
		else
			-- if this is a stored value
			if (bit.band((xPos ^ yPos), 1) == 0) then return RepVals0[modulationValues[xPos][yPos]]

			-- else average from the neighbours
			-- if H&V interpolation...
			elseif (modulationModes[xPos][yPos] == 1) then
				return (RepVals0[modulationValues[xPos][yPos - 1]] + RepVals0[modulationValues[xPos][yPos + 1]] + RepVals0[modulationValues[xPos - 1][yPos]] +
						   RepVals0[modulationValues[xPos + 1][yPos]] + 2) /
					4;
			-- else if H-Only
			elseif (modulationModes[xPos][yPos] == 2) then
				return (RepVals0[modulationValues[xPos - 1][yPos]] + RepVals0[modulationValues[xPos + 1][yPos]] + 1) / 2;
			-- else it's V-Only
			else
				return (RepVals0[modulationValues[xPos][yPos - 1]] + RepVals0[modulationValues[xPos][yPos + 1]] + 1) / 2;
			end
		end
	elseif (bpp == 4) then
		return modulationValues[xPos][yPos];
	end

	return 0;
end

local function pvrtcGetDecompressedPixels(P, Q, R, S, pColorData, bpp)
	-- 4bpp only needs 8*8 values, but 2bpp needs 16*8, so rather than wasting processor time we just statically allocate 16*8.
	local modulationValues = {}
	for i = 0, 16 - 1 do modulationValues[i] = {} end
	-- Only 2bpp needs this.
	local modulationModes = {}
	for i = 0, 16 - 1 do modulationModes[i] = {} end
	-- 4bpp only needs 16 values, but 2bpp needs 32, so rather than wasting processor time we just statically allocate 32.
	local upscaledColorA = {}
	for i = 0, 32 - 1 do upscaledColorA[i] = {} end
	local upscaledColorB = {}
	for i = 0, 32 - 1 do upscaledColorB[i] = {} end

	local wordWidth = 4;
	local wordHeight = 4;
	if (bpp == 2) then wordWidth = 8 end

	-- Get the modulations from each word.
	unpackModulations(P, 0, 0, modulationValues, modulationModes, bpp);
	unpackModulations(Q, wordWidth, 0, modulationValues, modulationModes, bpp);
	unpackModulations(R, 0, wordHeight, modulationValues, modulationModes, bpp);
	unpackModulations(S, wordWidth, wordHeight, modulationValues, modulationModes, bpp);

	-- Bilinear upscale image data from 2x2 -> 4x4
	interpolateColors(getColorA(P.colorData), getColorA(Q.colorData), getColorA(R.colorData), getColorA(S.colorData), upscaledColorA, bpp);
	interpolateColors(getColorB(P.colorData), getColorB(Q.colorData), getColorB(R.colorData), getColorB(S.colorData), upscaledColorB, bpp);

	for y = 0, wordHeight - 1 do
		for x = 0, wordWidth - 1 do
			local mod = getModulationValues(modulationValues, modulationModes, x + wordWidth / 2, y + wordHeight / 2, bpp)
			local punchthroughAlpha = false;
			if (mod > 10) then
				punchthroughAlpha = true;
				mod = mod - 10;
			end

			local result = {}
			result.red = (upscaledColorA[y * wordWidth + x].red * (8 - mod) + upscaledColorB[y * wordWidth + x].red * mod) / 8;
			result.green = (upscaledColorA[y * wordWidth + x].green * (8 - mod) + upscaledColorB[y * wordWidth + x].green * mod) / 8;
			result.blue = (upscaledColorA[y * wordWidth + x].blue * (8 - mod) + upscaledColorB[y * wordWidth + x].blue * mod) / 8;
			if (punchthroughAlpha) then result.alpha = 0
			else
				result.alpha = (upscaledColorA[y * wordWidth + x].alpha * (8 - mod) + upscaledColorB[y * wordWidth + x].alpha * mod) / 8;
			end

			-- Convert the 32bit precision Result to 8 bit per channel color.
			if (bpp == 2) then
				pColorData[y * wordWidth + x].red = (result.red);
				pColorData[y * wordWidth + x].green = (result.green);
				pColorData[y * wordWidth + x].blue = (result.blue);
				pColorData[y * wordWidth + x].alpha = (result.alpha);
			elseif (bpp == 4) then
				pColorData[y + x * wordHeight].red = (result.red);
				pColorData[y + x * wordHeight].green = (result.green);
				pColorData[y + x * wordHeight].blue = (result.blue);
				pColorData[y + x * wordHeight].alpha = (result.alpha);
			end
		end
	end
end

local function wrapWordIndex(numWords, word) return ((word + numWords) % numWords); end

local function isPowerOf2(input)
	local minus1;

	if (not input or input == 0) then return 0; end

	minus1 = input - 1;
	return (bit.bor(input, minus1) == (input ^ minus1));
end

local function TwiddleUV(XSize, YSize, XPos, YPos)
	-- Initially assume X is the larger size.
	local MinDimension = XSize;
	local MaxValue = YPos;
	local Twiddled = 0;
	local SrcBitPos = 1;
	local DstBitPos = 1;
	local ShiftCount = 0;

	-- Check the sizes are valid.
	assert(YPos < YSize);
	assert(XPos < XSize);
	assert(isPowerOf2(YSize));
	assert(isPowerOf2(XSize));

	-- If Y is the larger dimension - switch the min/max values.
	if (YSize < XSize) then
		MinDimension = YSize;
		MaxValue = XPos;
	end

	-- Step through all the bits in the "minimum" dimension
	while (SrcBitPos < MinDimension) do
		if bit.band(YPos, SrcBitPos) then Twiddled = bit.bor(Twiddled, DstBitPos); end

		if bit.band(XPos, SrcBitPos) then Twiddled = bit.bor(Twiddled, bit.lshift(DstBitPos, 1)); end

		SrcBitPos = bit.lshift(SrcBitPos, 1);
		DstBitPos = bit.lshift(DstBitPos, 2);
		ShiftCount = ShiftCount + 1;
	end

	-- Prepend any unused bits
	MaxValue = bit.rshift(MaxValue, ShiftCount);
	Twiddled = bit.bor(Twiddled, bit.lshift(MaxValue, (2 * ShiftCount)));

	return Twiddled;
end

local function mapDecompressedData(pOutput, width, pWord, words, bpp)
	local wordWidth = 4;
	local wordHeight = 4;
	if (bpp == 2) then wordWidth = 8; end

	for y = 0, wordHeight / 2 - 1 do
		for x = 0, wordWidth / 2 - 1 do
			pOutput[(((words.P[1] * wordHeight) + y + wordHeight / 2) * width + words.P[0] * wordWidth + x + wordWidth / 2)] = pWord[y * wordWidth + x]; -- map P

			pOutput[(((words.Q[1] * wordHeight) + y + wordHeight / 2) * width + words.Q[0] * wordWidth + x)] = pWord[y * wordWidth + x + wordWidth / 2]; -- map Q

			pOutput[(((words.R[1] * wordHeight) + y) * width + words.R[0] * wordWidth + x + wordWidth / 2)] = pWord[(y + wordHeight / 2) * wordWidth + x]; -- map R

			pOutput[(((words.S[1] * wordHeight) + y) * width + words.S[0] * wordWidth + x)] = pWord[(y + wordHeight / 2) * wordWidth + x + wordWidth / 2]; -- map S
		end
	end
end
local function pvrtcDecompress(pCompressedData, pDecompressedData, width, height, bpp)
	local wordWidth = 4;
	local wordHeight = 4;
	if (bpp == 2) then wordWidth = 8; end

	local pWordMembers = pCompressedData;
	local pOutData = pDecompressedData;

	-- Calculate number of words
	local i32NumXWords = math.floor(width / wordWidth);
	local i32NumYWords = math.floor(height / wordHeight);

	-- Structs used for decompression
	local indices = {P = {}, Q = {}, R = {}, S = {}};
	-- std::vector<Pixel32> pPixels(wordWidth * wordHeight * sizeof(Pixel32));
	local pPixels = {}
	for i = 0, wordWidth * wordHeight - 1 do pPixels[i] = {} end

	-- For each row of words
	for wordY = -1, i32NumYWords - 1 - 1 do
		-- for each column of words
		for wordX = -1, i32NumXWords - 1 - 1 do
			--romoney5: is math.floor needed? i don't see any floats
			indices.P[0] = math.floor(wrapWordIndex(i32NumXWords, wordX));
			indices.P[1] = math.floor(wrapWordIndex(i32NumYWords, wordY));
			indices.Q[0] = math.floor(wrapWordIndex(i32NumXWords, wordX + 1));
			indices.Q[1] = math.floor(wrapWordIndex(i32NumYWords, wordY));
			indices.R[0] = math.floor(wrapWordIndex(i32NumXWords, wordX));
			indices.R[1] = math.floor(wrapWordIndex(i32NumYWords, wordY + 1));
			indices.S[0] = math.floor(wrapWordIndex(i32NumXWords, wordX + 1));
			indices.S[1] = math.floor(wrapWordIndex(i32NumYWords, wordY + 1));

			-- Work out the offsets into the twiddle structs, multiply by two as there are two members per word.
			local WordOffsets = {
				[0] = TwiddleUV(i32NumXWords, i32NumYWords, indices.P[0], indices.P[1]) * 2,
				[1] = TwiddleUV(i32NumXWords, i32NumYWords, indices.Q[0], indices.Q[1]) * 2,
				[2] = TwiddleUV(i32NumXWords, i32NumYWords, indices.R[0], indices.R[1]) * 2,
				[3] = TwiddleUV(i32NumXWords, i32NumYWords, indices.S[0], indices.S[1]) * 2,
			};

			-- Access individual elements to fill out PVRTCWord
			local P, Q, R, S = {}, {}, {}, {};
			P.colorData = pWordMembers:sub(WordOffsets[0] + 1, WordOffsets[0] + 1):byte()
			P.modulationData = pWordMembers:sub(WordOffsets[0], WordOffsets[0]):byte()
			Q.colorData = pWordMembers:sub(WordOffsets[1] + 1, WordOffsets[1] + 1):byte()
			Q.modulationData = pWordMembers:sub(WordOffsets[1], WordOffsets[1]):byte()
			R.colorData = pWordMembers:sub(WordOffsets[2] + 1, WordOffsets[2] + 1):byte()
			R.modulationData = pWordMembers:sub(WordOffsets[2], WordOffsets[2]):byte()
			S.colorData = pWordMembers:sub(WordOffsets[3] + 1, WordOffsets[3] + 1):byte()
			S.modulationData = pWordMembers:sub(WordOffsets[3], WordOffsets[3]):byte()

			-- assemble 4 words into struct to get decompressed pixels from
			pvrtcGetDecompressedPixels(P, Q, R, S, pPixels, bpp);
			mapDecompressedData(pOutData, width, pPixels, indices, bpp);

		end -- for each word
	end -- for each row of words

	-- Return the data size
	return width * height / ((wordWidth / 2));
end

function PVRTDecompressPVRTC(pCompressedData, Do2bitMode, XDim, YDim, pResultImage)
	-- Cast the output buffer to a Pixel32 pointer.
	local pDecompressedData = pResultImage;

	-- Check the X and Y values are at least the minimum size.
	local XTrueDim = math.max(XDim, (Do2bitMode == 1 and 16 or 8));
	local YTrueDim = math.max(YDim, 8);

	-- If the dimensions aren't correct, we need to create a new buffer instead of just using the provided one, as the buffer will overrun otherwise.
	if (XTrueDim ~= XDim or YTrueDim ~= YDim) then pDecompressedData = {}; end

	-- Decompress the surface.
	local retval = pvrtcDecompress(pCompressedData, pDecompressedData, XTrueDim, YTrueDim, Do2bitMode == 1 and 2 or 4);

	local resultstr = ""

	-- If the dimensions were too small, then copy the new buffer back into the output buffer.
	if (XTrueDim ~= XDim or YTrueDim ~= YDim) then
		-- Loop through all the required pixels.
		for x = 0, XDim - 1 do
			-- for y = 0, YDim - 1 do pResultImage[x + y * XDim] = pDecompressedData[x + y * XTrueDim]; end
			for y = 0, YDim - 1 do
				local pixel = pDecompressedData[x + y * XTrueDim]
				pResultImage[x + y * XDim] = pixel
				resultstr = resultstr..string.char(pixel.red)..string.char(pixel.green)..string.char(pixel.blue)..string.char(pixel.alpha)
			end
		end

		-- Free the temporary buffer.
		-- delete[] pDecompressedData;
	else
		for x = 0, XDim - 1 do
			-- for y = 0, YDim - 1 do pResultImage[x + y * XDim] = pDecompressedData[x + y * XTrueDim]; end
			for y = 0, YDim - 1 do
				local pixel = pDecompressedData[x + y * XTrueDim]
				resultstr = resultstr..string.char(pixel.red)..string.char(pixel.green)..string.char(pixel.blue)..string.char(pixel.alpha)
			end
		end
	end
	return retval, resultstr
end

-------------------------------------- ETC Compression --------------------------------------
-- } -- namespace pvr