--this massive function runs every frame

--clear key* tables instead of making them {}
require("table.clear")

local pausedaudios = {} --thanks love 11
zoomLevel = 0
wantedZoomLevel = 0
local hasfocus = true

function updateDisplayScale()
	if autoScale > 0 then
		local w, h = love.graphics.getDimensions()
		displayScale = (math.min(w, h) / autoScale)

		if displayScale >= .9 and displayScale <= 1.15 then --snap to 1 if close enough
			displayScale = 1
		end
	end
	love.graphics.scale(displayScale)
end

function love.update(dt)
	if love.window.hasFocus() or enableDebug then
		if love.joystick then
			local joysticks = love.joystick.getJoysticks()
			joystick = joysticks[1]
		end

		if not hasfocus then
			for i,v in pairs(pausedaudios) do
				v:play()
			end
			pausedaudios = {}
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
		screenWidth = math.floor(love.graphics.getWidth() / displayScale)
		screenHeight = math.floor(love.graphics.getHeight() / displayScale)
		
		--update window title
		love.window.setTitle("Angry Birds ("..screenWidth.."x"..screenHeight..")")

		if particles and not getmetatable(particles) then
			setmetatable(particles, getAddParticles)
		end

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
		if checkDebugOpen then checkDebugOpen() end

		if keyHold["LALT"] and keyPressed["RETURN"] then setFullScreenMode(not isInFullScreenMode()) end

		-- if mainMenu and not menuItemsEdited then
		-- 	menuItemsEdited = true
			-- local credits = getItemByName(mainMenu.items,"credits")
			-- credits.callFunction = function()love.event.quit("restart")end
		-- end

		love.graphics.setScissor()

		dt2 = speedUpPre(math.min(dt, .4) * ((debugOpen or optionsOpen) and 0.2 or 1) * timeScale)

		local kp, kr, kh = keyPressed, keyReleased, keyHold
		if currentPopup.open or debugOpen or fmOpen or optionsOpen then keyPressed, keyReleased, keyHold = {},{},{} end

		if currentGameMode == updateSomething then
			currentGameMode(dt2)
		else
			if currentPopup and currentPopup.important then
				if not alreadyLoadedFonts and loadFonts then
					alreadyLoadedFonts = true
					loadFonts()
				end
			else
				update(dt2,dt2)
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
			local v = type(dmonitor) == "string" and _G[dmonitor] or (type(dmonitor)=="table" and dmonitor[2] and _G[dmonitor[1]][dmonitor[2]])
			local i = type(dmonitor) == "string" and dmonitor or (type(dmonitor)=="table" and dmonitor[2] and dmonitor[1].."."..dmonitor[2])
			res.useFont(fontBasic or "FONT_BASIC")
			setRenderState(0, 0, 1, 1)
			if v then
				res.drawString("", i..": "..tostring(v), 50, 100)
			else
				res.drawString("", "Invalid debug monitor", 50, 100)
			end
		end
		
		keyPressed, keyReleased, keyHold = kp, kr, kh
		updatePhysics(dt)

		zoomLevel = lerp(zoomLevel, wantedZoomLevel, dt * 8)
		if currentGameMode ~= updateGame and currentGameMode ~= updateEditor then
			wantedZoomLevel = 0
		end

		if debugOpen then
			love.keyboard.setKeyRepeat(true)
			updateDebug(dt)
		else
			love.keyboard.setKeyRepeat(false)
		end

		if optionsOpen then
			updateOptions(dt)
		end

		setRenderState(0, 0, 1, 1)
		updatePopup()
		love.graphics.present()
	elseif hasfocus then
		hasfocus = false
		pausedaudios = love.audio.pause()

		gamePaused()
		love.graphics.present()
	end
	-- if not cursor.wheelTriggered then
		cursor.wheel = 0
	-- end

	--clear key* tables instead of making them {}
	table.clear(keyPressed)
	table.clear(keyReleased)
end

function updatePopup()
	if currentPopup.open then
		local w, h = math.max(res.getStringWidth(currentPopup.title, "FONT_MENU") - 50, res.getStringWidth(currentPopup.text, "FONT_BASIC") + 50) + 320, 300 + (currentPopup.h or 0)
		w = math.min(w, screenWidth * .9)
		local ox, oy = screenWidth * .5, screenHeight * .5
		local x, y = ox - w * .5, oy - h * .5

		drawRect2(0, 0, 0, .6, 0, 0, screenWidth, screenHeight)
		drawRect2(10 / 255, 10 / 255, 10 / 255, .3, x + 10, y + 10, w, h, 16)
		drawRect2(24 / 255, 50 / 255, 75 / 255, 1, x, y, w, h, 16)

		drawDebugText(currentPopup.title, ox, y, "HCENTER", "FONT_MENU")
		drawDebugText(currentPopup.text, x + 50, y + 75, "LEFT", "FONT_BASIC")

		local btns = #currentPopup.buttons
		local sx = w / (btns + 1) --start x
		if currentPopup.extra then
			currentPopup.extra(x + 50, y + 100, w - 50 - 50, h - 50 - 90, currentPopup)
		end

		for i,v in pairs(currentPopup.buttons) do
			drawDebugButton(v.sprite, ox + (i - (btns + 1) / 2) * sx, oy + h * .5, 1, function()
				-- optionsOpen = false
				if v.callback and v.callback() then
					currentPopup = {}
				end
			end, true, v.sound or "menu_confirm")
		end
	end
end