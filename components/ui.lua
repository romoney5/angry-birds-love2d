--some ui components used in more recent menus

--console ui
CUI = {}

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

function drawDebugButton(sprite, x, y, w, h, scale, call, enabled, sound)
	local image = checkSprite(sprite)
	
	love.graphics.push()
	
	local w,h = image and image.width or w or 100, image and image.height or h or 100

	local s = 1
	if enabled and checkBounds(x - w/2, y - h/2, w * scale, h * scale, cursor.x, cursor.y)then
		if keyHold["LBUTTON"] then
			s = .9
		elseif (gameOptions.ui and gameOptions.ui.enableHoverScaling) or not gameOptions.ui then
			s = 1.1
		end

		if keyReleased["LBUTTON"] then
			res.playAudio(sound or "menu_confirm", 1, false)
			call()
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
			love.graphics.circle("line", 0, 0, w/2)
			if sprite == "TUTORIAL_OK" then
				love.graphics.line(-40, 0, -15, 25, 35, -25)
			elseif sprite == "MENU_NO" then
				love.graphics.line(-25, -25, 25, 25)
				love.graphics.line(25, -25, -25, 25)
			elseif sprite == "BUTTON_ARROW_LEFT" then
				love.graphics.line(10, 25, -15, 0, 10, -25)
			end
		else
			res.drawSprite(sprite, 0, 0)
		end
	else
		love.graphics.rectangle("line", -w / 2, -h / 2, w, h, 20)
	end
	
	love.graphics.pop()
end

function drawDebugText(text,x,y, align, font)
	align = align or "LEFT"
	res.useFont(font)
	love.graphics.setColor(0, 0, 0, .2)
	res.drawString("", text, x + 8, y + 8, align, "VCENTER")
	love.graphics.setColor(1, 1, 1, 1)
	res.drawString("", text, x, y, align, "VCENTER")
end