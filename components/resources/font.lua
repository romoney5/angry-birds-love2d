--fonts (if no font is present, a fallback is used)

fonts = {}
textGroups = {}

drawfont = ""

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
			if endsWith(spritesheet, ".pvr") then
				-- spritesheet = spritesheet..".png"
				local data = love.filesystem.read(filepath)
				spritesheet = love.graphics.newImage(convertImagePVR(data, spritesheet))
			else
				spritesheet = love.graphics.newImage(filepath)
			end
			
			--TODO last time i checked, some properties are inaccurate to fusion
			fonts[fontname] = {leading = data.leading, tracking = data.tracking, spritesheet = spritesheet, chars = {}, height = data.height - data.mbaseline}

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

--TODO: font y positions are inaccurate
function res.drawString(group, text, x, y, aligny, alignx)
	text = tostring(text) or ""
	if group and group~="" then
		text = res.getString(group,text)
	end

	local font = fonts[drawfont]
	if font then
		local ay = 0
		local h = -font.leading
		
		for l in text:gmatch("[^\n]+") do h = h + font.leading end
		if alignx=="VCENTER" or aligny=="VCENTER" then ay = -h * .75 + res.getFontHeight() * .25 end
		if alignx=="BOTTOM" or aligny=="BOTTOM" then ay = -(h + font.leading) * .5  end
		if alignx=="TOP" or aligny=="TOP" then ay = h + font.leading * .75 end
		
		local line = 0
		local linex = x
		for l in text:gmatch("[^\n]+") do
			local ax, i = 0, 0
			if alignx=="HCENTER" or aligny=="HCENTER" then ax = -res.getStringWidth(l) / 2 end
			if alignx=="RIGHT" or aligny=="RIGHT" then ax = -res.getStringWidth(l) end

			for c in l:gmatch(".") do
				local char = font.chars[string.format("%04x", string.byte(c))]
				if char then
					local charX = (x + i + ax)
					local charY = (y + ay - char.pivoty + (line * font.leading))
					
					love.graphics.draw(font.spritesheet, char.quad, math.floor(charX), math.floor(charY), drawangle)
					i = i + (char.width + font.tracking) --math.floor for crisp text
				end
			end
			line = line + 1
		end
	else
		--temporarily revert blendmode
		local bm, am = love.graphics.getBlendMode()
		love.graphics.setBlendMode("alpha")
		local ay = 0
		if alignx=="VCENTER" or aligny=="VCENTER" then ay = 24 * .75 + res.getFontHeight() * .25 end
		if alignx=="BOTTOM" or aligny=="BOTTOM" then ay = 24 * .5  end
		-- if alignx=="TOP" or aligny=="TOP" then ay=.75 end
		love.graphics.print(text, x, y + ay)
		love.graphics.setBlendMode(bm, am)
	end
	
	-- local bm,am = love.graphics.getBlendMode() love.graphics.setBlendMode("alpha")
	-- love.graphics.print(tostring(aligny)..tostring(alignx).." "..res.getFontHeight(), x, y) love.graphics.setBlendMode(bm,am)
end

--drawstring but more incomplete
function drawUITextNative(self, x, y, scale_x, scale_y, angle, hover_scale)
	-- print(_G.math.floor(self.x + x), _G.math.floor(self.y + y))
	local alpha = self.alpha or 1
	local hs = hover_scale or 1
	res.useFont(self.font or "FONT_BASIC")
	love.graphics.push()
	setRenderState(0, 0, 1, 1)
	-- res.drawString("",self.hanchor..self.vanchor, self.x+x, self.y+y)
	love.graphics.translate(math.floor(self.x * hs + x), math.floor(self.y * hs + y))
	love.graphics.scale(scale_x * self.scaleX * hs, scale_y * self.scaleY * hs)
	-- print(self.font or "FONT_BASIC")
	love.graphics.setColor(1 * alpha, 1 * alpha, 1 * alpha, alpha)
	res.drawString(self.group, self.text, 0, 0, self.hanchor, self.vanchor)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.pop()
end

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

function res.getStringWidth(text, font)
	text = text or ""
	local font = fonts[font or drawfont]
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
			end
		end
		return highscore
	else
		local font = love.graphics.getFont()
		return font:getWidth(text)
	end
	-- return 0
	-- return screenWidth*.75
end

function res.getFontLeading()
	local font = fonts[drawfont]
	if font then return font.leading end
	return 0
end

function res.getFontMaxAscending()
	local font = fonts[drawfont]
	if font then return font.leading end
	return 0
end

function res.getFontMaxDescending()
	local font = fonts[drawfont]
	if font then return -font.leading end
	return 0
end

function res.getFontHeight()
	local font = fonts[drawfont]
	if font then return font.height end
	return 24
end