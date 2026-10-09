--replacement for love's default error handler

local errors = 0

function love.errorhandler(msg)
	errors = errors + 1

	--enough
	if errors >= 3 then
		return
	end
	
	removeAutoboot()

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

	love.graphics.reset()
	love.graphics.setBlendMode("alpha", "premultiplied")
	love.graphics.setColor(1, 1, 1)
	
	love.graphics.setFont(default_font)

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

	res.useFont(nil)
	
	local output_scroll = {}

	local function draw(dt)
		if not love.graphics.isActive() then return end
		
		local round_padding = 10
		
		local pos = 40
		love.graphics.clear(love.graphics.getBackgroundColor())
		gamelua.screenHeight = love.graphics.getHeight()
		-- love.graphics.printf(p, pos, pos, love.graphics.getWidth() - pos)
		updateDisplayScale()
		local scale = displayScale
		gamelua.setRenderState(0, 0, 1, 1)--scale, scale)

		-- res.useFont("FONT_MENU") --most newer games don't have letters in FONT_MENU
		gamelua.clipText("", p, (gamelua.screenWidth - pos * 2))
		
		local text = gamelua.clippedText and table.concat(gamelua.clippedText.lines, "\n") or p

		--update scrolling logic
		output_scroll.height = gamelua.screenHeight
		output_scroll.contentHeight = #gamelua.clippedText.lines * res.getFontHeight()
		CUI.HandleScroll(output_scroll, dt)
		
		--draw the scroll bar
		CUI.ScrollbarFromScrollState(output_scroll, --scroll state
			gamelua.screenWidth - round_padding / 2, --x
			round_padding + round_padding / 2, --y
			gamelua.screenHeight - round_padding / 2 * 2 - round_padding, --height
			output_scroll.contentHeight) --content height
		
		res.drawString("", text, pos, pos + (output_scroll.scroll or 0))
	end

	return function()
		local dt = love.timer.step()

		love.event.pump()
		table.clear(keyReleased)
		table.clear(keyPressed)
		
		local cx, cy = cursor.x, cursor.y
		pcall(function()
			gamelua.screenWidth = math.floor(love.graphics.getWidth() / displayScale)
			gamelua.screenHeight = math.floor(love.graphics.getHeight() / displayScale)
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
					-- {icon = "BUTTON_RESTART", callback = function()
					-- 	love.event.quit("restart")
					-- end},
					{icon = "cross", callback = function()
						return true
					end},
					{icon = "check", callback = function()
						love.event.quit()
					end},
				})
			end
		end

		draw(dt)
		
		prevCursor.x, prevCursor.y = cx, cy
		updateConsole(dt)

		gamelua.setRenderState(0, 0, 1, 1)
		updatePopup()
		
		if debugOpen then
			love.keyboard.setKeyRepeat(true)
		else
			love.keyboard.setKeyRepeat(false)
		end
		love.graphics.present()

		if love.timer then
			love.timer.sleep(0.001)
		end
	end
end

--thread error handler in case fetch encountered an error
function love.threaderror(thread, errorstr)
	print("Error running thread:\n", errorstr)
end
