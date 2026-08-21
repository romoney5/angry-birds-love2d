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

--scroll bar indicator
function CUI.Scrollbar(x, y, sc_w, h, scroll, maxscroll, contentHeight)
	local percent = scroll / maxscroll
	-- print(maxscroll)
	local barHeight = math.min(1, h / math.max(contentHeight, 1)) * h
	love.graphics.setColor(.5, .5, .5, .5)
	love.graphics.setLineWidth(2)
	love.graphics.setLineStyle("rough")
	love.graphics.rectangle("fill", x - sc_w, lerp(y, y + h - barHeight, percent), sc_w, barHeight, sc_w / 2, sc_w / 2)
	love.graphics.rectangle("line", x - sc_w, y, sc_w, h, sc_w / 2, sc_w / 2)
	love.graphics.setColor(1, 1, 1, 1)
end

--recommended scrollbar settings
function CUI.ScrollbarFromScrollState(scroll, x, y, h, contentHeight)
	CUI.Scrollbar(
		x,
		y,
		10,
		h,
		scroll.scroll,
		scroll.maxscroll,
		contentHeight)
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
	
	state.scroll = state.scroll or {}
	state.scroll.height = h
	state.scroll.contentHeight = res.getStringHeight(state.value)
	
	local hovering = checkBounds(x, y, w, h, cursor.x, cursor.y)
	local textx = x
	local lineswidth = 50
	
	if state.multiline then
		textx = textx + lineswidth + 10 --higher numbers
	end
	
	local scroll, disable = state.scroll.scroll or 0, false
	if hovering and state.multiline then
		scroll, disable = CUI.HandleScroll(state.scroll, love.timer.getDelta())
	end
	
	if keyReleased.LBUTTON and hovering and not disable then
		CUI.currentTextboxState = state
		state.cursorBlink = 0
		
		local cx, cy = cursor.x - textx, cursor.y - y - (state.scroll and state.scroll.scroll or 0)
		local lines = 0
		local font = love.graphics.getFont()
		local fontheight = font:getHeight() - .5
		local len = 0
		
		for line in state.value:gmatch("[^\n]+") do
			lines = lines + fontheight
			
			if cy < lines then
				local maxtext = ""
				local amount = 0
				for p, c in utf8.codes(line) do
					local char = utf8.char(c)
					amount = amount + 1
					maxtext = maxtext..char
					
					if font:getWidth(maxtext) --[[- font:getWidth(char) * 0]] >= cx then
						break
					end
					state.cursor = amount + len
				end
				break
			end
			
			len = len + utf8.len(line) + 1
		end
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

		if keyPressed.RETURN and state.multiline then
			CUI.OnTextInput("\n")
		end

		if keyPressed.TAB then
			CUI.OnTextInput("\t")
		end
	end
	
	love.graphics.setColor(.5, .5, .5, .5)
	love.graphics.setLineWidth(2)
	love.graphics.setLineStyle("rough")
	love.graphics.rectangle("fill", x, y, w, h, 10, 10)
	love.graphics.rectangle("line", x, y, w, h, 10, 10)

	--TODO: doesn't play well with scrolling
	--TODO: newlines also don't display properly
	res.setClipRect(x, y, w, h)
	
	love.graphics.push()
	love.graphics.translate(0, scroll)
	
	local font = love.graphics.getFont()
	local fontheight = font:getHeight() - .5
	
	--draw the mutliline view if applicable
	if state.multiline then
		love.graphics.rectangle("fill", x, y - scroll, lineswidth, h, 10, 10)
	end
	
	--draw the placeholder if applicable
	if state.value == "" then
		love.graphics.setColor(1, 1, 1, .5)
		res.drawString("", state.placeholder, textx + 5, y)
	end

	love.graphics.setColor(1, 1, 1, 1)
	
	--draw the text per line to avoid drawing too much text at once
	local lines = 0
	
	for line in state.value:gmatch("[^\n]+") do --sucks
		local final_y = y + lines * fontheight
		
		--only draw the line if it is below the top
		if final_y >= y - scroll - fontheight then
			if state.multiline then
				res.drawString("", lines + 1, x + 5, final_y) --line number
			end
			
			res.drawString("", line, textx + 5, final_y) --the actual line
		end
		
		lines = lines + 1
		
		--stop if we reach the bottom of the text box
		if final_y > y - scroll + h then break end
	end
	
	if CUI.currentTextboxState == state then
		local clip = utf8.sub(state.value, 1, state.cursor)
		res.drawString("", ((state.cursorBlink * 2) % 2 <= 1 and "|" or ""),
			res.getStringWidth(clip:getLineAt(-1), nil, nil, nil, true) + textx + 5 - 5,
			res.getStringHeight(clip) + y)
	end
	
	love.graphics.pop()

	--scroll bar indicator
	if state.multiline then
		local f_padding = 50
		CUI.ScrollbarFromScrollState(state.scroll, --scroll state
			x + w - f_padding / 2, --x
			y + f_padding / 2, --y
			h - f_padding / 2 * 2, --height
			state.scroll.contentHeight) --content height
	end

	love.graphics.setScissor()
