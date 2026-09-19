--gamepads

local gpcx, gpcy, gpc = 0, 0, 0 --gamepad cursor x/y, gamepad cooldown
joystick = nil

gpcx, gpcy = love.mouse.getPosition()

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

local scroll_charge = 0
local move_charge = 0

local press_anim = 0

function updateGamepad(dt)
	if not joystick then return end

	local x, y = joystick:getAxis(1), joystick:getAxis(2)
	local deadzone = .1
	-- if math.abs(x) < .1 then x = 0 end
	-- if math.abs(y) < .1 then y = 0 end
	if math.abs(x) < deadzone and math.abs(y) < deadzone then
		x, y = 0, 0
	end

	if physicsEnabled then
		if not gamelua.levelCompleted and (x ~= 0 or y ~= 0) and not gamelua.cameraTargetObject then
			if gamelua.currentBirdName ~= nil then
				local obj = objects.world[gamelua.currentBirdName]
				if gamelua.panToBirdCamera then gamelua.panToBirdCamera() end
				gamelua.selectedBird = obj
			end
			
			registerGamepadKey(joystick, "LBUTTON", true)

			local rubberBandMaximumLength = 2.2 + 3.2
			local sx,sy = physicsToWorldTransform(gamelua.levelStartPosition.x, gamelua.levelStartPosition.y)
			cursor.x, cursor.y = (sx - renderLeft) * renderScale + (x * rubberBandMaximumLength * 20 * renderScale),
				(sy - renderTop) * renderScale + (y * rubberBandMaximumLength * 20 * renderScale)
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
		local speed = gamelua.screenHeight / 1080 * (800 + move_charge * 600)
		local padding = gamelua.screenWidth / 1920 * 20
		
		gpcx = math.max(padding, math.min(gpcx + (x * speed * dt), gamelua.screenWidth - padding))
		gpcy = math.max(padding, math.min(gpcy + (y * speed * dt), gamelua.screenHeight - padding))
		if gpc <= 0 then
			registerGamepadKey(joystick, "LBUTTON", "a")

			--only update the cursor variables if you are actually moving the cursor
			if x ~= 0 or y ~= 0 then
				cursor.x = gpcx
				cursor.y = gpcy
				
				move_charge = math.min(move_charge + dt / 2, 1)
			else
				move_charge = 0
			end
		end
	end
	
	local scroll_x = joystick:getAxis(3)
	local scroll_y = joystick:getAxis(4)
	local scroll = 0
	
	if math.abs(scroll_x) >= deadzone * 3 then
		scroll = scroll_x
	elseif math.abs(scroll_y) >= deadzone then
		scroll = scroll_y
	end
	
	if math.abs(scroll) >= deadzone then
		scroll_charge = math.min(scroll_charge + dt / .5, 1)
		cursor.wheel = scroll * -.5 * ease.inQuad(scroll_charge, .3, 1)
		cursor.wheelTriggered = true
	else
		scroll_charge = 0
	end

	registerGamepadKey(joystick, "ESCAPE", "b")
	registerGamepadKey(joystick, "R", "x")
	registerGamepadKey(joystick, "RIGHT", "rightshoulder")
	registerGamepadKey(joystick, "LEFT", "leftshoulder")
	registerGamepadKey(joystick, "RBUTTON", "rightstick")
	
	if keyHold.LBUTTON then
		press_anim = math.min(press_anim + dt / .01, 1)
	else
		press_anim = math.max(press_anim - dt / .1, 0)
	end
end

--draw gamepad cursor
function drawGamepad(dt)
	if not joystick or physicsEnabled then return end
	
	love.graphics.push("all")
	
	local radius_factor = gamelua.screenHeight / 1080
	local radius = 30
	love.graphics.setLineWidth(radius_factor * 4)
	
	love.graphics.setColor(0, 0, 0, .5)
	love.graphics.circle("line", cursor.x, cursor.y, radius_factor * (radius + press_anim * 8))
	
	love.graphics.setColor(.5, .5, .5, .5)
	love.graphics.circle("fill", cursor.x, cursor.y, radius_factor * (radius * 25 / 30 - press_anim * 8))
	
	love.graphics.pop()
end
