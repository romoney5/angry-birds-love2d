--update physics every frame

function solvePhysics(updateStep) -- WIP
	local delta = math.floor(dt2 * 10000) / 10000
	local timeStep = delta * (physicsTimeScale or 1)
	timeStep = math.floor(timeStep * 10000) / 10000
	local velocityIterations = 10
	local positionIterations = 10
	
	if dt2 > 0.0 then
		WorldSolve({
			dt = timeStep,
			velocityIterations = velocityIterations,
			positionIterations = positionIterations
		})
	end

	if updateStep then
		physicsWorld:update(timeStep, velocityIterations, positionIterations) -- where do we call this?
	end	
	--return timeStep, velocityIterations, positionIterations --ab uses 1/30, 10, 10
end

local function getObjectCount()
	local total = 0
	
	for _, count in pairs(objects.counts) do
		total = total + count
	end
	
	return total
end

function updatePhysics(dt)
	if isPhysicsEnabled() ~= true then                 
		return
	end
	
	if physicsSpeedFactor ~= physicsTimeScale then -- nifty hack, should probably change it later
		physicsTimeScale = physicsSpeedFactor
	end
	--[[ TODO : fix this
	if LevelParticlesManager.initialized then
		LevelParticlesManager.start()
	else
		LevelParticlesManager.firstFrame()
	end
	]]

	if waterUpdate then waterUpdate() end

	updateGameParticlesNative(dt2)
	setRenderState(-screen.left - (cameraShakeX or 0), -screen.top - (cameraShakeY or 0), worldScale, worldScale, 0)
	
	for _, v in pairs(objects.world) do
		local PHYSICS_TIMESTEP = 1/30
		if v.friction or not v.gravityEnabled then
			updateFriction(v, PHYSICS_TIMESTEP)
			updateForceAdder(v, PHYSICS_TIMESTEP)
		end
	end
	
	for name, teleporter in pairs(activeTeleporters) do
		local objectBody = teleporter.object.body
		
		if objectBody:isDestroyed() then
			activeTeleporters[name] = nil
		else
			local isComplete = teleporter:update(dt)
			
			if isComplete then
				teleporter.finished = true
			end
		end
	end

	if applyForcesAtPhysicsStep then applyForcesAtPhysicsStep() end
	
	solvePhysics(true)

	if clearLuaForceFunctions then clearLuaForceFunctions() end
	
	if removeBlocks then
		removeBlocks()
	end
	
	hasAwakeObjects = false
	hasMovingObjects = false
	hasMovingObjectsAboveTolerance = false
	
	local objIndex = 0
	local rollingVolumes = {}
	local cx, cy = cursorPhysics.x, cursorPhysics.y
	for _, obj in pairs(objects.world) do
		if obj.body and not obj.body:isDestroyed() then
			obj.x, obj.y = obj.body:getPosition()
			
			local bDef = getObjectDefinition(obj.name)
			local xVel, yVel = obj.body:getLinearVelocity()
			local velMagnitude = xVel^2 + yVel^2
			local angularVelocity = obj.body:getAngularVelocity()
			
			if velMagnitude ~= 0 then
				obj.frozen = obj.y > 20.0 or obj.x < objects.limits.mix or obj.x > objects.limits.max
				obj.outsideBoundaries = obj.frozen
			end
			
			if obj.ignoreMotionCheck ~= true then
				if velMagnitude >= 0.0005 then
					hasMovingObjectsAboveTolerance = true
				end
				
				if velMagnitude >= 9.0 or angularVelocity >= 1.0 then
					hasMovingObjects = true
				end
			end
			
			obj.angle = (obj.body:getAngle() + math.pi) % (math.pi * 2) - math.pi
			obj.xVel = xVel
			obj.yVel = yVel
			hasAwakeObjects = true
			
			local mat = blockTable.materials[getMaterial(obj.name)]
			if obj.controllable ~= true and mat and obj.radius then
				local sound = mat.rollingSound
				if sound then
					local volume = math.min(1, math.abs(angularVelocity) * obj.mass / 400.0 * obj.body:getInertia())
					rollingVolumes[sound] = math.max(rollingVolumes[sound] or 0, volume)
				end
			end
			
			local bounceThreshold = 0.01
			local bounceMax = 4.0
			
			if obj.bounce.maxAmplitude > 0 then
				obj.bounce.time = obj.bounce.time + dt
				local factor = 1.0 - obj.bounce.time
				obj.bounce.amplitude = factor * obj.bounce.maxAmplitude * obj.bounce.frequencyMultiplier
				obj.bounce.amplitude = math.min(obj.bounce.amplitude, bounceMax)
				
				if obj.bounce.amplitude <= bounceThreshold then
					obj.bounce.time = 0
					obj.bounce.amplitude = 0
					obj.bounce.maxAmplitude = 0
				else
					local offset = (objIndex / getObjectCount()) * (math.pi / 2) -- rio uses an object index as an offset for every object
					local frequency = (obj.bounce.amplitude * 100 + obj.bounce.frequencyMultiplier * 5) * obj.bounce.time + offset
					
					local scaleX = 1 + math.sin(frequency) * obj.bounce.amplitude
					local scaleY = 1 - math.sin(frequency) * obj.bounce.amplitude 

					obj.scale = { x = scaleX, y = scaleY }
				end
			end
			
			if selectObjectAnimation then
				selectObjectAnimation(obj.name, math.sqrt(velMagnitude), obj.angle, dt)
			end
			
			objIndex = objIndex + 1
		end
	end
	
	for _, joint in pairs(objects.joints) do
		if not joint.joint:isDestroyed() then
			local physicsJoint = joint.joint
			local jointType = physicsJoint:getType()
			if joint.backAndForth then
				local angle
				if jointType == "prismatic" then
					angle = physicsJoint:getJointTranslation()
				elseif jointType == "revolute" then
					angle = physicsJoint:getJointAngle()
				end
				
				if joint.direction == 1 and angle >= joint.upperLimit then
					joint.direction = -1
					physicsJoint:setMotorSpeed(-joint.motorSpeed)
				elseif joint.direction == -1 and angle <= joint.lowerLimit then
					joint.direction = 1
					physicsJoint:setMotorSpeed(joint.motorSpeed)
				end
			end
			
			if joint.destroyTimer then
				joint.destroyTimer = joint.destroyTimer - dt
				if joint.destroyTimer <= 0 then
					destroyJoint(joint.name)
				end
			end
		end
	end
	
	for rollingSound, volume in pairs(rollingVolumes) do
		if volume > 0 then
			if not res.isAudioPlaying(rollingSound) then
				res.playAudio(rollingSound, volume, true, 2)
			else
				cachedaudios[rollingSound]:setVolume(volume) -- make a standalone function for this?
			end
		else
			res.stopAudio(rollingSound)
		end
	end

	--ab aimbot
	if not releaseBuild then
		updatePhysicsCheats(dt)
	end
