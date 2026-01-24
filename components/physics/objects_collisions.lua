--functions related to objects and collisions

function removeObject(name)
	local obj = objects.world[name]

	if obj and obj.body then
		obj.body:destroy()
		if not obj.controllable then
			objects.world[name] = nil -- DO NOT REMOVE THIS!!! 
		end
	end
	
	removeJoints()
end

function destroyJoint(name)
	local obj = objects.joints[name]

	if obj and obj.joint and not obj.joint:isDestroyed() then
		obj.joint:destroy()
	end
	
	objects.joints[name] = nil
end

function removeJoints()
	if g_jointsToDestroy then
		for jointName, joint in pairs(objects.joints) do
			if not objects.world[joint.end1] or not objects.world[joint.end2] then
				destroyJointDeferred(jointName)
				print(joint.end1, joint.end2)
			end
		end
		
		for _, jointName in ipairs(g_jointsToDestroy) do
			destroyJoint(jointName)
		end
	end
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

function getVelocity(object)
	if not objects.world[object] then return end
	return objects.world[object].xVel, objects.world[object].yVel
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

applyForceNative = applyForce

function setAngularVelocity(object, a)
	local obj = objects.world[object]
	if obj and obj.body then
		obj.body:setAngularVelocity(a)
	end
end

function setFriction(object, friction)
	local obj = objects.world[object]
	if obj and obj.fixture then
		obj.fixture:setFriction(friction)
	end
end

function setRestitution(object, restitution)
	local obj = objects.world[object]
	if obj and obj.fixture then
		obj.fixture:setRestitution(restitution)
	end
end

function setDensity(object, density)
	local obj = objects.world[object]
	if obj and obj.fixture then
		obj.fixture:setDensity(density)
	end
end

function getMaterial(object)
	return objects.world[object].material or objects.world[object].materialName
end

function setMaterial(object, material)
	if objects.world[object].materialName then
		objects.world[object].materialName = material
	else
		objects.world[object].material = material
	end
end

function setFilterMask(object, m)
	local obj = objects.world[object]
	if obj and obj.fixture then
		local categories, _, group = obj.fixture:getFilterData()
		obj.fixture:setFilterData(categories, m, group)
	end
end

function setFilterCategory(object, c) -- TODO : find the right filter categories (egg defender has a block mask for pigs)
	local obj = objects.world[object]
	if obj and obj.fixture then
		local categories, mask, group = obj.fixture:getFilterData()
		obj.fixture:setFilterData(c, mask, group)
	end
end

function getTrajectory(name)
	local trajectoryTable = {}
	local body = objects.world[name].body
	
	local startX = body:getX()
	local startY = body:getY()
	local xVel, yVel = body:getLinearVelocity()
	
	local timeStep = 1/30
	local velocityScale = 1.506
	local maxVel = b2_maxTranslation / velocityScale
	local gravity = worldgravity.y
	
	local velocityMagnitude = math.sqrt(xVel * xVel + yVel * yVel)
	if maxVel < velocityMagnitude then
        xVel = xVel / velocityMagnitude * maxVel
        yVel = yVel / velocityMagnitude * maxVel
	end
	
	local currentTime = 0
	for i = 1, 300 do
		local x = startX + xVel * currentTime
		local y = startY + yVel * currentTime + 
        (currentTime * currentTime * gravity * timeStep) +
        (gravity * currentTime * timeStep)
		
		
		local point = {x = x, y = y, t = currentTime}
		table.insert(trajectoryTable, math.floor(currentTime) + 1, point)
		currentTime = currentTime + timeStep
	end
	
	return trajectoryTable
end

