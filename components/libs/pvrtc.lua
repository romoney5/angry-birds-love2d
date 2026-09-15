--decompress the mystical pvrtc format
--direct translation from https://github.com/powervr-graphics/Native_SDK/blob/master/framework/PVRCore/texture/PVRTDecompress.cpp

--not even ffi is present?
if not jit then
	return
end

--https://love2d.org/forums/viewtopic.php?t=94270
--https://stackoverflow.com/questions/1675351/typedef-struct-vs-struct-definitions
ffi.cdef
[[

enum
{
	ETC_MIN_TEXWIDTH = 4,
	ETC_MIN_TEXHEIGHT = 4,
	DXT_MIN_TEXWIDTH = 4,
	DXT_MIN_TEXHEIGHT = 4,
};

struct Pixel32
{
	uint8_t red, green, blue, alpha;
};

struct Pixel128S
{
	int32_t red, green, blue, alpha;
};

struct PVRTCWord
{
	uint32_t modulationData;
	uint32_t colorData;
};

struct PVRTCWordIndices
{
	int P[2], Q[2], R[2], S[2];
};

typedef struct Pixel32 Pixel32;
typedef struct Pixel128S Pixel128S;
typedef struct PVRTCWord PVRTCWord;
typedef struct PVRTCWordIndices PVRTCWordIndices;

]]

--note: a subtle difference between c and lua is how c considers if (0) to be false,
--while lua considers if (0) to be true
--also watch the ^ operators as lua uses them for exponentiation, not xor

local function --[[Pixel32]] getColorA(--[[uint32_t]] colorData)
	local color = ffi.new("Pixel32")

	-- Opaque Color Mode - RGB 554
	if ((colorData & 0x8000) ~= 0) then
		color.red = ((colorData & 0x7c00) >> 10); -- 5->5 bits
		color.green = ((colorData & 0x3e0) >> 5); -- 5->5 bits
		color.blue = (colorData & 0x1e) | ((colorData & 0x1e) >> 4); -- 4->5 bits
		color.alpha = (0xf); -- 0->4 bits
	-- Transparent Color Mode - ARGB 3443
	else
		color.red = ((colorData & 0xf00) >> 7) | ((colorData & 0xf00) >> 11); -- 4->5 bits
		color.green = ((colorData & 0xf0) >> 3) | ((colorData & 0xf0) >> 7); -- 4->5 bits
		color.blue = ((colorData & 0xe) << 1) | ((colorData & 0xe) >> 2); -- 3->5 bits
		color.alpha = ((colorData & 0x7000) >> 11); -- 3->4 bits - note 0 at right
	end

	return color
end

local function --[[Pixel32]] getColorB(--[[uint32_t]] colorData)
	local color = ffi.new("Pixel32")

	-- Opaque Color Mode - RGB 555
	if ((colorData & 0x80000000) ~= 0) then
		color.red = ((colorData & 0x7c000000) >> 26); -- 5->5 bits
		color.green = ((colorData & 0x3e00000) >> 21); -- 5->5 bits
		color.blue = ((colorData & 0x1f0000) >> 16); -- 5->5 bits
		color.alpha = (0xf); -- 0 bits
	-- Transparent Color Mode - ARGB 3444
	else
		color.red = (((colorData & 0xf000000) >> 23) | ((colorData & 0xf000000) >> 27)); -- 4->5 bits
		color.green = (((colorData & 0xf00000) >> 19) | ((colorData & 0xf00000) >> 23)); -- 4->5 bits
		color.blue = (((colorData & 0xf0000) >> 15) | ((colorData & 0xf0000) >> 19)); -- 4->5 bits
		color.alpha = ((colorData & 0x70000000) >> 27); -- 3->4 bits - note 0 at right
	end

	return color
end

