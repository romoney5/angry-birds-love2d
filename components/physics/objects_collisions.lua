--functions related to objects and collisions

function removeObject(name)
	local obj = objects.world[name]

	if obj and obj.body then
		obj.body:destroy()
	end
	
	objects.world[name] = nil
end

function destroyJoint(name)
	local obj = objects.joints[name]

	if obj and obj.joint then
		obj.joint:destroy()
	end
	
	objects.joints[name] = nil
end

function setSleeping(object, dozing)
	if objects.world[object].body then
		objects.world[object].body:setAwake(not dozing)
	end
end

function setRotation(object, rotation)
	objects.world[object].angle = rotation % (math.pi * 2)
	if objects.world[object].body then
		objects.world[object].body:setAngle(rotation)
		objects.world[object].body:setAngularVelocity(0)
	end
end

function getAngle(object)
	return objects.world[object].angle
end

function setPosition(object, x, y)
	if not objects.world[object] then return end
	objects.world[object].x = x
	objects.world[object].y = y
	if objects.world[object].body then
		objects.world[object].body:setPosition(x, y)
		setVelocity(object, 0, 0)
	end
end

function setVelocity(object, x, y)
	if not objects.world[object] then return end
	objects.world[object].xVel = x
	objects.world[object].yVel = y
	if objects.world[object].body then
		objects.world[object].body:setLinearVelocity(x, y)
	end
end

function applyImpulse(object, x, y, xp, yp)
	local obj = objects.world[object]
	if obj.body then
		obj.body:applyLinearImpulse(x / 100, y / 100, xp or obj.x, yp or obj.y) --TODO: no division?
	end
end

function applyForce(object, x, y, xp, yp)
	local obj = objects.world[object]
	if obj.body then
		local mass = obj.mass
		obj.body:applyForce(x / 100, y / 100, xp, yp)
	end
end

function setAngularVelocity(object, a)
	local obj = objects.world[object]
	if obj and obj.body then
		obj.body:setAngularVelocity(a)
	end
end

function setMaterial(object, material)
	objects.world[object].material = material
end

function setTexture(object, texture)
	objects.world[object].texture = texture
end

function setSprite(object, sprite)
	objects.world[object].sprite = sprite
end

function setRollingSound(object, rollingSound) --3.0.1 only
	objects.world[object].rollingSound = rollingSound
end

function setColliderType(object, collider) --3.0.1 only
	objects.world[object].collider = collider
end

function setSensor(object,sensor)
	local obj = objects.world[object]
	if obj and obj.fixture then
		obj.sensor = sensor
		obj.fixture:setSensor(sensor)
	end
end

function setObjectParameter(object, parameter, value)
	local obj = objects.world[object]
	if obj then
		--NOTE: the c code subtracts 1 from parameter
		--print("setObjectParameter: "..object.." "..parameter.." "..value)
		if parameter == 1 then -- is object enabled
			if obj.body then
				obj.body:setActive(value == 1)
			end
		elseif parameter == 2 then -- set object type
			if obj.body then
				obj.body:setType(value == 0 and "static" or "dynamic")
			end
		elseif parameter == 3 then -- nothing
		elseif parameter == 4 then -- nothing
		elseif parameter == 5 then -- ?

		elseif parameter == 6 then -- ?

		end
	end
end

function getWorldPoint(object, x, y)
	local obj = objects.world[object]
	if obj and obj.body then
		return obj.body:getWorldPoint(x, y)
	end

	return 0, 0
end

function getLocalPoint(object, x, y)
	local obj = objects.world[object]
	if obj and obj.body then
		return obj.body:getLocalPoint(x, y)
	end

	return 0, 0
end

function setJointParameters(params)
	local obj = params and params.name and objects.joints[params.name]

	if obj then
		for k, v in pairs(params) do
			if k ~= "name" then
				obj[k] = v
			end
		end
	end
end


--vastly improved damage system, credits to halo

