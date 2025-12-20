--resources: graphics and sprites

function getBGColor(r,g,b) --not used, but i found it in ghidra
	return love.graphics.getBackgroundColor()
end
function setBGColor(r,g,b) --set the background color
	love.graphics.setBackgroundColor(r / 255, g / 255, b / 255)
end

--quite literally used everywhere
function setRenderState(x,y,xs,ys,angle,xp,yp)
	love.graphics.origin()
	love.graphics.scale(xs, ys)
	love.graphics.scale(displayScale)
	love.graphics.translate(x, y)

	drawangle = angle or 0
	drawxp = xp ~= 0 and xp
	drawyp = yp ~= 0 and yp
end

--frontend of drawsprite
function res.drawSprite(sprite, x, y, vanchor, hanchor, iwidth, iheight, nopma, _)
	if not tonumber(x) then	--pc 1.0.0?
		drawSprite(x, y, vanchor, hanchor, iwidth, iheight, nopma, _)
	else --any other version
		drawSprite(sprite, x, y, vanchor, hanchor, iwidth, iheight, nopma)
	end
end

function res.drawCompoSprite(sheet, sprite, x, y)
	if tonumber(sprite) and not y then
		sprite, x, y = sheet, sprite, x
	end
	
	local image = checkAndLoadSprite(sprite)
	drawxp, drawyp = nil, nil

	if image then
		for i,v in ipairs(image.sprites) do
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
	sprite = checkAndLoadSprite(sprite)
	if sprite then
		return sprite.width, sprite.height
	end
	return 0, 0
end

function res.getSpritePivot(sheet, sprite)
	if not sprite then sprite = sheet end
	sprite = checkAndLoadSprite(sprite)
	if sprite then
		return sprite.px or 0, sprite.py or 0
	end
	return 0, 0
end

function drawSprite(sprite, x, y, vanchor, hanchor, iwidth, iheight, nopma)
	if sprite == g_currentCursorName and gameOptions and gameOptions.ui and (not gameOptions.ui.enableCursor or false) then return end
	local image = type(sprite) == "string" and checkAndLoadSprite(sprite) or {spsh = sprite.spritesheet, quad = sprite.quad}

	if image and image.quad and image.spsh then
		local w, h = iwidth or image.width, iheight or image.height
		
		--tiny margin for non-integer scales
		--x = x + .01
		--y = y + .01
		--w = w - .01 - .01
		--h = h - .01 - .01
		
		local wm = w / image.width
		local hm = h / image.height

		local xpr, ypr = drawxp or image.px, drawyp or image.py

		if hanchor == "LEFT" or vanchor == "LEFT" then xpr = 0 end
		if hanchor == "RIGHT" or vanchor == "RIGHT" then xpr = quad_width end
		
		if vanchor == "TOP" or hanchor == "TOP" then ypr = 0 end
		if vanchor == "BOTTOM" or hanchor == "BOTTOM" then ypr = quad_height end
		
		-- if vanchor == "HCENTER" or hanchor == "HCENTER" then xpr = image.w/2 end
		-- if vanchor == "VCENTER" or hanchor == "VCENTER" then ypr = image.h/2 end

		local r, g, b, a = love.graphics.getColor()
		love.graphics.setColor(r * alpha, g * alpha, b * alpha, alpha)
		local b1, b2 = love.graphics.getBlendMode()
		if nopma then love.graphics.setBlendMode("alpha") end
		
		love.graphics.draw(
			image.spsh,	--spritesheet
			image.quad,	--quad
			x,			--x
			y,			--y
			drawangle,	--angle
			wm,			--x scale
			hm,			--y scale
			xpr,		--x pivot
			ypr)		--y pivot
		
		love.graphics.setBlendMode(b1,b2)
		love.graphics.setColor(r, g, b, a)
	elseif image and image.sprites then --composprite used in later versions
		res.drawCompoSprite(sprite,x,y)
	end
end

