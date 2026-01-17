--draw bg, fg, and game

trajectory = {{{}, {}, {}}}

--[1] = sheet
--[2] = sprite
--[3] = parallax speed
--[4] = scale
--[5] = looping
--[6] = position
function drawLayer(layer)
	local sprite = layer[2]
	local relativeSpeed = layer[3]
	local relativeScale = layer[4]
	local isLooping = layer[5]
	local startX = layer[6] or 0
	local scrollFrequency = layer.v or 0
	
	local px, py = res.getSpritePivot(sprite)
	local w, h = res.getSpriteBounds(sprite)
	local wScale = tempWorldScale or worldScale
	local autoScroll = -scrollFrequency * time / 16
	local shakeX, shakeY = cameraShakeX or 0, cameraShakeY or 0
	
	if w > 0 and wScale > .02 then --don't draw if the scale is too low
		for x = -1, math.floor(screenWidth / w / wScale) do
			local pivotX = w * x + startX
			local left = -screen.left * relativeSpeed / relativeScale
			local top = -screen.top / relativeScale
			
			if episode4BGCranes and sprite:find("CRANE") then
				left = left + episode4BGCranes.startX / 16
			elseif isLooping ~= false then
				left = (left + autoScroll) % w
			end
			
			setRenderState(pivotX + left - shakeX, top - shakeY, wScale * relativeScale, wScale * relativeScale, 0, px, py)
			
			if not (x ~= 0 and isLooping == false) then
				res.drawSprite(sprite, 0, 0)
			end
		end
	end
end

function drawBackgroundNative()
	local theme = blockTable.themes[currentTheme]
	if not theme then return end
	if theme.color then setBGColor(theme.color.r, theme.color.g, theme.color.b) end
	for _,v in ipairs(theme.bgLayers) do
		drawLayer(v)
	end
end

function drawForegroundNative()
	local theme = blockTable.themes[currentTheme]
	if not theme then return end
	local s = worldScale or 1
	setRenderState(0, 0, 1, 1)

	local _, ground_h = res.getSpriteBounds(theme.fgLayers[1][1], theme.fgLayers[1][2])
	local rect_x = 0
	local rect_y = (-screen.top + ground_h) * s
	drawRect(theme.groundColor.r / 255, theme.groundColor.g / 255, theme.groundColor.b / 255, 1, rect_x, rect_y, screenWidth, screenHeight + screen.top * s + rect_y)

	for _,v in ipairs(theme.fgLayers) do
		v[3], v[4] = v[3] or 1, v[4] or 1.5
		drawLayer(v)
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

function drawGameNative() --work in progress
	setRenderState(-screen.left - (cameraShakeX or 0), -screen.top - (cameraShakeY or 0), worldScale, worldScale, 0, 0, 1)

	--draw textures
	for k, v in _G.pairs(objects.world) do
		local texture = checkSprite(v.texture) --or blockTable.themes[currentTheme].texture
		if not texture then --try to find based on a png name
			texture = findSpriteByPNG(v.texture)
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
			
			drawObject(v)
			
			love.graphics.setBlendMode(b1, b2)
			love.graphics.setShader()
			love.graphics.pop()
		end
	end

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
	
	--[[
		LAYER HIEARCHY 
		
		- objects (z_order <= 4)
		- birds
		- objects (z_order >= 5) 
		- background sprites (the eagle)
	
	]]
	
	-- TODO : maybe shorten this.
	local layers = {
		{},
		{},
		{},
		{}
	}
	
	for i, v in pairs(objects.world) do
		if not v.texture then
			if v.z_order <= 4.0 then
				if v.controllable ~= true then
					table.insert(layers[1], 1, i)
				else
					table.insert(layers[2], 1, i)
				end
			end
			
			if v.z_order >= 5.0 then
				table.insert(layers[3], 1, i)
			end
			
			if v.isBackground then
				table.insert(layers[4], 1, i)
			end
		end
	end

	--draw objects
	for i = 1, #layers do
		for k, v in _G.pairs(layers[i]) do
			drawObject(objects.world[v])
		end
	end
	
	--draw particles
	drawParticlesNative()
end

function drawObject(v)
	if v.visible == false then return end

	local x, y = physicsToWorldTransform(v.x, v.y)
	love.graphics.push()

	drawxp, drawyp = res.getSpritePivot(v.sprite)
	drawangle = v.angle
	
	local scale = v.scale or 1
	if v.isBackground then scale = 2 end

	love.graphics.scale(scale)
	if v.flipx then love.graphics.scale(-1, 1) end

	res.drawSprite(v.sprite, x / scale, y / scale)

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