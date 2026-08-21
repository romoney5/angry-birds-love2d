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
	local x, y = joystick:getAxis(1), joystick:getAxis(2)
	-- if math.abs(x) < .1 then x = 0 end
	-- if math.abs(y) < .1 then y = 0 end
	if math.abs(x) < .1 and math.abs(y) < .1 then
		x, y = 0, 0
	end

	if physicsEnabled then
		if not levelCompleted and (x ~= 0 or y ~= 0) and not cameraTargetObject then
			if currentBirdName ~= nil then
				local obj = objects.world[currentBirdName]
				panToBirdCamera()
				selectedBird = obj
			end
			registerGamepadKey(joystick, "LBUTTON", true)

			local rubberBandMaximumLength = 2.2 + 3.2
			local sx,sy = physicsToWorldTransform(levelStartPosition.x,levelStartPosition.y)
			cursor.x, cursor.y = (sx - screen.left) * worldScale + (x * rubberBandMaximumLength * 20 * worldScale),
				(sy - screen.top) * worldScale + (y * rubberBandMaximumLength * 20 * worldScale)
			if joystick:isGamepadDown("a") then
				registerGamepadKey(joystick, "LBUTTON", false)
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
	else
		--move cursor
		gpcx = math.max(20, math.min(gpcx + (x * 800 * dt), screenWidth - 20))
		gpcy = math.max(20, math.min(gpcy + (y * 800 * dt), screenHeight - 20))
		if gpc <= 0 then
			registerGamepadKey(joystick, "LBUTTON", "a")

			--only update the cursor variables if you are actually moving the cursor
			if x ~= 0 or y ~= 0 then
				cursor.x = gpcx
				cursor.y = gpcy
			end
		end
	end

	registerGamepadKey(joystick, "ESCAPE", "b")
	registerGamepadKey(joystick, "R", "x")
	registerGamepadKey(joystick, "RIGHT", "rightshoulder")
	registerGamepadKey(joystick, "LEFT", "leftshoulder")
	registerGamepadKey(joystick, "RBUTTON", "rightstick")
end