--resources: graphics and sprites

drawxp, drawyp = 0, 0
drawangle = 0
alpha = 1

cachedcs = {} --individual composprites
cachedimgs = {} --individual sprites

function getBGColor() --not used, but i found it in ghidra
	return love.graphics.getBackgroundColor()
end
function setBGColor(r, g, b) --set the background color
	love.graphics.setBackgroundColor(r / 255, g / 255, b / 255)
end

--quite literally used everywhere
function setRenderState(x, y, xs, ys, angle, xp, yp)
	love.graphics.origin()
	love.graphics.scale(xs, ys)
	love.graphics.scale(displayScale)
	love.graphics.translate(x, y)

	drawangle = angle or 0
	--drawxp and yp are exclusively used for rotation, they are useless when angle is 0
	drawxp = xp or 0
	drawyp = yp or 0
end

--frontend of drawsprite
function res.drawSprite(sheet, sprite, x, y, vanchor, hanchor, iwidth, iheight, nopma) --nopma = no premultiply alpha
	if tonumber(sprite) then --sprite, x, y, etc.
		sheet, sprite, x, y, vanchor, hanchor, iwidth, iheight, nopma = "", sheet, sprite, x, y, vanchor, hanchor, iwidth, iheight
	end
	drawSprite(sheet, sprite, x, y, vanchor, hanchor, iwidth, iheight, nopma)
end

function res.drawCompoSprite(sheet, sprite, x, y)
	if tonumber(sprite) and not y then
		sprite, x, y = sheet, sprite, x
	end
	
	local image = checkSprite(sprite)

	if image then
		for i,v in ipairs(image.items) do
			res.drawSprite(v.n, math.floor(x + v.x), math.floor(y + v.y))
		end
	end
end

function res.setClipRect(x1, y1, x2, y2)
	x1, y1, x2, y2 = math.max(x1 or 0, 0), math.max(y1 or 0, 0), math.max(x2 or 0, 0), math.max(y2 or 0, 0)
	love.graphics.setScissor(x1 * displayScale, y1 * displayScale, x2 * displayScale, y2 * displayScale)
end

function res.getSpriteBounds(sheet, sprite)
	if not sprite then sprite = sheet end
	sprite = checkSprite(sprite)
	if sprite then
		return sprite.width, sprite.height
	end
	return 0, 0
end

function res.getSpritePivot(sheet, sprite)
	if not sprite then sprite = sheet end
	sprite = checkSprite(sprite)
	if sprite then
		return sprite.px or 0, sprite.py or 0
	end
	return 0, 0
end

function drawSprite(sheet, sprite, x, y, vanchor, hanchor, iwidth, iheight, nopma)
	if sprite == g_currentCursorName and gameOptions and gameOptions.ui and (not gameOptions.ui.enableCursor or false) then return end
	local image = type(sprite) == "string" and checkSprite(sprite) or sprite

	if image and image.quad and image.spsh then
		local w, h = iwidth or image.width, iheight or image.height
		
		--tiny margin for non-integer scales
		--x = x + .01
		--y = y + .01
		--w = w - .01 - .01
		--h = h - .01 - .01
		
		local wm = w / image.width
		local hm = h / image.height

		local xpr, ypr = image.px, image.py

		if hanchor == "LEFT" or vanchor == "LEFT" then xpr = 0 end
		if hanchor == "RIGHT" or vanchor == "RIGHT" then xpr = image.width end
		
		if vanchor == "TOP" or hanchor == "TOP" then ypr = 0 end
		if vanchor == "BOTTOM" or hanchor == "BOTTOM" then ypr = image.height end
		
		-- if vanchor == "HCENTER" or hanchor == "HCENTER" then xpr = image.w/2 end
		-- if vanchor == "VCENTER" or hanchor == "VCENTER" then ypr = image.h/2 end

		local r, g, b, a = love.graphics.getColor()
		love.graphics.setColor(r * alpha, g * alpha, b * alpha, alpha)
		local b1, b2 = love.graphics.getBlendMode()
		if nopma then love.graphics.setBlendMode("alpha") end
		
		love.graphics.draw(
			image.spsh,					--spritesheet
			image.quad,					--quad
			x - xpr + drawxp,	--x position
			y - ypr + drawyp,	--y position
			drawangle,					--angle
			wm,							--x scale
			hm,							--y scale
			drawxp,				--x rotation pivot
			drawyp)				--y rotation pivot
		
		love.graphics.setBlendMode(b1,b2)
		love.graphics.setColor(r, g, b, a)
	elseif image and image.items then --composprite used in later versions
		res.drawCompoSprite(sprite,x,y)
	end
