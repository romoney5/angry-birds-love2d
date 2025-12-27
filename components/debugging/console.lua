--console (activated by shift+d or clicking in the bottom right corner)

debugText = ""
debugCursorPosition = 0
debugCursorBlink = 0
debugPrevious = {}
debugPreviousIndex = 1
debugOpen = false
debugPrints = ""
debugPadding = 50

function checkDebugOpen()
	if (keyHold["SHIFT"] and keyPressed["D"]) or (keyPressed["LBUTTON"] and cursor.x >= screenWidth - 20 and cursor.y >= screenHeight - 20) or (debugOpen and keyPressed["ESCAPE"]) then
		keyPressed["ESCAPE"] = nil
		debugOpen = not debugOpen
		debugText = ""
		debugCursorPosition = 0
		debugPreviousIndex = 0
		res.playAudio("menu_confirm", 1, false)
		if debugOpen then
			love.keyboard.setTextInput(true)
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

			if debugText == "clear" then
				debugPrints = ""
				res.playAudio("menu_select", 1, false)
			else
				local su,re = pcall(loadstring(debugText))
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
			debugText = ""--debugText:sub(1,-2)
			debugCursorPosition = 0
			debugPreviousIndex = 0
		end
	end
	if keyPressed["LEFT"] then
		res.playAudio("menu_select", 1, false)
		debugCursorPosition = math.max(debugCursorPosition - 1, 0)
		debugCursorBlink = 0
	end
	if keyPressed["RIGHT"] then
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
	res.drawString("", debugText,debugPadding,debugPadding)
	-- love.graphics.printf((debugCursorBlink%.5 <= .25 and "|" or ""), res.getStringWidth(debugText:sub(1, debugCursorPosition)) + debugPadding - 3, (debugPadding + 0.5), screenWidth)-- + (textLines * font:getHeight()), screenWidth)
	res.drawString("", (debugCursorBlink % .5 <= .25 and "|" or ""), res.getStringWidth(debugText:sub(1, debugCursorPosition)) + debugPadding, (debugPadding + 3))

	-- love.graphics.printf(debugPrints, debugPadding, debugPadding * 2 + 70, screenWidth - debugPadding*2)-- + (#linesTotal * font:getHeight()), screenWidth - debugPadding * 2)
	res.drawString("", debugPrints, debugPadding, debugPadding * 2 + 70)

	local boxsprites = tutorialBoxSprites
	if boxsprites then
		local tl = checkSprite(boxsprites.topLeft)
		if not tl then return end
		local tlw, tlh = tl.width, tl.height
		local x, y = screenWidth - 125, 65
		local w, h = 75 * .9, 75 * .4
		local s = 1
		if checkBounds(x - tlw*2, y - tlh * 1.5, w + tlw*2, h + tlh*2, cursor.x, cursor.y) then
			if keyHold["LBUTTON"] then
				s = .8
			elseif (gameOptions.ui and gameOptions.ui.enableHoverScaling) or not gameOptions.ui then
				s = 1.2
			end
			w, h = w * s, h * s
			
			if keyReleased["LBUTTON"] then
				res.playAudio("menu_confirm", 1, false)
				debugOpen = false
				-- optionsOpen = true
				sgm()
				return
			end
		end
		drawBox(boxsprites or {}, "", x - w*.5, y - h*.5, w, h)
		love.graphics.translate(x, y)
		love.graphics.scale(s)
		res.drawString("", "Files", 0, 0, "HCENTER", "VCENTER")

		setRenderState(0,0,1,1)

		local w, h = 75 * .9, 75 * .4
		local x, y = screenWidth - 145 - w*2, 65
		local s = 1
		if checkBounds(x - tlw*2, y - tlh*1.5, w + tlw*2, h + tlh*2, cursor.x, cursor.y)then
			if keyHold["LBUTTON"] then
				s = .8
			elseif (gameOptions.ui and gameOptions.ui.enableHoverScaling) or not gameOptions.ui then
				s = 1.2
			end
			w, h = w * s, h * s
			
			if keyReleased["LBUTTON"] then
				res.playAudio("menu_confirm", 1, false)
				debugOpen = false
				optionsOpen = true
				-- sgm()
				return
			end
		end
		drawBox(boxsprites or {}, "", x - w*.5, y - h*.5, w, h)
		love.graphics.translate(x, y)
		love.graphics.scale(s)
		res.drawString("", "Options", 0, 0, "HCENTER", "VCENTER")
	end
end

function love.textinput(key)
	-- print(key)
	if debugOpen then
		res.playAudio("menu_confirm", 1, false)
		debugText = string.insert(debugText, key, debugCursorPosition)
		debugCursorPosition = debugCursorPosition + 1
		debugCursorBlink = 0
	elseif somethingTextInput then
		somethingTextInput = key
	end
end