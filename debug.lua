--debugging

--debug menu
debugText = ""
debugCursorPosition = 0
debugCursorBlink = 0
debugPrevious = {}
debugPreviousIndex = 1
debugOpen = false
debugPrints = ""

function updateDebug(dt)
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
		setRenderState(pos*2,pos*2,worldScale*.6,worldScale*.6)
		res.useFont("FONT_MENU")
		love.graphics.setColor(0, 0, 0,.2)
		res.drawString("",p,pos+(worldScale*16),pos+(worldScale*16))
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
			elseif e == "touchpressed" then
				local name = love.window.getTitle()
				if #name == 0 or name == "Untitled" then name = "Game" end
				local buttons = {"OK", "Cancel"}
				if love.system then
					buttons[3] = "Copy to clipboard"
				end
				local pressed = love.window.showMessageBox("Quit "..name.."?", "", buttons)
				if pressed == 1 then
					return 1
				elseif pressed == 3 then
					-- copyToClipboard()
				end
			end
		end

		draw()

		if love.timer then
			love.timer.sleep(0.01)
		end
	end

end