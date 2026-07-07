--this massive function runs every frame

table.clear = table.clear or function(t) for i, v in pairs(t) do t[i] = nil end end

local pausedaudios = {}
zoomLevel = 0
wantedZoomLevel = 0
local hasfocus = true

dmonitor = nil

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
end

function updateMouse(dt)
	if not joystick then
		cursor.x, cursor.y = love.mouse.getPosition()
		cursor.x = cursor.x / displayScale
		cursor.y = cursor.y / displayScale
	else --gamepad logic
		updateGamepad(dt)
	end

	love.mouse.setVisible(deviceModel ~= "windows"
		or debugOpen or openPopups[1] ~= nil or something.on)
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
		if love.joystick then
			local joysticks = love.joystick.getJoysticks()
			joystick = joysticks[1]
		end

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
		
		updateDisplayScale()

		g_updatedScreenWidth, g_updatedScreenHeight = screenWidth, screenHeight --4.0.0
		
		--update window title
		love.window.setTitle("Angry Birds ("..screenWidth.."x"..screenHeight..")")

		restoreParticles()
		
		fetch.update()

		--cursor delta for debug scrolling
		updateMouse(dt)
		--proper multitouch support, at last
		local mttouches = love.touch.getTouches()
		table.clear(touches)
		if #mttouches > 0 then
			for i, v in ipairs(mttouches) do
				local x, y = love.touch.getPosition(v)
				touches[i] = {x = x / displayScale, y = y / displayScale, p = love.touch.getPressure(v)} --pressure sensitivity for the two touchscreens that support it
			end
		elseif keyHold["LBUTTON"] then
			touches[1] = {x = cursor.x, y = cursor.y}
		end
		touchcount = #touches
		
		--update pinch to zoom
		updatePinch()
		if checkDebugOpen then checkDebugOpen() end

		if keyHold["LALT"] and keyPressed["RETURN"] then setFullScreenMode(not isInFullScreenMode()) end

		-- if mainMenu and not menuItemsEdited then
		-- 	menuItemsEdited = true
			-- local credits = getItemByName(mainMenu.items,"credits")
			-- credits.callFunction = function()love.event.quit("restart")end
		-- end

		love.graphics.setScissor()

		dt2 = speedUpPre(math.min(dt, 1/30) * (debugOpen and 0.2 or 1) * timeScale)

		local kp, kr, kh, cw = keyPressed, keyReleased, keyHold, cursor.wheel
		if openPopups[1] or debugOpen or fmOpen then
			keyPressed, keyReleased, keyHold = {}, {}, {}
			cursor.wheel = 0
		end

		if something.on then
			updateSomething(dt2)
		elseif update then
			--pause the game if there's an important popup
			local t1 = love.timer.getTime()
			update(dt2, dt2)

			if draw then draw() end

			if enableDebug then
				local t2 = love.timer.getTime()
				setRenderState(0, 0, 1, 1)
				res.useFont("FONT_BASIC")
				res.drawString("", "update: "..(math.floor((t2 - t1) * 1000 * 10) / 10).." ms", 10, 10)
			end
		end

		--try it out, just for fun
		-- if keyHold.MBUTTON then makeClickExplosion(cursorPhysics.x, cursorPhysics.y, 20000/10, 10, 200/200, 5, getAudioName("special_explosion")) end

		if enableDebug then
			fpsDebug(dt)
			drawCollisionsList()
		end
		if speedUpPost then speedUpPost() end

		drawParticlesNative(true)
		updateScreenParticlesNative(dt2)

		if dmonitor then
			local v = type(dmonitor) == "string" and _G[dmonitor] or (type(dmonitor)=="table" and dmonitor[1] and _G[dmonitor[1]] and dmonitor[2] and (_G[dmonitor[1]][dmonitor[2]] or "nil"))
			local i = type(dmonitor) == "string" and dmonitor or (type(dmonitor)=="table" and dmonitor[2] and dmonitor[1].."."..dmonitor[2])
			res.useFont(fontBasic or "FONT_BASIC")
			setRenderState(0, 0, 1, 1)
			if v ~= nil then
				res.drawString("", i..": "..tostring(v), 50, 100)
			else
				res.drawString("", "Invalid debug monitor", 50, 100)
			end
		end
		
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

		if not (debugPaused and dt2 == 0) then
			-- love.graphics.present()
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
	-- if not cursor.wheelTriggered then
		cursor.wheel = 0
	-- end
	prevCursor.x, prevCursor.y = cursor.x, cursor.y

	--clear key* tables instead of remaking them
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
