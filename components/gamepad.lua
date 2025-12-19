--gamepads

local gpcx, gpcy, gpc = 0, 0, 0 --gamepad cursor x/y, gamepad cooldown
joystick = nil

function registerGamepadKey(joystick, key, button) --check if a controller button is pressed and press a keyboard/mouse button accordingly
	local hold = keyHold[key]
	if button == false then
		keyHold[key] = nil
	else
		keyHold[key] = button == true and true or joystick:isGamepadDown(button)
	end

	if keyHold[key] and not hold then keyPressed[key] = true end
	if not keyHold[key] and hold then keyReleased[key] = true end
end

function updateGamepad(dt)
	if physicsEnabled then
		if not levelCompleted and (joystick:getAxis(1) ~= 0 or joystick:getAxis(2) ~= 0) and not cameraTargetObject then
			if currentBirdName ~= nil then
				local obj = objects.world[currentBirdName]
				panToBirdCamera()
				selectedBird = obj
			end
			registerGamepadKey(joystick, "LBUTTON", true)

			local sx,sy = physicsToWorldTransform(levelStartPosition.x,levelStartPosition.y)
			cursor.x, cursor.y = (sx - screen.left) * worldScale + (joystick:getAxis(1) * rubberBandMaximumLength() * 20 * worldScale),
				(sy - screen.top) * worldScale + (joystick:getAxis(2) * rubberBandMaximumLength() * 20 * worldScale)
			if joystick:isGamepadDown("a") then
				registerGamepadKey(joystick, "LBUTTON" ,false)
			end
			gpc = .01
		else
			if gpc > 0 then
				if not joystick:isGamepadDown("a") then
					gpc = gpc - dt
					if currentBirdName then
						gpc = 0
						if cancelBirdDrag then
							cancelBirdDrag()
						end
					end
				end
			else
				registerGamepadKey(joystick, "LBUTTON", "a")
			end
		end

		gameOptions.ui.enableCursor = false
	else
		--move cursor
		gpcx = math.max(20, math.min(gpcx + (joystick:getAxis(3 - 2) * 800 * dt),screenWidth - 20))
		gpcy = math.max(20, math.min(gpcy + (joystick:getAxis(4 - 2) * 800 * dt),screenHeight - 20))
		if gpc <= 0 then
			registerGamepadKey(joystick, "LBUTTON", "a")
			gameOptions.ui.enableCursor = true
			cursor.x = gpcx
			cursor.y = gpcy
		end
	end
	registerGamepadKey(joystick, "ESCAPE", "b")
	registerGamepadKey(joystick, "R", "x")
	registerGamepadKey(joystick, "RIGHT", "rightshoulder")
	registerGamepadKey(joystick, "LEFT", "leftshoulder")
	registerGamepadKey(joystick, "RBUTTON", "rightstick")
end