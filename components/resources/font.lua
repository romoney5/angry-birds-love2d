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
				spritesheet = love.graphics.newImage(convertImagePVR(data, spritesheet))
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
		print("Failed to load font "..fontname)
	end
end

function res.useFont(font)
	if fonts[font] then
		drawfont = font
	end
end

function res.drawString(group, text, x, y, aligny, alignx)
	text = tostring(text) or ""
	if group and group~="" then
		text = res.getString(group,text)
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
		for l in text:gmatch("[^\n]+") do
			local ax, i = 0, 0
			if alignx=="HCENTER" or aligny=="HCENTER" then ax = -res.getStringWidth(l) / 2 end
			if alignx=="RIGHT" or aligny=="RIGHT" then ax = -res.getStringWidth(l) end

			for c in l:gmatch(".") do
				local char = font.chars[string.format("%04x", string.byte(c))]
				if char then
					local charX = (x + i + ax)
					local charY = (y + ay - char.pivoty + (line * font.leading))
					
					love.graphics.draw(font.spritesheet, char.quad, textFloor(charX), textFloor(charY), drawangle)
					i = i + (char.width + font.tracking)
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
	if self.clipped then
		local font = fonts[drawfont]

		love.graphics.translate(0, textFloor(-res.getFontLeading() * (#self.lines - 1) / 2))

		for i, line in ipairs(self.lines) do
			love.graphics.push()
			love.graphics.scale((scale_x or 1) * self.scaleX * hs, (scale_y or 1) * self.scaleY * hs)
			res.drawString(line.group, line.text, 0, 0, line.hanchor, line.vanchor)
			love.graphics.pop()
			love.graphics.translate(0, textFloor(res.getFontLeading()))
		end
	else
		love.graphics.scale((scale_x or 1) * self.scaleX * hs, (scale_y or 1) * self.scaleY * hs)
		res.drawString(self.group, self.text, 0, 0, self.hanchor, self.vanchor)
	end
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.pop()
end

clippedText = {lines = {}, widestLine = 0}
function clipText(group, text, size)
	local font = fonts[drawfont]
	if not font then return end

	clippedText = {lines = {}, widestLine = 0}
	
	local cline = ""
	local clinewidth = 0
	local widestLine = 0
	if group and group ~= "" then
		text = res.getString(group, text)
	end

	local function getWordWidth(word)
		local wordWidth = 0
		for c in word:gmatch(".") do
			local char = font.chars[string.format("%04x", string.byte(c))]
			if char then
				wordWidth = wordWidth + char.width + font.tracking
			end
		end
		return wordWidth - font.tracking
	end

	for word in text:gmatch("%S+%s*") do
		local newlineIndex = word:find("\n")
		if newlineIndex then
			local beforeNewline = word:sub(1, newlineIndex - 1)
			local afterNewline = word:sub(newlineIndex + 1)

			local wordWidth = getWordWidth(beforeNewline)
			if clinewidth + wordWidth > size then
				table.insert(clippedText.lines, cline)
				widestLine = math.max(widestLine, clinewidth)
				cline = beforeNewline
				clinewidth = wordWidth
			else
				cline = cline..beforeNewline
				clinewidth = clinewidth + wordWidth
			end

			table.insert(clippedText.lines, cline)
			widestLine = math.max(widestLine, clinewidth)
			cline = ""
			clinewidth = 0

			word = afterNewline

			while word:find("\n") do
				table.insert(clippedText.lines, "")
				word = word:sub(word:find("\n") + 1)
			end
		end

		local wordWidth = getWordWidth(word)
		if clinewidth + wordWidth > size then
			table.insert(clippedText.lines, cline)
			widestLine = math.max(widestLine, clinewidth)
			cline = word
			clinewidth = wordWidth
		else
			cline = cline..word
			clinewidth = clinewidth + wordWidth
		end
	end

	if cline ~= "" then
		table.insert(clippedText.lines, cline)
		widestLine = math.max(widestLine, clinewidth)
	end
	clippedText.widestLine = widestLine
end

function res.getStringWidth(text, font, _, _, resetline)
	text = text or ""
	local font = fonts[font] or fonts[drawfont]
	if font then
		local highscore = 0
		local i = 0
		for c in text:gmatch(".") do
			local char = font.chars[string.format("%04x", string.byte(c))]
			if char then
				i = i + char.width + font.tracking
				highscore = math.max(highscore, i)
			elseif c == "\n" then
				i = 0
				if resetline then
					highscore = 0
				end
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
	local increment = font and font.leading or (love.graphics.getFont():getHeight() + love.graphics.getFont():getLineHeight())
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