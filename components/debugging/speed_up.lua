--speed-up the game by 5x with shift+a
--pause the game by pressing shift+z and step a frame by pressing a (5x with shift+a)

debugPaused = false

function isSpeedingUp()
	return keyHold.SHIFT and keyHold.A
end

function getPauseState()
	local val = debugPaused and (keyPressed.A and 2 or 1) or false

	--deliberately do the check after making the value
	--so the game still draws when you first pause
	if keyHold.SHIFT and keyPressed.Z then
		debugPaused = not debugPaused
	end

	return val
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
	if isSpeedingUp() or debugPaused then
		drawRect2(.2, .2, .2, .5, 0, 0, screenWidth, screenHeight)
	end
end