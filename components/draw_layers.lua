--draw bg, fg, and game

local drawSprites --old seasons versions define drawSprites
trajectory = {{{}, {}, {}}}


themeSpriteObjects = {}

function createThemeSprite(name, sprite, x, y, speedX, scaleX, scaleY, angle, layerNumber)
	themeSpriteObjects[name] = {sprite = sprite, x = x, y = y, speedX = speedX, scaleX = scaleX, scaleY = scaleY, angle = angle, layerNumber = layerNumber}
end

function removeThemeSprite(name, layerNumber)
	themeSpriteObjects[name] = nil
end

function modifyThemeSprite(name, x, y, scaleX, scaleY, angle, layerNumber)
	if not themeSpriteObjects[name] then return end
	themeSpriteObjects[name].x = x
	themeSpriteObjects[name].y = y
	themeSpriteObjects[name].scaleX = scaleX
	themeSpriteObjects[name].scaleY = scaleY
	themeSpriteObjects[name].angle = angle
	themeSpriteObjects[name].layerNumber = layerNumber
end

local yoffsets = {}
local layercolors = {}

function setThemeForegroundOffsetY(layer, y)
	yoffsets[layer] = y
end

function setThemeRectColour(layer, r, g, b, a)
	r, g, b, a = r / 255, g / 255, b / 255, a / 255
	layercolors[layer] = {r * a, g * a, b * a, a}
end

function setTheme(theme)
	currentTheme = theme
	objects.theme = theme
	yoffsets = {}
	layercolors = {}

	restoreParticles()
end

local function getScreenTopLeft()
	local screenLeft = renderLeft or screen.left - (cameraShakeX or 0)
	local screenTop = renderTop or screen.top - (cameraShakeY or 0)
	return screenLeft, screenTop
end

--[1] = sheet
--[2] = sprite
--[3] = parallax speed
--[4] = scale
--[5] = looping
--[6] = position
function drawLayer(layer, yoffset)
	local sprite = layer[2]
	local relativeSpeed = layer[3] or 1
	local relativeScale = layer[4] or 1.5
	local isLooping = layer[5]
	local startX = layer[6] or 0
	local startY = layer[7] or 0
	local scrollFrequency = layer.v or 0
	
	local px, py = res.getSpritePivot(sprite)
	local w, h = res.getSpriteBounds(sprite)
	local wScale = tempWorldScale or renderScale or worldScale or 1
	local autoScroll = -scrollFrequency * time / 16 --TODO: inaccurate with water
	local shakeX, shakeY = cameraShakeX or 0, cameraShakeY or 0

	if layer.water then
		yoffset = -(objects.waterLevel or 0) * physicsToWorld / relativeScale
	end

	local xScale = layer.scaleWobbleX and math.sin(time) * layer.scaleWobbleX / wScale or 0
	local yScale = layer.scaleWobbleY and math.sin(time) * layer.scaleWobbleY / wScale or 0
	
	local screenLeft = renderLeft - shakeX or screen.left -- really weird hack, change this asap
	local screenTop = renderTop - shakeY or screen.top
	
	if w > 0 and wScale > .02 then --don't draw so many if the scale is too low
		for x = -1, math.floor(screenWidth / (w - px) / wScale) do
			local pivotX = w * x + startX
			local left = -screenLeft * relativeSpeed / relativeScale
			local top = -(screenTop - startY) / relativeScale + (yoffset or 0)
			
			if episode4BGCranes and sprite:find("CRANE") then
				left = left + episode4BGCranes.startX / 16
			elseif isLooping ~= false then
				left = (left + autoScroll) % w
			end
			
			setRenderState(pivotX + left - shakeX / (relativeScale + xScale), top - shakeY / (relativeScale + yScale), wScale * (relativeScale + xScale), wScale * (relativeScale + yScale), 0, px, py)
			
			if not (x ~= 0 and isLooping == false) then
				res.drawSprite(sprite, 0, 0)
			end
		end
	end
end

function drawThemeSprite(v, layer)
	local px, py = res.getSpritePivot("", v.sprite)
	local w, h = res.getSpriteBounds("", layer[2])

	local wScale = tempWorldScale or renderScale or worldScale
	local relativeSpeed = layer[3] or 1
	local relativeScale = layer[4] or 1.5
	local isLooping = layer[5]
	local shakeX, shakeY = cameraShakeX or 0, cameraShakeY or 0
	
	local screenLeft = renderLeft or screen.left
	local screenTop = renderTop or screen.top
	
	if w > 0 and wScale > .02 then --don't draw so many if the scale is too low
		for x = -1, math.floor(screenWidth / w / wScale) do
			local pivotX = w * x
			local left = (-screenLeft * relativeSpeed / relativeScale) % w
			local top = (-screenTop / v.scaleY)

			setRenderState(pivotX + left - shakeX, top - shakeY, wScale * v.scaleX, wScale * v.scaleY, v.angle, px, py)

			if not (x ~= 0 and isLooping == false) then
				res.drawSprite(v.sprite, v.x * 16, v.y)
			end
		end
	end
