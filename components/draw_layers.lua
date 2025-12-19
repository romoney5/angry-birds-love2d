--draw bg, fg, and game

function drawThemeLayer(v)
	local px, py = res.getSpritePivot("",v[2])
	local w, h = res.getSpriteBounds("",v[2])
	local s = worldScale or 1
	local ext = v[7] or {}
	local scroll = (v.v or 0) * time
	ext.color = ext.color or {1,1,1,1}
	local color = {ext.color[1]*ext.color[4],ext.color[2]*ext.color[4],ext.color[3]*ext.color[4],ext.color[4]} --for premultiply alpha
	local bcolor
	if ext.bcolor then
		bcolor = {ext.bcolor[1]*ext.bcolor[4],ext.bcolor[2]*ext.bcolor[4],ext.bcolor[3]*ext.bcolor[4],ext.bcolor[4]} --for premultiply alpha
	end
	ext.y = ext.y or 0
	
	if w > 0 and s > .02 then
		local cr,cg,cb,ca = love.graphics.getColor()
		love.graphics.setColor(color)
		for x = -1,math.floor(screenWidth/w/s) do
			-- local i = #theme.bgLayers - k
			local xp = w * x + (v[6] or 0)
			local left = (-screen.left * v[3] / v[4] + scroll - cameraShakeX) % w
			local top = (-screen.top / v[4] - cameraShakeY)
			-- top = (-screen.top * v[3] / v[4] - cameraShakeY)

			setRenderState(xp+left, top, s * v[4], s*v[4], 0, px, py)

			if not (x ~= 0 and v[5] == false) then
				res.drawSprite(v[2],0,ext.y)
			end
		end
		love.graphics.setColor(cr,cg,cb,ca)
	end

	if ext.bcolor then
		setRenderState(0,-screen.top / v[4] - cameraShakeY,1,s*v[4],0,px,py)
		drawRect2(bcolor[1],bcolor[2],bcolor[3],bcolor[4],0,ext.y + (h-py-1),screenWidth,(screenHeight/s)+screen.top)
	end
end

function drawBackgroundNative()
	local theme = blockTable.themes[currentTheme]
	if not theme then return end
	setBGColor(theme.color.r,theme.color.g,theme.color.b)
	for _,v in ipairs(theme.bgLayers) do
		drawThemeLayer(v)
	end
end

function drawForegroundNative()
	local theme = blockTable.themes[currentTheme]
	if not theme then return end
	local s = worldScale or 1
	setRenderState(0,0,1,1)
	drawRect2(theme.groundColor.r/255,theme.groundColor.g/255,theme.groundColor.b/255,1,0,-screen.top*s,screenWidth,screenHeight+screen.top*s)
	for _,v in ipairs(theme.fgLayers) do
		v[3],v[4] = v[3] or 1,v[4] or 1.5
		drawThemeLayer(v)
	end
end

function drawGameNative() --work in progress
	-- return
	if cameraTargetObject then
		local obj = cameraTargetObject
		local y,x = 0,0
		if keyHold["UP"] then y = y - 1 end
		if keyHold["DOWN"] then y = y + 1 end
		if keyHold["LEFT"] then x = x - 1 end
		if keyHold["RIGHT"] then x = x + 1 end

		if y ~= 0 or x ~= 0 then
			setVelocity(obj.name,x*20,y*20)
			setRotation(obj.name,math.atan2(obj.yVel or 0, obj.xVel or 1))
		end
	end

	love.graphics.push()
	-- love.graphics.origin()
	local texture = blockTable.themes[currentTheme].texture

	love.graphics.stencil(function()
		if res.textureShader then love.graphics.setShader(res.textureShader) end
		for i,v in pairs(objects.world) do
			if v.texture then drawangle = v.angle local x,y = physicsToWorldTransform(v.x,v.y) res.drawSprite(v.sprite,x,y) end
		end
		if res.textureShader then love.graphics.setShader() end
	end, "replace", 1)
	love.graphics.setStencilTest("greater", .9)
	-- love.graphics.scale(2)
	-- drawangle = 0
	setRenderState(0,0,worldScale,worldScale)
	local w,h = res.getSpriteBounds("",texture)
	if w > 0 and worldScale > .05 then
		for i=-1,(screenWidth/worldScale)/w do
			for ii=-1,(screenHeight/worldScale)/h do
				local x = (w - screen.left)%(w) + (i*w)
				local y = (h - screen.top)%(h) + (ii*h)
				res.drawSprite(texture,x,y)
			end
		end
	end
	love.graphics.setStencilTest()
	love.graphics.pop()

	--trajectories (thanks again halo)
	local trSprites = {}
	for i=1,3 do trSprites[i-1] = "TRAIL_WHITE_"..i end
	trSprites[#trSprites+1] = "PARTICLE_SLINGDOT"

	for _,tr in ipairs(trajectory)do
		for _,v in ipairs(tr)do
			for i,vv in ipairs(v)do
				res.drawSprite(vv.s or trSprites[(i-1)%3], vv.x, vv.y)
			end
		end
	end

	--draw objects
	for i,v in pairs(objects.world) do
		drawObject(v)
	end
	-- drawObject(sonc)

	--draw particles
	drawParticlesNative()
end

function drawObject(v)
	if not v.texture then
		local x,y = physicsToWorldTransform(v.x,v.y)
		drawangle = v.angle
		love.graphics.push()
		drawxp = v.xp
		drawyp = v.yp
		love.graphics.translate(x,y)
		love.graphics.scale(v.powerup_scale or 1)
		if v.flipx then love.graphics.scale(-1, 1) end
		res.drawSprite(v.sprite,0,0)
		love.graphics.pop()
		drawangle = 0
	end
end