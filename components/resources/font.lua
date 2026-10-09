--fonts (if no font is present, a fallback is used)

local fonts = {}

local usingBMFont = false

--if the displayscale is not 1, text snapping to pixels is probably more important than non-crisp text
--(the text would be blurry already)
local function textFloor(a)
	if displayScale * love.graphics.getDPIScale() ~= 1 then
		return a
	end

	return math.floor(a)
end

--generate (part of) a bmfont metadata for use in newFont
--https://www.angelcode.com/products/bmfont/doc/file_format.html
function generateBMFont(font, imagedata)
	local out = ""
	
	--block 1, info
	out = out..("info ") --identifier
	out = out..("unicode=%s "):format(1) --is unicode
	
	--block 2, common
	out = out..("\n")
	out = out..("common ") --identifier
	out = out..("lineHeight=%s "):format(font.height) --line height in pixels
	out = out..("base=%s "):format(font.maxascending) --distance from line top to baseline (base)
	out = out..("scaleW=%s "):format(imagedata:getWidth()) --texture width
	out = out..("scaleH=%s "):format(imagedata:getHeight()) --texture height
	out = out..("pages=%s "):format(1) --amount of pages
	
	--we don't need pages
	
	--block 4, characters
	out = out..("\n")
	out = out..("chars ") --identifier
	
	local amount = 0
	
	for i, char in pairs(font.chars) do
		amount = amount + 1
	end
	
	out = out..("count=%s "):format(amount) --chars amount
	
	for i, char in pairs(font.chars) do
		out = out..("\n")
		out = out..("char ") --identifier
		out = out..("id=%s "):format(i) --char id
		out = out..("x=%s "):format(char.x) --char x
		out = out..("y=%s "):format(char.y) --char y
		out = out..("width=%s "):format(char.width) --char width
		out = out..("height=%s "):format(char.height) --char height
		out = out..("xoffset=%s "):format(0) --char x offset
		out = out..("yoffset=%s "):format(-char.baseline) --char y offset
		out = out..("xadvance=%s "):format(char.width + font.tracking) --char x advance
		out = out..("page=%s "):format(0) --char page number
		out = out..("chnl=%s "):format(15) --char channels
	end
	
	--we don't need kerning pairs
	
	local filedata = love.filesystem.newFileData(out, "font.bmfont")
	
	--re-encode the image data into rgba8 since love2d requires it for bmfonts
	local new_imagedata = love.image.newImageData(imagedata:getWidth(), imagedata:getHeight(), "rgba8")
	new_imagedata:paste(imagedata, 0, 0, 0, 0, imagedata:getWidth(), imagedata:getHeight())
	
	local newfont = love.graphics.newFont(filedata, new_imagedata)
	
	--set the line height manually
	newfont:setLineHeight(font.leading)
	
	return newfont
end