-- RMF related stuff
function updateForceAdder(object, dt)
	
	local body = object.body
	
	local isForceEnabled = true
	if object.disableForce then
		isForceEnabled = not object.disableForce
	end
	
	if isForceEnabled then
		if object.applyForceInterval then
			if object.forceTime then
				object.forceTime = object.forceTime - dt
			else
				object.forceTime = object.applyForceInterval
			end
			
			if object.forceTime <= 0 then
				object.forceTime = object.forceTime + object.applyForceInterval
				
				setSprite(object.name, object.spriteWhenForceApplied)
				
				local volume = object.soundWhenForceAppliedVolume or 1.0
				local audio = object.soundWhenForceApplied
				
				if type(audio) == "table" then
					audio = audio[math.random(1, #audio)]
				end
				
				res.playAudio(audio, volume, false, 0)
				
			elseif object.forceTime < object.applyForceInterval * 0.9 then
				local currentSprite = object.sprite
				local sprite = object.damageSprite
				
				if sprite ~= currentSprite then
					setSprite(object.name, sprite)
				end
			end
		end
		
		local forceX = 0.0
		local forceY = 0.0
		local applyAsImpulse = object.forceTime and object.forceTime <= 0.0
		
		if object.forceRelative then
			local forceRelative = object.forceRelative
			if math.abs(forceRelative) > 0.0 then
				local bodyAngle = body:getAngle()
				forceX = math.cos(bodyAngle) * forceRelative
				forceY = math.sin(bodyAngle) * forceRelative
			end
		else
			local baseForce = object.force or 1.0 -- whatever this is???
			if object.forceX then
				forceX = baseForce * object.forceX
			end
			
			if object.forceY then
				forceY = baseForce * object.forceY
			end
		end
		
		if forceX ~= 0.0 or forceY ~= 0.0 then
			local velX, velY = body:getLinearVelocity()
						
			if object.targetVelocity then
				local maxVel = object.targetVelocity
			
				if maxVel <= math.abs(velX) then
					if velX * forceX > 0.0 then
						forceX = 0.0
					end
				end
				
				if maxVel <= math.abs(velY) then
					if velY * forceY > 0.0 then
						forceY = 0.0
					end
				end
			end
			
			if body:getType() == "dynamic" then
				body:setAwake(true)
				
				local centerX, centerY = body:getWorldCenter()
				local mass = object.mass
				local invMass = 1 / mass
				local invInertia = 1 / body:getInertia()
				local torque = centerX * forceY - centerY * forceX
				
				if applyAsImpulse then
					local vx = forceX * invMass + velX
					local vy = forceY * invMass + velY
					
					body:setLinearVelocity(vx, vy)
					--body:applyAngularImpulse(torque * invInertia)
				
				else
					applyForce(object.name, forceX * mass, forceY * mass, centerX, centerY)
					--body:applyTorque(torque)
				end
			end
		end
	end
end

function updateFriction(object, dt)

	local body = object.body
	
	local friction = object.friction
	local velX, velY = body:getLinearVelocity()
	--[[
	if friction ~= 0.0 then
		return applyForce(object.name, velX * friction, velY * friction, object.x, object.y)
	end
	]]
	
	local fx = 0.0
	local fy = 0.0
	
	if object.frictionXRelative then
		fx = object.frictionXRelative
	end
	
	if object.frictionYRelative then
		fy = object.frictionYRelative
	end
	
	if fx == 0.0 and fy == 0.0 then return end
	
	local angle = body:getAngle()
	local cosA = math.cos(angle)
	local sinA = math.sin(angle)
	
	local determinant = (cosA * cosA) + (sinA * sinA)
	if determinant ~= 0.0 then
		determinant = 1.0 / determinant
	end
	
	local appliedFriction = ((fx * cosA - sinA * fy) * determinant * velX) +
                            ((fy * cosA - sinA * fx) * determinant * velY)
							
	if appliedFriction < 0.0 then
		applyForce(object.name, velX * appliedFriction, velY * appliedFriction, object.x, object.y)
	end
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

function inheritTeleportation(object, others) --3.3.0
	--[[inheritTeleportation(flyingBird.name, {
      flyingBird.name .. "a",
      flyingBird.name .. "b",
      flyingBird.name .. "c"
    })]]
	return
end

function setSensor(object,sensor)
	local obj = objects.world[object]
	if obj and obj.fixture then
		obj.sensor = sensor
		obj.fixture:setSensor(sensor)
	end
end

--absw
setAsSensor = setSensor

function setLinearDamping(object, damping)
	local obj = objects.world[object]
	if obj and obj.body then
		obj.body:setLinearDamping(damping)
	end
end

function setActive(object, active)
	local obj = objects.world[object]
	if obj and obj.body then
		obj.body:setActive(active)
	end
end

function setVisible(object, visible)
	local obj = objects.world[object]
	if obj then
		obj.visible = visible
	end
end

--does the callback run immediately?
function getRayCastedObjects(info)
	local x1, y1 = info.x1, info.y1
	local x2, y2 = info.x2, info.y2
	local obj = objects.world[info.source]

	if not obj or (obj and obj.body and obj.fixture) then
		local hits = {}

		physicsWorld:rayCast(x1, y1, x2, y2, function(fixture, x, y, xn, yn, fraction)
			if not obj or fixture ~= obj.fixture then
				local body = fixture:getBody()
				local userdata = body and body:getUserData()
				local name = userdata and userdata.name
				if not name then return 1 end

				table.insert(hits, name)
				table.insert(hits, x)
				table.insert(hits, y)
				table.insert(hits, xn)
				table.insert(hits, yn)
				table.insert(hits, fraction)

				return 1
			end
		end)

		return hits
	end
end

function getIntersectingObjects(info)
	local x, y = info.x, info.y
	local left, right = info.left, info.right
	local up, down = info.up, info.down
    
    local hits = {}
        
	physicsWorld:queryBoundingBox(x - left, y - up, x + right, y + down, function(fixture)
		local body = fixture:getBody()
		local userdata = body and body:getUserData()
		local name = userdata and userdata.name
		
		if name then
			table.insert(hits, {
				name = name,
				fixture = fixture
			})
		end
		
		return true
	end)
	
	return hits
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
		elseif parameter == 5 then -- scale
			if obj.body then
				setScale(object, value)
			end
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

function resizeCircle(name, radius)
	local obj = objects.world[name]

	if obj.shape then
		--set the radius
		radius = math.max(radius, 0)
		obj.shape:setRadius(radius)
		obj.radius = radius
		obj.height = radius

		--and then remake the fixture
		local restitution, friction, density, category =
			obj.fixture:getRestitution(), obj.fixture:getFriction(), obj.fixture:getDensity(), obj.fixture:getCategory()
		obj.fixture:destroy()

		obj.fixture = love.physics.newFixture(obj.body, obj.shape, density)

		obj.fixture:setRestitution(restitution)
		obj.fixture:setFriction(friction)
		obj.fixture:setCategory(category)
		obj.fixture:setUserData(obj)

		updateObjectMass(name)
	end
end

function getRadius(name)
	local obj = objects.world[name]
	if obj then
		return obj.shape:getRadius()
	end
end

function getAngularVelocity(name)
	local obj = objects.world[name]
	if obj then
		return obj.body:getAngularVelocity()
	end
end

function setScale(name, scale)
	local obj = objects.world[name]
	if obj then
		obj.scale = scale
		-- if obj.type == "circle" then
		-- 	resizeCircle(name, obj.radius * obj.scale)
		-- end
	end
end

function getScale(name)
    local obj = objects.world[name]
    if obj then
        return obj.scale or 1
    end
end

--5.0.1
--[[
function addObjectUpdateFunction(name, f)
	if object.updateFunction == nil then
		object.updateFunction = f
    elseif _G.type(object.updateFunction) == "table" and not contains(object.updateFunction, f) then
        _G.table.insert(object.updateFunction, f)
	elseif _G.type(r0_205.updateFunction) == "function" then
		local old = object.updateFunction
		object.updateFunction = {old, f}
		local meta = {
		  __call = function(fl, o, dt)
			for _, v in _G.ipairs(fl) do
			  v(o, dt)
			end
		  end
		}
		_G.setmetatable(object.updateFunction, meta)
	else
		_G.assert(false)
	end
	gameUpdateFunctions[object.name] = object.updateFunction
end
]]

function destroyBreakableJoints(name, force)
	for _, joint in pairs(objects.joints) do
		if joint.end1 == name or joint.end2 == name then
			if not joint.joint:isDestroyed() and joint.breakable then
				if force >= joint.breakForce then
					destroyJoint(joint.name)
				end
			end
		end
	end
end
--[[
	this function is supposed to roughly estimate box2D's restitution
	i commented it in its unfinished state, so feel free to work on it.
	
function postSolveBounce(o1, o2, contact)
	local b1 = o1.body
	local b2 = o2.body
	local cx, cy = contact:getPositions()
	
	local function vec4(x, y, x1, y1)
		local table = {x = x, y = y, x1 = x1, y1 = y1}
		return table
	end
	
	local function isStatic(b)
		return b:getType() == "static"
	end

	if cx then
		local nx, ny = contact:getNormal()
		
        local cmx, cmy = b1:getWorldCenter()
        local cmx1, cmy1 = b2:getWorldCenter()
		
		local relativeVector = vec4(cx - cmx, cy - cmy, cx - cmx1, cy - cmy1)
		
        local velXa, velYa = b1:getLinearVelocity()
        local velXb, velYb = b2:getLinearVelocity()
        local w1, w2 = b1:getAngularVelocity(), b2:getAngularVelocity()
		
        local pointVelocity = vec4(velXa - w1 * relativeVector.y, 
				velYa + w1 * relativeVector.x, 
				velXb - w2 * relativeVector.y1, 
				velYb + w2 * relativeVector.x1)
		
        local rvx, rvy = pointVelocity.x1 - pointVelocity.x, pointVelocity.y1 - pointVelocity.y
        local velAlongNormal = rvx * nx + rvy * ny
		
		print(velAlongNormal, o1.name, o2.name)
		
		if velAlongNormal > -3.0 then -- velocity normal on hit
			local inv_mass_a = isStatic(b1) and 0 or 1 / b1:getMass()
			local inv_inertia_a = isStatic(b1) and 0 or 1 / b1:getInertia()
			
			local inv_mass_b = isStatic(b2) and 0 or 1 / b2:getMass()
			local inv_inertia_b = isStatic(b2) and 0 or 1 / b2:getInertia()
			
			local relativeNormal_A = relativeVector.x * ny - relativeVector.y * nx
            local relativeNormal_B = relativeVector.x1 * ny - relativeVector.y1 * nx
			local kNormal = inv_mass_a + inv_mass_b + (relativeNormal_A ^ 2 * inv_inertia_a) 
							+ (relativeNormal_B ^ 2 * inv_inertia_b)
	
            local restitution = math.max(o1.restitution, o2.restitution)
            local normalImpulse = (-(1 + restitution) * velAlongNormal) / kNormal
			
			local tangentX, tangentY = -ny, nx
			local relativeTangent_A = relativeVector.x * tangentY - relativeVector.y * tangentX
            local relativeTangent_B = relativeVector.x1 * tangentY - relativeVector.y1 * tangentX
			local kTangent = inv_mass_a + inv_mass_b + (relativeTangent_A ^ 2 * inv_inertia_a) 
							+ (relativeTangent_B ^ 2 * inv_inertia_b)
			
            local velAlongTangent = rvx * tangentX + rvy * tangentY
            local friction = math.sqrt(o1.friction * o2.friction)
			local maxFriction = math.abs(normalImpulse) * friction
            local tangentImpulse = math.max(-maxFriction, math.min(maxFriction, -velAlongTangent / kTangent))
			
			local forceX = (normalImpulse * nx) + (tangentImpulse * tangentX)
			local forceY = (normalImpulse * ny) + (tangentImpulse * tangentY)
			
			b1:applyLinearImpulse(-forceX, -forceY)
            b2:applyLinearImpulse(forceX, forceY)
			
            b1:applyAngularImpulse(-(relativeVector.x * forceY - relativeVector.y * forceX))
            b2:applyAngularImpulse( (relativeVector.x1 * forceY - relativeVector.y1 * forceX))
		end
	
	end
end
]]

--vastly improved damage system, credits to halo

--used to be postsolve
function physicsBeginContact(obj1, obj2, contact)
	local b1 = obj1:getBody()
	local b2 = obj2:getBody()
	
	local o1 = obj1:getUserData()
	local o2 = obj2:getUserData()
	
	if not objects.world[o1.name] or not objects.world[o2.name] then return end
	solvePhysics()
	
	local contactPoint = contact:getPositions()
	local contactNormal = contact:getNormal()
	
	if not o1.controllable and not o2.controllable then -- object to object collision
		
		local vx, vy = b1:getLinearVelocity()
		local m1 = b1:getMass() * 100
		
		local vx1, vy1 = b2:getLinearVelocity()
		local m2 = b2:getMass() * 100
		
		local diffx = m2 * vx1 - m1 * vx
		local diffy = m2 * vy1 - m1 * vy
		
		local linearForce = _G.math.sqrt(diffx * diffx + diffy * diffy) * 0.1
		
		local currentScore = scoreTable.blocks.score
		
		local ignoreAllDamage = o1.ignoreAllDamage or o2.ignoreAllDamage
		local damage = 0
		local block1Destroyed = true
		if o2.strength then
			local defence = o2.defence or 0
			if linearForce < defence or o2.defence >= 1000 or ignoreAllDamage then
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
			if linearForce < defence or o1.defence >= 1000 or ignoreAllDamage then
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
		
		local relativeSpeed = linearForce --* 6.0
		
		destroyBreakableJoints(o1.name, relativeSpeed)
		destroyBreakableJoints(o2.name, relativeSpeed)
		
		--assert(damage >= 0, "damage < 0 "..o1.name..", "..o2.name)
		damageDone = linearForce

		local old_score = currentScore
		
		if blockCollision then blockCollision(o1.name, o2.name, linearForce, damageDone, contactPoint, -contactNormal) end

		if joystick and linearForce >= 6 then
			joystick:setVibration(math.min(linearForce / 15, 1), math.min(linearForce / 15, 1), .1)
		end
		
		if currentScore == old_score and damage > 0 then
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
		
		--3.0.1 uses materialName instead of material
		local damageFactor = blockTable.damageFactors[bird.damageFactors]
		local blockTable_damage = damageFactor.damageMultiplier[getMaterial(block.name)]
		local blockTable_velocity = damageFactor.velocityMultiplier[getMaterial(block.name)]
		
		if blockTable_damage then
			damageMultiplier = blockTable_damage
		end
		
		if blockTable_velocity then
			velocityMultiplier = blockTable_velocity
		end
		
		local birdMass = bird.body:getMass() * 100
		local vx, vy = bird.body:getLinearVelocity()
		
		local linearForce = (_G.math.sqrt(vx * vx + vy * vy) * birdMass) / 10.0 -- the factor is 60.0 in newer versions
		
		local effectiveDamage = linearForce * damageMultiplier
		local damage = 0
		
		destroyBreakableJoints(block.name, linearForce)
		
		if objects.world[block.name] and block.ignoreAllDamage ~= true then
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
						
						local overkillDamage
						if bird.useLegacyCollisionPath then
							--60.0 * (math.abs(newStrength) / birdMass) / effectiveDamage * 1.2 NEW
							overkillDamage = ((-newStrength / birdMass) / effectiveDamage) * 10.0 * 1.75
						else
							overkillDamage = ((effectiveDamage - strength) / effectiveDamage) * velocityMultiplier
						end
						
						if overkillDamage > 1.0 then
							overkillDamage = 1.0
						end
						
						local birdVelocityX = vx * overkillDamage
						local birdVelocityY = vy * overkillDamage
						setVelocity(bird.name, birdVelocityX, birdVelocityY)
						
						damage = strength--math.min(damageDealt, strength)
					else
						damage = damageDealt
					end
				end
			
			end
		end
		
		if enableDebug and damage > 0 then
			table.insert(collisionsList, 1, {o1 = o1.name, o2 = o2.name, veloc = math.floor(linearForce * 10) / 10,
				damage = effectiveDamage, m1 = math.floor((o1.strength + damage or -1) * 10) / 10,
				m2 = math.floor((o2.strength + damage or -1) * 10) / 10})
		end
		
		if birdCollision then birdCollision(bird.name, block.name, effectiveDamage, math.floor(damage), contactPoint, contactNormal) end
		if joystick and effectiveDamage >= 6 then
			joystick:setVibration(math.min(effectiveDamage / 15, 1), math.min(effectiveDamage / 15, 1), .1)
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
		
		if birdCollision then birdCollision(o1.name, o2.name, force, 0, contactPoint, contactNormal) end
	end
	
	--use deadBlocks table in non-pc versions
	if deadBlocks then
		if o1.strength <= 0 then deadBlocks[o1.name] = o1 end
		if o2.strength <= 0 then deadBlocks[o2.name] = o2 end
	end
end