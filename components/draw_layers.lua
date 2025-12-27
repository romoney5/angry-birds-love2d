--draw bg, fg, and game

function drawLayer(v)
	local px, py = res.getSpritePivot("", v[2])
	local w, h = res.getSpriteBounds("", v[2])
	local s = worldScale or 1
	local scroll = (v.v or 0) * time
	
	if w > 0 and s > .02 then --don't draw if the scale is too low
		for x = -1, math.floor(screenWidth / w / s) do
			-- local i = #theme.bgLayers - k
			local xp = w * x + (v[6] or 0)
			local left = (-screen.left * v[3] / v[4] + scroll - cameraShakeX) % w
			local top = (-screen.top / v[4] - cameraShakeY)
			-- top = (-screen.top * v[3] / v[4] - cameraShakeY)

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
	setBGColor(theme.color.r, theme.color.g, theme.color.b)
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
	uniform vec2 textureSize;
	uniform vec2 camera;
	extern float worldScale;

	vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
			vec2 worldCoords = (screen_coords / worldScale) + camera;
			
			vec4 mask = Texel(textureMask, worldCoords / textureSize );
			vec4 pixel = Texel(texture, texture_coords);
			
			pixel.rgb = mix(pixel.rgb, mask.rgb, mask.a);
			
			return pixel * color;
		  
	}]]
)

function drawGameNative() --work in progress

	--draw textures
	--TODO: non-pc versions (pc <= 1.6.3.1) have different texture names
	for k, v in _G.pairs(objects.world) do
		local texture = v.texture --or blockTable.themes[currentTheme].texture
		
		if texture and checkSprite(texture) then
			love.graphics.push()
			local b1, b2 = love.graphics.getBlendMode()
			love.graphics.setBlendMode("alpha", "alphamultiply")
			
			local textureImage = checkSprite(texture).spsh
			textureImage:setWrap("repeat", "repeat")
			
			textureShader:send("textureMask", textureImage)
			
			local w, h = textureImage:getDimensions()
			textureShader:send("textureSize", {w, h})
			
			textureShader:send("worldScale", worldScale)
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

	--draw objects
	for i, v in pairs(objects.world) do
		if not v.texture then
			drawObject(v)
		end
	end

	--draw particles
	drawParticlesNative()
end

function drawObject(v)
	local x, y = physicsToWorldTransform(v.x, v.y)
	love.graphics.push()

	drawxp, drawyp = res.getSpritePivot(v.sprite)
	drawangle = v.angle

	love.graphics.scale(v.powerup_scale or 1)
	if v.flipx then love.graphics.scale(-1, 1) end

	res.drawSprite(v.sprite, x, y)

	drawangle = 0
	love.graphics.pop()
end