end

function res.getCompoSpriteBounds(sheet, composprite) --not used in 1.6.3.1
	if not composprite then composprite = sheet end
	composprite = checkSprite(composprite)

	if composprite then
		local w, h = composprite.width, composprite.height
		local px, py = composprite.px or 0, composprite.py or 0
		return -px, -py, -px + w, -py + h
	end

	return 0, 0, 0, 0
end

function setAlpha(a)
	alpha = a
end

function checkSprite(sprite)
	return cachedcs[sprite] or cachedimgs[sprite]
end

function drawRect(r, g, b, a, x, y, w, h, inWorld)
	love.graphics.push()
	if not inWorld then --if the rect is not supposed to be drawn in world space
		love.graphics.origin()
	end

	--rotate around the x/y rotation pivot
	love.graphics.scale(displayScale)
	love.graphics.translate(x, y)
	love.graphics.translate(drawxp, drawyp)
	love.graphics.rotate(drawangle)
	love.graphics.translate(-drawxp, -drawyp)

	local r2,y2,b2,a2 = love.graphics.getColor()
	love.graphics.setColor(r, g, b, a)
	w = w - x
	h = h - y
	love.graphics.rectangle("fill", 0, 0, w, h)
	love.graphics.setColor(r2, y2, b2, a2)

	love.graphics.pop()
end

function drawRect2(r, g, b, a, x, y, w, h, round)
	local r2, y2, b2, a2 = love.graphics.getColor()
	love.graphics.setColor(r, g, b, a)
	love.graphics.rectangle("fill", x, y, w, h, round)
	love.graphics.setColor(r2, y2, b2, a2)
end

function drawLine2D(x0, y0, x1, y1, w, r, g, b, a) --TODO: hitbox (8) rotations center on the origin
	local r2, y2, b2, a2 = love.graphics.getColor()
	love.graphics.push()
	-- love.graphics.origin()
	love.graphics.setColor(r / 255, g / 255, b / 255, a / 255)
	love.graphics.setLineWidth(w * .75)
	-- setRenderState(-screen.left - cameraShakeX, -screen.top - cameraShakeY, worldScale, worldScale, 0)
	-- love.graphics.scale(worldScale)
	-- love.graphics.translate(-screen.left - cameraShakeX, -screen.top - cameraShakeY)
	-- gra

	--rotate around the x/y rotation pivot
	love.graphics.translate(x0, y0)
	love.graphics.translate(drawxp, drawyp)
	love.graphics.rotate(drawangle)
	love.graphics.translate(-drawxp, -drawyp)
	-- print(x1,y1,x2,y2)
	love.graphics.line(0, 0, x1-x0, y1-y0)
	love.graphics.setColor(r2,y2,b2,a2)
	love.graphics.pop()
end

function drawRubberband(x1, y1, x2, y2, width, sprite)
	sprite = checkSprite(sprite)
	if not sprite then return end

	local dist = math.sqrt((x1 - x2) ^ 2 + (y1 - y2) ^ 2)
	local angle = math.atan2(y2 - y1, x2 - x1)

	love.graphics.push()

	love.graphics.origin()
	love.graphics.translate(x1, y1)
	love.graphics.rotate(angle)
	love.graphics.scale(dist / sprite.width, width / sprite.height)
	res.drawSprite(sprite, 0, -sprite.height / 4, "LEFT")

	love.graphics.pop()
end

local loadedSheets = {}
pngMapping = {}

function findSpriteByPNG(name)
	local map = pngMapping[name]
	if map then
		local sheet = loadedSheets[map]
		if sheet then
			local sprite = sheet.sprites[1]
			return sprite and cachedimgs[sprite]
		end
	end
end

local function releaseSheet(sheet, usecomposprites)
	local cache = usecomposprites and cachedcs or cachedimgs
	local lsheet = loadedSheets[sheet]
	if not lsheet then return end --just ignore it if it's already unloaded
	
	for i, v in ipairs(lsheet.sprites) do
		if cache[v] then
			-- print("res.releaseSpriteSheet: freeing sprite "..tostring(v))
			cache[v].quad:release()
			cache[v] = nil
		end
	end

	for i, v in pairs(pngMapping) do
		if v == sheet then
			pngMapping[i] = nil
			break
		end
	end
	
	if lsheet.sheet then lsheet.sheet:release() end
	loadedSheets[sheet] = nil