function res.createBitmapFont(font, silent)
	font = datapath.."/"..font
	local fontname = font:match("([^/]+)$"):sub(1, -5)
	
	print("Loading font file \""..font.."\"...")
	
	--find it case-insensitively
	font = findCaseInsensitive(font) or font

	if love.filesystem.exists(font) then
		if not fonts[fontname] then
			local data = getDatInfo(love.filesystem.read(font), font, "FONT")
			if not data then print("Failed to load font "..fontname) return end
			local spritesheet = data.filename
			local filepath = (font:match("(.+)/[^/]+$") or "").."/"..spritesheet

			if not love.filesystem.exists(filepath) and love.filesystem.exists(filepath..".zip") then
				--android versions also like to zip some fonts
				local zip = filepath..".zip"
				local src = love.filesystem.newFileData(zip)
				local success = love.filesystem.mount(src, zip)

				if success then
					--get the given font's base directory
					local _, parentDir = resolvePath(font)
					parentDir = table.concat(parentDir, "/", 2, #parentDir - 1)

					--and append the real filename to it before passing in the real path
					local newname, paths = findCaseInsensitive(zip.."/"..parentDir.."/"..data.filename)
					if not newname then
						newname, paths = findCaseInsensitive(zip.."/"..data.filename)
					end
					
					filepath = newname
				else
					--or it didn't even work
					print("createBitmapFont: could not unzip "..zip)
				end
			end
			
			if not filepath or not love.filesystem.exists(filepath) then
				print("Failed to find font "..font)
				
				return
			end
			
			local imagedata
			
			if endsWith(spritesheet, ".pvr") then
				-- spritesheet = spritesheet..".png"
				local data = love.filesystem.read(filepath)
				local pvr, w, h = convertImagePVR(data, spritesheet)
				
				imagedata = pvr
			else
				imagedata = love.image.newImageData(filepath)
			end
			
			--bmfont
			fonts[fontname] = generateBMFont(data, imagedata)
		else
			print("Font "..fontname.." is already loaded")
		end
	else
		print("Could not find font "..fontname)
	end
end

function res.releaseFont(font)
	font = datapath.."/"..font
	local fontname = font:match("([^/]+)$"):sub(1, -5)
	
	if fonts[fontname] then
		fonts[fontname]:release()
		fonts[fontname] = nil
	end
end

function res.useFont(font)
	if not fonts[font] then
		love.graphics.setFont(default_font)
		usingBMFont = false
		
		return
	end

	love.graphics.setFont(fonts[font])
	usingBMFont = true
end

function res.drawString(group, text, x, y, aligny, alignx)
	text = tostring(text)
	
	if group then
		text = res.getString(group, text)
	end

	love.graphics.push("all")
	
	local font = love.graphics.getFont()
	
	--temporarily revert blendmode for normal fonts, otherwise they appear as white squares
	if not usingBMFont then
		love.graphics.setBlendMode("alpha")
		
		--also reposition the text
		y = y - font:getBaseline()
	end
	
	local ay = 0
	--if alignx=="BASELINE" or aligny=="BASELINE" then ay = 0 end
	if alignx=="VCENTER" or aligny=="VCENTER" then ay = font:getBaseline() - font:getHeight() / 2 end
	if alignx=="BOTTOM" or aligny=="BOTTOM" then ay = font:getBaseline() / 2 - font:getHeight() end
	if alignx=="TOP" or aligny=="TOP" then ay = font:getBaseline() end
	
	if alignx == "HCENTER" or aligny == "HCENTER" then x = x - res.getStringWidth(text) / 2 end
	if alignx == "RIGHT" or aligny == "RIGHT" then x = x - res.getStringWidth(text) end
	
	love.graphics.print(text, x, y + ay)
	love.graphics.pop()
end

--draw 2.0.0 text
function gamelua.drawUITextNative(self, x, y, scale_x, scale_y, angle, hover_scale)
	local alpha = self.alpha or 1
	local hs = hover_scale or 1
	
	local height = self:getFontLeading()
	
	res.useFont(self.font or "FONT_BASIC")
	love.graphics.push()
	gamelua.setRenderState(0, 0, 1, 1)
	
	love.graphics.setColor(1 * alpha, 1 * alpha, 1 * alpha, alpha)
	love.graphics.translate(textFloor((self.x or 0) * hs + x), textFloor((self.y or 0) * hs + y))

	--spans multiple lines
	if self.clipped then
		--scaling goes above everything else
		love.graphics.scale((scale_x or 1) * self.scaleX * hs, (scale_y or 1) * self.scaleY * hs)
		
		if self.hanchor == "VCENTER" or self.vanchor == "VCENTER" then
			love.graphics.translate(0, textFloor(-height * (#self.lines - 1) / 2))
		end

		for i, line in ipairs(self.lines) do
			res.drawString(line.group, line.text, 0, 0, line.hanchor, line.vanchor)

			--go to the next line
			love.graphics.translate(0, textFloor(height))
		end
	else
		love.graphics.scale((scale_x or 1) * self.scaleX * hs, (scale_y or 1) * self.scaleY * hs)
		res.drawString(self.group, self.text, 0, 0, self.hanchor, self.vanchor)
	end
	
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.pop()
end

function gamelua.clipText(group, text, size)
	local font = love.graphics.getFont()

	if group then
		text = res.getString(group, text)
	end

	local widestLine, lines = font:getWrap(text, size)

	gamelua.clippedText = {widestLine = widestLine, lines = lines}
end

function res.getStringWidth(text)
	local font = love.graphics.getFont()
	return font:getWidth(text)
end

--used by console
function res.getStringHeight(text, font, start)
	text = text or ""
	local increment = love.graphics.getFont():getHeight() - .5
	local i = increment * (text:getLines() + (start and 0 or -1))
	
	return i
end

function res.getFontLeading()
	local font = love.graphics.getFont()
	return font:getLineHeight()
end

function res.getFontMaxAscending()
	local font = love.graphics.getFont()
	return font:getAscent()
end

function res.getFontMaxDescending()
	local font = love.graphics.getFont()
	return font:getDescent()
end

function res.getFontHeight()
	local font = love.graphics.getFont()
	return font:getHeight()
end

--global string functions

function endsWith(str, ending)
	return str:sub(-ending:len()) == ending
end

--custom function, returns total amount of lines
function string.getLines(str)
	local _, newlines = str:gsub("\n", "")
	
	return newlines + 1
end

function string.insert(str1, str2, pos)
	--[[local len = utf8.len(str1, 1, pos)
	return str1:sub(1, len)..str2..str1:sub(len + 1)]]
	local final = ""
	local amount = 0
	if pos == 0 then
		return str2..str1
	end
	
	for p, c in utf8.codes(str1) do
		amount = amount + 1
		final = final..utf8.char(c)
		
		if amount == pos then
			final = final..str2
		end
	end
	
	return final
end

function string.back(str1, pos)
	--[[pos = pos + 1
	if pos <= 1 or pos > #str1 + 1 then
		return str1
	end
	return str1:sub(1, pos - 2)..str1:sub(pos)]]
	local final = ""
	local amount = 0
	
	for p, c in utf8.codes(str1) do
		amount = amount + 1
		
		if amount ~= pos then
			final = final..utf8.char(c)
		end
	end
	
	return final
end

function string.getLineAt(text, cursor)
	local len = 0
	local last = ""
	local lines = 0
	
	for line in text:gmatch("[^\n]+") do
		len = len + line:len()
		lines = lines + 1
		
		if cursor < 0 then
			last = line
		elseif cursor <= len then
			return line, lines
		end
	end
	
	if text:sub(text:len(), text:len()) == "\n" then
		return "", lines
	end
	
	return last, lines
end

--string.sub but respects utf8, from https://love2d.org/wiki/TextInputField

function utf8.sub(s, i, j)
	if not s then return "" end
	local len = utf8.len(s) or 0
	i = i or 1
	j = j or len
	if i < 0 then i = len + i + 1 end
	if j < 0 then j = len + j + 1 end
	if i < 1 then i = 1 end
	if j > len then j = len end
	if i > j then return "" end
	local startByte = utf8.offset(s, i)
	local endByte = utf8.offset(s, j + 1)
	return string.sub(s, startByte, endByte and endByte - 1 or -1)
end