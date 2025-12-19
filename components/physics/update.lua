--update physics

function updatePhysics(dt)
	if not physicsEnabled then return end
	updateParticlesNative(dt2)
	setRenderState(-screen.left - cameraShakeX, -screen.top - cameraShakeY, worldScale, worldScale, 0)
	physicsWorld:update(dt2 * physicsTimeScale)
	hasMovingObjects = false
	local cx,cy = cursorPhysics.x,cursorPhysics.y
	for i,v in pairs(objects.world) do
		local obj = objects.world[i]
		if obj.body then
			obj.x,obj.y = obj.body:getPosition()
			if obj.x < objects.limits.mix
			or obj.x > objects.limits.max
			or obj.y < objects.limits.miy
			or obj.y > objects.limits.may then
				removeObject(i)
			else
				obj.xVel, obj.yVel = obj.body:getLinearVelocity()
				setVelocity(i, clamp(obj.xVel, 56), clamp(obj.yVel, 56))
				obj.angle = (obj.body:getAngle() + math.pi) % (math.pi * 2) - math.pi

				if not hasMovingObjects and (math.abs(obj.xVel) >= .2 or math.abs(obj.yVel) >= .2) then hasMovingObjects = true end

				--grab objects
				if checkObjectBounds(obj.x, obj.y, (obj.width or obj.radius) + 5, (obj.height or obj.radius) + 5, obj.angle, cx, cy) then
					if keyHold["RBUTTON"] then
						res.drawString("",obj.name,obj.x*20,obj.y*20+50)
						obj.body:setLinearVelocity((cx-obj.x)*4,(cy-obj.y)*4)
					end
				end
			end
		end
	end
end

function sign(a)
	return a > 0 and 1 or (a < 0 and -1 or 0)
end