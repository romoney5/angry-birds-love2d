--fonts (if no font is present, a fallback is used)

fonts = {}
textGroups = {}

drawfont = ""

--if the displayscale is not 1, text snapping to pixels is probably more important than non-crisp text
--(the text would be blurry already)
local function textFloor(a)
	if displayScale * love.graphics.getDPIScale() ~= 1 then
		return a
	end

	return math.floor(a)
end

function res.createBitmapFont(font, silent)
	font = datapath.."/"..font
	local fontname = font:match("([^/]+)$"):sub(1, -5)
	if not silent then
		print("Loading font file \""..font.."\"...")
	end
	
	if not checkDirectory(font) then --attempt to use pc font if current doesn't exist
		font = fontPath.."/1024x768/"..font:match("([^/]+)$")
	end

	if checkDirectory(font) then
		if not fonts[fontname] then
			local data = getDatInfo(love.filesystem.read(font), font, "FONT")
			if not data then print("Failed to load font "..fontname) return end
			local spritesheet = data.filename
			local filepath = (font:match("(.+)/[^/]+$") or "").."/"..spritesheet

			if not checkDirectory(filepath) and checkDirectory(filepath..".zip") then
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
			
			if endsWith(spritesheet, ".pvr") then
				-- spritesheet = spritesheet..".png"
				local data = love.filesystem.read(filepath)
				local pvr, w, h = convertImagePVR(data, spritesheet)
				spritesheet = love.graphics.newImage(pvr)
			else
				spritesheet = love.graphics.newImage(filepath)
			end
			
			fonts[fontname] = {leading = data.leading, tracking = data.tracking, spritesheet = spritesheet, chars = {},
				height = data.height, maxascending = data.maxascending, maxdescending = data.maxdescending}

			--for each character, also construct a quad
			for _, char in pairs(data.chars) do
				fonts[fontname].chars[_] = {quad = love.graphics.newQuad(char.x, char.y, char.width, char.height, spritesheet:getWidth(), spritesheet:getHeight()),
					width = char.width, height = char.height, pivoty = char.pivotY}
			end
		elseif not silent then
			print("Font "..fontname.." is already loaded.")
		end
	elseif not silent then
		print("Could not find font "..fontname)
	end
end

function res.useFont(font)
	if fonts[font] then
		drawfont = font
	end
end

function res.drawString(group, text, x, y, aligny, alignx)
	text = tostring(text) or ""
	if group and group ~= "" then
		text = res.getString(group, text)
	end

	local font = fonts[drawfont]
	if font then
		local ay = font.maxascending

		if alignx=="VCENTER" or aligny=="VCENTER" then ay = ay - font.height / 2 end
		if alignx=="BOTTOM" or aligny=="BOTTOM" then ay = ay - font.height end
		if alignx=="BASELINE" or aligny=="BASELINE" then ay = ay - font.maxascending end
		-- if alignx=="TOP" or aligny=="TOP" then ay = ay + font.leading end
		-- text = (alignx or "")..(aligny or "")
		
		local line = 0
		local height = love.graphics.getHeight()
		
		for l in text:gmatch("[^\n]+") do
			local ax, i = 0, 0
			
			--don't calculate the widths and draw everything if it goes off screen
			local _, miny = love.graphics.transformPoint(x + i + ax, (y + ay - font.leading + (line * font.leading)))
			local _, maxy = love.graphics.transformPoint(x + i + ax, (y + ay + font.leading + (line * font.leading)))
			
			if not (miny > height or maxy < 0) then
				if alignx=="HCENTER" or aligny=="HCENTER" then ax = -res.getStringWidth(l) / 2 end
				if alignx=="RIGHT" or aligny=="RIGHT" then ax = -res.getStringWidth(l) end

				for p, c in utf8.codes(l) do
					local char = font.chars[c]
					if char then
						local charX = (x + i + ax)
						local charY = (y + ay - char.pivoty + (line * font.leading))
						
						love.graphics.draw(font.spritesheet, char.quad, textFloor(charX), textFloor(charY), drawangle)
						i = i + (char.width + font.tracking)
					end
				end
			end

			line = line + 1
		end
	else
		--temporarily revert blendmode
		local bm, am = love.graphics.getBlendMode()
		love.graphics.setBlendMode("alpha")
		local ay = 0
		if alignx=="VCENTER" or aligny=="VCENTER" then ay = -res.getFontHeight() / 2 end
		if alignx=="BOTTOM" or aligny=="BOTTOM" then ay = -res.getFontHeight() end
		-- if alignx=="TOP" or aligny=="TOP" then ay=.75 end
		if alignx == "HCENTER" or aligny == "HCENTER" then x = x - res.getStringWidth(text) / 2 end
		if alignx == "RIGHT" or aligny == "RIGHT" then x = x - res.getStringWidth(text) end
		love.graphics.print(text, x, y + ay)
		love.graphics.setBlendMode(bm, am)
	end
	
	-- local bm,am = love.graphics.getBlendMode() love.graphics.setBlendMode("alpha")
	-- love.graphics.print(tostring(aligny)..tostring(alignx).." "..res.getFontHeight(), x, y) love.graphics.setBlendMode(bm,am)
