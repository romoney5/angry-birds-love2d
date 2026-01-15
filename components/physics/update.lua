--update physics every frame

function solvePhysics()
	local timeStep = dt2 * physicsTimeScale
	local velocityIterations = 10
	local positionIterations = 10
	
	if dt2 > 0.0 then
		WorldSolve({
			dt = timeStep,
			velocityIterations = velocityIterations,
			positionIterations = positionIterations
		})
	end
	
	return timeStep, velocityIterations, positionIterations --ab uses 1/30, 10, 10
end

function updatePhysics(dt)
	if not physicsEnabled then return end
	
	if physicsSpeedFactor ~= physicsTimeScale then
		physicsTimeScale = physicsSpeedFactor
	end

	updateParticlesNative(dt2)
	setRenderState(-screen.left - (cameraShakeX or 0), -screen.top - (cameraShakeY or 0), worldScale, worldScale, 0)
	
	physicsWorld:update(solvePhysics())

	if removeBlocks then
		removeBlocks()
	end
	
	hasAwakeObjects = false
	hasMovingObjects = false
	hasMovingObjectsAboveTolerance = false
	
	local rollingVolumes = {
		light = 0,
		wood = 0, 
		rock = 0,
	}
	
	local cx, cy = cursorPhysics.x, cursorPhysics.y
	for _, obj in pairs(objects.world) do
		if obj.body and not obj.body:isDestroyed() then
			obj.x, obj.y = obj.body:getPosition()
			
			local xVel, yVel = obj.body:getLinearVelocity()
			local velMagnitude = xVel^2 +  yVel^2
			local angularVelocity = obj.body:getAngularVelocity()
			
			if velMagnitude ~= 0 then
				obj.frozen = obj.y > 20.0 or obj.x < objects.limits.mix or obj.x > objects.limits.max
			end
			
			if velMagnitude >= 0.0005 then
				hasMovingObjectsAboveTolerance = true
			end
			
			if velMagnitude >= 9.0 or angularVelocity >= 1.0 then
				hasMovingObjects = true
			end
			
			obj.angle = (obj.body:getAngle() + math.pi) % (math.pi * 2) - math.pi
			obj.xVel = xVel
			obj.yVel = yVel
			hasAwakeObjects = true
			
			local material = getMaterial(obj.name)
			local volume = (math.abs(angularVelocity) * obj.mass / 400.0) * obj.body:getInertia()
			
			if volume > 1.0 then
				volume = 1.0
			end

			if obj.type == "circle" and rollingVolumes[material] and volume > rollingVolumes[material] then
				rollingVolumes[material] = volume
			end
			
			--grab objects
			if not releaseBuild and keyHold.RBUTTON and checkObjectBounds(obj.x, obj.y, (obj.width or obj.radius) + 5, (obj.height or obj.radius) + 5, obj.angle, cx, cy) then
				res.drawString("", obj.name, obj.x * 20, obj.y * 20 + 50)
				obj.body:setLinearVelocity((cx - obj.x) * 4, (cy - obj.y) * 4)
			end
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
	
	for material, volume in pairs(rollingVolumes) do
		local rollingSound = blockTable.materials[material] and blockTable.materials[material].rollingSound
		
		if rollingSound then
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
	end

	--ab aimbot
	if not releaseBuild and cameraTargetObject then
		local obj = cameraTargetObject
		--_G.res.drawString("", _G.tostring(obj.xVel), obj.x * 20, obj.y * 20 + 50)
		--_G.res.drawString("", _G.tostring(obj.yVel), obj.x * 20, obj.y * 20 + 100)
		local x, y = 0, 0
		if keyHold["UP"] then y = y - 1 end
		if keyHold["DOWN"] then y = y + 1 end
		if keyHold["LEFT"] then x = x - 1 end
		if keyHold["RIGHT"] then x = x + 1 end

		if x ~= 0 or y ~= 0 then
			setVelocity(obj.name, x * 20, y * 20)
			setRotation(obj.name, math.atan2(obj.yVel or 0, obj.xVel or 1))
		end
	end
end

---- SOLVE FUNCTION ----
function WorldSolve(step)
	step.dt = 1/60
	
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
			local vx, vy = body:getLinearVelocity()
			
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