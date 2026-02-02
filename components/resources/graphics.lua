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
function setRenderState(x, y, xs, ys, angle, xp, yp, alpha)
	love.graphics.origin()
	love.graphics.scale(xs, ys)
	love.graphics.scale(displayScale)
	love.graphics.translate(x, y)

	drawangle = angle or 0
	--drawxp and yp are exclusively used for rotation, they are useless when angle is 0
	drawxp = xp or 0
	drawyp = yp or 0

	if alpha then
		setAlpha(alpha)
	end
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
			--TODO: scale and angle
			drawSprite(sheet, v.n, math.floor(x + v.x), math.floor(y + v.y))
		end
	end
end

function res.setClipRect(x1, y1, x2, y2)
	x1, y1, x2, y2 = math.max(x1 or 0, 0), math.max(y1 or 0, 0), math.max(x2 or 0, 0), math.max(y2 or 0, 0)
	love.graphics.setScissor(x1 * displayScale, y1 * displayScale, x2 * displayScale, y2 * displayScale)
end

function res.getClipRect(x1, y1, x2, y2)
	local x, y, w, h = love.graphics.getScissor()
	return x / displayScale, y / displayScale, w / displayScale, h / displayScale
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
	if sprite == g_currentCursorName and ((gameOptions and gameOptions.ui and (not gameOptions.ui.enableCursor))
		or (joystick and physicsEnabled)) then return end

	local image = type(sprite) == "string" and (cachedimgs[sprite] or cachedcs[sprite]) or sprite

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
		local ox, oy = drawxp, drawyp

		if hanchor == "LEFT" or vanchor == "LEFT" then xpr = 0 end
		if hanchor == "RIGHT" or vanchor == "RIGHT" then xpr = image.width end
		if hanchor == "HPIVOT" or vanchor == "HPIVOT" then xpr = drawxp end
		
		if vanchor == "TOP" or hanchor == "TOP" then ypr = 0 end
		if vanchor == "BOTTOM" or hanchor == "BOTTOM" then ypr = image.height end
		if vanchor == "VPIVOT" or hanchor == "VPIVOT" then ypr = drawyp end
		
		if vanchor == "LEFT" and hanchor == "TOP" then -- fix to the shockwave issue
			ox = image.px
			oy = image.py
		end
		
		-- if vanchor == "HCENTER" or hanchor == "HCENTER" then xpr = image.w/2 end
		-- if vanchor == "VCENTER" or hanchor == "VCENTER" then ypr = image.h/2 end

		love.graphics.push("all")
		local r, g, b, a = love.graphics.getColor()
		love.graphics.setColor(r * alpha, g * alpha, b * alpha, a * alpha)
		if nopma then love.graphics.setBlendMode("alpha") end

		love.graphics.draw(
			image.spsh,			--spritesheet
			image.quad,			--quad
			x - xpr + drawxp,	--x position
			y - ypr + drawyp,	--y position
			drawangle,			--angle
			wm,					--x scale
			hm,					--y scale
			ox,					--x rotation pivot
			oy)					--y rotation pivot
		
		love.graphics.pop()
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
	love.graphics.push("all")
	if not inWorld then --if the rect is not supposed to be drawn in world space
		love.graphics.origin()
		love.graphics.scale(displayScale)
	end

	love.graphics.setBlendMode("alpha", "alphamultiply")

	--rotate around the x/y rotation pivot
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

function drawLine2D(x0, y0, x1, y1, w, r, g, b, a)
	local r2, y2, b2, a2 = love.graphics.getColor()
	love.graphics.push("all")
	love.graphics.setBlendMode("alpha", "alphamultiply")

	love.graphics.setColor(r / 255, g / 255, b / 255, a / 255)
	love.graphics.setLineWidth(w * .75)

	--rotate around the x/y rotation pivot
	love.graphics.translate(x0, y0)
	love.graphics.translate(drawxp, drawyp)
	love.graphics.rotate(drawangle)
	love.graphics.translate(-drawxp, -drawyp)
	
	love.graphics.line(0, 0, x1-x0, y1-y0)
	love.graphics.setColor(r2,y2,b2,a2)
	love.graphics.pop()
end

--3.0.1
function drawRubberband(x1, y1, x2, y2, width, sprite)
	sprite = checkSprite(sprite)
	if not sprite then return end

	local dist = math.sqrt((x1 - x2) ^ 2 + (y1 - y2) ^ 2)
	local angle = math.atan2(y2 - y1, x2 - x1)

	love.graphics.push()

	love.graphics.origin()
	love.graphics.scale(displayScale)
	love.graphics.translate(x1, y1)
	love.graphics.rotate(angle)
	love.graphics.scale(dist / sprite.width, width / sprite.height)
	res.drawSprite(sprite, 0, -sprite.height / 4, "LEFT")

	love.graphics.pop()
