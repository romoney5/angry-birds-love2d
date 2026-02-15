--particles
local SCREEN = {}
local WORLD = {}
--menu is not used ingame
function drawParticlesNative(menu)
	if not particles then return end
	
	local activeParticles = menu and SCREEN or WORLD
	
	for _, p in _G.pairs(activeParticles) do
		if menu then
			setRenderState(0, 0, p.scale, p.scale, p.angle, p.spritePivotX, p.spritePivotY)
			_G.res.drawSprite(p.sprite, p.x / p.scale, p.y / p.scale)
		else
			setRenderState(-screen.left / p.scale, -screen.top / p.scale, (worldScale or 1) * p.scale, (worldScale or 1) * p.scale, p.angle, p.spritePivotX, p.spritePivotY)
			_G.res.drawSprite(p.sprite, p.x / p.scale, p.y / p.scale)
		end
	end
end

function loadParticleFile(name) -- check if this is correct?
	return-- loadLuaFile(scriptPath .. "/particles/" .. name, "", false)
end

function clearParticles()
	WORLD = {}
	SCREEN = {}
	particleAmount = 0
	restoreParticles()
end

function drawMenuParticlesInAdvance() --what is it with particles
	return
end

function drawScreenParticles()
	return
end

function drawLevelParticlesNative(layer)
	return
end

local updateParticles = function(dt, activeParticles)
	for i = #activeParticles, 1, -1 do
		local p = activeParticles[i]

		p.time = p.time + dt
		--[[
		local weather = LevelParticlesManager.getWeatherParticles()
		local isWeatherParticle = activeParticles == WORLD and LevelParticlesManager.initialized
		local offScreen = isWeatherParticle and (p.y > weather.height or p.x > weather.width)
		]]
		
		local levelParticles = LevelParticlesManager.getLevelParticles()
		local isWeatherParticle = activeParticles == WORLD and g_levelParticlesEnabled
		local offScreen = isWeatherParticle and (p.y > (levelParticles.height or 0.0) or p.x > levelParticles.width)
		
		if p.time > p.lifeTime or offScreen then
			table.remove(activeParticles, i)
			particleAmount = particleAmount - 1
		else
			pt = particleTable.particles[p.type]
			
			p.xVel = p.xVel + pt.gravityX * dt
			p.yVel = p.yVel + pt.gravityY * dt
			p.x = p.x + p.xVel * dt
			p.y = p.y + p.yVel * dt
			p.angle = p.angle + p.angleVel * dt
			
			local t = p.time / p.lifeTime
			p.scale = p.scaleBegin + (p.scaleEnd - p.scaleBegin) * t
			
			if p.lifeTimeAnimation then
				local sprite_count = #pt.sprites
				index = math.ceil(sprite_count * t)
				
				if index < 1 then index = 1 end
				if index > sprite_count then index = sprite_count end
				
				p.sprite = pt.sprites[index]
				
				if p.oldSprite ~= p.sprite then
					p.spritePivotX, p.spritePivotY = res.getSpritePivot(p.sheet, p.sprite)
					p.oldSprite = p.sprite
				end
			end
		end
	end
end

function updateScreenParticlesNative(dt)
	updateParticles(dt, SCREEN)
end

function updateGameParticlesNative(dt)
	updateParticles(dt, WORLD)
end

function updateParticlesNative(dt)

end

--no, love does not run on an iphone 4
-- ignoreParticleLimits = true

