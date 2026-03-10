--some ui components used in more recent menus

--easing functions, syntax inspired by srb2 and formulas from https://easings.net/
ease = {}

function ease.linear(t, a, b)
	return t * (b - a) + a
end

function ease.inSine(t, a, b)
	local c = 1 - math.cos((t * math.pi) / 2)
	return ease.linear(c, a, b)
end

function ease.outSine(t, a, b)
	local c = math.sin((t * math.pi) / 2)
	return ease.linear(c, a, b)
end

function ease.inOutSine(t, a, b)
	local c = -(math.cos(t * math.pi) - 1) / 2
	return ease.linear(c, a, b)
end


function ease.inQuad(t, a, b)
	local c = t ^ 2
	return ease.linear(c, a, b)
end

function ease.outQuad(t, a, b)
	local c = 1 - ((1 - t) ^ 2)
	return ease.linear(c, a, b)
end

function ease.inOutQuad(t, a, b)
	local c = t < .5 and (t ^ 2) * 2 or 1 - (-2 * t + 2) ^ 2 / 2
	return ease.linear(c, a, b)
end


function ease.inCubic(t, a, b)
	local c = t ^ 3
	return ease.linear(c, a, b)
end

function ease.outCubic(t, a, b)
	local c = 1 - ((1 - t) ^ 3)
	return ease.linear(c, a, b)
end

function ease.inOutCubic(t, a, b)
	local c = t < .5 and (t ^ 3) * 4 or 1 - (-2 * t + 2) ^ 3 / 2
	return ease.linear(c, a, b)
end

--console ui
CUI = {}

CUI.BGColor_Blue = {24 / 255, 50 / 255, 75 / 255}

CUI.currentTextboxState = nil

--unused right now
function CUI.State()
	local state = {}
	setmetatable(state, state)
	
	function state.__index(self, k)
		rawset(state, k, {})
		return state[k]
	end
	
	return state
end

function CUI.Scrollbar(x, y, sc_w, h, scroll, maxscroll, contenth)
	--scroll bar indicator
	local percent = scroll / maxscroll
	-- print(maxscroll)
	local barHeight = math.min(1, h / math.max(contenth, 1)) * h
	love.graphics.setColor(.5, .5, .5, .5)
	love.graphics.setLineWidth(2)
	love.graphics.setLineStyle("rough")
	love.graphics.rectangle("fill", x - sc_w, lerp(y, y + h - barHeight, percent), sc_w, barHeight, sc_w / 2, sc_w / 2)
	love.graphics.rectangle("line", x - sc_w, y, sc_w, h, sc_w / 2, sc_w / 2)
	love.graphics.setColor(1, 1, 1, 1)
end

function CUI.Textbox(state, x, y, w, h)
	--text field
	state.value = state.value or ""
	state.numeric = state.numeric or false
	state.placeholder = state.placeholder or "Enter text here..."
	state.cursor = state.cursor or state.value:len()
	state.cursorBlink = state.cursorBlink or 0
	state.cursorBlink = state.cursorBlink + love.timer.getDelta()
	state.timer = 2
	
	local hovering = checkBounds(x, y, w, h, cursor.x, cursor.y)
	if keyPressed.LBUTTON and hovering then
		CUI.currentTextboxState = state
		state.cursorBlink = 0
	elseif CUI.currentTextboxState == state and keyPressed.LBUTTON and not hovering then
		CUI.currentTextboxState = nil
	end

	if CUI.currentTextboxState == state then
		--move the selection left/right
		if keyPressed.LEFT or keyPressed.RIGHT and not (keyPressed.LEFT and keyPressed.RIGHT) then
			local direction = (keyPressed.RIGHT and 1 or -1)
			res.playAudio("menu_select", 1, false)

			state.cursor = math.min(math.max(state.cursor + direction, 0), state.value:len())
			state.cursorBlink = 0
		end
		
		if keyPressed.BACKSPACE then
			res.playAudio("menu_back", 1, false)
			state.value = string.back(state.value, state.cursor)
			state.cursor = math.max(state.cursor - 1, 0)
			state.cursorBlink = 0
		end

		if keyPressed.DELETE then
			res.playAudio("menu_back", 1, false)
			state.value = string.back(state.value, state.cursor + 1)
			state.cursorBlink = 0
		end
	end
	
	-- print(maxscroll)
	love.graphics.setColor(.5, .5, .5, .5)
	love.graphics.setLineWidth(2)
	love.graphics.setLineStyle("rough")
	love.graphics.rectangle("fill", x, y, w, h, 10, 10)
	love.graphics.rectangle("line", x, y, w, h, 10, 10)
	
	if state.value == "" then
		love.graphics.setColor(1, 1, 1, .5)
		res.drawString("", state.placeholder, x + 5, y)
	end
	
	love.graphics.setColor(1, 1, 1, 1)
	res.drawString("", state.value, x + 5, y)
	
	if CUI.currentTextboxState == state then
		res.drawString("", ((state.cursorBlink * 2) % 2 <= 1 and "|" or ""),
			res.getStringWidth(state.value:sub(1, state.cursor), nil, nil, nil, true) + x + 5 - 5,
			res.getStringHeight(state.value:sub(1, state.cursor)) + y)
	end
