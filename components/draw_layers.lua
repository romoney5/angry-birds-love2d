--draw bg, fg, and game

trajectory = {{{}, {}, {}}}

function drawLayer(v)
	local px, py = res.getSpritePivot("", v[2])
	local w, h = res.getSpriteBounds("", v[2])
	local s = worldScale or 1
	local scroll = (v.v or 0) * time
	
	if w > 0 and s > .02 then --don't draw if the scale is too low
		for x = -1, math.floor(screenWidth / w / s) do
			-- local i = #theme.bgLayers - k
			local xp = w * x + (v[6] or 0)
			local left = (-screen.left * v[3] / v[4] + scroll - (cameraShakeX or 0)) % w
			local top = (-screen.top / v[4] - (cameraShakeY or 0))
			-- top = (-screen.top * v[3] / v[4] - cameraShakeY)

			if episode4BGCranes and v[2]:find("CRANE") then
				left = -screen.left * v[3] / v[4] + episode4BGCranes.startX * 0.0625 - cameraShakeX
			end

			setRenderState(xp+left, top, s * v[4], s * v[4], 0, px, py)

			if not (x ~= 0 and v[5] == false) then
				res.drawSprite(v[2], 0, 0)
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