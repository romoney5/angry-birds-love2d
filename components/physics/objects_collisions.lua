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
	objects.world[object].angle = (rotation%(math.pi*2))
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
		objects.world[object].body:setPosition(x,y)
		setVelocity(object,0,0)
	end
end

function setVelocity(object,x,y)
	if not objects.world[object] then return end
	objects.world[object].xVel = x
	objects.world[object].yVel = y
	if objects.world[object].body then
		objects.world[object].body:setLinearVelocity(x,y)
	end
end

function applyImpulse(object,x,y,xp,yp)
	local obj = objects.world[object]
	if obj.body then
		obj.body:applyLinearImpulse(x/100,y/100,xp or obj.x,yp or obj.y)
	end
end

function applyForce(object,x,y,xp,yp)
	local obj = objects.world[object]
	if obj.body then
		local mass = obj.mass
		obj.body:applyForce(x/100, y/100, xp, yp)
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

function physicsPostSolve(obj1,obj2,contact,nimpulse,timpulse) --the very heart and soul of angry birds
	local o1,o2 = obj1:getUserData(),obj2:getUserData() --get the objects.world object
	if o2.controllable then o1,o2=o2,o1 end --prioritize bird over any block

	local veloc = nimpulse*10
	--velocity multiplier, halo
	if o1.controllable then
		veloc = veloc * (blockTable.damageFactors[o1.damageFactors or "DefaultDamageFactors"].velocityMultiplier[o2.material] or 1)
	end
	if toremove and (toremove[o1.name] or toremove[o2.name]) then contact:setEnabled(false) --skip this collision if the block already broke
	else

		local damage = 0
		local ucdamage = 0 --uncapped damage

		--obj 1 damage
		if o1.strength and not o1.controllable then
			local df = (blockTable.damageFactors[o2.damageFactors or "DefaultDamageFactors"].damageMultiplier[o1.material] or 1)
			ucdamage = (veloc * df)-(o1.defence or 0)
			damage = math.max(math.min(ucdamage, o1.strength),0)
			o1.strength = o1.strength - damage
		end

		--obj 2 damage
		if o2.strength and not o2.controllable then
			local df = (blockTable.damageFactors[o1.damageFactors or "DefaultDamageFactors"].damageMultiplier[o2.material] or 1)
			ucdamage = (veloc * df)-(o2.defence or 0)
			damage = math.max(math.min(ucdamage, o2.strength),0)
			o2.strength = o2.strength - damage
		end
			
		if enableDebug and (veloc >= 1 or o2.strength <= 0) and damage >= 0 then
			table.insert(collisionsList, 1, {o1 = o1.name, o2 = o2.name, veloc = math.floor(veloc*10)/10,
				damage = damage, m1 = math.floor((o1.strength+damage or -1)*10)/10,
				m2 = math.floor((o2.strength+damage or -1)*10)/10})
		end

		if o1.strength <= 0 or o2.strength <= 0 then
			contact:setEnabled(false) --make objects pass each other if one was broken
		end
		if deadBlocks and o1.strength <= 0 then deadBlocks[o1.name] = o1 end
		if deadBlocks and o2.strength <= 0 then deadBlocks[o2.name] = o2 end
		
		--call the collision function
		if objects.world[o1.name] and objects.world[o2.name] then
			if o1.controllable then
				birdCollision(o1.name,o2.name,veloc,math.floor(damage))
			else
				blockCollision(o1.name,o2.name,veloc,damage>=0)
				contact:setEnabled(true) --disable objects going through if neither are a bird
			end
			if damage >= 8 then
				if joystick then
					joystick:setVibration(damage/20,damage/20,.1)
				end
				-- cameraShake = math.max(damage/13,cameraShake or 0)
			end
		end

		--without this the objects don't go through, it must be a quirk of post solve
		--nearby blocks still move though
		if not contact:isEnabled() then
			local factor = 1 - (damage/ucdamage) --final damage output / max damage output (if object strength didn't dip under 0)
			setVelocity(o1.name,o1.xVel*factor,o1.yVel*factor)
			setVelocity(o2.name,o2.xVel*factor,o2.yVel*factor)
		end
		if (o1.strength <= 0 or o2.strength <= 0) then removeBlocks() end
	end
end