--debug: fps

FPSFrames = 0
FPSTime = 0
FPSMin = 1000000
FPSMax = 0
function fpsDebug(dt)
	drawFPSStatistics = true
	
	local FPS = 1/dt
	if drawFPSStatistics or FPSFrames > FPS/10 then
	
		-- if not drawFPSStatistics then
		-- 	drawFPSStatistics = true
			-- FPSFrames = 0
			-- FPSTime = 0
			-- FPSMin = 1000000
			-- FPSMax = 0
		-- end
			
		if FPS < FPSMin then
			FPSMin = FPS
		end
		if FPS > FPSMax then
			FPSMax = FPS
		end
	end
	
	FPSFrames = FPSFrames + 1
	FPSTime = FPSTime + dt
	
	if drawFPSStatistics then
		res.useFont("FONT_BASIC")
		local FPSMinStr = String
		_G.res.drawString("", _G.string.format("FPSMin: %.1f", FPSMin), 0, screenHeight - 60, "BOTTOM", "LEFT")
		_G.res.drawString("", _G.string.format("FPSAvg: %.1f", FPSFrames/FPSTime), 0, screenHeight - 30, "BOTTOM", "LEFT")
		_G.res.drawString("", _G.string.format("FPSMax: %.1f", FPSMax), 0, screenHeight, "BOTTOM", "LEFT")
	end
end