end

function drawSlingScopeNative(s_vx, s_vy, vertical_force)
	love.graphics.push()
	-- setRenderState(-screen.left - (cameraShakeX or 0), -screen.top - (cameraShakeY or 0), worldScale, worldScale, 0, 0, 1)
	local lsx, lsy = physicsToWorldTransform(selectedBird.x, selectedBird.y)
	local spacing = 4
	local amount = 16

	local offset = g_sling_scope_animation % 1

	s_vy = s_vy - worldgravity.y / physicsToWorld * spacing / 2
	s_vy = s_vy + worldgravity.y / physicsToWorld * spacing * (offset)
	
	local verticalForce = (vertical_force / selectedBird.mass) / physicsToWorld
	if vertical_force ~= 0 then
		s_vy = s_vy - verticalForce * spacing / 2
		s_vy = s_vy + verticalForce * spacing * (offset)
	end
	
	lsx = lsx + s_vx * spacing * offset
	lsy = lsy + s_vy * spacing * offset

	for i = 1, amount do
		love.graphics.push()

		love.graphics.translate(lsx, lsy)
		love.graphics.scale(lerp(1, 0, (i - 1 + offset) / amount))
		s_vy = s_vy + worldgravity.y / physicsToWorld * spacing
		-- apply extra impulse on the curve
		if vertical_force ~= 0 then
			s_vy = s_vy + verticalForce * spacing
		end

		lsx = lsx + s_vx * spacing
		lsy = lsy + s_vy * spacing

		res.drawSprite("PARTICLE_SLINGDOT", 0, 0)

		love.graphics.pop()
	end
	love.graphics.pop()
end

--4.0.0
function drawFullscreenRect(r, g, b, a)
	love.graphics.push("all")
	love.graphics.origin()
	love.graphics.setBlendMode("alpha", "alphamultiply")
	love.graphics.setColor(r, g, b, a)
	love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())
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
	
	if lsheet.zip then
		love.filesystem.unmount(lsheet.zip)
	end
	
	if lsheet.sheet then lsheet.sheet:release() end
	loadedSheets[sheet] = nil
end

