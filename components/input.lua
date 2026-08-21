--things related to keyboard, mouse, etc.

--hack, is the pressed cursor a touchscreen?
local isTouching = false

function love.keypressed(key)
	if key == "lshift" then key = "shift" end
	if key == "lctrl" then key = "control" end

	keyPressed[string.upper(key)] = true
	keyHold[string.upper(key)] = true
end

function love.keyreleased(key, scancode)
	if key == "lshift" then key = "shift" end
	if key == "lctrl" then key = "control" end

	keyReleased[string.upper(key)] = true
	keyHold[string.upper(key)] = false
end

function love.mousepressed(x, y, button, istouch, presses)
	if button == 1 then
		keyPressed.LBUTTON = true
		keyHold.LBUTTON = true
	elseif button == 2 then
		keyPressed.RBUTTON = true
		keyHold.RBUTTON = true
	elseif button == 3 then
		keyPressed.MBUTTON = true
		keyHold.MBUTTON = true
	end
end

function love.mousereleased(x, y, button, istouch, presses)
	if button == 1 then
		keyReleased.LBUTTON = true
		keyHold.LBUTTON = false
	elseif button == 2 then
		keyReleased.RBUTTON = true
		keyHold.RBUTTON = false
	elseif button == 3 then
		keyReleased.MBUTTON = true
		keyHold.MBUTTON = false
	end
end

local touches_done = 0

function updatePhysicsCheats(dt)
	local obj = cameraTargetObject
	
	--angry birds aimbot
	if obj then
		local x, y = 0, 0
		
		if joystick then
			x, y = joystick:getAxis(1), joystick:getAxis(2)
		end
		
		if keyHold["UP"] then y = y - 1 end
		if keyHold["DOWN"] then y = y + 1 end
		if keyHold["LEFT"] then x = x - 1 end
		if keyHold["RIGHT"] then x = x + 1 end

		if x ~= 0 or y ~= 0 then
			setVelocity(obj.name, x * 20, y * 20)
			setRotation(obj.name, math.atan2(obj.yVel or 0, obj.xVel or 1))
		end
	end
	
	--Krita
	local touch = touches[1]
	if isTouching and touch then
		touches_done = touches_done + 1
		local x, y = screenToPhysicsTransform(touch.x, touch.y)
		
		local name = "touch_"..touches_done
		
		if touches_done % 2 == 0 then
			createCircle(name, "BIRD_RED", x, y, 1, 0, 1, .5, false, 0)
			local obj = objects.world[name]
			obj.definition = "RedBird"
		end
	end
	
	--grab objects
	if keyHold.RBUTTON then
		for _, obj in pairs(objects.world) do
			if obj.body and not obj.body:isDestroyed()
			and checkObjectBounds(obj.x, obj.y, (obj.width or obj.radius) + 5, (obj.height or obj.radius) + 5, obj.angle, cx, cy) then
				res.drawString("", obj.name, obj.x * 20, obj.y * 20 + 50)
				obj.body:setLinearVelocity((cx - obj.x) * 4, (cy - obj.y) * 4)
			end
		end
	end
end

local prev_mouse_x, prev_mouse_y = 0, 0

function updateMouse(dt)
	--regular cursor
	local x, y = love.mouse.getPosition()
	x, y = x / displayScale, y / displayScale
	
	--only update the cursor if you are moving the mouse
	--for compatibility with gamepads
	if x ~= prev_mouse_x or y ~= prev_mouse_y then
		cursor.x = x
		cursor.y = y
		
		prev_mouse_x = x
		prev_mouse_y = y
	end
	
	if joystick then
		--gamepad logic
		updateGamepad(dt)
	end

	love.mouse.setVisible(deviceModel ~= "windows"
		or debugOpen or openPopups[1] ~= nil or something.on)
end

local prevTouches

function updateTouch()
	local mttouches = love.touch.getTouches()
	table.clear(touches)
	
	isTouching = false
	
	if #mttouches > 0 then
		for i, v in ipairs(mttouches) do
			local x, y = love.touch.getPosition(v)
			--pressure sensitivity for the two touchscreens that support it
			touches[i] = {x = x / displayScale, y = y / displayScale, p = love.touch.getPressure(v)}
			
			isTouching = true
		end
	elseif keyHold["LBUTTON"] then
		touches[1] = {x = cursor.x, y = cursor.y}
	end
	
	touchcount = #touches
	
	--update pinch to zoom
	if touches and prevTouches and #touches == 2 and #prevTouches == 2 then
		local dist = math.sqrt((touches[1].x - touches[2].x) ^ 2 + (touches[1].y - touches[2].y) ^ 2)
		local prevdist = math.sqrt((prevTouches[1].x - prevTouches[2].x) ^ 2 + (prevTouches[1].y - prevTouches[2].y) ^ 2)
		zoomLevel = zoomLevel + (dist - prevdist) / 16 / 28
		wantedZoomLevel = zoomLevel
	end
	
	prevTouches = touches
end

function love.wheelmoved(x, y)
	cursor.wheelTriggered = y ~= 0--true
	-- cursor.wheelTriggered = -y ~= 0
	cursor.wheel = y

	-- zoomLevel = zoomLevel + y/16
	wantedZoomLevel = wantedZoomLevel + y / 16

	-- if zoomLevel > 1.5 then zoomLevel = 1.5 end
	-- if wantedZoomLevel > 1.5 then wantedZoomLevel = 1.5 end
	-- if wantedZoomLevel > maxWorldScale then wantedZoomLevel = maxWorldScale end
	-- if wantedZoomLevel < maxWorldScale then wantedZoomLevel = maxWorldScale end
	-- if zoomLevel < -1.1 then zoomLevel = -1.1 end
end

function doesMouseClickSetsTouchCount() --probably returns if on windows
	return true
end

function setIsMultitouchMouseWheelSimulationEnabled()
	return true
end