--speed-up the game by 5x with shift+a
--pause the game by pressing shift+z and step a frame by pressing a (5x with shift+a)

local paused = false

function isSpeedingUp()
	return keyHold.SHIFT and keyHold.A
end

function getPauseState()
	if keyHold.SHIFT and keyPressed.Z then
		paused = not paused
	end

	return paused and (keyPressed.A and 2 or 1) or false
end

function speedUpPre(dt2)
	if isSpeedingUp() then
		dt2 = dt2 * 5
	end

	local pauseState = getPauseState()

	if pauseState == 1 then
		dt2 = 0
	end

	return dt2
end

function speedUpPost()
	if isSpeedingUp() or paused then
		drawRect2(.2, .2, .2, .5, 0, 0, screenWidth, screenHeight)
	end
end