end

local function findCaseInsensitive(dir)
	local _, paths = resolvePath(dir)
	if checkDirectory(dir) then
		table.remove(paths) --omit the old filename
		return dir, paths
	elseif dir and dir ~= "" then
		if #paths == 0 then return "" end
		local name = paths[#paths] --get the filename before it's too late
		table.remove(paths) --omit the old filename
		dir = table.concat(paths, "/") --and update dir according to that

		for _, f in ipairs(love.filesystem.getDirectoryItems(dir)) do
			if f:lower() == name:lower() then
				return dir.."/"..f, paths --and make a new one
			end
		end
	end

	error("no "..dir)
	return "", nil
end

local function loadSheet(sheet, usecomposprites)
	if loadedSheets[sheet] then return end
	
	if endsWith(sheet, ".dat") then
		loadedSheets[sheet] = {sheet = nil, sprites = {}}
		
		local newname, paths = findCaseInsensitive(datapath.."/"..sheet)
		local data = love.filesystem.read(newname)
		local info = getDatInfo(data, sheet, "SPRT")

		if usecomposprites and info.compos then
			for i, v in pairs(info.compos) do
				--calculate the bounds here
				local composprite = {items = v}
				local x0, x1, y0, y1 = 0,0,0,0
				
				for ii, vv in pairs(v) do
					local sprite = cachedimgs[vv.n]
					if sprite then
						local _,_,w,h = sprite.quad:getViewport()
						x0,x1 = math.min(x0,vv.x - w), math.max(x1,vv.x + w)
						y0,y1 = math.min(y0,vv.y - h), math.max(y1,vv.y + h)
					end
				end
				
				composprite.width, composprite.height = x1, y1
				composprite.px, composprite.py = x0, y0

				cachedcs[i] = composprite
			end
		elseif not usecomposprites and info.sprites and info.filename then
			local filename = info.filename
			local extensionlength = 4

			local lsheet = loadedSheets[sheet]

			if endsWith(filename,".pvr") then
				-- extensionlength = 4 + 4 --.pvr + .png
				-- filename = filename..".png"

				extensionlength = 4
				--most angry birds pvrs are usually listed as R4 G4 B4 A4 UNorm Linear under pvrtextool, so 16bpp
				--the file size also lines up, width x height x 2 (bytes per pixel) + 52 bytes of headers = filesize
				--the headers and formats differ however
				local data = love.filesystem.read(table.concat(paths, "/").."/"..filename)

				lsheet.sheet = love.graphics.newImage(convertImagePVR(data, filename))
			elseif endsWith(filename,".webp") then
				extensionlength = 5 + 4 --.webp + .png
				filename = filename..".png"

				lsheet.sheet = love.graphics.newImage(table.concat(paths, "/").."/"..filename)
			else
				lsheet.sheet = love.graphics.newImage(table.concat(paths, "/").."/"..filename)
			end
			
			pngMapping[filename:sub(1, -extensionlength - 1)] = sheet --filename is the index for easy finding in drawGameNative

			for i, spr in pairs(info.sprites) do
				-- print("res.createSpriteSheet: adding sprite "..tostring(i))
				cachedimgs[i] = {quad = love.graphics.newQuad(spr.x, spr.y, spr.width, spr.height, lsheet.sheet:getWidth(), lsheet.sheet:getHeight()),
					spsh = lsheet.sheet, px = spr.pivotX, py = spr.pivotY, width = spr.width, height = spr.height}
				table.insert(lsheet.sprites, i)
			end
		end
	end
end

function res.releaseSpriteSheet(sheet)
	-- print("res.releaseSpriteSheet: unloading "..tostring(sheet))
	releaseSheet(sheet, false)
end

function res.createSpriteSheet(sheet)
	-- print("res.createSpriteSheet: loading "..tostring(sheet))
	loadSheet(sheet, false)
end


function res.releaseCompoSpriteSet(sheet)
	-- print("res.releaseCompoSpriteSet: unloading "..tostring(sheet))
	releaseSheet(sheet, true)
end

function res.createCompoSpriteSet(sheet)
	-- print("res.createCompoSpriteSet: loading "..tostring(sheet))
	loadSheet(sheet, true)
end

function res.releaseFont(font)return end

function getRokuImagePath(dat)
	return ""
end

--seasons TODO
function setThemeRectColour(layer, r, g, b, a)
	return
end