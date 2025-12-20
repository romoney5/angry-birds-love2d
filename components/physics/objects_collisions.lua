--objects and collisions

function removeObject(name)
	local obj = objects.world[name]
	obj.body:destroy()
	
	objects.world[name] = nil
	--if not toremove then toremove = {} end
	--if obj then toremove[obj.name] = {name = obj.name, body = obj.body} end
end

function setSleeping(object,dozing)
	if objects.world[object].body then
		objects.world[object].body:setAwake(not dozing)
	end
end

function setRotation(object,rotation)
	objects.world[object].angle = rotation % (math.pi * 2)
	if objects.world[object].body then
		objects.world[object].body:setAngle(rotation)
		objects.world[object].body:setAngularVelocity(0)
	end
end

function getAngle(object)
	return objects.world[object].angle
end

function setPosition(object,x,y)
	if not objects.world[object] then return end
	objects.world[object].x = x
	objects.world[object].y = y
	if objects.world[object].body then
		objects.world[object].body:setPosition(x, y)
		setVelocity(object, 0, 0)
	end
end

function setVelocity(object,x,y)
	if not objects.world[object] then return end
	objects.world[object].xVel = x
	objects.world[object].yVel = y
	if objects.world[object].body then
		objects.world[object].body:setLinearVelocity(x, y)
	end
end

function applyImpulse(object,x,y,xp,yp)
	local obj = objects.world[object]
	if obj.body then
		obj.body:applyLinearImpulse(x / 100, y / 100, xp or obj.x, yp or obj.y)
	end
end

function applyForce(object,x,y,xp,yp)
	local obj = objects.world[object]
	if obj.body then
		local mass = obj.mass
		obj.body:applyForce(x / 100, y / 100, xp, yp)
	end
end

function setAngularVelocity(object,a)
	local obj = objects.world[object]
	if obj and obj.body then
		obj.body:setAngularVelocity(a)
	end
end

function setMaterial(object,material)
	objects.world[object].material = material
end

function setTexture(object,texture)
	return
end

function setSprite(object,sprite)
	objects.world[object].sprite = sprite
end

function setRollingSound(object,rollingSound) --3.0.1 only
	objects.world[object].rollingSound = rollingSound
end

function setColliderType(object,collider) --3.0.1 only
	objects.world[object].collider = collider
end

function setSensor(object,sensor)
	objects.world[object].sensor = sensor
end

-- function physicsPreSolve(obj1,obj2,contact) --most work in progress thing ever
-- 	local b1 = obj1:getBody()
-- 	local b2 = obj2:getBody()
-- 	local o1,o2 = obj1:getUserData(),obj2:getUserData() --to get the physics.world object
-- 	if toremove and (toremove[o1.name] or toremove[o2.name]) then contact:setEnabled(false) return end
-- end


--vastly improved damage system, credits to halo
--[[
	TODO LIST :
	
	- fix contacts so that the birds no longer bounce off
	- tune damage handling to be game accurate
	- fix damage scores
]]

function getImpactForce(obj1, obj2)
	local vx, vy = obj1:getLinearVelocity()
	local m1 = obj1:getMass() * 100
	local velocityA = {x = vx * m1, y = vy * m1}
	
	local vx1, vy1 = obj2:getLinearVelocity()
	local m2 = obj2:getMass() * 100
	local velocityB = {x = vx1 * m2, y = vy1 * m2}
	
	local relativeSpeed = { x = velocityA.x - velocityB.x, y = velocityA.y - velocityB.y }
	local rawDamage = _G.math.sqrt(relativeSpeed.x^2 + relativeSpeed.y^2)
	
	return rawDamage
end

function applyDamage(obj, force)
	local defence = obj.defence or 0
	if force > defence then
		local damage = force - defence
		obj.strength = obj.strength - damage
	end
end

