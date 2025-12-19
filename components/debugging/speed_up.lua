--speed-up the game by 5x with shift+a

function isSpeedingUp()
	return keyHold.SHIFT and keyHold.A
end

function speedUpPre(dt2)
	if isSpeedingUp() then
		dt2 = dt2 * 5
	end
	return dt2
end

function speedUpPost()
	if isSpeedingUp() then
		drawRect2(.2, .2, .2, .5, 0, 0, screenWidth, screenHeight)
	end
end