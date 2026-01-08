--this massive function runs every frame

local pausedaudios = {} --thanks love 11
zoomLevel = 0
wantedZoomLevel = 0
local hasfocus = true

dmonitor = nil

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
			love.graphics.clear(love.graphics.getBackgroundColor())
		end
		
		if audiochannels then
			for _, c in ipairs(audiochannels) do
				for i, v in ipairs(c) do
					if cachedaudios[v]:isPlaying() ~= true then
						table.remove(c, k)
					end
				end
			end
		end

		love.audio.setVolume(audiovolume)
		
		updateDisplayScale()

		g_updatedScreenWidth, g_updatedScreenHeight = screenWidth, screenHeight --4.0.0
		
		--update window title
		love.window.setTitle("Angry Birds ("..screenWidth.."x"..screenHeight..")")

		--restore particle functions
		if particles and not getmetatable(particles) then
			setmetatable(particles, getParticles)
		end

		--cursor delta for debug scrolling
		local cx, cy = cursor.x, cursor.y
		if not joystick then
			cursor.x, cursor.y = love.mouse.getPosition()
			cursor.x = cursor.x / displayScale
			cursor.y = cursor.y / displayScale
		else --gamepad logic
			updateGamepad(dt)
		end

		--proper multitouch support, at last
		local mttouches = love.touch.getTouches()
		touches = {}
		if #mttouches > 0 then
			for i,v in pairs(mttouches)do
				local x, y = love.touch.getPosition(v)
				touches[i] = {x = x, y = y, p = love.touch.getPressure(v)} --pressure sensitivity for the two touchscreens that support it
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

		dt2 = speedUpPre(math.min(dt, .4) * ((debugOpen or optionsOpen) and 0.2 or 1) * timeScale)

		local kp, kr, kh, cw = keyPressed, keyReleased, keyHold, cursor.wheel
		if openPopups[1] or debugOpen or fmOpen or optionsOpen then
			keyPressed, keyReleased, keyHold = {}, {}, {}
			cursor.wheel = 0
		end

		if currentGameMode and currentGameMode == updateSomething then
			currentGameMode(dt2)
		else
			--pause the game if there's an important popup
			if openPopups[1] and openPopups[1].pause then
				if not alreadyLoadedFonts and loadFonts then
					alreadyLoadedFonts = true
					loadFonts()
				end
			elseif update then
				update(dt2, dt2)
			end
		end

		--try it out, just for fun
		-- if keyHold.MBUTTON then makeClickExplosion(cursorPhysics.x, cursorPhysics.y, 20000/10, 10, 200/200, 5, getAudioName("special_explosion")) end

		if enableDebug then
			fpsDebug(dt)
			drawCollisionsList()
		end

		if draw then draw() end
		if speedUpPost then speedUpPost() end

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
		updatePhysics(dt)

		zoomLevel = lerp(zoomLevel, wantedZoomLevel, dt * 8)
		if currentGameMode ~= updateGame and currentGameMode ~= updateEditor then
			wantedZoomLevel = 0
		end

		if debugOpen then
			love.keyboard.setKeyRepeat(true)
			updateDebug(dt, cx, cy)
		else
			love.keyboard.setKeyRepeat(false)
		end

		if optionsOpen then
			updateOptions(dt)
		end

		love.mouse.setVisible(not (gameOptions and gameOptions.ui and gameOptions.ui.enableCursor) or deviceModel ~= "windows"
			or debugOpen or optionsOpen)
		setRenderState(0, 0, 1, 1)
		updatePopup()
		love.graphics.present()
	elseif hasfocus then
		hasfocus = false
		pausedaudios = love.audio.pause()

		--don't keep saving settings.lua every time you defocus
		if gamePaused and not enableDebug then
			gamePaused()
		end

		love.graphics.present()
	end
	-- if not cursor.wheelTriggered then
		cursor.wheel = 0
	-- end

	--clear key* tables instead of remaking them
	table.clear(keyPressed)
	table.clear(keyReleased)
end

function updatePopup()
	local popup = openPopups[1]

	if popup then
		local w, h = math.max(res.getStringWidth(popup.title, "FONT_MENU") - 50, res.getStringWidth(popup.text, "FONT_BASIC") + 50) + 320, 300 + (popup.h or 0)
		w = math.min(w, screenWidth * .9)

		local ox, oy = screenWidth * .5, screenHeight * .5
		local x, y = ox - w * .5, oy - h * .5

		drawRect2(0, 0, 0, .6, 0, 0, screenWidth, screenHeight)
		drawRect2(10 / 255, 10 / 255, 10 / 255, .3, x + 10, y + 10, w, h, 16)
		drawRect2(24 / 255, 50 / 255, 75 / 255, 1, x, y, w, h, 16)

		drawDebugText(popup.title, ox, y, "HCENTER", "FONT_MENU")
		drawDebugText(popup.text, x + 50, y + 75, "LEFT", "FONT_BASIC")

		local btns = #popup.buttons
		local sx = w / (btns + 1) --start x
		if popup.extra then
			popup.extra(x + 50, y + 100, w - 50 - 50, h - 50 - 90, popup)
		end

		for i,v in pairs(popup.buttons) do
			drawDebugButton(v.sprite, ox + (i - (btns + 1) / 2) * sx, oy + h * .5, nil, nil, 1, function()
				-- optionsOpen = false
				if v.callback and v.callback() then
					table.remove(openPopups, 1)
				end
			end, true, v.sound or "menu_confirm")
		end
	end
end

function love.resize(width, height)
	if resolutionChanged then
		resolutionChanged(width, height)
	end
end

--set dt to 0 resizing
if love.event.setModalDrawCallback then
	love.event.setModalDrawCallback(function() loveUpdate(true) end)
end