function res.getCompoSpriteBounds(sheet, composprite) --not used in 1.6.3.1
	if not composprite then composprite = sheet end
	composprite = checkAndLoadSprite(composprite)

	if composprite then
		local w,h = composprite.w, composprite.h
		local px,py = composprite.px or 0, composprite.py or 0
		return -px, -py, -px + w, -py + h
	end
end

function setAlpha(a)
	alpha = a
end

function checkAndLoadSprite(sprite)
	return cachedcs[sprite] or cachedimgs[sprite]
end

function drawRect(r, g, b, a, x, y, xs, ys, inWorld)
	local r2,y2,b2,a2 = love.graphics.getColor()
	love.graphics.setColor(r, g, b, a)
	xs = xs - x
	ys = ys - y
	love.graphics.rectangle("fill", x, y, xs, ys)
	love.graphics.setColor(r2, y2, b2, a2)
end

function drawRect2(r, g, b, a, x, y, xs, ys, round)
	local r2, y2, b2, a2 = love.graphics.getColor()
	love.graphics.setColor(r, g, b, a)
	love.graphics.rectangle("fill", x, y, xs, ys, round)
	love.graphics.setColor(r2, y2, b2, a2)
end

function drawLine2D(lx1, ly1, lx2, ly2, lz, r, g, b, a) --unfinished
	local r2, y2, b2, a2 = love.graphics.getColor()
	love.graphics.push()
	-- love.graphics.origin()
	love.graphics.setColor(r / 255, g / 255, b / 255, a / 255)
	love.graphics.setLineWidth(lz * .75)
	-- setRenderState(-screen.left - cameraShakeX, -screen.top - cameraShakeY, worldScale, worldScale, 0)
	-- love.graphics.scale(worldScale)
	-- love.graphics.translate(-screen.left - cameraShakeX, -screen.top - cameraShakeY)
	-- gra
	love.graphics.rotate(drawangle)
	-- print(x1,y1,x2,y2)
	love.graphics.line(lx1, ly1, lx2, ly2)
	love.graphics.setColor(r2,y2,b2,a2)
	love.graphics.pop()
end

local loadedSheets = {}
function res.releaseSpriteSheet(sheet)return end
function res.createSpriteSheet(sheet)
	--print("res.createSpriteSheet: loading "..tostring(sheet))
	local sprite = sheet
	local dat_suffix = ".dat"
	if endsWith(sprite, dat_suffix) then
		if loadedSheets[sheet] then return end
		loadedSheets[sheet] = true
		
		local data = love.filesystem.read(dataPath..sheet)
		local info = getDatInfo(data,sprite,"SPRT")
		if info.compos then
			--TODO: fix composprites
			for i,v in pairs(info.compos) do
				cachedimgs.csprites[i] = v
			end
		elseif info.sprites and info.filename then
			local filename = info.filename
			local extension = ".png"
			if endsWith(filename,".pvr") then extension = ".pvr.png" filename=filename..".png" end
			if endsWith(filename,".webp") then extension = ".webp.png" filename=filename..".png" end
			-- print(sprite)
			local spritesheet = love.graphics.newImage(dataPath..string.sub(sheet, 1, -string.len(dat_suffix) - 1)..extension)
			for i,spr in pairs(info.sprites) do
				-- if i:sub(1,21)=="THEME_GROUND_TEXTURE_"then print(filename:sub(1,-5))end
				--print("res.createSpriteSheet: adding sprite "..tostring(i))
				cachedimgs[i] = {quad = love.graphics.newQuad(spr.x, spr.y, spr.width, spr.height,spritesheet:getWidth(),spritesheet:getHeight()),
					spsh=spritesheet,px=spr.pivotX,py=spr.pivotY, width = spr.width, height = spr.height}--,src=path.."/"..sprite:sub(1,-5)..extension}--imagePath.."/img/"..sprite:sub(1,-5)..".png"}
			end
		end
		if love.keyboard.isDown("escape") then print("abort") error()return end
	end
end
function res.releaseCompoSpriteSet(sheet)return end
function res.createCompoSpriteSet(sheet)return end

function res.releaseFont(font)return end

function getRokuImagePath(dat)
	return ""
end

--seasons TODO
function setThemeRectColour(layer, r, g, b, a)
	return
end