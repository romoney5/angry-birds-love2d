--some ui components used in more recent menus

function drawDebugButton(sprite,x,y,scale,call,enabled,sound)
	local image = checkAndLoadSprite(sprite)
	if not image then image = {width = 100, height = 100} end
	
	love.graphics.push()
	
	local w,h = image.width * scale, image.height * scale
	local s = 1
	if enabled and checkBounds(x - w/2, y - h/2, w, h, cursor.x, cursor.y)then
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

	if sprite == "TUTORIAL_OK" and not image.px then
		love.graphics.circle("line", 0, 0, w/2)
		love.graphics.line(-40, 0, -15, 25, 35, -25)
	elseif sprite == "MENU_NO" and not image.px then
		love.graphics.circle("line", 0, 0, w/2)
		love.graphics.line(-25, -25, 25, 25)
		love.graphics.line(25, -25, -25, 25)
	else
		res.drawSprite(sprite, 0, 0)
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