end

function drawBackgroundNative(highGFX)
	local theme = blockTable.themes[currentTheme]
	if not (theme and theme.bgLayers) then return end

	if theme.color then setBGColor(theme.color.r, theme.color.g, theme.color.b) end

	if highGFX ~= false then
		for layernum, layer in ipairs(theme.bgLayers) do
			--theme rect colors
			love.graphics.push("all")
			if layercolors[layernum - 1] then
				local colors = layercolors[layernum - 1]
				love.graphics.setColor(colors)
				if layer.rect then
					local a = colors[4] or layer.rect.a
					drawRect(layer.rect.r * a, layer.rect.g * a, layer.rect.b * a, a, 0, 0, screenWidth, screenHeight)
				end
			end

			drawLayer(layer)

			love.graphics.pop()

			for k, object in pairs(themeSpriteObjects) do
				if object.layerNumber == layernum then
					-- setRenderState(-screen.left - (cameraShakeX or 0), -screen.top - (cameraShakeY or 0), worldScale, worldScale, 0, 0, v.angle)
					-- res.drawSprite(v.sprite, v.x, 0)
					drawThemeSprite(object, theme.bgLayers[layernum + 1] or layer)
				end
			end
		end
	end
end

function drawForegroundNative()
	local theme = blockTable.themes[currentTheme]
	if not (theme and theme.fgLayers) then return end
	
	local screenLeft = renderLeft or screen.left
	local screenTop = renderTop or screen.top

	local s = renderScale or worldScale or 1
	setRenderState(0, 0, 1, 1)

	--draw ground color
	local fgLayers = theme.fgLayers
	local ground_num = 1

	--hack(?) for bad piggies
	if theme.effects then
		for i, v in ipairs(theme.effects) do
			if v.type == "Waves" then
				--check that all sprites are valid?
				ground_num = v.params.water_layer.index
				break
			end
		end
	end

	for layernum, layer in ipairs(fgLayers) do
		if layernum == ground_num then
			local _, ground_h = res.getSpriteBounds(fgLayers[ground_num][1], fgLayers[ground_num][2])
			local _, ground_py = res.getSpritePivot(fgLayers[ground_num][1], fgLayers[ground_num][2])
			local startY = fgLayers[ground_num][7] or 0
			
			local scale = fgLayers[ground_num][4] or 1.5
			local rect_x = 0
			local rect_y = (-screenTop + startY - (cameraShakeY or 0) + (ground_h - ground_py) * scale) * s
			rect_y = rect_y + (yoffsets[#fgLayers - 1] or 0) * s

			drawRect(theme.groundColor.r / 255, theme.groundColor.g / 255, theme.groundColor.b / 255, 1, rect_x, rect_y, screenWidth, screenHeight + screenTop * s + rect_y)
		end

		drawLayer(layer, yoffsets[layernum - 1])
	end
end

local textureShader = love.graphics.newShader([[
	uniform Image textureMask;
	uniform vec2 textureDimensions;
	uniform vec2 camera;
	extern float worldScale;

	vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
			vec2 worldCoords = (screen_coords / worldScale) + camera;
			
			vec4 mask = Texel(textureMask, worldCoords / textureDimensions );
			vec4 pixel = Texel(texture, texture_coords);
			
			pixel.rgb = mix(pixel.rgb, mask.rgb, mask.a);
			
			return pixel * color;
		  
	}]]
)

function drawGameNative()
	local screenLeft, screenTop = getScreenTopLeft()
	local scale = renderScale or worldScale
	
	setRenderState(-screenLeft, -screenTop, scale, scale, 0, 0, 1)

	--trajectories (thanks again halo)
	local trSprites = {}
	for i = 1, 3 do trSprites[i - 1] = "TRAIL_WHITE_"..i end
	trSprites[#trSprites + 1] = "PARTICLE_SLINGDOT"

	for _,tr in ipairs(trajectory) do
		for _,v in ipairs(tr) do
			for i,vv in ipairs(v) do
				res.drawSprite(vv.s or trSprites[(i - 1) % 3], vv.x, vv.y)
			end
		end
	end
	
	drawSprites()
	
	--draw particles
	drawParticlesNative()
end

--TODO : unwind everything and make this look cleaner
local renderList
function drawSprites()
	local screenLeft, screenTop = getScreenTopLeft()
	local scale = renderScale or worldScale
	
	if not objectsSorted then
		renderList = {}
		for z, objects in pairs(zOrderedObjects) do
			for _, obj in ipairs(objects) do
				table.insert(renderList, obj)
			end
		end
		
		for _, entry in pairs(native.luaRenderBuffer) do
			table.insert(renderList, entry.renderer)
		end
		
		-- sort the flat list by z_order
		table.sort(renderList, function(a, b) 
			return (a.z or a.z_order) < (b.z or b.z_order) 
		end)
		objectsSorted = true
	end

	for k, v in ipairs(renderList) do
		local obj = objects.world[v.name]
		
		if obj then
			local texture = checkSprite(obj.texture) --or blockTable.themes[currentTheme].texture
			if not texture then --try to find based on a png name
				texture = findSpriteByPNG(obj.texture)
			end
			
			if texture then
				love.graphics.push()
				local b1, b2 = love.graphics.getBlendMode()
				love.graphics.setBlendMode("alpha", "alphamultiply")
				
				local textureImage = texture.spsh
				textureImage:setWrap("repeat", "repeat")
				
				textureShader:send("textureMask", textureImage)
				
				local w, h = textureImage:getDimensions()
				textureShader:send("textureDimensions", {w, h})
				
				textureShader:send("worldScale", scale * displayScale * love.graphics.getDPIScale())
				textureShader:send("camera", {screenLeft, screenTop})
				
				love.graphics.setShader(textureShader)
				
				drawObject(obj)
				
				love.graphics.setBlendMode(b1, b2)
				love.graphics.setShader()
				love.graphics.pop()
			else
				drawObject(obj)
			end
		else
			drawObject(v)
		end
	end
end
--[[
function drawSprites()
	local layers = { {}, {}, {}, {} }
	
	for k, v in pairs(objects.world) do
		local lookup = { [false] = 0, [true] = 1 }
		local index = 1 + lookup[v.controllable]
		
		if v.isBackground then
			index = 4
		elseif v.z_order > 4.0 or (v.z_order == 0 and v.body:getType() == "dynamic") then
			index = 3
		end
		
		table.insert(layers[index], { name = k, z_order = v.z_order or 0 })
	end
	
	-- sort sprites based on depth
	for i = 1, #layers do
		table.sort(layers[i], function(a, b)
			return a.z_order < b.z_order
		end)
	end
	
	-- draw object
	for i = 1, #layers do
		for k, v in ipairs(layers[i]) do
			local obj = objects.world[v.name]
			local texture = checkSprite(obj.texture) --or blockTable.themes[currentTheme].texture
			if not texture then --try to find based on a png name
				texture = findSpriteByPNG(obj.texture)
			end
			
			if texture then
				love.graphics.push()
				local b1, b2 = love.graphics.getBlendMode()
				love.graphics.setBlendMode("alpha", "alphamultiply")
				
				local textureImage = texture.spsh
				textureImage:setWrap("repeat", "repeat")
				
				textureShader:send("textureMask", textureImage)
				
				local w, h = textureImage:getDimensions()
				textureShader:send("textureDimensions", {w, h})
				
				textureShader:send("worldScale", worldScale * displayScale * love.graphics.getDPIScale())
				textureShader:send("camera", {screen.left, screen.top})
				
				love.graphics.setShader(textureShader)
				
				drawObject(obj)
				
				love.graphics.setBlendMode(b1, b2)
				love.graphics.setShader()
				love.graphics.pop()
			else
				drawObject(obj)
			end
		end
	end
end
]]
function drawObject(v)
	if v.visible == false then return end
	
	local x, y
	if v.position then
		x, y = v.position.x, v.position.y
	else
		x, y = physicsToWorldTransform(v.x or 0, v.y or 0) -- fix this
	end
	
	love.graphics.push()

	drawxp, drawyp = res.getSpritePivot(v.sprite)
	drawangle = v.angle
	
	if v.colors then
		love.graphics.setColor(v.colors)
	end
	
	if v.shader then
		love.graphics.setShader(v.shader)
	end
	
	local scale = v.scale or 1
	
	if type(scale) == "table" then
		love.graphics.scale(scale.x, scale.y)
		
		res.drawSprite(v.sprite, x / scale.x, y / scale.y)
	else
		if v.isBackground then scale = 2 end

		love.graphics.scale(scale)
		if v.flipx then love.graphics.scale(-1, 1) end

		res.drawSprite(v.sprite, x / scale, y / scale)
	end
	
	love.graphics.setShader()

	drawangle = 0
	love.graphics.pop()
end
--massive thanks halo
function addToTrajectory(index, x, y)
	table.insert(trajectory[#trajectory][index], {x = x, y = y})
end

function addPuffToTrajectory(index, x, y)
	table.insert(trajectory[#trajectory][index], {x = x, y = y, s = "BIRD_SPECIAL"})
end

function startNewTrajectory()
	table.insert(trajectory, {{}, {}, {}})
	if #trajectory > 2 then
		table.remove(trajectory, 1)
	end
end