--used to be postsolve
function physicsBeginContact(obj1, obj2, contact)
	local b1 = obj1:getBody()
	local b2 = obj2:getBody()
	
	local o1 = obj1:getUserData()
	local o2 = obj2:getUserData()
	
	if not objects.world[o1.name] or not objects.world[o2.name] then return end
	solvePhysics()
	
	if not o1.controllable and not o2.controllable then -- object to object collision
		
		local vx, vy = b1:getLinearVelocity()
		local m1 = b1:getMass() * 100
		
		local vx1, vy1 = b2:getLinearVelocity()
		local m2 = b2:getMass() * 100
		
		local diffx = m2 * vx1 - m1 * vx
		local diffy = m2 * vy1 - m1 * vy
		
		local linearForce = _G.math.sqrt(diffx * diffx + diffy * diffy) * 0.1
		
		local currentScore = scoreTable.blocks.score
		
		local damage = 0
		local block1Destroyed = true
		if o2.strength then
			local defence = o2.defence or 0
			if linearForce < defence or o2.defence >= 1000 then
				block1Destroyed = false
			else
				local finalDamage = linearForce - defence
				local newStrength = o2.strength - finalDamage
				o2.strength = newStrength
				
				damage = newStrength
				if newStrength >= 0 then damage = finalDamage end
			end
		end
		
		local block2Destroyed = true
		if o1.strength then
			local defence = o1.defence or 0
			if linearForce < defence or o1.defence >= 1000 then
				block2Destroyed = false
			else
				local finalDamage = linearForce - defence
				local newStrength = o1.strength - finalDamage
				o1.strength = newStrength
				
				if newStrength >= 0 then
					damage = damage + finalDamage
				else
					damage = damage + newStrength
				end
			end
		end
		
		local damageDone = block1Destroyed or block2Destroyed
		
		if enableDebug and damageDone then
			table.insert(collisionsList, 1, {o1 = o1.name, o2 = o2.name, veloc = math.floor(linearForce * 10) / 10,
				damage = damage, m1 = math.floor((o1.strength + damage or -1) * 10) / 10,
				m2 = math.floor((o2.strength + damage or -1) * 10) / 10})
		end
		
		--assert(damage >= 0, "damage < 0 "..o1.name..", "..o2.name)
		
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
					local strength = block.strength
					local newStrength = strength - damageDealt
					block.strength = newStrength
					
					if newStrength < 0 then
						contact:setEnabled(false)
						
						if bird.useLegacyCollisionPath then
							local overkillDamage = ((-newStrength / birdMass) / effectiveDamage) * 10.0 * 1.75
							if overkillDamage > 1.0 then
								overkillDamage = 1.0
							end
							
							local birdVelocityX = vx * overkillDamage
							local birdVelocityY = vy * overkillDamage
							setVelocity(bird.name, birdVelocityX, birdVelocityY)
						else
							local overkillDamage = ((effectiveDamage - strength) / effectiveDamage) * velocityMultiplier
							if overkillDamage > 1.0 then
								overkillDamage = 1.0
							end
							
							local birdVelocityX = vx * overkillDamage
							local birdVelocityY = vy * overkillDamage
							setVelocity(bird.name, birdVelocityX, birdVelocityY)
						end
						
						damage = strength--math.min(damageDealt, strength)
					end
				end
			
			end
		end
		
		birdCollision(bird.name, block.name, effectiveDamage, math.floor(damage))
		if joystick and effectiveDamage >= 6 then
			--TODO: test this on not a 2 year-old offbrand switch pro controller
			joystick:setVibration(math.min(effectiveDamage / 30, 1), math.min(effectiveDamage / 20, 1), .1) --deliberately stronger on the right side
		end
			
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
	
	--use deadBlocks table in non-pc versions
	if deadBlocks then
		if o1.strength <= 0 then deadBlocks[o1.name] = o1 end
		if o2.strength <= 0 then deadBlocks[o2.name] = o2 end
	end
end