end

--draw 2.0.0 text
function drawUITextNative(self, x, y, scale_x, scale_y, angle, hover_scale)
	local alpha = self.alpha or 1
	local hs = hover_scale or 1
	res.useFont(self.font or "FONT_BASIC")
	love.graphics.push()
	setRenderState(0, 0, 1, 1)
	
	love.graphics.setColor(1 * alpha, 1 * alpha, 1 * alpha, alpha)
	love.graphics.translate(textFloor(self.x * hs + x), textFloor(self.y * hs + y))

	--spans multiple lines
	if self.clipped then
		local font = fonts[drawfont]

		--scaling goes above everything else
		love.graphics.scale((scale_x or 1) * self.scaleX * hs, (scale_y or 1) * self.scaleY * hs)

		for i, line in ipairs(self.lines) do
			love.graphics.push()

			love.graphics.translate(0, textFloor(-res.getFontLeading() * (#self.lines - 1) / 2))
			res.drawString(line.group, line.text, 0, 0, line.hanchor, line.vanchor)

			love.graphics.pop()

			--go to the next line
			love.graphics.translate(0, textFloor(res.getFontLeading()))
		end
	else
		love.graphics.scale((scale_x or 1) * self.scaleX * hs, (scale_y or 1) * self.scaleY * hs)
		res.drawString(self.group, self.text, 0, 0, self.hanchor, self.vanchor)
	end
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.pop()
end

function clipText(group, text, size)
	local font = fonts[drawfont]
	--if not font then return end

	clippedText = {lines = {}, widestLine = 0}
	
	local cline = ""
	local clinewidth = 0
	
	if group and group ~= "" then
		text = res.getString(group, text)
	end

	for word in text:gmatch("%S+%s*") do
		local newline = word:find("\n")
		if newline then
			local preline = word:sub(1, newline - 1)
			local postline = word:sub(newline + 1)

			local wordwidth = res.getStringWidth(preline)
			
			if clinewidth + wordwidth > size then
				table.insert(clippedText.lines, cline)
				clippedText.widestLine = math.max(clippedText.widestLine, clinewidth)
				cline = preline
				clinewidth = wordwidth
			else
				cline = cline..preline
				clinewidth = clinewidth + wordwidth
			end

			table.insert(clippedText.lines, cline)
			clippedText.widestLine = math.max(clippedText.widestLine, clinewidth)
			cline = ""
			clinewidth = 0

			word = postline

			while word:find("\n") do
				table.insert(clippedText.lines, "")
				word = word:sub(word:find("\n") + 1)
			end
		end

		local wordwidth = res.getStringWidth(word)
		if clinewidth + wordwidth > size then
			table.insert(clippedText.lines, cline)
			clippedText.widestLine = math.max(clippedText.widestLine, clinewidth)
			cline = word
			clinewidth = wordwidth
		else
			cline = cline..word
			clinewidth = clinewidth + wordwidth
		end
	end

	if cline ~= "" then
		table.insert(clippedText.lines, cline)
		clippedText.widestLine = math.max(clippedText.widestLine, clinewidth)
	end
end

function res.getStringWidth(text, font, _, _, resetline)
	text = text or ""
	local font = fonts[font] or fonts[drawfont]
	if font then
		local highscore = 0
		local i = 0
		for p, c in utf8.codes(text) do
			local char = font.chars[c]
			if c == "\n" then
				i = 0
				if resetline then
					highscore = 0
				end
			elseif char then
				i = i + char.width + font.tracking
				highscore = math.max(highscore, i)
			end
		end
		return highscore - font.tracking
	else
		local font = love.graphics.getFont()
		return font:getWidth(text) --does not account for line breaks
	end
	-- return 0
	-- return screenWidth*.75
end

--used by console
function res.getStringHeight(text, font, start)
	text = text or ""
	local font = fonts[font or drawfont]
	local increment = font and font.leading or (love.graphics.getFont():getHeight() - .5)
	local i = start and increment or 0
	for c in text:gmatch(".") do
		if c == "\n" then
			i = i + increment
		end
	end
	return i
end

function res.getFontLeading()
	local font = fonts[drawfont]
	if font then return font.leading end
	return 0
end

function res.getFontMaxAscending()
	local font = fonts[drawfont]
	if font then return font.maxascending end
	return 0
end

function res.getFontMaxDescending()
	local font = fonts[drawfont]
	if font then return font.maxdescending end
	return 0
end

function res.getFontHeight()
	local font = fonts[drawfont]
	if font then return font.height end
	return 24
end

--global string functions

function endsWith(str, ending)
	return string.sub(str, -string.len(ending)) == ending
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