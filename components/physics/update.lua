--update physics every frame

local function clamp(v, max)
	if v > max then return max end
	if v < -max then return -max end
	return v
end

function updateObjectMomentum(name)
	local obj = objects.world[name]
	if obj then
		obj.xVel, obj.yVel = obj.body:getLinearVelocity()
		--setVelocity(name, clamp(obj.xVel, 56), clamp(obj.yVel, 56))
		--angry birds limits momentum radially to 60 units
		local magnitude = math.sqrt(obj.xVel ^ 2 + obj.yVel ^ 2)
		if magnitude > 60 then
			setVelocity(name, obj.xVel * 60 / magnitude, obj.yVel * 60 / magnitude)
		end
	end
end

function updatePhysics(dt)
	if not physicsEnabled then return end
	updateParticlesNative(dt2)
	setRenderState(-screen.left - cameraShakeX, -screen.top - cameraShakeY, worldScale, worldScale, 0)
	
	physicsWorld:update(dt2 * physicsTimeScale, 10, 10) --ab uses 1/30, 10, 10
	
	removeBlocks()
	hasAwakeObjects = false
	hasMovingObjects = false
	
	local cx, cy = cursorPhysics.x, cursorPhysics.y
	for i,v in pairs(objects.world) do
		local obj = objects.world[i]
		if obj.body then
			obj.x, obj.y = obj.body:getPosition()
			if obj.x < objects.limits.mix
			or obj.x > objects.limits.max
			or obj.y < objects.limits.miy
			or obj.y > objects.limits.may then
				removeObject(i)
			else
				updateObjectMomentum(i)
				updateObjectMass(i)
				--_G.res.drawString("", _G.tostring(obj.density), obj.x * 20, obj.y * 20 + 20)
				obj.angle = (obj.body:getAngle() + math.pi) % (math.pi * 2) - math.pi

				if not hasMovingObjects and (math.abs(obj.xVel) >= .2 or math.abs(obj.yVel) >= .2) then hasMovingObjects = true end
				if not hasAwakeObjects and obj.body:isAwake() then hasAwakeObjects = true end

				--grab objects
				if checkObjectBounds(obj.x, obj.y, (obj.width or obj.radius) + 5, (obj.height or obj.radius) + 5, obj.angle, cx, cy) then
					if keyHold["RBUTTON"] then
						res.drawString("", obj.name, obj.x * 20, obj.y * 20 + 50)
						obj.body:setLinearVelocity((cx - obj.x) * 4, (cy - obj.y) * 4)
					end
				end
			end
		end
	end

	--ab aimbot
	if cameraTargetObject then
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