end

function CUI.OnTextInput(key)
	if CUI.currentTextboxState then
		local state = CUI.currentTextboxState
		local nextval = string.insert(state.value, key, state.cursor)
		
		if state.numeric and not tonumber(key) and not tonumber(nextval) and nextval ~= "-" then
			return
		end
		
		state.value = nextval
		state.cursor = state.cursor + 1
		state.cursorBlink = 0
	end
end

function CUI.Checkbox(state, x, y, w, h, label)
	--check box
	state.value = state.value and true or false

	drawDebugButton(sprite, x + w / 2, y + h / 2, w, h, 1, function() state.value = not state.value end, true, sound)
	
	love.graphics.push()
	
	love.graphics.translate(x + w / 2, y + h / 2)
	love.graphics.scale(.4)
	if state.value then
		CUI.DrawIcon("check")
	end
	
	love.graphics.pop()
	
	if label then
		res.drawString("", label, x + w + 10, y + h / 2, "VCENTER")
	end
end

function CUI.DrawIcon(icon)
	if icon == "check" then
		love.graphics.line(-40, 0, -15, 25, 35, -25)
	elseif icon == "cross" then
		love.graphics.line(-25, -25, 25, 25)
		love.graphics.line(25, -25, -25, 25)
	elseif icon == "left" then
		love.graphics.line(10, 25, -15, 0, 10, -25)
	end
end

function CUI.DrawWrappedString(group, text, x, y, w, aligny, alignx)
	clipText(group, text, w)
	local text = clippedText and table.concat(clippedText.lines, "\n") or text
	
	res.drawString(group, text, x, y, aligny, alignx)
end

function drawDebugButton(sprite, x, y, w, h, scale, call, enabled, sound)
	local image = checkSprite(sprite)
	
	love.graphics.push()
	
	local w,h = image and image.width or w or 100, image and image.height or h or 100

	local s = 1
	do
		--[[local w, h = love.graphics.transformPoint(w + x, h + y)
		local x, y = love.graphics.transformPoint(x, y)
		w, h = w - x, h - y]]
		
		if enabled and checkBounds(x - w/2, y - h/2, w * scale, h * scale, cursor.x, cursor.y)then
			if keyHold["LBUTTON"] then
				s = .9
			elseif (gameOptions.ui and gameOptions.ui.enableHoverScaling) or not gameOptions.ui then
				s = 1.1
			end

			if keyReleased["LBUTTON"] then
				res.playAudio(sound or "menu_confirm", 1, false)
				if call then
					call()
				end
			end
		end
	end

	love.graphics.translate(x, y)
	love.graphics.scale(s * scale)
	
	if sprite == "MENU_QUIT_EN" then
		local _, py = res.getSpritePivot("", "MENU_NO")
		drawyp = py
	end

	if sprite then
		if not image then
			love.graphics.push("all")
			love.graphics.setColor(table.unpack(CUI.BGColor_Blue))
			love.graphics.circle("fill", 0, 0, w/2)
			love.graphics.pop()
			love.graphics.circle("line", 0, 0, w/2)
			if sprite == "TUTORIAL_OK" then
				CUI.DrawIcon("check")
			elseif sprite == "MENU_NO" then
				CUI.DrawIcon("cross")
			elseif sprite == "BUTTON_ARROW_LEFT" then
				CUI.DrawIcon("left")
			end
		else
			res.drawSprite(sprite, 0, 0)
		end
	elseif sprite ~= false then
		love.graphics.rectangle("line", -w / 2, -h / 2, w, h, 20)
	end
	
	love.graphics.pop()
end

function drawDebugText(text, x, y, align, font, w)
	if w then
		clipText(group, text, w)
		text = clippedText and table.concat(clippedText.lines, "\n") or text
	end
	
	align = align or "LEFT"
	res.useFont(font)
	love.graphics.setColor(0, 0, 0, .2)
	res.drawString("", text, x + 8, y + 8, align, "VCENTER")
	love.graphics.setColor(1, 1, 1, 1)
	res.drawString("", text, x, y, align, "VCENTER")
	
	if w then
		return clippedText and clippedText.widestLine, res.getStringHeight(text)
	end
end