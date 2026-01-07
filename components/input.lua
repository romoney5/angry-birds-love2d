--related to keys, mouse, scroll wheel

function love.keypressed(key)
	if key == "lshift" then key = "shift" end
	if key == "lctrl" then key = "control" end

	keyPressed[string.upper(key)] = true
	-- keyHoldTime[string.upper(key)] = 0.01
	keyHold[string.upper(key)] = true
end

function love.keyreleased(key, scancode)
	if key == "lshift" then key = "shift" end
	if key == "lctrl" then key = "control" end

	keyReleased[string.upper(key)] = true
	-- keyHoldTime[string.upper(key)] = 0
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

local prevTouches
function updatePinch()
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

	if not optionsOpen then
		-- zoomLevel = zoomLevel + y/16
		wantedZoomLevel = wantedZoomLevel + y / 16

		-- if zoomLevel > 1.5 then zoomLevel = 1.5 end
		-- if wantedZoomLevel > 1.5 then wantedZoomLevel = 1.5 end
		-- if wantedZoomLevel > maxWorldScale then wantedZoomLevel = maxWorldScale end
		-- if wantedZoomLevel < maxWorldScale then wantedZoomLevel = maxWorldScale end
		-- if zoomLevel < -1.1 then zoomLevel = -1.1 end
	end
end

function doesMouseClickSetsTouchCount() --probably returns if on windows
	return true
end

function setIsMultitouchMouseWheelSimulationEnabled()
	return true
end