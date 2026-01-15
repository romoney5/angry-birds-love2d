--particles

--menu is not used ingame
function drawParticlesNative(menu)
	if not particles then return end

	for _, p in _G.pairs(particles) do
		if menu and p.menu then
			setRenderState(0, 0, p.scale, p.scale, p.angle, p.spritePivotX, p.spritePivotY)
			_G.res.drawSprite(p.sprite, p.x / p.scale, p.y / p.scale)
		elseif not menu and not p.menu then
			setRenderState(-screen.left / p.scale, -screen.top / p.scale, worldScale * p.scale, worldScale * p.scale, p.angle, p.spritePivotX, p.spritePivotY)
			_G.res.drawSprite(p.sprite, p.x / p.scale, p.y / p.scale)
		end
	end
end

function loadParticleFile(name) -- check if this is correct?
	return-- loadLuaFile(scriptPath .. "/particles/" .. name, "", false)
end

function clearParticles()
	particles = {}
	particleAmount = 0
end

function drawMenuParticlesInAdvance() --what is it with particles
	return
end

function drawLevelParticlesNative(layer)
	return
end

function updateParticlesNative(dt, menu)
	if not particles then return end

	for k, v in pairs(particles) do
		local p = v

		if (menu and p.menu) or (not menu and not p.menu) then
			p.time = p.time + dt
			if p.time > p.lifeTime then
				table.remove(particles, k)
				particleAmount = particleAmount - 1
			else
				pt = particleTable.particles[p.type]
				p.xVel = p.xVel + pt.gravityX * dt
				p.yVel = p.yVel + pt.gravityY * dt
				p.x = p.x + p.xVel * dt
				p.y = p.y + p.yVel * dt
				p.angle = p.angle + p.angleVel * dt
				p.scale = p.scaleBegin + (p.scaleEnd - p.scaleBegin) * (p.time / p.lifeTime)
				
				if p.lifeTimeAnimation then
					index = math.ceil(#pt.sprites * (p.time / p.lifeTime))
					if index < 1 then index = 1 end
					if index > #pt.sprites then index = #pt.sprites end
					p.sprite = pt.sprites[index]
					if p.oldSprite ~= p.sprite then
						p.spritePivotX, p.spritePivotY = res.getSpritePivot(p.sheet, p.sprite)
						p.oldSprite = p.sprite
					end
				end
			end
		end
	end
end

--no, love does not run on an iphone 4
-- ignoreParticleLimits = true

local function addParticles(type, amount, x, y, w, h, angle, ignoreLimits, menu)
	local pt = particleTable.particles[type]
	if softLimitSimultaneousParticles < particleAmount + amount and not ignoreParticleLimits then
		amount = amount * 0.5
	end
	
	for i = 1, amount, 1 do
		if particleAmount < hardLimitSimultaneousParticles or ignoreLimits or ignoreParticleLimits then
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

				p.x = x + (_G.math.random(0, w) - 0.5*w ) * cos(angle)
				p.y = y + (_G.math.random(0, h) - 0.5*h ) * sin(angle)
				p.xVel, p.yVel = math.cos(angle) * vel, math.sin(angle) * vel
			else
				p.xVel, p.yVel = _G.math.random(mivx, mavx), _G.math.random(mivy, mavy)
			end

			p.angle = _G.math.random(p.minAngle or 1, p.maxAngle or 3.14)
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

			_G.table.insert(particles, p)
		end
	end
end

local function setHardLimit(limit)
	hardLimitSimultaneousParticles = limit
end

local function setSoftLimit(limit, multiplier)
	softLimitSimultaneousParticles = _G.math.random(limit, multiplier)
end

local function clear(kind)
	return
end

local function addLevelParticles(type, amount, x, y, w, h, angle, ignoreLimits, isWeather)
	--objects.levelParticles?
	return
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

		elseif i == "addLevelParticles" then
			return addLevelParticles

		elseif i == "native_addParticlesWithMode" then
			return native_addParticlesWithMode
		end
	end
}