end

--non-elastic scrolling
--[[function CUI.HandleScroll(state, dt)
	state.scroll = state.scroll or 0
	state.dest = state.dest or 0
	
	state.touch_curscroll = state.touch_curscroll or 0
	state.touch_maxscroll = state.touch_maxscroll or 0 --velocity
	
	state.height = state.height or 0
	state.contentHeight = state.contentHeight or 0
	
	if (keyHold.LBUTTON or keyReleased.LBUTTON) and not keyPressed.LBUTTON then --try not to snap the cursor on touchscreens
		state.dest = state.dest + (cursor.y - prevCursor.y) * 1.2
		state.touch_curscroll = state.touch_curscroll or 0
		state.touch_curscroll = state.touch_curscroll + (cursor.y - prevCursor.y)
		state.touch_maxscroll = state.touch_maxscroll or 0
		state.touch_maxscroll = math.max(state.touch_maxscroll, math.abs(state.touch_curscroll))
	else
		state.touch_curscroll = 0
		state.touch_maxscroll = 0
	end

	state.dest = state.dest + cursor.wheel * 48
	state.scroll = ease.linear(dt * 16, state.scroll, state.dest)

	state.maxscroll = -(state.contentHeight - state.scroll) + state.height - 190
	state.dest = math.max(state.dest, state.maxscroll)
	state.dest = math.min(state.dest, 0)
	
	--shortcut
	return state.scroll, state.touch_maxscroll >= 10
end]]

local function sign(x)
	return x > 0 and 1 or (x < 0 and -1 or 0)
end

