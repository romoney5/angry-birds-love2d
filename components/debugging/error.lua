--replacement for love's default error handler

local errors = 0

function love.errorhandler(msg)
	errors = errors + 1

	--enough
	if errors >= 3 then
		return
	end
	
	pcall(function()
		--reset identity
		setDataPathFromFile("")
		
		--clear autoboot if it exists
		if mobileDevice and love.filesystem.remove(autoboot_path) then
			print("Removed "..autoboot_path)
		end
	end)

	msg = tostring(msg)

	print((debug.traceback("Error: "..tostring(msg), 1 + (layer or 1)):gsub("\n[^\n]+$", "")))

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
		for i,v in ipairs(love.joystick.getJoysticks()) do
			v:setVibration()
		end
	end

	time = 0
	love.graphics.reset()
	love.graphics.setBlendMode("alpha", "premultiplied")
	love.graphics.setColor(1, 1, 1)

	local trace = debug.traceback()

	love.graphics.origin()

	local sanitizedmsg = {}
	for char in msg:gmatch(utf8.charpattern) do
		table.insert(sanitizedmsg, char)
	end
	sanitizedmsg = table.concat(sanitizedmsg)

	local err = {}

	table.insert(err, "Error:\n") --make it more clear that an error occurred
	table.insert(err, sanitizedmsg)

	if #sanitizedmsg ~= #msg then
		table.insert(err, "Invalid UTF-8 string in error message.")
	end

	table.insert(err, "\n")

	for l in trace:gmatch("(.-)\n") do
		if not l:match("boot.lua") then
			l = l:gsub("stack traceback:", "Stack traceback:\n")
			table.insert(err, l)
		end
	end

	local p = table.concat(err, "\n")

	p = p:gsub("\t", "")
	p = p:gsub("%[string \"(.-)\"%]", "%1")

	local fullErrorText = p

	autoScale = 1000

	local function draw(dt)
		if not love.graphics.isActive() then return end
		
		local pos = 40
		lgClear(love.graphics.getBackgroundColor())
		screenHeight = love.graphics.getHeight()
		-- love.graphics.printf(p, pos, pos, love.graphics.getWidth() - pos)
		updateDisplayScale()
		local scale = displayScale
		setRenderState(0, 0, 1, 1)--scale, scale)

		if res then
			res.useFont(fontBasic or "FONT_BASIC")
			-- res.useFont("FONT_MENU") --most newer games don't have letters in FONT_MENU
			love.graphics.setColor(0, 0, 0, .2)
			clipText("", p, (screenWidth - pos * 2))
			
			local text = clippedText and table.concat(clippedText.lines, "\n") or p
			
			res.drawString("", text, pos + 8, pos + 8)
			love.graphics.setColor(1, 1, 1, 1)
			res.drawString("", text, pos, pos)
		else
			love.graphics.print(p, pos, pos)
		end
	end

	return function()
		local dt = 1 / 100

		love.event.pump()
		table.clear(keyReleased)
		table.clear(keyPressed)
		
		local cx, cy = cursor.x, cursor.y
		pcall(function()
			screenWidth = math.floor(love.graphics.getWidth() / displayScale)
			screenHeight = math.floor(love.graphics.getHeight() / displayScale)
			cursor.x, cursor.y = love.mouse.getPosition()
			cursor.x = cursor.x / displayScale
			cursor.y = cursor.y / displayScale
		end)

		for name, a, b, c, d, e, f, g, h in love.event.poll() do
			if name == "quit" then
				return 1
			elseif name == "keypressed" and a == "escape" then
				return 1
			elseif name:find("mouse") or name:find("touch") or name:find("key") or name:find("textinput") then
				love.handlers[name](a,b,c,d,e,f,g,h)
			end
		end
		
		if keyReleased.LBUTTON and not debugOpen then
			if not openPopups[1] then
				openPopup("Angry Birds", "Exit the game?", {
					-- {sprite = "BUTTON_RESTART", callback = function()
					-- 	love.event.quit("restart")
					-- end},
					{sprite = "MENU_NO", callback = function()
						return true
					end},
					{sprite = "TUTORIAL_OK", callback = function()
						requestExit()
					end},
				})
			end
		end

		draw(dt)
		setRenderState(0, 0, 1, 1)
		updatePopup()
		
		prevCursor.x, prevCursor.y = cx, cy
		if checkDebugOpen then checkDebugOpen() end
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
		love.graphics.present()

		if love.timer then
			love.timer.sleep(dt)
		end
	end
end

--thread error handler in case fetch encountered an error
function love.threaderror(thread, errorstr)
	print("Error running thread:\n", errorstr)
end