--used to be postsolve
function physicsBeginContact(obj1,obj2,contact)
	local b1 = obj1:getBody()
	local b2 = obj2:getBody()
	
	local o1 = obj1:getUserData()
	local o2 = obj2:getUserData()
	
	if not objects.world[o1.name] or not objects.world[o2.name] then return end
	
	if not o1.controllable and not o2.controllable then -- object to object collision
		
		local vx, vy = b1:getLinearVelocity()
		local m1 = b1:getMass() * 100
		local velocityA = {x = vx * m1, y = vy * m1}
		
		local vx1, vy1 = b2:getLinearVelocity()
		local m2 = b2:getMass() * 100
		local velocityB = {x = vx1 * m2, y = vy1 * m2}
		
		local relativeSpeed = { x =  velocityB.x - velocityA.x, y =  velocityB.x - velocityA.y}
		local linearForce = math.abs(_G.math.sqrt(relativeSpeed.x^2 + relativeSpeed.y^2)) * 0.1
		
		local currentScore = scoreTable.blocks.score
		
		local damage = 0
		local block1Destroyed = true
		if o2.strength then
			if o2.defence and linearForce < o2.defence then
				block1Destroyed = false
			end
			
			local finalDamage = linearForce - o2.defence
			local newStrength = o2.strength - finalDamage
			o2.strength = newStrength
			
			if newStrength >= 0 then damage = newStrength end
		end
		
		local block2Destroyed = true
		if o1.strength then
			if o1.defence and linearForce < o1.defence then
				block2Destroyed = false
			end
			
			local finalDamage = linearForce - o1.defence
			local newStrength = o1.strength - finalDamage
			o1.strength = newStrength
			
			if newStrength >= 0 then damage = damage + newStrength end
		end
		
		local damageDone = block1Destroyed or block2Destroyed
		blockCollision(o1.name, o2.name, linearForce, damageDone)
		
		if damage > 0 then
			local score = math.floor(linearForce) * 10.0
			scoreTable.blocks.score = currentScore + score
		end
		
	elseif o1.controllable ~= o2.controllable then -- bird to object collision
	
		local bird = o1
		local block = o2
		
		if block.controllable then
			bird = o2
			block = o1
		end
		
		local damageMultiplier = 1.0
		local velocityMultiplier = 1.0
		
		local damageFactor = blockTable.damageFactors[bird.damageFactors]
		local blockTable_damage = damageFactor.damageMultiplier[block.material]
		local blockTable_velocity = damageFactor.velocityMultiplier[block.material]
		
		if blockTable_damage then
			damageMultiplier = blockTable_damage
		end
		
		if blockTable_velocity then
			velocityMultiplier = blockTable_velocity
		end
		
		local birdMass = bird.body:getMass() * 100
		local vx, vy = bird.body:getLinearVelocity()
		
		local linearForce = (_G.math.sqrt(vx * vx + vy * vy) * birdMass) / 10.0
		
		local effectiveDamage = linearForce * damageMultiplier
		local damage = 0
		
		if objects.world[block.name] then
			if block.strength then
				local damageDealt = effectiveDamage
				if block.defence then
					damageDealt = damageDealt - block.defence
				end	
				
				if damageDealt > 0 then
					local newStrength = block.strength - damageDealt
					block.strength = newStrength
					
					if newStrength < 0 then
						-- NOTE : there exists a false case here, however since it's unused i didn't bother adding it.
						if bird.useLegacyCollisionPath then
							local overkillDamage = ((-newStrength / birdMass) / effectiveDamage) * 10.0 * 1.75
							if overkillDamage > 1.0 then
								overkillDamage = 1.0
							end
							
							local birdVelocityX = vx * overkillDamage
							local birdVelocityY = vy * overkillDamage
							setVelocity(bird.name, birdVelocityX, birdVelocityY)
							block.fixture:setSensor(true)
						end
					end
					
					damage = damageDealt
				end
			
			end
		end
		
		birdCollision(bird.name, block.name, effectiveDamage, math.floor(damage))
	else -- bird to bird collision 
	
		local vx, vy = b1:getLinearVelocity()
		local length = vx * vx + vy * vy
		
		local vx1, vy1 = b2:getLinearVelocity()
		local length1 = vx1 * vx1 + vy1 * vy1
		
		local collisionVelocity = math.sqrt(length)
		local mass = o1.mass
		
		if length < length1 then
			collisionVelocity = math.sqrt(length1)
			mass = o2.mass
		end
		
		local force = (collisionVelocity * mass) / 10.0
		
		birdCollision(o1.name, o2.name, force, 0)
	end
	
	removeBlocks()
end