--global scrolling system, it's become too complicated to include in everything separately
--scroll, disable = CUI.HandleScroll(so.scroll, dt)
function CUI.HandleScroll(state, dt)
	state.scroll = state.scroll or 0
	state.dest = state.dest or 0
	state.velocity_y = state.velocity_y or 0
	state.maxscroll = state.maxscroll or 0
	
	--used to keep touch scrolling from accidentally pressing buttons
	state.touch_curscroll = state.touch_curscroll or 0
	state.touch_maxscroll = state.touch_maxscroll or 0
	
	--general touch scrolling
	state.touch_scrolling = state.touch_scrolling or false
	state.touch_scrollVelocity = state.touch_scrollVelocity or 0
	state.touch_scrollVelocityTimeout = state.touch_scrollVelocityTimeout or 0
	
	state.height = state.height or 0
	state.contentHeight = state.contentHeight or 0
	
	--elastic scrolling, overscroll
	state.overscroll = state.overscroll or 0
	state.overscrollPosition = state.overscrollPosition or 0
	state.overscrollDest = state.overscrollDest or 0
	
	local outOfBounds = (state.maxscroll < 0 and state.scroll < state.maxscroll and state.velocity_y <= 0)
	or (state.scroll > 0 and state.velocity_y >= 0)
	
	if (keyHold.LBUTTON or keyReleased.LBUTTON) and not keyPressed.LBUTTON then --try not to snap the cursor on touchscreens
		--state.dest = state.dest + (cursor.y - prevCursor.y) * 1.2
		state.touch_scrolling = true
		state.velocity_y = 0
		
		local delta = (cursor.y - prevCursor.y)
		
		if outOfBounds then
			delta = delta / 2
		end
		
		if not keyReleased.LBUTTON then
			state.scroll = state.scroll + delta
			
			--windows can report 0 for a few frames after releasing touch, use a timeout to mitigate that
			if delta ~= 0 then
				state.touch_scrollVelocity = delta
				state.touch_scrollVelocityTimeout = .2
			else
				state.touch_scrollVelocityTimeout = math.max(state.touch_scrollVelocityTimeout - dt, 0)
				
				if state.touch_scrollVelocityTimeout == 0 then
					state.touch_scrollVelocity = 0
				end
			end
		end
		--print(state.touch_scrollVelocity)
		
		state.touch_curscroll = state.touch_curscroll or 0
		state.touch_curscroll = state.touch_curscroll + delta
		state.touch_maxscroll = state.touch_maxscroll or 0
		state.touch_maxscroll = math.max(state.touch_maxscroll, math.abs(state.touch_curscroll))
	else
		if state.touch_scrolling then
			--print("final "..state.touch_scrollVelocity)
			--fling it based on its last velocity
			state.velocity_y = state.touch_scrollVelocity * 100
		end
		
		state.touch_scrolling = false
		state.touch_scrollVelocityTimeout = 0
		state.touch_scrollVelocity = 0
		
		state.touch_curscroll = 0
		state.touch_maxscroll = 0
	end

	--state.dest = state.dest + cursor.wheel * 48
	local wspeed = dt * 4000
	local wpeed = dt * 24000
	local maxspeed = 200000 --00
	state.velocity_y = state.velocity_y - sign(state.velocity_y) * wspeed
	if math.abs(state.velocity_y) < wspeed then
		state.velocity_y = 0
	elseif math.abs(state.velocity_y) > maxspeed then
		state.velocity_y = maxspeed * sign(state.velocity_y)
	end

	state.maxscroll = -(state.contentHeight) + state.height - 190
	--[[state.dest = math.max(state.dest, state.maxscroll)
	state.dest = math.min(state.dest, 0)]]
	
	state.velocity_y = state.velocity_y + cursor.wheel * 500
	state.scroll = state.scroll + state.velocity_y * dt--ease.linear(dt * 16, state.scroll, state.dest)
	
	if not state.touch_scrolling and outOfBounds then
		local delta = state.scroll > 0 and state.scroll or (state.maxscroll - state.scroll)
		--if state.velocity_y < 0 then
			state.velocity_y = state.velocity_y - sign(state.velocity_y) * delta
		--end
		
		if state.overscroll == 0 and state.velocity_y >= 0 then
			--print("a", state.maxscroll, state.scroll)
			--state.velocity_y = math.sqrt(2 * 4000 * (state.maxscroll - state.scroll))--(state.maxscroll - state.scroll) * 400
			state.overscroll = .5
			state.overscrollPosition = state.scroll
			state.overscrollDest = state.scroll > 0 and 0 or state.maxscroll
		end
	end
	
	if state.overscroll > 0 then
		state.overscroll = math.max(state.overscroll - dt, 0)
		
		local sc = 1 - (state.overscroll * 2)
		local new = ease.outCubic(sc, state.overscrollPosition, state.overscrollDest)
		
		if not state.touch_scrolling and math.abs(new - state.scroll) > math.abs(state.velocity_y) then
			state.scroll = new
		else
			state.overscroll = 0
		end
	end
	
	--shortcut
	return state.scroll, state.touch_maxscroll >= 10
end

function CUI.OnTextInput(key)
	if CUI.currentTextboxState then
		local state = CUI.currentTextboxState
		local nextval = string.insert(state.value, key, state.cursor)
		
		if (state.numeric and not tonumber(key) and not tonumber(nextval) and nextval ~= "-") and not (key == "\n" and state.multiline) then
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

function drawDebugButton(sprite, x, y, w, h, scale, call, enabled, sound) --TODO: use states, ox/oy are hacky
	local image = checkSprite(sprite)
	
	love.graphics.push()
	
	local w,h = image and image.width or w or 100, image and image.height or h or 100

	local s = 1
	do
		local w, h = love.graphics.transformPoint((w + x) / displayScale, (h + y) / displayScale)
		local x, y = love.graphics.transformPoint(x / displayScale, y / displayScale)
		w, h = w - x, h - y
		
		if enabled and checkBounds(x - w/2, y - h/2, w * scale, h * scale, cursor.x, cursor.y) then
			if keyHold["LBUTTON"] then
				s = .9
			else
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
	text = tostring(text)
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

