--debugging

--debug menu
debugText = ""
debugCursorPosition = 0
debugCursorBlink = 0
debugPrevious = {}
debugPreviousIndex = 1
debugOpen = false
debugPrints = ""

optionsOpen = false
optionsScrolling = 0
optionsScrollTo = 0

function updateDebug(dt)
	setRenderState(0,0,1,1)

	debugCursorBlink = debugCursorBlink + dt
	-- local font = love.graphics.getFont()
	
	if keyPressed["BACKSPACE"] or (keyHoldTime["BACKSPACE"]and keyHoldTime["BACKSPACE"] >= .5 and keyHoldTime["BACKSPACE"]%.04 <= dt) then
		res.playAudio("menu_back", 1, false)
		debugText = string.back(debugText,debugCursorPosition)
		debugCursorPosition = math.max(debugCursorPosition - 1, 0)
		debugCursorBlink = 0
	end
	if keyPressed["DELETE"] or (keyHoldTime["DELETE"]and keyHoldTime["DELETE"] >= .5 and keyHoldTime["DELETE"]%.04 <= dt) then
		res.playAudio("menu_back", 1, false)
		debugText = string.back(debugText,debugCursorPosition + 1)
		-- debugCursorPosition = math.max(debugCursorPosition, 0)
		debugCursorBlink = 0
	end
	if keyPressed["RETURN"] then
		res.playAudio("menu_confirm", 1, false)
		debugCursorBlink = 0
		if keyHold["SHIFT"] then
			debugText = debugText.."\n"
			debugCursorPosition = math.min(debugCursorPosition + 1, string.len(debugText))
		else
			if debugText ~= debugPrevious[debugPreviousIndex + 1] and debugText ~= "" then --prevent duplicate indexes
				table.insert(debugPrevious, 1, debugText)
			end

			if debugText == "clear" then
				debugPrints = ""
				res.playAudio("menu_select", 1, false)
			else
				local su,re = pcall(loadstring(debugText))
				if not su then
					print("Error while running command: "..re)
				else
					if re then
						print(re)--"Ran command successfully with result: "..re)
					else
						-- print()--"Ran command successfully")
					end
				end
			end
			debugText = ""--debugText:sub(1,-2)
			debugCursorPosition = 0
			debugPreviousIndex = 0
		end
	end
	if keyPressed["LEFT"] or (keyHoldTime["LEFT"]and keyHoldTime["LEFT"] >= .5 and keyHoldTime["LEFT"]%.03 <= dt) then
		res.playAudio("menu_select", 1, false)
		debugCursorPosition = math.max(debugCursorPosition - 1, 0)
		debugCursorBlink = 0
	end
	if keyPressed["RIGHT"] or (keyHoldTime["RIGHT"]and keyHoldTime["RIGHT"] >= .5 and keyHoldTime["RIGHT"]%.03 <= dt) then
		res.playAudio("menu_select", 1, false)
		debugCursorPosition = math.min(debugCursorPosition + 1, string.len(debugText))
		debugCursorBlink = 0
	end

	if keyPressed["UP"] and debugPreviousIndex < #debugPrevious then
		res.playAudio("menu_select", 1, false)
		if debugPreviousIndex == 0 then debugPrevious[0] = debugText end
		debugPreviousIndex = debugPreviousIndex + 1
		debugText = debugPrevious[debugPreviousIndex]
		debugCursorPosition = #debugText
	end
	if keyPressed["DOWN"] and debugPreviousIndex > 0 then
		res.playAudio("menu_select", 1, false)
		debugPreviousIndex = debugPreviousIndex - 1
		debugText = debugPrevious[debugPreviousIndex]
		debugCursorPosition = #debugText
	end

	
	-- local textLength,textLines = 0,-1
	-- local maxLength,lines = font:getWrap(debugText:sub(1, debugCursorPosition),screenWidth - debugPadding * 2)
	-- local _,linesTotal = font:getWrap(debugText,screenWidth - debugPadding * 2)
	
	-- for i,v in pairs(lines) do
	-- 	textLines = textLines + 1
	-- 	textLength = font:getWidth(v)
	-- end

	love.graphics.setColor(0, 0, 0, .5)
	love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
	love.graphics.rectangle("fill", 0, 0, screenWidth, debugPadding * 2 + 30)-- + (#linesTotal * font:getHeight()))
	love.graphics.setColor(1, 1, 1, 1)

	-- love.graphics.printf(debugText, debugPadding, debugPadding, screenWidth - debugPadding * 2)
	res.useFont("FONT_BASIC")
	res.drawString("",debugText,debugPadding,debugPadding)
	-- love.graphics.printf((debugCursorBlink%.5 <= .25 and "|" or ""), res.getStringWidth(debugText:sub(1, debugCursorPosition)) + debugPadding - 3, (debugPadding + 0.5), screenWidth)-- + (textLines * font:getHeight()), screenWidth)
	res.drawString("",(debugCursorBlink%.5 <= .25 and "|" or ""), res.getStringWidth(debugText:sub(1, debugCursorPosition)) + debugPadding, (debugPadding+3))

	-- love.graphics.printf(debugPrints, debugPadding, debugPadding * 2 + 70, screenWidth - debugPadding*2)-- + (#linesTotal * font:getHeight()), screenWidth - debugPadding * 2)
	res.drawString("",debugPrints, debugPadding, debugPadding * 2 + 70)

	local boxsprites = tutorialBoxSprites
	local tl = checkSprite(boxsprites.topLeft)
	local tlw,tlh = tl.w,tl.h
	local x,y = screenWidth-125,65
	local w,h = 75*.9,75*.4
	local s = 1
	if checkBounds(x-tlw*2,y-tlh*1.5,w+tlw*2,h+tlh*2,cursor.x,cursor.y)then
		if keyHold["LBUTTON"]then
			s = .8
		elseif gameOptions.ui.enableHoverScaling then
			s = 1.2
		end
		w,h = w * s, h * s

		if keyReleased["LBUTTON"]then
			res.playAudio("menu_confirm", 1, false)
			debugOpen = false
			optionsOpen = true
			return
		end
	end
	drawBoxNative(boxsprites or {}, x - w*.5, y - h*.5, w, h)
	love.graphics.translate(x, y)
	love.graphics.scale(s)
	res.drawString("", "Options", 0, 0, "HCENTER", "VCENTER")
end

function updateOptions(dt)
	if keyPressed["ESCAPE"] then
		optionsOpen = false
		optionsScrollTo = 0
		optionsScrolling = 0
		res.playAudio("menu_back", 1, false)
		return
	end

	setRenderState(0,0,1,1)

	love.graphics.setColor(0, 0, 0, .5)
	love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
	-- love.graphics.rectangle("fill", 0, 0, screenWidth, debugPadding * 2 + 30)-- + (#linesTotal * font:getHeight()))
	love.graphics.setColor(1, 1, 1, 1)

	-- love.graphics.printf(debugText, debugPadding, debugPadding, screenWidth - debugPadding * 2)
	res.useFont("FONT_MENU")
	-- res.drawString("",debugText,debugPadding,debugPadding)

	local boxsprites = tutorialBoxSprites
	-- local tl = checkSprite(boxsprites.topLeft)
	-- local tlw,tlh = tl.w,tl.h
	local x,y = screenWidth/2,screenHeight/2
	local w,h = screenWidth-debugPadding*7,screenHeight-debugPadding*7
	-- local s = 1
	-- if checkBounds(x-tlw*2,y-tlh*1.5,w+tlw*2,h+tlh*2,cursor.x,cursor.y)then
	-- 	if keyHold["LBUTTON"]then
	-- 		s = .8
	-- 	elseif gameOptions.ui.enableHoverScaling then
	-- 		s = 1.2
	-- 	end
	-- 	w,h = w * s, h * s

	-- 	if keyReleased["LBUTTON"]then
	-- 		res.playAudio("menu_confirm", 1, false)
	-- 		debugOpen = false
	-- 		optionsOpen = true
	-- 		return
	-- 	end
	-- end
	drawBox(boxsprites or {},"",x - w*.5,y - h*.5,w,h)
	drawDebugText("Options",240,170)
	drawDebugButton("BUTTON_ARROW_LEFT",180,170,1, function()
		optionsOpen = false
		optionsScrollTo = 0
		optionsScrolling = 0
	end,true,"menu_back")

	res.useFont("FONT_BASIC")
	optionsScrollTo = optionsScrollTo + cursor.wheel * 48
	optionsScrolling = (optionsScrolling*9 + optionsScrollTo) * .1
	local optionsy = 250 + optionsScrolling
	local basey = optionsy
	local y0,y1 = y-h*.4,y+h*.5
	res.setClipRect(0,y0,screenWidth,y1-y0)
	for i,v in pairs(gameOptions)do
		if type(v) == "boolean" then
			drawDebugButton(v and "TUTORIAL_OK" or "MENU_NO",200,optionsy,.5, function()
				-- optionsOpen = false
				gameOptions[i] = not v
			end,(optionsy <= y1 and optionsy >= y0),"menu_confirm")
			drawDebugText(i,200 + 36,optionsy)
			optionsy = optionsy + 50
		elseif type(v) == "table" then
			drawDebugText(i,200 - 25,optionsy)
			optionsy = optionsy + 50
			for ii,vv in pairs(v) do
				if type(vv) == "boolean" then
					drawDebugButton(vv and "TUTORIAL_OK" or "MENU_NO",200+56,optionsy,.5, function()
						-- optionsOpen = false
						gameOptions[i][ii] = not vv
					end,(optionsy <= y1 and optionsy >= y0),"menu_confirm")
					drawDebugText(ii,200 + 36 + 56,optionsy)
					optionsy = optionsy + 50
				end
			end
			optionsy = optionsy + 25
		end
	end
	optionsScrollTo = math.max(optionsScrollTo,-(optionsy-basey) + (y1-y0))
	optionsScrollTo = math.min(optionsScrollTo,res.getFontHeight()/displayScale)
	love.graphics.setScissor()
end

function drawDebugButton(sprite,x,y,scale,call,enabled,sound)
	-- love.graphics.origin()
	love.graphics.push()
	local image = checkSprite(sprite)
	local w,h = image.w*scale,image.h*scale
	local s = 1
	if enabled and checkBounds(x-w/2,y-h/2,w,h,cursor.x,cursor.y)then
		if keyHold["LBUTTON"]then
			s = .9
		elseif gameOptions.ui.enableHoverScaling then
			s = 1.1
		end

		if keyReleased["LBUTTON"]then
			res.playAudio(sound or "menu_confirm", 1, false)
			call()
			-- return
		end
	end
	love.graphics.translate(x, y)
	love.graphics.scale(s*scale)
	res.drawSprite(sprite,0,0)
	love.graphics.pop()
	-- love.graphics.origin()
end

function drawDebugText(text,x,y)
	love.graphics.setColor(0, 0, 0,.2)
	res.drawString("",text,x+8,y+8,"LEFT","VCENTER")
	love.graphics.setColor(1, 1, 1,1)
	res.drawString("",text,x,y,"LEFT","VCENTER")
end

function love.textinput(key)
	-- print(key)
	if debugOpen then
		res.playAudio("menu_confirm", 1, false)
		debugText = string.insert(debugText,key,debugCursorPosition)
		debugCursorPosition = debugCursorPosition + 1
		debugCursorBlink = 0
	end
end

--shh: don't ask
function makeSnWave(hz)
	local rate      = 44100 -- samples per second
	local length    = 1/32 * 16  -- 0.03125 seconds
	local tone      = hz or 440.0 -- Hz
	local p         = math.floor(rate/tone) -- 100 (wave length in samples)
	local soundData = love.sound.newSoundData(math.floor(length*rate), rate, 16, 1)
	for i=0, soundData:getSampleCount() - 1 do
		soundData:setSample(i, math.sin(2*math.pi*i/p)) -- sine wave.
	end
	local source = love.audio.newSource(soundData)
	source:setVolume(.3)
	source:play()
	print("Played sine wave with length "..length..", "..tone.."Hz")
end

function makeSqWave(hz)
	local rate      = 44100 -- samples per second
	local length    = 1/32 * 16  -- 0.03125 seconds
	local tone      = hz or 440.0 -- Hz
	local p         = math.floor(rate/tone) -- 100 (wave length in samples)
	local soundData = love.sound.newSoundData(math.floor(length*rate), rate, 16, 1)
	for i=0, soundData:getSampleCount() - 1 do
		soundData:setSample(i, i%p<p/2 and 1 or -1)     -- square wave; the first half of the wave is 1, the second half is -1.
	end
	local source = love.audio.newSource(soundData)
	source:setVolume(.1)
	source:play()
	print("Played square wave with length "..length..", "..tone.."Hz")
	print("Note: The square wave was toned down in volume a bit for your \"convenience\"")
end

function love.errorhandler(msg)
	local utf8 = require("utf8")
	msg = tostring(msg)

	print((debug.traceback("Error: " .. tostring(msg), 1+(layer or 1)):gsub("\n[^\n]+$", "")))

	if not love.window or not love.graphics or not love.event then
		return
	end

	if not love.graphics.isCreated() or not love.window.isOpen() then
		local success, status = pcall(love.window.setMode, 800, 600)
		if not success or not status then
			return
		end
	end

	-- Reset state.
	if love.mouse then
		love.mouse.setVisible(true)
		love.mouse.setGrabbed(false)
		love.mouse.setRelativeMode(false)
		if love.mouse.isCursorSupported() then
			love.mouse.setCursor()
		end
	end
	if love.joystick then
		-- Stop all joystick vibrations.
		for i,v in ipairs(love.joystick.getJoysticks()) do
			v:setVibration()
		end
	end
	-- if love.audio then love.audio.stop() end

	love.graphics.reset()
	love.graphics.setBlendMode("alpha","premultiplied")
	-- local font = love.graphics.setNewFont(24)

	love.graphics.setColor(1, 1, 1)

	local trace = debug.traceback()

	love.graphics.origin()

	local sanitizedmsg = {}
	for char in msg:gmatch(utf8.charpattern) do
		table.insert(sanitizedmsg, char)
	end
	sanitizedmsg = table.concat(sanitizedmsg)

	local err = {}

	table.insert(err, sanitizedmsg)

	if #sanitizedmsg ~= #msg then
		table.insert(err, "Invalid UTF-8 string in error message.")
	end

	table.insert(err, "\n")

	for l in trace:gmatch("(.-)\n") do
		if not l:match("boot.lua") then
			l = l:gsub("stack traceback:", "Traceback\n")
			table.insert(err, l)
		end
	end

	local exited = false

	local p = table.concat(err, "\n")

	p = p:gsub("\t", "")
	p = p:gsub("%[string \"(.-)\"%]", "%1")

	setTheme("theme"..math.random(1,15))
	if not screen then screen = {top = 0, left = 0} end

	local function draw()
		if not love.graphics.isActive() then return end
		local pos = 70
		love.graphics.clear(love.graphics.getBackgroundColor())
		screenHeight = love.graphics.getHeight()
		local topCamera = (-2*screenHeight) / (screenHeight / (450 * (currentZoomLevelMainMenu or 1) * 0.585)) + ((111 * 1.6  )/ (screenHeight / (450 * (currentZoomLevelMainMenu or 1) * 0.5)))
		screen.top = topCamera
		setWorldScale((0.5 * screenHeight / 400) / ((currentZoomLevelMainMenu or 1) * 0.66))
		drawBackgroundNative()
		drawForegroundNative()

		screen.left = screen.left + 1
		-- love.graphics.printf(p, pos, pos, love.graphics.getWidth() - pos)
		setRenderState(pos*2,pos*2,1*.6,1*.6)
		res.useFont("FONT_MENU")
		love.graphics.setColor(0, 0, 0,.2)
		res.drawString("",p,pos+(1*16),pos+(1*16))
		love.graphics.setColor(1, 1, 1,1)
		res.drawString("",p,pos,pos)
		love.graphics.present()
	end

	local fullErrorText = p

	return function()
		love.event.pump()

		for e, a, b, c in love.event.poll() do
			if e == "quit" then
				return 1
			elseif e == "keypressed" and a == "escape" then
				return 1
				-- love.event.quit("restart")
			elseif e == "keypressed" and a == "c" and love.keyboard.isDown("lctrl", "rctrl") then
				-- copyToClipboard()
			elseif e == "touchpressed" or e == "mousepressed" then
				local buttons = {"Exit", "Cancel"}
				if love.system then
					buttons[3] = "Copy Error"
				end
				local pressed = love.window.showMessageBox("Angry Birds", "Exit the game?", buttons)
				if pressed == 1 then
					return 1
				elseif pressed == 3 then
					love.system.setClipboardText(fullErrorText)
				end
			end
		end

		draw()

		if love.timer then
			love.timer.sleep(0.01)
		end
	end

end