--update physics

function updatePhysics(dt)
	if physicsEnabled then
		updateParticlesNative(dt2)
		setRenderState(-screen.left - cameraShakeX, -screen.top - cameraShakeY, worldScale, worldScale, 0)
		physicsWorld:update(dt2*physicsTimeScale)
		hasMovingObjects = false
		local cx,cy = cursorPhysics.x,cursorPhysics.y
		for i,v in pairs(objects.world) do
			local obj = objects.world[i]
			if obj.body then
				obj.x,obj.y = obj.body:getPosition()
				if obj.x < objects.limits.mix
				or obj.x > objects.limits.max
				or obj.y < objects.limits.miy
				or obj.y > objects.limits.may then removeObject(i) else

					obj.xVel,obj.yVel = obj.body:getLinearVelocity()
					setVelocity(i,clamp(obj.xVel,56),clamp(obj.yVel,56))
					obj.angle = (obj.body:getAngle()+math.pi)%(math.pi*2)-math.pi

					if not hasMovingObjects and (math.abs(obj.xVel) >= .2 or math.abs(obj.yVel) >= .2) then hasMovingObjects = true end

					if checkObjectBounds(obj.x,obj.y,(obj.width or obj.radius)+5, (obj.height or obj.radius)+5, obj.angle,cx,cy) then
						if keyHold["RBUTTON"] then
							res.drawString("",obj.name,obj.x*20,obj.y*20+50)
							obj.body:setLinearVelocity((cx-obj.x)*4,(cy-obj.y)*4)
						end
					end
				end
			end
		end

		-- local dt = dt*60
		-- sonc.x,sonc.y = sonc.body:getPosition()
		-- sonc.body:setLinearVelocity(sonc.xVel*5,sonc.yVel*5)
		-- sonc.body:setAngle(0)
		-- sonc.yVel = math.min(sonc.yVel + dt*(.21875),6)
		-- local accel = 0.046875*dt
		-- local decel = .5*dt
		-- local friction = accel
		-- local top = 6
		-- local jump = 6.5
		-- physicsWorld:rayCast(sonc.x,sonc.y,sonc.x,sonc.y+sonc.h*.5+.5,
		-- 	function(f,x,y,nx,ny,pos)
		-- 		sonc.yVel = dt*.1
		-- 		return 1
		-- 	end)
		-- if keyHold.A then
		-- 	if sonc.xVel>0 then
		-- 		sonc.xVel = sonc.xVel - decel
		-- 		if sonc.xVel<=0 then sonc.xVel = -decel end
		-- 	elseif sonc.xVel>-top then
		-- 		sonc.xVel = sonc.xVel - accel
		-- 		if sonc.xVel<=-top then sonc.xVel = -top end
		-- 	end
		-- end
		-- if keyHold.D then
		-- 	if sonc.xVel<0 then
		-- 		sonc.xVel = sonc.xVel + decel
		-- 		if sonc.xVel>=0 then sonc.xVel = decel end
		-- 	elseif sonc.xVel<top then
		-- 		sonc.xVel = sonc.xVel + accel
		-- 		if sonc.xVel>=top then sonc.xVel = top end
		-- 	end
		-- end

		-- if not keyHold.A and not keyHold.D then
		-- 	sonc.xVel = sonc.xVel - math.min(math.abs(sonc.xVel),friction)*sign(sonc.xVel)
		-- end
		-- if sonc.xVel>0 then sonc.flipx=false elseif sonc.xVel<0 then sonc.flipx=true end

		-- if keyPressed.SPACE then sonc.yVel = -jump end
		-- -- drawRect2(1,1,1,1,sonc.x,sonc.y,4,8)
	end
end

function sign(a)
	return a>0 and 1 or (a<0 and -1 or 0)
end