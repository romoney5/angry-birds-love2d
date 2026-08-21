--this massive function runs every frame

table.clear = table.clear or function(t) for i, v in pairs(t) do t[i] = nil end end

local pausedaudios = {}
zoomLevel = 0
wantedZoomLevel = 0
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
	
	screenWidth = math.floor(love.graphics.getWidth() / displayScale)
	screenHeight = math.floor(love.graphics.getHeight() / displayScale)

	g_updatedScreenWidth, g_updatedScreenHeight = screenWidth, screenHeight --4.0.0
	
	--update window title
	love.window.setTitle("Angry Birds ("..screenWidth.."x"..screenHeight..")")
end

--restore particle functions
function restoreParticles()
	particles = particles or {}
	if particles and not getmetatable(particles) then
		setmetatable(particles, getParticles)
	end
end

lgClear = love.graphics.clear

function love.graphics.clear(...)
	-- if a == true then
	-- 	return lgClear(...)
	-- end
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

			if gameResumed and not enableDebug then
				gameResumed()
			end
		end

		hasfocus = true
		if love.graphics and love.graphics.isActive() then
			love.graphics.origin()
			lgClear(love.graphics.getBackgroundColor())
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

		restoreParticles()
		
		fetch.update()

		--cursor delta for debug scrolling
		updateMouse(dt)
		--proper multitouch support, at last
		updateTouch()
		
		if checkDebugOpen then checkDebugOpen() end

		--toggle fullscreen with alt+enter
		if keyHold["LALT"] and keyPressed["RETURN"] then
			setFullScreenMode(not isInFullScreenMode())
		end

		love.graphics.setScissor()

		dt2 = speedUpPre(math.min(dt, 1/30) * (debugOpen and 0.2 or 1) * timeScale)

		local kp, kr, kh, cw = keyPressed, keyReleased, keyHold, cursor.wheel
		if openPopups[1] or debugOpen or fmOpen then
			keyPressed, keyReleased, keyHold = {}, {}, {}
			cursor.wheel = 0
		end

		if something.on then
			something:update(dt2)
		elseif update then
			--pause the game if there's an important popup
			local t1 = love.timer.getTime()
			local m1 = collectgarbage("count")
			
			--update the game
			if not keyHold.I then
				update(dt2, dt2)
			end

			if draw then
				draw()
			end

			if enableDebug then
				local t2 = love.timer.getTime()
				setRenderState(0, 0, 1, 1)
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
		
		keyPressed, keyReleased, keyHold, cursor.wheel = kp, kr, kh, cw
		
		-- temporary fix for rio/space
		if sm and sm.currentScene == sm.scenes.pause then
			setPhysicsEnabled(false)
			g_gamePaused = true
		end
		
		updatePhysics(dt)

		zoomLevel = lerp(zoomLevel, wantedZoomLevel, dt * 8)
		if currentGameMode ~= updateGame and currentGameMode ~= updateEditor then
			wantedZoomLevel = 0
		end

		if debugOpen then
			updateDebug(dt)
		end

		cursor.wheelTriggered = nil
		
		cursor.wheel = 0
		prevCursor.x, prevCursor.y = cursor.x, cursor.y
		
		setRenderState(0, 0, 1, 1)
		updatePopup()
		
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
	elseif hasfocus then
		hasfocus = false
		pausedaudios = love.audio.pause()

		--don't keep saving settings.lua every time you defocus
		if gamePaused and not enableDebug then
			gamePaused()
		end

		if not debugPaused then
			love.graphics.present()
		end
	end

	--clear key tables instead of remaking them
	table.clear(keyPressed)
	table.clear(keyReleased)
end

function love.resize(width, height)
	if resolutionChanged then
		resolutionChanged(width, height)
	end
end

--set dt to 0 resizing
if love.event.setModalDrawCallback then
	--love.event.setModalDrawCallback(function() loveUpdate(true) if clearLuaForceFunctions then clearLuaForceFunctions() end end)
end
