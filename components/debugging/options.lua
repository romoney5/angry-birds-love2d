--options menu

optionsOpen = false
optionsScrolling = 0
optionsScrollTo = 0

function updateOptions(dt)
	if keyPressed["ESCAPE"] then
		optionsOpen = false
		optionsScrollTo = 0
		optionsScrolling = 0
		res.playAudio("menu_back", 1, false)
		return
	end

	setRenderState(0, 0, 1, 1)

	love.graphics.setColor(0, 0, 0, .5)
	love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
	-- love.graphics.rectangle("fill", 0, 0, screenWidth, debugPadding * 2 + 30)-- + (#linesTotal * font:getHeight()))
	love.graphics.setColor(1, 1, 1, 1)

	-- love.graphics.printf(debugText, debugPadding, debugPadding, screenWidth - debugPadding * 2)
	-- res.drawString("",debugText,debugPadding,debugPadding)

	local boxsprites = tutorialBoxSprites
	-- local tl = checkSprite(boxsprites.topLeft)
	-- local tlw,tlh = tl.w,tl.h
	local x,y = screenWidth / 2, screenHeight / 2
	local w,h = screenWidth - debugPadding * 7, screenHeight - debugPadding * 7
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
	drawBoxNative(boxsprites or {}, x - w*.5, y - h*.5, w, h)
	drawDebugText("Options", 240, 170, nil, "FONT_MENU")
	drawDebugButton("BUTTON_ARROW_LEFT", 180, 170, 1, function()
		optionsOpen = false
		optionsScrollTo = 0
		optionsScrolling = 0
	end, true, "menu_back")

	res.useFont("FONT_BASIC")
	optionsScrollTo = optionsScrollTo + cursor.wheel * 48
	optionsScrolling = (optionsScrolling * 9 + optionsScrollTo) * .1
	local optionsy = 250 + optionsScrolling
	local basey = optionsy
	local y0, y1 = y - h*.4, y + h*.5
	res.setClipRect(0, y0, screenWidth, y1 - y0)
	for i,v in pairs(gameOptions) do
		if type(v) == "boolean" then
			drawDebugButton(v and "TUTORIAL_OK" or "MENU_NO", 200, optionsy, .5, function()
				-- optionsOpen = false
				gameOptions[i] = not v
			end, (optionsy <= y1 and optionsy >= y0), "menu_confirm")
			drawDebugText(i, 200 + 36, optionsy)
			optionsy = optionsy + 50
		elseif type(v) == "table" then
			drawDebugText(i, 200 - 25, optionsy)
			optionsy = optionsy + 50
			for ii,vv in pairs(v) do
				if type(vv) == "boolean" then
					drawDebugButton(vv and "TUTORIAL_OK" or "MENU_NO", 200 + 56, optionsy, .5, function()
						-- optionsOpen = false
						gameOptions[i][ii] = not vv
					end, (optionsy <= y1 and optionsy >= y0), "menu_confirm")
					drawDebugText(ii, 200 + 36 + 56, optionsy)
					optionsy = optionsy + 50
				end
			end
			optionsy = optionsy + 25
		end
	end
	
	optionsScrollTo = math.max(optionsScrollTo, -(optionsy-basey) + (y1 - y0))
	optionsScrollTo = math.min(optionsScrollTo, res.getFontHeight() / displayScale)
	love.graphics.setScissor()
end