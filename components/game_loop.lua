--this massive function runs every frame

table.clear = table.clear or function(t) for i, v in pairs(t) do t[i] = nil end end

local pausedaudios = {}
gamelua.zoomLevel = 0
gamelua.wantedZoomLevel = 0
local hasfocus = true

prevCursor = {x = 0, y = 0}

function updateDisplayScale()
	if autoScale > 0 then
		local w, h = love.graphics.getDimensions()
		displayScale = (math.min(w, h) / autoScale)

		if displayScale >= .9 and displayScale <= 1.15 then --snap to 1 if close enough
			displayScale = 1
		end
	end
	love.graphics.scale(displayScale)
	
	gamelua.screenWidth = math.floor(love.graphics.getWidth() / displayScale)
	gamelua.screenHeight = math.floor(love.graphics.getHeight() / displayScale)

	gamelua.g_updatedScreenWidth, gamelua.g_updatedScreenHeight = gamelua.screenWidth, gamelua.screenHeight --4.0.0
	
	--update window title
	love.window.setTitle("Angry Birds ("..gamelua.screenWidth.."x"..gamelua.screenHeight..")")
end

function love.update(dt)
	if love.window.hasFocus() then
		--select the first gamepad
		if love.joystick then
			local joysticks = love.joystick.getJoysticks()
			joystick = joysticks[1]
		end

		--on resuming the game, restore all audios
		if not hasfocus then
			love.audio.play(pausedaudios)
			table.clear(pausedaudios)

			if gamelua.gameResumed and not enableDebug then
				gamelua.gameResumed()
			end
		end

		hasfocus = true
		if love.graphics and love.graphics.isActive() then
			love.graphics.origin()
			love.graphics.clear(love.graphics.getBackgroundColor())
		end
		
		--clear stopped audios
		if audiochannels then
			for i, channel in ipairs(audiochannels) do
				for ii, sound in ipairs(channel) do
					local source = sound.source
					if not source:isPlaying() then
						source:release()

						table.remove(channel, ii)
					end
				end
			end
		end
		
		--update stuff related to screen scale/size
		updateDisplayScale()
		
		fetch.update()

		--cursor delta for debug scrolling
		updateMouse(dt)
		--proper multitouch support, at last
		updateTouch()
		
		if checkDebugOpen then checkDebugOpen() end

		--toggle fullscreen with alt+enter
		if keyHold["LALT"] and keyPressed["RETURN"] then
			gamelua.setFullScreenMode(not gamelua.isInFullScreenMode())
		end

		love.graphics.setScissor()

		dt2 = speedUpPre(math.min(dt, 1/30) * (debugOpen and 0.2 or 1) * timeScale)

		local kp, kr, kh, cw = gamelua.keyPressed, gamelua.keyReleased, gamelua.keyHold, cursor.wheel
		if openPopups[1] or debugOpen or fmOpen then
			gamelua.keyPressed, gamelua.keyReleased, gamelua.keyHold = {}, {}, {}
			cursor.wheel = 0
		end

		if something.on then
			something:update(dt2)
		elseif gamelua.update then
			--pause the game if there's an important popup
			local t1 = love.timer.getTime()
			local m1 = collectgarbage("count")
			
			--update the game
			if not gamelua.keyHold.I then
				gamelua.update(dt2, dt2)
			end

			if gamelua.draw then
				gamelua.draw()
			end

			if enableDebug then
				local t2 = love.timer.getTime()
				gamelua.setRenderState(0, 0, 1, 1)
				res.useFont(nil)
				res.drawString("", "Update time: "..(math.floor((t2 - t1) * 1000 * 10) / 10).." ms", 10, 10)
				res.drawString("", "Memory diff: "..(math.floor((collectgarbage("count") - m1) * 100) / 100).." kb", 10, 50)
				res.drawString("", "Current mem: "..(math.floor(collectgarbage("count") / 1024 * 100) / 100).." mb", 10, 90)
			end
		end

		--try it out, just for fun
		-- if keyHold.MBUTTON then makeClickExplosion(cursorPhysics.x, cursorPhysics.y, 20000/10, 10, 200/200, 5, getAudioName("special_explosion")) end

		if enableDebug then
			drawCollisionsList()
		end
		if speedUpPost then speedUpPost() end

		drawParticlesNative(true)
		updateScreenParticlesNative(dt2)
		
		gamelua.keyPressed, gamelua.keyReleased, gamelua.keyHold, cursor.wheel = kp, kr, kh, cw
		
		updatePhysics(dt)

		gamelua.zoomLevel = lerp(gamelua.zoomLevel, gamelua.wantedZoomLevel, dt * 8)
		if currentGameMode ~= updateGame and currentGameMode ~= updateEditor then
			gamelua.wantedZoomLevel = 0
		end

		if debugOpen then
			updateDebug(dt)
		end
		
		gamelua.setRenderState(0, 0, 1, 1)
		updatePopup()

		cursor.wheelTriggered = nil
		cursor.wheel = 0
		prevCursor.x, prevCursor.y = cursor.x, cursor.y
		
		if debugOpen then
			love.keyboard.setKeyRepeat(true)
		else
			love.keyboard.setKeyRepeat(false)
		end
		
		if CUI.currentTextboxState and CUI.currentTextboxState.timer then
			CUI.currentTextboxState.timer = CUI.currentTextboxState.timer - 1
			love.keyboard.setKeyRepeat(true)
			
			if CUI.currentTextboxState.timer <= 0 then
				CUI.currentTextboxState = nil
			end
		end

		--only draw anything if the game is focused,
		--otherwise it will just endlessly hog up the gpu
		if love.graphics and love.graphics.isActive() then
			love.graphics.present()
		end
	elseif hasfocus then
		hasfocus = false
		pausedaudios = love.audio.pause()

		--don't keep saving settings.lua every time you defocus
		if gamelua.gamePaused and not enableDebug then
			gamelua.gamePaused()
		end

		if not debugPaused and love.graphics and love.graphics.isActive() then
			love.graphics.present()
		end
	end

	--clear key tables instead of remaking them
	table.clear(gamelua.keyPressed)
	table.clear(gamelua.keyReleased)
end

function love.resize(width, height)
	if resolutionChanged then
		resolutionChanged(width, height)
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
