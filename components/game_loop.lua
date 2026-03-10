--this massive function runs every frame

table.clear = table.clear or function(t) for i, v in pairs(t) do t[i] = nil end end

local pausedaudios = {}
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

local function updateCursor(dt)
	if not joystick then
		cursor.x, cursor.y = love.mouse.getPosition()
		cursor.x = cursor.x / displayScale
		cursor.y = cursor.y / displayScale
	else --gamepad logic
		updateGamepad(dt)
	end

	love.mouse.setVisible(not (gameOptions and gameOptions.ui and gameOptions.ui.enableCursor) or deviceModel ~= "windows"
		or debugOpen or optionsOpen or openPopups[1] ~= nil)
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
		local cx, cy = cursor.x, cursor.y
		updateCursor(dt)
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

		dt2 = speedUpPre(math.min(dt, 1/30) * ((debugOpen or optionsOpen) and 0.2 or 1) * timeScale)

		local kp, kr, kh, cw = keyPressed, keyReleased, keyHold, cursor.wheel
		if openPopups[1] or debugOpen or fmOpen or optionsOpen then
			keyPressed, keyReleased, keyHold = {}, {}, {}
			cursor.wheel = 0
		end

		if currentGameMode and currentGameMode == updateSomething then
			currentGameMode(dt2, cx, cy)
		elseif update then
			--pause the game if there's an important popup
			local t1 = love.timer.getTime()
			update(dt2, dt2)

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

		if draw then draw() end
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
		updatePhysics(dt)

		zoomLevel = lerp(zoomLevel, wantedZoomLevel, dt * 8)
		if currentGameMode ~= updateGame and currentGameMode ~= updateEditor then
			wantedZoomLevel = 0
		end

		if debugOpen then
			updateDebug(dt, cx, cy)
		end

		if optionsOpen then
			updateOptions(dt)
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

	--clear key* tables instead of remaking them
	table.clear(keyPressed)
	table.clear(keyReleased)
end

--TODO: this probably belongs in ui.lua
function updatePopup()
	local popup = openPopups[1]
	local dt = love.timer.getDelta()

	if popup then
		local function update()
			popup.anim = popup.anim or 0
			popup.anim = math.max(math.min(popup.anim + (popup.closing and -dt * 2 or dt), .25), 0)

			local maxWidth = math.max(res.getStringWidth(popup.title, "FONT_MENU") - 50, res.getStringWidth(popup.text, "FONT_BASIC"), 480) + 100
			maxWidth = math.min(maxWidth, screenWidth * .9)
			popup.w = popup.w or maxWidth
			popup.h = popup.h or 0
			popup.h_anim = popup.h_anim or 0
			popup.h_anim = ease.linear(dt * 16, popup.h_anim, popup.h)

			love.graphics.push()
			local w = popup.w
			local h = 300 + (popup.h_anim or 0)
			w = math.min(w, screenWidth * .9)

			local ox, oy = screenWidth * .5, screenHeight * .5
			local x, y = ox - w * .5, oy - h * .5

			drawRect2(0, 0, 0, #openPopups > 1 and .6 or ease.outCubic(popup.anim / .25, 0, .6), 0, 0, screenWidth, screenHeight)
			love.graphics.translate(x + w / 2, y + h / 2)
			love.graphics.scale(ease.outCubic(popup.anim / .25, .8, 1))
			love.graphics.translate(-(x + w / 2), -(y + h / 2))
			drawRect2(10 / 255, 10 / 255, 10 / 255, .3, x + 10, y + 10, w, h, 16)
			drawRect2(24 / 255, 50 / 255, 75 / 255, 1, x, y, w, h, 16)

			drawDebugText(popup.title, ox, y, "HCENTER", "FONT_MENU", maxWidth)
			local twidth, theight = drawDebugText(popup.text, x + 50, y + 75, "LEFT", "FONT_BASIC", maxWidth - 50 - 50)
			popup.w = math.max(twidth, 480) + 100
			popup.h = theight

			local btns = #popup.buttons
			local sx = w / (btns + 1) --start x
			if popup.extra then
				popup.extra(x + 50, y + 100 + theight, w - 50 - 50, h - 50 - 80 - theight, popup)
			end

			for i,v in pairs(popup.buttons) do
				drawDebugButton(v.sprite, ox + (i - (btns + 1) / 2) * sx, oy + h * .5, nil, nil, 1, function()
					local len = #openPopups
					if not popup.closing and v.callback and v.callback() then
						popup.closing = true

						--hack
						if #openPopups ~= len then
							popup.closing = false
							table.remove(openPopups, #openPopups - len + 1)
						end
					end
				end, true, v.sound or "menu_confirm")
			end

			--i lost my number one status
			if popup ~= openPopups[1] then
				popup.anim = 0
			end
			
			love.graphics.pop()
			
			if popup.closing and popup.anim <= 0 then
				table.remove(openPopups, 1)
			end
		end

		if popup.pause then
			while popup and popup.pause do
				--[[local ]]dt = love.timer and love.timer.step() or 0
				love.event.pump()
				for name, a,b,c,d,e,f,g,h in love.event.poll() do
					if name == "quit" then
						if c or not love.quit or not love.quit() then
							-- return a or 0, b
							openPopups = {}
							break
						end
					end
					love.handlers[name](a,b,c,d,e,f,g,h)
				end

				--dt = love.timer.getDelta()
				update()
				updateCursor(dt)
				love.graphics.present()
				love.timer.sleep(0.001)

				popup = openPopups[1]
			end
		else
			update()
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
	--love.event.setModalDrawCallback(function() loveUpdate(true) if clearLuaForceFunctions then clearLuaForceFunctions() end end)
end
