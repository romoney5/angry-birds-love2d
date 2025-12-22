--draw bg, fg, and game

function drawLayer(v)
	local px, py = res.getSpritePivot("", v[2])
	local w, h = res.getSpriteBounds("", v[2])
	local s = worldScale or 1
	local scroll = (v.v or 0) * time
	
	if w > 0 and s > .02 then
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
	drawRect2(theme.groundColor.r / 255, theme.groundColor.g / 255, theme.groundColor.b / 255, 1, 0, -screen.top * s,screenWidth, screenHeight + screen.top * s)
	for _,v in ipairs(theme.fgLayers) do
		v[3], v[4] = v[3] or 1, v[4] or 1.5
		drawLayer(v)
	end
end

function drawGameNative() --work in progress
	love.graphics.push()
	-- love.graphics.origin()
	local texture = blockTable.themes[currentTheme].texture

	--TODO: immovable block edges lack translucency (not a stencil?)
	love.graphics.stencil(function()
		if res.textureShader then love.graphics.setShader(res.textureShader) end
		for i,v in pairs(objects.world) do
			if v.texture then
				drawangle = v.angle
				local x, y = physicsToWorldTransform(v.x, v.y)
				res.drawSprite(v.sprite, x, y)
			end
		end
		if res.textureShader then love.graphics.setShader() end
	end, "replace", 1)
	love.graphics.setStencilTest("greater", .9)
	-- love.graphics.scale(2)
	-- drawangle = 0
	setRenderState(0, 0, worldScale, worldScale)
	local w,h = res.getSpriteBounds("", texture)
	if w > 0 and worldScale > .05 then
		for i = -1, (screenWidth / worldScale) / w do
			for ii = -1, (screenHeight / worldScale) / h do
				local x = (w - screen.left) % (w) + (i * w)
				local y = (h - screen.top) % (h) + (ii * h)
				res.drawSprite(texture, x, y)
			end
		end
	end
	love.graphics.setStencilTest()
	love.graphics.pop()

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
	for i,v in pairs(objects.world) do
		drawObject(v)
	end

	--draw particles
	drawParticlesNative()
end

function drawObject(v)
	if not v.texture then
		local x,y = physicsToWorldTransform(v.x, v.y)
		drawangle = v.angle
		love.graphics.push()
		drawxp = v.xp
		drawyp = v.yp
		love.graphics.translate(x, y)
		love.graphics.scale(v.powerup_scale or 1)
		if v.flipx then love.graphics.scale(-1, 1) end
		res.drawSprite(v.sprite, 0, 0)
		love.graphics.pop()
		drawangle = 0
	end
end