function updatePopup()
	local popup = openPopups[1]
	local dt = love.timer.getDelta()

	if popup then
		local function update()
			setRenderState(0, 0, 1, 1, 0, 0, 0, 1)
			popup.anim = popup.anim or 0
			popup.anim = math.max(math.min(popup.anim + (popup.closing and -dt * 2 or dt), .25), 0)
			
			popup.scroll = popup.scroll or {}

			local maxWidth = math.max(res.getStringWidth(popup.title) - 50, res.getStringWidth(popup.text), 480) + 100
			maxWidth = math.min(maxWidth, screenWidth * .9)
			popup.w = popup.w or maxWidth
			popup.h = popup.h or 0
			popup.h_anim = popup.h_anim or 0
			popup.h_anim = ease.linear(dt * 16, popup.h_anim, popup.h)

			love.graphics.push()
			local w = popup.w
			local h = 300 + (popup.h_anim or 0)
			w = math.min(w, screenWidth * .9)

			local ox, oy = screenWidth * .5, screenHeight * .5
			local x, y = ox - w * .5, oy - h * .5
			
			popup.scroll.height = screenHeight
			popup.scroll.contentHeight = h
			local enableScroll = popup.scroll.height < popup.scroll.contentHeight + 100 --hack
			if enableScroll then
				--y = y + 150
				y = 0 + 50
			end
			
			local scroll, disable = 0, false
			
			if enableScroll then
				scroll, disable = CUI.HandleScroll(popup.scroll, dt)
			end

			drawRect2(0, 0, 0, #openPopups > 1 and .6 or ease.outCubic(popup.anim / .25, 0, .6), 0, 0, screenWidth, screenHeight)
			love.graphics.translate(x + w / 2, y + h / 2 + scroll)
			love.graphics.scale(ease.outCubic(popup.anim / .25, .8, 1))
			love.graphics.translate(-(x + w / 2), -(y + h / 2))
			drawRect2(10 / 255, 10 / 255, 10 / 255, .3, x + 10, y + 10, w, h, 16)
			drawRect2(24 / 255, 50 / 255, 75 / 255, 1, x, y, w, h, 16)

			drawDebugText(popup.title, ox, y, "HCENTER", nil, maxWidth)
			local twidth, theight = drawDebugText(popup.text, x + 50, y + 75, "LEFT", nil, maxWidth - 50 - 50)
			popup.w = math.max(twidth, 480) + 100
			popup.h = theight
			
			local function close(len)
				if not popup.closing then
					popup.closing = true

					--hack
					if #openPopups ~= len then
						popup.closing = false
						table.remove(openPopups, #openPopups - len + 1)
					end
				end
			end

			local btns = #popup.buttons
			local sx = w / (btns + 1) --start x
			local len = #openPopups
			if popup.extra and popup.extra(x + 50, y + 100 + theight, w - 50 - 50, h - 50 - 80 - theight, popup) then
				close(len)
			end

			for i,v in ipairs(popup.buttons) do
				drawDebugButton(v.sprite, ox + (i - (btns + 1) / 2) * sx, y + h, nil, nil, 1, function()
					local len = #openPopups
					if v.callback and v.callback() then
						close(len)
					end
				end, true, v.sound or "menu_confirm")
			end

			--i lost my number one status
			if popup ~= openPopups[1] then
				popup.anim = 0
			end
			
			love.graphics.pop()

			--scroll bar indicator
			if enableScroll then
				local f_padding = 50
				CUI.ScrollbarFromScrollState(popup.scroll, --scroll state
					screenWidth - f_padding / 2, --x
					f_padding / 2, --y
					screenHeight - f_padding / 2 * 2, --height
					popup.scroll.contentHeight) --content height
			end
			
			if popup.closing and popup.anim <= 0 then
				table.remove(openPopups, 1)
			end
		end

		if popup.pause then
			while popup and popup.pause do
				--[[local ]]dt = love.timer and love.timer.step() or 0
				love.event.pump()
				for name, a,b,c,d,e,f,g,h in love.event.poll() do
					if name == "quit" then
						if c or not love.quit or not love.quit() then
							-- return a or 0, b
							openPopups = {}
							break
						end
					end
					love.handlers[name](a,b,c,d,e,f,g,h)
				end

				--dt = love.timer.getDelta()
				update()
				updateMouse(dt)
				love.graphics.present()
				love.timer.sleep(0.001)

				popup = openPopups[1]
			end
		else
			update()
		end
	end
end