--local function --[[void]] interpolateColors(Pixel32 P, Pixel32 Q, Pixel32 R, Pixel32 S, Pixel128S* pPixel, uint8_t bpp)
local function --[[void]] interpolateColors(P, Q, R, S, --[[Pixel128S*]] pPixel, bpp)
	local wordWidth = 4
	local wordHeight = 4
	if (bpp == 2) then wordWidth = 8; end

	-- Convert to int 32.
	--Pixel128S
	local hP = ffi.new("Pixel128S", (P.red), (P.green), (P.blue), (P.alpha));
	local hQ = ffi.new("Pixel128S", (Q.red), (Q.green), (Q.blue), (Q.alpha));
	local hR = ffi.new("Pixel128S", (R.red), (R.green), (R.blue), (R.alpha));
	local hS = ffi.new("Pixel128S", (S.red), (S.green), (S.blue), (S.alpha));

	-- Get vectors.
	local QminusP = ffi.new("Pixel128S", hQ.red - hP.red, hQ.green - hP.green, hQ.blue - hP.blue, hQ.alpha - hP.alpha);
	local SminusR = ffi.new("Pixel128S", hS.red - hR.red, hS.green - hR.green, hS.blue - hR.blue, hS.alpha - hR.alpha);

	-- Multiply colors.
	hP.red *= wordWidth;
	hP.green *= wordWidth;
	hP.blue *= wordWidth;
	hP.alpha *= wordWidth;
	hR.red *= wordWidth;
	hR.green *= wordWidth;
	hR.blue *= wordWidth;
	hR.alpha *= wordWidth;

	if (bpp == 2) then
		-- Loop through pixels to achieve results.
		for x = 0, wordWidth - 1 do
			local result = ffi.new("Pixel128S", 4 * hP.red, 4 * hP.green, 4 * hP.blue, 4 * hP.alpha);
			local dY = ffi.new("Pixel128S", hR.red - hP.red, hR.green - hP.green, hR.blue - hP.blue, hR.alpha - hP.alpha);

			for y = 0, wordHeight - 1 do
				pPixel[y * wordWidth + x].red = ((result.red >> 7) + (result.red >> 2));
				pPixel[y * wordWidth + x].green = ((result.green >> 7) + (result.green >> 2));
				pPixel[y * wordWidth + x].blue = ((result.blue >> 7) + (result.blue >> 2));
				pPixel[y * wordWidth + x].alpha = ((result.alpha >> 5) + (result.alpha >> 1));

				result.red += dY.red;
				result.green += dY.green;
				result.blue += dY.blue;
				result.alpha += dY.alpha;
			end

			hP.red += QminusP.red;
			hP.green += QminusP.green;
			hP.blue += QminusP.blue;
			hP.alpha += QminusP.alpha;

			hR.red += SminusR.red;
			hR.green += SminusR.green;
			hR.blue += SminusR.blue;
			hR.alpha += SminusR.alpha;
		end
	else
		-- Loop through pixels to achieve results.
		for y = 0, wordHeight - 1 do
			local result = ffi.new("Pixel128S", 4 * hP.red, 4 * hP.green, 4 * hP.blue, 4 * hP.alpha);
			local dY = ffi.new("Pixel128S", hR.red - hP.red, hR.green - hP.green, hR.blue - hP.blue, hR.alpha - hP.alpha);

			for x = 0, wordWidth - 1 do
				pPixel[y * wordWidth + x].red = ((result.red >> 6) + (result.red >> 1));
				pPixel[y * wordWidth + x].green = ((result.green >> 6) + (result.green >> 1));
				pPixel[y * wordWidth + x].blue = ((result.blue >> 6) + (result.blue >> 1));
				pPixel[y * wordWidth + x].alpha = ((result.alpha >> 4) + (result.alpha));

				result.red += dY.red;
				result.green += dY.green;
				result.blue += dY.blue;
				result.alpha += dY.alpha;
			end

			hP.red += QminusP.red;
			hP.green += QminusP.green;
			hP.blue += QminusP.blue;
			hP.alpha += QminusP.alpha;

			hR.red += SminusR.red;
			hR.green += SminusR.green;
			hR.blue += SminusR.blue;
			hR.alpha += SminusR.alpha;
		end
	end
