--objects and collisions

function removeObject(name)
	local obj = objects.world[name]
	if not toremove then toremove = {} end
	if obj then toremove[obj.name] = {name = obj.name, body = obj.body} end
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

function physicsPostSolve(obj1, obj2, contact)
	local b1 = obj1:getBody()
	local b2 = obj2:getBody()
	
	local o1 = obj1:getUserData()
	local o2 = obj2:getUserData()
	
	if not objects.world[o1.name] or not objects.world[o2.name] then return end
	
	if o1.controllable ~= true and o2.controllable ~= true then
		local rawDamage = getImpactForce(b1, b2) * 0.1
		
		applyDamage(o1, rawDamage)
		applyDamage(o2, rawDamage)
		
		if o1.strength <= 0 then
			local scoreValue = math.floor(rawDamage) * 10
			scoreTable["blocks"].score = scoreTable["blocks"].score + scoreValue
		else
			blockCollision(o1.name, o2.name, rawDamage, true)
		end
		removeBlocks()
	else
		local damageMultiplier = 1.0
		local velocityMultiplier = 1.0
		
		if o2.material then
			local damageFactors = blockTable.damageFactors[o2.material]
			if damageFactors then
				damageMultiplier = damageFactors.damageMultiplier
				velocityMultiplier = damageFactors.velocityMultiplier
			end
		end
		
		local impactMass = o1.mass * o2.mass
		local impactForce = getImpactForce(b1, b2) * velocityMultiplier
		
		local rawDamage = (impactForce * impactMass / 10) * damageMultiplier
		
		if o1.controllable and o2.strength and not o2.controllable then
			local defence = o2.defence or 0

			if rawDamage > defence then
				local strength = o2.strength
				local damageDealt = rawDamage - defence
				
				o2.strength = strength - damageDealt
				--if o1.useLegacyCollisionPath then
					--b1:setLinearDamping(velocityMultiplier)
				--end
			end
			
			birdCollision(o1.name, o2.name, impactForce, rawDamage)
			removeBlocks()
		end
	end
end