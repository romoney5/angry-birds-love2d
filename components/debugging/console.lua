--console (activated by shift+d or clicking in the bottom right corner)

debugOpen = false

debugText = ""
debugCursorPosition = 0
debugCursorBlink = 0

debugPrevious = {}
debugPreviousIndex = 1

debugPrints = {}
debugPrintsLimit = 200

debugScroll = 0
debugScrollTarget = 0

debugPadding = 50

function checkDebugOpen()
	if (keyHold["SHIFT"] and keyPressed["D"]) or (keyPressed["LBUTTON"] and cursor.x >= screenWidth - 20 and cursor.y >= screenHeight - 20) or (debugOpen and keyPressed["ESCAPE"]) then
		keyPressed["ESCAPE"] = nil
		debugOpen = not debugOpen
		-- debugText = ""
		-- debugCursorPosition = 0
		debugPreviousIndex = 0
		debugScroll = 0
		debugScrollTarget = 0

		res.playAudio("menu_confirm", 1, false)
		if debugOpen then
			love.keyboard.setTextInput(true)
		end
	end
end

function debugExecute(text)
	if text == "clear" then
		table.clear(debugPrints)
		res.playAudio("menu_select", 1, false)
	else
		local su,re = pcall(loadstring(text))
		if not su then
			print("Error while running command: "..tostring(re))
		else
			if re then
				print(re)--"Ran command successfully with result: "..re)
			else
				-- print()--"Ran command successfully")
			end
		end
	end
end

function updateDebug(dt)
	setRenderState(0,0,1,1)

	debugCursorBlink = debugCursorBlink + dt
	-- local font = love.graphics.getFont()
	
	if keyPressed["BACKSPACE"] then
		res.playAudio("menu_back", 1, false)
		debugText = string.back(debugText, debugCursorPosition)
		debugCursorPosition = math.max(debugCursorPosition - 1, 0)
		debugCursorBlink = 0
	end

	if keyPressed["DELETE"] then
		res.playAudio("menu_back", 1, false)
		debugText = string.back(debugText, debugCursorPosition + 1)
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

			-- print(debugText)
			debugExecute(debugText)
			debugText = ""--debugText:sub(1,-2)
			debugCursorPosition = 0
			debugPreviousIndex = 0
		end
	end

	--move the selection left/right
	if keyPressed.LEFT or keyPressed.RIGHT and not (keyPressed.LEFT and keyPressed.RIGHT) then
		local direction = (keyPressed.RIGHT and 1 or -1)
		res.playAudio("menu_select", 1, false)

		debugCursorPosition = math.min(math.max(debugCursorPosition + direction, 0), debugText:len())
		debugCursorBlink = 0
	end

	--swap to the next/previous entry
	if keyPressed.UP or keyPressed.DOWN and not (keyPressed.UP and keyPressed.DOWN) then
		local direction = (keyPressed.UP and 1 or -1)
		if (direction == 1 and debugPreviousIndex < #debugPrevious) or (direction == -1 and debugPreviousIndex > 0) then
			res.playAudio("menu_select", 1, false)

			if direction == 1 and debugPreviousIndex == 0 then debugPrevious[0] = debugText end
			debugPreviousIndex = debugPreviousIndex + direction
			debugText = debugPrevious[debugPreviousIndex]
			debugCursorPosition = #debugText
		end
	end

	--scrolling
	res.useFont("FONT_BASIC")

	local logText = table.concat(debugPrints, "\n")
	local logHeight = res.getStringHeight(logText, nil, true) --there can be line breaks in some prints
	local scrollLimit = -logHeight + screenHeight - debugPadding * 2 - 70
	debugScrollTarget = debugScrollTarget + math.min(math.max(cursor.wheel, -10), 10) * 64

	--touch scrolling
	if keyHold.LBUTTON and not keyPressed.LBUTTON then --try not to snap the cursor on touchscreens
		debugScrollTarget = debugScrollTarget + (cursor.y - prevCursor.y)
	end

	debugScroll = lerp(debugScroll, debugScrollTarget, dt * 16)
	debugScrollTarget = math.min(math.max(debugScrollTarget, scrollLimit), 0)

	local round_padding = debugPadding / 4
	local input_h = debugPadding * 2 + 50 - round_padding * 2 + math.max(res.getStringHeight(debugText) - 50, 0)
	love.graphics.setColor(0, 0, 0, .5)
	love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
	love.graphics.rectangle("fill", round_padding, round_padding, screenWidth - round_padding * 2, input_h, 20, 20)-- + (#linesTotal * font:getHeight()))
	love.graphics.setColor(1, 1, 1, 1)

	res.drawString("", debugText, debugPadding, debugPadding)
	res.drawString("", (debugCursorBlink % .5 <= .25 and "|" or ""),
		res.getStringWidth(debugText:sub(1, debugCursorPosition), nil, nil, nil, true) + debugPadding,
		res.getStringHeight(debugText:sub(1, debugCursorPosition)) + (debugPadding + 3))

	love.graphics.setScissor(0, (input_h + 20) * displayScale, love.graphics.getDimensions())
	res.drawString("", logText, debugPadding, input_h + round_padding + 40 + debugScroll)
	love.graphics.setScissor()

	--scroll bar indicator
	CUI.Scrollbar(
		screenWidth - round_padding,
		input_h + round_padding * 2,
		10,
		screenHeight - (input_h + round_padding * 3),
		debugScroll,
		scrollLimit,
		logHeight)

	--files link
	local tlw, tlh = 35, 36--tl.width, tl.height
	local x, y = screenWidth - debugPadding - round_padding - tlw, debugPadding + round_padding * 2
	x, y = math.floor(x), math.floor(y)
	local w, h = 60 + tlw*2, 20 + tlh*2
	local s = 1
	drawDebugButton(nil, x, y, w, h, s, function()
		debugOpen = false
		sgm()
		return
	end, true, "menu_confirm")
	love.graphics.translate(x, y)
	love.graphics.scale(s)
	res.drawString("", "Files", 0, 0, "HCENTER", "VCENTER")

	setRenderState(0,0,1,1)
end

function love.textinput(key)
	-- print(key)
	if debugOpen then
		if not (keyHold["SHIFT"] and keyPressed["D"]) then --hack to stop D from being added
			res.playAudio("menu_confirm", 1, false)
			debugText = string.insert(debugText, key, debugCursorPosition)
			debugCursorPosition = debugCursorPosition + 1
			debugCursorBlink = 0
		end
	elseif somethingTextInput then
		somethingTextInput = key
	end
	
	CUI.OnTextInput(key)
end