end

---- SOLVE FUNCTION ----
function WorldSolve(step)
	step.dt = 1/60 * (physicsTimeScale or 1)
	
	if step.dt > 0 then
		step.inv_dt = 1.0 / step.dt
	else
		step.inv_dt = 0
	end
	
	local dt = step.dt
	local inv_dt = step.inv_dt	
	local velocityIterations = step.velocityIterations
	local positionIterations = step.positionIterations
	
	for name, object in pairs(objects.world) do
		local body = object.body
		
		if body and not body:isDestroyed() and body:getType() == "dynamic" then
			local vx, vy = object.xVel, object.yVel
			
			--- calculate speed then limit it.
			local translationSq = vx*vx + vy*vy
			local EPSILON = 1.1920929e-07
			
			local maxVel = b2_maxTranslation * inv_dt
			local maxVelSquared = b2_maxTranslationSquared * inv_dt ^ 2
			
			if translationSq > maxVelSquared then
				local translationMag = math.sqrt(translationSq)
				
				if translationMag > EPSILON then
					local dir = maxVel / translationMag
					
					vx = vx * dir
					vy = vy * dir
					
					body:setLinearVelocity(vx, vy)
				end
			end
		end
	end
end

function setMaxTranslation(translation)
	b2_maxTranslation = translation * 0.5 -- TODO : tune this to be game accurate
	b2_maxTranslationSquared = b2_maxTranslation * b2_maxTranslation
end