end

--local function void unpackModulations(const PVRTCWord& word, int32_t offsetX, int32_t offsetY, int32_t modulationValues[16][8], int32_t modulationModes[16][8], uint8_t bpp)
local function unpackModulations(word, offsetX, offsetY, modulationValues, modulationModes, bpp)
	local WordModMode = word.colorData & 0x1;
	local ModulationBits = word.modulationData;

	-- Unpack differently depending on 2bpp or 4bpp modes.
	if (bpp == 2) then
		if (WordModMode ~= 0) then
			-- determine which of the three modes are in use:

			-- If this is the either the H-only or V-only interpolation mode...
			if (ModulationBits & 0x1 ~= 0) then
				-- look at the "LSB" for the "centre" (V=2,H=4) texel. Its LSB is now
				-- actually used to indicate whether it's the H-only mode or the V-only...

				-- The centre texel data is the at (y==2, x==4) and so its LSB is at bit 20.
				if (ModulationBits & (0x1 << 20) ~= 0) then
					-- This is the V-only mode
					WordModMode = 3;
				else
					-- This is the H-only mode
					WordModMode = 2;
				end

				-- Create an extra bit for the centre pixel so that it looks like
				-- we have 2 actual bits for this texel. It makes later coding much easier.
				if (ModulationBits & (0x1 << 21) ~= 0) then
					-- set it to produce code for 1.0
					ModulationBits |= (0x1 << 20);
				else
					-- clear it to produce 0.0 code
					ModulationBits &= ~(0x1 << 20);
				end
			end -- end if H-Only or V-Only interpolation mode was chosen

			if (ModulationBits & 0x2 ~= 0) then ModulationBits |= 0x1; --[set it]]
			else
				ModulationBits &= ~0x1; --[[clear it]]
			end

			-- run through all the pixels in the block. Note we can now treat all the
			-- "stored" values as if they have 2bits (even when they didn't!)
			for y = 0, 4 - 1 do
				for x = 0, 8 - 1 do
					modulationModes[(x + offsetX)][(y + offsetY)] = WordModMode;

					-- if this is a stored value...
					if (((x ~ y) & 1) == 0) then modulationValues[static_cast<uint32_t>(x + offsetX)][static_cast<uint32_t>(y + offsetY)] = ModulationBits & 3;
						ModulationBits >>= 2;
					end
				end
			end -- end for y
		-- else if direct encoded 2bit mode - i.e. 1 mode bit per pixel
		else
			for y = 0, 4 - 1 do
				for x = 0, 8 - 1 do
					modulationModes[(x + offsetX)][(y + offsetY)] = WordModMode;

					--[[
					// double the bits so 0=> 00, and 1=>11
					]]
					if (ModulationBits & 1 ~= 0) then modulationValues[static_cast<uint32_t>(x + offsetX)][static_cast<uint32_t>(y + offsetY)] = 0x3;
					else
						modulationValues[(x + offsetX)][(y + offsetY)] = 0x0;
					end
					ModulationBits >>= 1;
				end
			end -- end for y
		end
	else
		-- Much simpler than the 2bpp decompression, only two modes, so the n/8 values are set directly.
		-- run through all the pixels in the word.
		if (WordModMode ~= 0) then
			for y = 0, 4 - 1 do
				for x = 0, 4 - 1 do
					modulationValues[(y + offsetY)][(x + offsetX)] = ModulationBits & 3;
					-- if (modulationValues==0) {}. We don't need to check 0, 0 = 0/8.
					if (modulationValues[(y + offsetY)][(x + offsetX)] == 1) then
						modulationValues[(y + offsetY)][(x + offsetX)] = 4;
					elseif (modulationValues[(y + offsetY)][(x + offsetX)] == 2) then
						modulationValues[(y + offsetY)][(x + offsetX)] = 14; --+10 tells the decompressor to punch through alpha.
					elseif (modulationValues[(y + offsetY)][(x + offsetX)] == 3) then
						modulationValues[(y + offsetY)][(x + offsetX)] = 8;
					end
					ModulationBits >>= 2;
				end -- end for x
			end -- end for y
		else
			for y = 0, 4 - 1 do
				for x = 0, 4 - 1 do
					modulationValues[(y + offsetY)][(x + offsetX)] = ModulationBits & 3;
					modulationValues[(y + offsetY)][(x + offsetX)] *= 3;
					if (modulationValues[(y + offsetY)][(x + offsetX)] > 3) then
						modulationValues[(y + offsetY)][(x + offsetX)] -= 1;
					end
					ModulationBits >>= 2;
				end -- end for x
			end -- end for y
		end
	end
end

--static int32_t getModulationValues(int32_t modulationValues[16][8], int32_t modulationModes[16][8], uint32_t xPos, uint32_t yPos, uint8_t bpp)
local function getModulationValues(modulationValues, modulationModes, xPos, yPos, bpp)
	if (bpp == 2) then
		local RepVals0 = ffi.new("int32_t[4]", 0, 3, 5, 8);

		-- extract the modulation value. If a simple encoding
		if (modulationModes[xPos][yPos] == 0) then return RepVals0[modulationValues[xPos][yPos]];
		else
			-- if this is a stored value
			if (((xPos ~ yPos) & 1) == 0) then return RepVals0[modulationValues[xPos][yPos]];

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

--local function void pvrtcGetDecompressedPixels(const PVRTCWord& P, const PVRTCWord& Q, const PVRTCWord& R, const PVRTCWord& S, Pixel32* pColorData, uint8_t bpp)
local function pvrtcGetDecompressedPixels(P, Q, R, S, pColorData, bpp)
	-- 4bpp only needs 8*8 values, but 2bpp needs 16*8, so rather than wasting processor time we just statically allocate 16*8.
	local modulationValues = ffi.new("uint32_t[16][8]");
	-- Only 2bpp needs this.
	local modulationModes = ffi.new("uint32_t[16][8]");
	-- 4bpp only needs 16 values, but 2bpp needs 32, so rather than wasting processor time we just statically allocate 32.
	local upscaledColorA = ffi.new("Pixel128S[32]");
	local upscaledColorB = ffi.new("Pixel128S[32]");

	local wordWidth = 4;
	local wordHeight = 4;
	if (bpp == 2) then wordWidth = 8; end

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
			local mod = getModulationValues(modulationValues, modulationModes, x + wordWidth / 2, y + wordHeight / 2, bpp);
			local punchthroughAlpha = false;
			if (mod > 10) then
				punchthroughAlpha = true;
				mod -= 10;
			end

			local result = ffi.new("Pixel128S");
			result.red = (upscaledColorA[y * wordWidth + x].red * (8 - mod) + upscaledColorB[y * wordWidth + x].red * mod) / 8;
			result.green = (upscaledColorA[y * wordWidth + x].green * (8 - mod) + upscaledColorB[y * wordWidth + x].green * mod) / 8;
			result.blue = (upscaledColorA[y * wordWidth + x].blue * (8 - mod) + upscaledColorB[y * wordWidth + x].blue * mod) / 8;
			if (punchthroughAlpha) then result.alpha = 0;
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

--local function uint32_t wrapWordIndex(uint32_t numWords, int word) { return ((word + numWords) % numWords); }
local function wrapWordIndex(numWords, word) return ((word + numWords) % numWords); end

--local function bool isPowerOf2(uint32_t input)
local function isPowerOf2(input)
	local minus1;

	if (input == 0) then return 0; end

	minus1 = input - 1;
	return ((input | minus1) == (input ~ minus1));
end

--local function uint32_t TwiddleUV(uint32_t XSize, uint32_t YSize, uint32_t XPos, uint32_t YPos)
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
		if (YPos & SrcBitPos ~= 0) then Twiddled |= DstBitPos; end

		if (XPos & SrcBitPos ~= 0) then Twiddled |= (DstBitPos << 1); end

		SrcBitPos <<= 1;
		DstBitPos <<= 2;
		ShiftCount += 1;
	end

	-- Prepend any unused bits
	MaxValue >>= ShiftCount;
	Twiddled |= (MaxValue << (2 * ShiftCount));

	return Twiddled;
end

--local function void mapDecompressedData(Pixel32* pOutput, uint32_t width, const Pixel32* pWord, const PVRTCWordIndices& words, uint8_t bpp)
local function mapDecompressedData(pOutput, width, pWord, words, bpp)
	local wordWidth = 4;
	local wordHeight = 4;
	if (bpp == 2) then wordWidth = 8; end

	for y = 0, wordHeight / 2 - 1 do
		for x = 0, wordWidth / 2 - 1 do
			--[[
			]]
			pOutput[(((words.P[1] * wordHeight) + y + wordHeight / 2) * width + words.P[0] * wordWidth + x + wordWidth / 2)] = pWord[y * wordWidth + x]; -- map P

			pOutput[(((words.Q[1] * wordHeight) + y + wordHeight / 2) * width + words.Q[0] * wordWidth + x)] = pWord[y * wordWidth + x + wordWidth / 2]; -- map Q

			pOutput[(((words.R[1] * wordHeight) + y) * width + words.R[0] * wordWidth + x + wordWidth / 2)] = pWord[(y + wordHeight / 2) * wordWidth + x]; -- map R

			pOutput[(((words.S[1] * wordHeight) + y) * width + words.S[0] * wordWidth + x)] = pWord[(y + wordHeight / 2) * wordWidth + x + wordWidth / 2]; -- map S
		end
	end
end
--local function uint32_t pvrtcDecompress(uint8_t* pCompressedData, Pixel32* pDecompressedData, uint32_t width, uint32_t height, uint8_t bpp)
local function pvrtcDecompress(pCompressedData, pDecompressedData, width, height, bpp)
	local wordWidth = 4;
	local wordHeight = 4;
	if (bpp == 2) then wordWidth = 8; end

	--uint32_t* pWordMembers = (uint32_t*)pCompressedData;
	--Pixel32* pOutData = pDecompressedData;
	local pWordMembers = ffi.cast("uint32_t *", pCompressedData); --no cast?
	local pOutData = ffi.cast("Pixel32 *", pDecompressedData);

	-- Calculate number of words
	local i32NumXWords = math.floor(width / wordWidth);
	local i32NumYWords = math.floor(height / wordHeight);

	-- Structs used for decompression
	local indices = ffi.new("PVRTCWordIndices");
	--std::vector<Pixel32> pPixels(wordWidth * wordHeight * sizeof(Pixel32));
	local pPixels = ffi.new("Pixel32[?]", wordWidth * wordHeight); --?

	-- For each row of words
	for wordY = -1, i32NumYWords - 1 - 1 do
		-- for each column of words
		for wordX = -1, i32NumXWords - 1 do
			indices.P[0] = (wrapWordIndex(i32NumXWords, wordX));
			indices.P[1] = (wrapWordIndex(i32NumYWords, wordY));
			indices.Q[0] = (wrapWordIndex(i32NumXWords, wordX + 1));
			indices.Q[1] = (wrapWordIndex(i32NumYWords, wordY));
			indices.R[0] = (wrapWordIndex(i32NumXWords, wordX));
			indices.R[1] = (wrapWordIndex(i32NumYWords, wordY + 1));
			indices.S[0] = (wrapWordIndex(i32NumXWords, wordX + 1));
			indices.S[1] = (wrapWordIndex(i32NumYWords, wordY + 1));

			-- Work out the offsets into the twiddle structs, multiply by two as there are two members per word.
			local WordOffsets = ffi.new("uint32_t[4]",
				TwiddleUV(i32NumXWords, i32NumYWords, indices.P[0], indices.P[1]) * 2,
				TwiddleUV(i32NumXWords, i32NumYWords, indices.Q[0], indices.Q[1]) * 2,
				TwiddleUV(i32NumXWords, i32NumYWords, indices.R[0], indices.R[1]) * 2,
				TwiddleUV(i32NumXWords, i32NumYWords, indices.S[0], indices.S[1]) * 2
			)

			-- Access individual elements to fill out PVRTCWord
			--PVRTCWord P, Q, R, S;
			local P, Q, R, S = ffi.new("PVRTCWord"), ffi.new("PVRTCWord"), ffi.new("PVRTCWord"), ffi.new("PVRTCWord");
			P.colorData = (pWordMembers[WordOffsets[0] + 1]);
			P.modulationData = (pWordMembers[WordOffsets[0]]);
			Q.colorData = (pWordMembers[WordOffsets[1] + 1]);
			Q.modulationData = (pWordMembers[WordOffsets[1]]);
			R.colorData = (pWordMembers[WordOffsets[2] + 1]);
			R.modulationData = (pWordMembers[WordOffsets[2]]);
			S.colorData = (pWordMembers[WordOffsets[3] + 1]);
			S.modulationData = (pWordMembers[WordOffsets[3]]);

			-- assemble 4 words into struct to get decompressed pixels from
			pvrtcGetDecompressedPixels(P, Q, R, S, pPixels--[[.data()]], bpp);
			mapDecompressedData(pOutData, width, pPixels--[[.data()]], indices, bpp);

		end -- for each word
	end -- for each row of words
	
	--if true then return end

	-- Return the data size
	return width * height / math.floor((wordWidth / 2));
end

--local function uint32_t PVRTDecompressPVRTC(const void* pCompressedData, uint32_t Do2bitMode, uint32_t XDim, uint32_t YDim, uint8_t* pResultImage)
local function PVRTDecompressPVRTC(pCompressedData, Do2bitMode, XDim, YDim, pResultImage)
	-- Cast the output buffer to a Pixel32 pointer.
	--Pixel32* pDecompressedData = (Pixel32*)pResultImage;
	local pDecompressedData = pResultImage;

	-- Check the X and Y values are at least the minimum size.
	local XTrueDim = math.max(XDim, ((Do2bitMode == 1) ? 16 : 8));
	local YTrueDim = math.max(YDim, 8);

	-- If the dimensions aren't correct, we need to create a new buffer instead of just using the provided one, as the buffer will overrun otherwise.
	if (XTrueDim ~= XDim or YTrueDim ~= YDim) then error() --[[pDecompressedData = new Pixel32[XTrueDim * YTrueDim];]] end

	-- Decompress the surface.
	--local retval = pvrtcDecompress((uint8_t*)pCompressedData, pDecompressedData, XTrueDim, YTrueDim, uint8_t(Do2bitMode == 1 ? 2 : 4));
	local retval = pvrtcDecompress(pCompressedData, pDecompressedData, XTrueDim, YTrueDim, (Do2bitMode == 1 and 2 or 4));

	-- If the dimensions were too small, then copy the new buffer back into the output buffer.
	if (XTrueDim ~= XDim or YTrueDim ~= YDim) then
		-- Loop through all the required pixels.
		for x = 0, XDim - 1 do--(uint32_t x = 0; x < XDim; ++x)
			--for (uint32_t y = 0; y < YDim; ++y) { ((Pixel32*)pResultImage)[x + y * XDim] = pDecompressedData[x + y * XTrueDim]; }
			for y = 0, YDim - 1 do (pResultImage)[x + y * XDim] = pDecompressedData[x + y * XTrueDim]; end
		end

		-- Free the temporary buffer.
		--delete[] pDecompressedData;
	end
	
	return retval
end

return {PVRTDecompressPVRTC = PVRTDecompressPVRTC}
