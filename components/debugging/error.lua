--replacement of love's default error handler

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
		for i,v in ipairs(love.joystick.getJoysticks()) do
			v:setVibration()
		end
	end

	time = 0
	love.graphics.reset()
	love.graphics.setBlendMode("alpha","premultiplied")
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
			l = l:gsub("stack traceback:", "Stack traceback:\n")
			table.insert(err, l)
		end
	end

	local p = table.concat(err, "\n")

	p = p:gsub("\t", "")
	p = p:gsub("%[string \"(.-)\"%]", "%1")

	setTheme("theme"..math.random(1,15))
	if not screen then screen = {top = 0, left = 0} end

	local fullErrorText = p

	local function draw()
		if not love.graphics.isActive() then return end
		local pos = 70*.6
		love.graphics.clear(love.graphics.getBackgroundColor())
		screenHeight = love.graphics.getHeight()
		screen.top = -400
		setWorldScale((0.5 * screenHeight / 400) / (0.66))
		if blockTable and blockTable.themes then
			drawBackgroundNative()
			drawForegroundNative()
		end

		screen.left = screen.left + 1
		-- love.graphics.printf(p, pos, pos, love.graphics.getWidth() - pos)
		setRenderState(pos*2,pos*2,1.2,1.2)

		if res then
			res.useFont(fontBasic or "FONT_BASIC")
			-- res.useFont("FONT_MENU") --most newer games don't support letters in FONT_MENU
			love.graphics.setColor(0, 0, 0,.2)
			res.drawString("",p,pos+(1*16),pos+(1*16))
			love.graphics.setColor(1, 1, 1,1)
			res.drawString("",p,pos,pos)
		else
			love.graphics.print(p, 50, 50)
		end
	end

	return function()
		love.event.pump()
		keyReleased = {}
		screenWidth = math.floor(love.graphics.getWidth()/displayScale)
		screenHeight = math.floor(love.graphics.getHeight()/displayScale)
		cursor.x, cursor.y = love.mouse.getPosition()
		cursor.x = cursor.x / displayScale
		cursor.y = cursor.y / displayScale

		for e, a, b, c in love.event.poll() do
			if e == "quit" then
				return 1
			elseif e == "keypressed" and a == "escape" then
				return 1
				-- love.event.quit("restart")
			elseif e == "keypressed" and a == "c" and love.keyboard.isDown("lctrl", "rctrl") then
				-- copyToClipboard()
			elseif e == "touchpressed" or e == "mousepressed" then
				if not currentPopup.open then
					showPopup("Angry Birds", "Exit the game?",{
						-- {sprite = "BUTTON_RESTART", callback = function()
						-- 	love.event.quit("restart")
						-- end},
						{sprite = "MENU_NO", callback = function()
							return true
						end},
						{sprite = "TUTORIAL_OK", callback = function()
							love.event.quit()
						end},})
					-- local buttons = {"Exit", "Cancel"}
					-- if love.system then
					-- 	buttons[3] = "Copy Error"
					-- end
					-- local pressed = love.window.showMessageBox("Angry Birds", "Exit the game?", buttons)
					-- if pressed == 1 then
					-- 	return 1
					-- elseif pressed == 3 then
					-- 	love.system.setClipboardText(fullErrorText)
					-- end
				else
					keyReleased.LBUTTON = true
				end
			end
		end

		draw()
		setRenderState(0,0,1,1)
		updatePopup()
		love.graphics.present()

		if love.timer then
			love.timer.sleep(0.01)
		end
	end
end