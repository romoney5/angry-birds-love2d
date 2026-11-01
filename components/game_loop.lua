--this massive function is called every frame to update the engine

baseTitle = "Angry Birds LÖVE2D"

prevCursor = {x = 0, y = 0}

--aspectRatio = 4 / 3
aspectRatio_offset = {x = 0, y = 0}
--TODO: alignment options?

function updateDisplayScale()
	if autoScale > 0 then
		local w, h = love.graphics.getDimensions()
		displayScale = (math.min(w, h) / autoScale)
	end
	love.graphics.scale(displayScale)
	
	gamelua.screenWidth = math.ceil(love.graphics.getWidth() / displayScale)
	gamelua.screenHeight = math.ceil(love.graphics.getHeight() / displayScale)
	
	aspectRatio_offset.x, aspectRatio_offset.y = 0, 0
	if aspectRatio then
		local width, height = gamelua.screenWidth, gamelua.screenHeight
		
		if aspectRatio <= width / height then
			gamelua.screenWidth = math.ceil(gamelua.screenHeight * aspectRatio)
			aspectRatio_offset.x = (width - gamelua.screenWidth) / 2
			aspectRatio_offset.y = 0
		else
			gamelua.screenHeight = math.ceil(gamelua.screenWidth / aspectRatio)
			aspectRatio_offset.x = 0
			aspectRatio_offset.y = (height - gamelua.screenHeight) / 2--[[]]
		end
	end

	gamelua.g_updatedScreenWidth, gamelua.g_updatedScreenHeight = gamelua.screenWidth, gamelua.screenHeight --4.0.0
	
	--update window title
	love.window.setTitle(baseTitle.." ("..gamelua.screenWidth.."x"..gamelua.screenHeight..")")
end

local empty_keytable = {}

function love.focus(focused)
	--on resuming the game, restore all audios
	if focused then
		resumeAudio()

		if gamelua.gameResumed and not enableDebug then
			gamelua.gameResumed()
		end
	else --upon defocus
		pauseAudio()

		--don't keep saving settings.lua every time you defocus
		if gamelua.gamePaused and not enableDebug then
			gamelua.gamePaused()
		end
		
		
		if not debugPaused and love.graphics and love.graphics.isActive() then
			love.graphics.present()
		end
	end
end

function love.update(dt)
	if not love.window.hasFocus() then return end
	
	updateAudio()
	
	if love.graphics and love.graphics.isActive() then
		gamelua.setRenderState(0, 0, 1, 1)
		love.graphics.origin()
		love.graphics.setScissor()
		love.graphics.clear(love.graphics.getBackgroundColor())
	end
	
	--update stuff related to screen scale/size
	updateDisplayScale()
	
	fetch.update()
	

	--cursor delta for debug scrolling
	updateMouse(dt)
	--proper multitouch support, at last
	updateTouch(dt)

	--toggle fullscreen with alt+enter
	if (keyHold["KEY_ALT"] and keyPressed["RETURN"]) or keyPressed.F11 then
		love.window.setFullscreen(not love.window.getFullscreen(), "desktop")
	end
	
	
	love.graphics.setScissor()

	dt2 = speedUpPre(math.min(dt, 1/30) * (debugOpen and 0 or 1) * timeScale)

	local t1 = love.timer.getTime()
	local m1 = collectgarbage("count")
	
	
	if something.on then
		something:update(dt2)
	elseif gamelua.update then
		local kp, kr, kh, cw = gamelua.keyPressed, gamelua.keyReleased, gamelua.keyHold, cursor.wheel
		if --[[CUI.GetLayer()]] openPopups[1] or debugOpen or fmOpen then
			gamelua.keyPressed, gamelua.keyReleased, gamelua.keyHold = empty_keytable, empty_keytable, empty_keytable
			cursor.wheel = 0
		end

		drawParticlesNative(true)
		updateScreenParticlesNative(dt2)
		
		
		updatePhysics(dt)
		

		--update the game
		if not keyHold.I then
			gamelua.update(dt2, dt2)
		end

		if gamelua.draw then
			gamelua.draw()
		end
		
		gamelua.keyPressed, gamelua.keyReleased, gamelua.keyHold, cursor.wheel = kp, kr, kh, cw
	end
	
	
	--draw debugging statistics
	if enableDebug then
		local t2 = love.timer.getTime()
		local m2 = collectgarbage("count")
		gamelua.setRenderState(0, 0, 1, 1)
		res.useFont(nil)
		res.drawString("", "Update time: "..(math.floor((t2 - t1) * 1000 * 10) / 10).." ms", 10, 10, "TOP")
		res.drawString("", "Memory diff: "..(math.floor((m2 - m1) * 100) / 100).." kb", 10, 50, "TOP")
		res.drawString("", "Current mem: "..(math.floor(m2 / 1024 * 100) / 100).." mb", 10, 90, "TOP")
		res.drawString("", "FPS: "..love.timer.getFPS(), 10, 130, "TOP")
		
		drawCollisionsList()
	end

	speedUpPost()
	
	
	updateConsole(dt)
	
	
	--use dt2 to keep popups from spazzing out at high delta times
	updatePopups(dt2)
	
	drawGamepad(dt)
	
	if CUI.currentTextboxState and CUI.currentTextboxState.timer then
		CUI.currentTextboxState.timer = CUI.currentTextboxState.timer - 1
		love.keyboard.setKeyRepeat(true)
		
		if CUI.currentTextboxState.timer <= 0 then
			CUI.currentTextboxState = nil
			love.keyboard.setKeyRepeat(false)
		end
	end

	--clear key tables instead of remaking them
	table.clear(gamelua.keyPressed)
	table.clear(gamelua.keyReleased)
	
	cursor.wheelTriggered = nil
	cursor.wheel = 0
	
	
	--only draw anything if the game is focused,
	--otherwise it will just endlessly hog up the gpu
	if love.graphics and love.graphics.isActive() then
		love.graphics.present()
	end
end

function love.resize(width, height)
	--always use the scaled screen width and height
	updateDisplayScale()
	
	if gamelua.resolutionChanged then
		gamelua.resolutionChanged(gamelua.screenWidth, gamelua.screenHeight)
	end
end

--set dt to 0 resizing
if love.event.setModalDrawCallback then
	love.event.setModalDrawCallback(function()
		local old_timeScale = timeScale
		timeScale = 0
		
		loveRunLoop()
		
		timeScale = old_timeScale
	end)
end