local function addParticles(type, amount, x, y, w, h, angle, ignoreLimits, menu)
	if not particleTable.particles then return end
	local pt = particleTable.particles[type]
	if softLimitSimultaneousParticles < particleAmount + amount and not ignoreLimits then
		amount = amount * 0.5
	end

	for i = 1, amount, 1 do
		if particleAmount < hardLimitSimultaneousParticles or ignoreLimits then
			particleAmount = particleAmount + 1
			local p = { }
			p.x = x + (_G.math.random(0, w) - 0.5*w ) -- * cos(angle)
			p.y = y + (_G.math.random(0, h) - 0.5*h ) -- * sin(angle)
			local mivx,mavx = pt.minVel or 0, pt.maxVel or 0
			local mivy,mavy = pt.minVel or 0, pt.maxVel or 0
			if pt.emitter_box then
				if pt.emitter_box.minVelX then
					mivx, mavx, mivy, mavy = pt.emitter_box.minVelX,pt.emitter_box.maxVelX,
											pt.emitter_box.minVelY,pt.emitter_box.maxVelY
				else
					mivx, mavx, mivy, mavy = pt.emitter_box.minVel,pt.emitter_box.maxVel,
											pt.emitter_box.minVel,pt.emitter_box.maxVel
				end
			end
			
			local circle = ((pt.minAngleEmitter ~= nil and pt.maxAngleEmitter ~= nil) and 1) or (pt.emitter_circle ~= nil and 2) or nil
			if circle then
				local emitter_circle = pt.emitter_circle or pt
				local min, max = emitter_circle.minAngleEmitter or -180, emitter_circle.maxAngleEmitter or 180
				local angle = math.random(min, max) * math.pi / 180
				local vel = math.random(emitter_circle.minVel or 0, emitter_circle.maxVel or 0)
				local minAngle = p.minAngle and p.minAngle * math.pi / 180 or 0
				local maxAngle = p.maxAngle and p.maxAngle * math.pi / 180 or 0

				p.x = x + (_G.math.random(0, w) - 0.5*w ) * cos(angle)
				p.y = y + (_G.math.random(0, h) - 0.5*h ) * sin(angle)
				p.angle = _G.math.random(minAngle, maxAngle)
				p.xVel, p.yVel = math.cos(angle) * vel, math.sin(angle) * vel
			else
				p.xVel, p.yVel = _G.math.random(mivx, mavx), _G.math.random(mivy, mavy)
				p.angle = _G.math.random(1, 3.14)
			end
			-- i don't know if this is applied elsewhere
			if type == "theme15rain" then			
				p.angle = math.atan2(p.yVel, p.xVel)
			end
				
			p.angleVel = _G.math.random(pt.minAngleVel or 0, pt.maxAngleVel or 0)
			p.scaleBegin = _G.math.random(pt.minScaleBegin or 0, pt.maxScaleBegin or 0)
			p.scaleEnd = _G.math.random(pt.minScaleEnd or 0, pt.maxScaleEnd or 0)
			p.scale = p.scaleBegin
			p.type = type
			p.sprite = pt.sprites[_G.math.random(1, #pt.sprites)]
			p.sheet = pt.sheet
			p.time = 0
			p.lifeTime = pt.lifeTime
			p.lifeTimeAnimation = pt.animation == "lifeTime"

			p.menu = menu

			if p.lifeTimeAnimation then
				p.sprite = pt.sprites[1]
			end
			p.oldSprite = p.sprite
			p.spritePivotX, p.spritePivotY = _G.res.getSpritePivot(p.sheet, p.sprite)

			if menu then
				_G.table.insert(SCREEN, p)
			else
				_G.table.insert(WORLD, p)
			end
		end
	end
end

local function addParticles2(type, amount, x, y, w, h, angle, ignoreLimits, menu) --different parameters
	return
end

local function setHardLimit(limit)
	hardLimitSimultaneousParticles = limit
end

local function setSoftLimit(limit, multiplier)
	softLimitSimultaneousParticles = _G.math.random(limit, multiplier)
end

local function clear(kind)
	if kind then
		for k in ipairs(kind) do
			kind[k] = nil
		end
	end
end

local function addLevelParticles(...)
	addParticles(...)
end

--absw
local function native_addParticlesWithMode(particle)
	return
end

getParticles = {
	__index = function(self, i)
		if i == "addParticles" then
			return addParticles
		elseif i == "setHardLimit" then
			return setHardLimit
		elseif i == "setSoftLimit" then
			return setSoftLimit
		elseif i == "clear" then
			return clear
		elseif i == "SCREEN" then
			return SCREEN
		elseif i == "WORLD" then
			return WORLD
		elseif i == "addLevelParticles" then
			return addLevelParticles

		elseif i == "native_addParticlesWithMode" then
			return native_addParticlesWithMode

		elseif i == "update" then
			return updateParticlesNative
		elseif i == "add" then
			return addParticles2
		end
	end
}