--console (activated by shift+d or clicking in the bottom right corner)

debugOpen = false

local debugPrevious = {}
local debugPreviousIndex = 1

local output_scroll = {}

local textbox_state = {
	multiline = true,
	
	on_confirm = function(self)
		if self.value ~= debugPrevious[debugPreviousIndex + 1] and self.value ~= "" then --prevent duplicate indexes
			table.insert(debugPrevious, 1, self.value)
		end
		
		debugExecute(self.value)
		self.value = ""--debugText:sub(1,-2)
		self.cursor = 0
		self.cursorBlink = 0
		
		output_scroll.overscroll = .5 / 2
		output_scroll.overscrollPosition = output_scroll.scroll / ease.inCubic(.5, 0, 1)
		output_scroll.overscrollDest = 0
	end,
}

debugPrints = {}
debugPrintsLimit = 200

local debugPadding = 50

function checkDebugOpen()
	if (keyHold["SHIFT"] and keyPressed["D"]) or (keyPressed["LBUTTON"] and cursor.x >= screenWidth - 20 and cursor.y >= screenHeight - 20) or (debugOpen and keyPressed["ESCAPE"]) then
		keyPressed["ESCAPE"] = nil
		debugOpen = not debugOpen
		debugPreviousIndex = 0
		textbox_state.cursorBlink = 0

		res.playAudio("menu_confirm", 1, false)
		if debugOpen then
			love.keyboard.setTextInput(true)
			CUI.currentTextboxState = textbox_state
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

	--swap to the next/previous entry
	--TODO: only do this if the cursor is at the last/first line
	if keyPressed.UP or keyPressed.DOWN and not (keyPressed.UP and keyPressed.DOWN) then
		local direction = (keyPressed.UP and 1 or -1)
		if (direction == 1 and debugPreviousIndex < #debugPrevious) or (direction == -1 and debugPreviousIndex > 0) then
			res.playAudio("menu_select", 1, false)

			if direction == 1 and debugPreviousIndex == 0 then debugPrevious[0] = debugText end
			debugPreviousIndex = debugPreviousIndex + direction
			textbox_state.value = debugPrevious[debugPreviousIndex]
			textbox_state.cursor = textbox_state.value:len()
		end
	end

	--scrolling
	res.useFont(nil)

	--local logText = table.concat(debugPrints, "\n")
	local round_padding = debugPadding / 4
	local input_h = debugPadding * 2 + 50 - round_padding * 2 + math.max(res.getStringHeight(textbox_state.value) - 50, 0)
	
	love.graphics.setColor(0, 0, 0, .5)
	love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
	love.graphics.setColor(1, 1, 1, 1)
	
	--update the text box
	CUI.Textbox(textbox_state, round_padding, round_padding, screenWidth - round_padding * 2, input_h)

	--draw the logs
	--TODO: kill out of bounds lines
	local log_y = 0
	local clip_y1 = input_h + 20
	local clip_y2 = screenHeight
	love.graphics.setScissor(0, clip_y1 * displayScale, screenWidth * displayScale, clip_y2 * displayScale)
	for i, line in ipairs(debugPrints) do
		local total_y = input_h + round_padding + log_y + 40 + (output_scroll.scroll or 0)
		local height = res.getStringHeight(line, nil, true)
		
		if total_y < clip_y2 and total_y >= clip_y1 - height then
			res.drawString("", line, debugPadding, total_y)
		end
		log_y = log_y + height
	end
	love.graphics.setScissor()

	--update scrolling logic
	output_scroll.height = screenHeight
	output_scroll.contentHeight = log_y
	CUI.HandleScroll(output_scroll, dt)
	
	--draw the scroll bar
	CUI.ScrollbarFromScrollState(output_scroll, --scroll state
		screenWidth - round_padding / 2, --x
		(input_h + round_padding) + round_padding / 2, --y
		screenHeight - round_padding / 2 * 2 - (input_h + round_padding), --height
		output_scroll.contentHeight) --content height

	--files link
	local tlw, tlh = 35, 36--tl.width, tl.height
	local x, y = screenWidth - debugPadding - round_padding * 3 - tlw, debugPadding + round_padding * 2
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
	if not debugOpen and somethingTextInput then
		somethingTextInput = key
	end
	
	if not (keyHold["SHIFT"] and keyPressed["D"]) then --hack to stop D from being added
		CUI.OnTextInput(key)
	end
end