local function loadSheet(sheet, usecomposprites)
	if loadedSheets[sheet] then return end
	
	local newname, paths = findCaseInsensitive(datapath.."/"..sheet)
	
	if not newname then
		newname, paths = findCaseInsensitive(datapath.."/"..sheet:sub(1, -5)..(usecomposprites and ".compo.json" or ".sheet.json"))
		if not newname then
			newname, paths = findCaseInsensitive(datapath.."/"..sheet:sub(1, -5).."_1"..(usecomposprites and ".compo.json" or ".sheet.json")) --ok
		end
	end

	if not newname then
		print("loadSheet: dat file \""..tostring(sheet).."\" not found")
		return
	end

	loadedSheets[sheet] = {sheet = nil, sprites = {}}

	local data = love.filesystem.read(newname or "")
	local info

	--TODO: another file.. ..
	if endsWith(newname, ".dat") then
		info = getDatInfo(data, newname, "SPRT")
	elseif endsWith(newname, ".json") then
		local jsondata = json.decode(decryptSrc(newname, data))
		
		if not usecomposprites then
			info = {sprites = {}}
			info.filename = jsondata.meta.image
			
			for i, sprite in ipairs(jsondata.frames) do
				info.sprites[sprite.filename] = {
					x = sprite.frame.x,
					y = sprite.frame.y,
					width = sprite.frame.w,
					height = sprite.frame.h,
					
					pivotX = sprite.pivot.x,
					pivotY = sprite.pivot.y,
				}
			end
			--print(jsondata.meta.app, jsondata.meta.image)
		else
			info = {compos = {}}
			
			for i, compo in ipairs(jsondata.compo) do
				info.compos[compo.name] = {}
				
				for i, sprite in ipairs(compo.sprites) do
					local scaleX = tonumber(sprite.scale) or sprite.scale[1]
					local scaleY = tonumber(sprite.scale) or sprite.scale[2]
					
					--insert at the start
					table.insert(info.compos[compo.name], 1, {
						sheet = "",
						x = sprite.x,
						y = sprite.y,
						sx = scaleX,
						sy = scaleY,
						a = sprite.angle,
						flip = {x = false, y = false},
						n = sprite.name
					})
				end
			end
			--error(newname)
			--print("sheet", jsondata.meta.sheet)
		end
	end

	if usecomposprites and info.compos then
		for i, v in pairs(info.compos) do
			--calculate the bounds here
			local composprite = {items = v}
			local x0, x1
			local y0, y1
			local width, height = 0, 0
			local px, py = 0, 0
			
			for ii, vv in ipairs(v) do
				local sprite = cachedimgs[vv.n]
				if sprite then
					local sx0, sx1 = vv.x - sprite.px, vv.x + sprite.width - sprite.px
					local sy0, sy1 = vv.y - sprite.py, vv.y + sprite.height - sprite.py

					--get bounds
					x0, x1 = math.min(x0 or sx0, sx0), math.max(x1 or sx1, sx1)
					y0, y1 = math.min(y0 or sy0, sy0), math.max(y1 or sy1, sy1)
					
					--set the pivots
					px = -x0
					py = -y0

					--set the dimensions
					width = math.abs(x1 - x0)
					height = math.abs(y1 - y0)
				end
			end
			
			composprite.width, composprite.height = width, height
			composprite.px, composprite.py = px or 0, py or 0

			cachedcs[i] = composprite
		end
	elseif not usecomposprites and info.sprites and info.filename then
		local filename = table.concat(paths, "/", 1, #paths - 1).."/"..info.filename
		local extensionlength = 4

		local lsheet = loadedSheets[sheet]

		local zipped = not checkDirectory(filename) and ((checkDirectory(filename..".zip") and ".zip") or (checkDirectory(filename..".kazip") and ".kazip"))
		if zipped then
			--android versions like to zip some images
			local zip = filename..zipped
			local src = love.filesystem.newFileData(zip)
			local success = love.filesystem.mount(src, zip)

			if success then
				lsheet.zip = zip
				--cut off the base path assuming this is running from an apk
				local _, og_datapath = resolvePath(datapath)
				og_datapath = table.concat(og_datapath, "/", 2)

				--then get the given sheet's base directory
				local _, parentDir = resolvePath(sheet)
				parentDir = table.concat(parentDir, "/", 1, #parentDir - 1)

				--and append the real filename to it before passing in the real path
				local newname, paths = findCaseInsensitive(zip.."/"..og_datapath.."/"..parentDir.."/"..info.filename)
				if not newname then
					newname, paths = findCaseInsensitive(zip.."/"..info.filename)
				end
				filename = newname
			else
				--or it didn't even work
				print("loadSheet: could not unzip "..zip)
				return
			end
		end

		if endsWith(filename, ".pvr") then
			-- extensionlength = 4 + 4 --.pvr + .png
			-- filename = filename..".png"

			extensionlength = 4
			--most angry birds pvrs are usually listed as R4 G4 B4 A4 UNorm Linear under pvrtextool, so 16bpp
			--the file size also lines up, width x height x 2 (bytes per pixel) + 52 bytes of headers = filesize
			--the headers and formats differ however
			local data = love.filesystem.read(filename)
			local pvr, w, h = convertImagePVR(data, filename)

			--pcall because love can throw an error anyways
			local success = pcall(function()
				lsheet.sheet = love.graphics.newImage(pvr)
			end)
			
			if not success then
				local rawdata = string.rep("\xFF", w * h * 16 / 8)--resultstr
				local imagedata = love.image.newImageData(w, h, "rgba4", rawdata)
				lsheet.sheet = love.graphics.newImage(imagedata)
			end
		elseif endsWith(filename, ".webp") then
			if not haswebp then
				extensionlength = 5 + 4 --.webp + .png
				filename = filename..".png"

				--lsheet.sheet = love.graphics.newImage(filename)
				lsheet.sheet = love.graphics.newImage(love.image.newImageData(1, 1, nil, nil))
			else
				local src = love.filesystem.read(filename)
				lsheet.sheet = love.graphics.newImage(webp.loadImage(src, src:len()))
			end
		else
			lsheet.sheet = love.graphics.newImage(filename)
		end
		
		pngMapping[info.filename:sub(1, -extensionlength - 1)] = sheet --filename is the index for easy finding in drawGameNative

		for i, spr in pairs(info.sprites) do
			-- print("res.createSpriteSheet: adding sprite "..tostring(i))
			cachedimgs[i] = {quad = love.graphics.newQuad(spr.x, spr.y, spr.width, spr.height, lsheet.sheet:getWidth(), lsheet.sheet:getHeight()),
				spsh = lsheet.sheet, px = spr.pivotX, py = spr.pivotY, width = spr.width, height = spr.height}
			table.insert(lsheet.sprites, i)
		end
	end
end

function loadDATFileToTable(sheet, table)
	local newname, paths = findCaseInsensitive(datapath.."/"..sheet)
	local data = love.filesystem.read(newname)
	local info = getDatInfo(data, sheet, "SPRT")

	_G[table] = info.sprites or info.compos
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

ResourceManager.native_createSpriteSheet = res.createSpriteSheet
ResourceManager.native_releaseSpriteSheet = res.releaseSpriteSheet

function res.releaseFont(font)
	return
end

function getRokuImagePath(dat)
	return ""
end