--particles

function drawParticlesNative()
	for _, p in _G.pairs(particles) do
		setRenderState(-screen.left/p.scale, -screen.top/p.scale, worldScale*p.scale, worldScale*p.scale, p.angle, p.spritePivotX, p.spritePivotY)
		_G.res.drawSprite(p.sprite, p.x/p.scale, p.y/p.scale)--p.sheet, p.sprite, p.x/p.scale, p.y/p.scale)
	end
end

function updateParticlesNative(dt)
	for k, v in pairs(particles) do
		local p = v
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

--no, love does not run on an iphone 4
ignoreParticleLimits = true

getAddParticles = {__index = function(self,i)
	if i == "addParticles" then
		return function(type, amount, x, y, w, h, angle)
				local pt = particleTable.particles[type]
				if softLimitSimultaneousParticles < particleAmount + amount and not ignoreParticleLimits then
					amount = amount * 0.5
				end
				
				for i = 1, amount, 1 do
					if particleAmount < hardLimitSimultaneousParticles or ignoreParticleLimits then
						particleAmount = particleAmount + 1
						local p = { }
						p.x = x + (_G.math.random(0, w) - 0.5*w ) -- * cos(angle)
						p.y = y + (_G.math.random(0, h) - 0.5*h ) -- * sin(angle)
						local mivx,mavx = pt.minVel,pt.maxVel
						local mivy,mavy = pt.minVel,pt.maxVel
						if pt.emitter_box then
							if pt.emitter_box.minVelX then
								mivx,mavx, mivy,mavy = pt.emitter_box.minVelX,pt.emitter_box.maxVelX,
														pt.emitter_box.minVelY,pt.emitter_box.maxVelY
							else
								mivx,mavx, mivy,mavy = pt.emitter_box.minVel,pt.emitter_box.maxVel,
														pt.emitter_box.minVel,pt.emitter_box.maxVel
							end end
						if pt.emitter_circle then mivx,mavx, mivy,mavy = pt.emitter_circle.minVel,pt.emitter_circle.maxVel,
																	pt.emitter_circle.minVel,pt.emitter_circle.maxVel end

						p.xVel,p.yVel = _G.math.random(mivx, mavx), _G.math.random(mivy, mavy)
						p.angle = _G.math.random(1, 3.14)
						p.angleVel = _G.math.random(pt.minAngleVel, pt.maxAngleVel)
						p.scaleBegin = _G.math.random(pt.minScaleBegin, pt.maxScaleBegin)
						p.scaleEnd = _G.math.random(pt.minScaleEnd, pt.maxScaleEnd)
						p.scale = p.scaleBegin
						p.type = type
						p.sprite = pt.sprites[_G.math.random(1, #pt.sprites)]
						p.sheet = pt.sheet
						p.time = 0
						p.lifeTime = pt.lifeTime
						p.lifeTimeAnimation = pt.animation == "lifeTime"

						if p.lifeTimeAnimation then
							p.sprite = pt.sprites[1]
						end
						p.oldSprite = p.sprite
						p.spritePivotX, p.spritePivotY = _G.res.getSpritePivot(p.sheet, p.sprite)

						_G.table.insert(particles, p)
					end
				end
			end
	elseif i == "clear" then
		return function(kind)
			return
		end
	end
end}