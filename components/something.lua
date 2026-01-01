--something
--TODO: remove in accordance to future plans

function sgm()
	something.pgm = currentGameMode
	currentGameMode = updateSomething
end

something = {
	loaded = false,
	pgm = nil,

	starttime = 0,
	time = 0,

	path = "/",
	files = {},
	cmenu = {
		attach = nil,
		hovering = false,
		w=200,
		h=300,
		x=0,
		y=0,

		items={
			{text = "Open with..", callback = function()
				
			end},
			false,
			{text = "Rename", callback = function(f)
				showPopup(
					"Rename",
					"Rename \""..f.name.."\" to..",
					{
						{sprite = "MENU_NO", callback = function()
							return true
						end},
						{sprite = "TUTORIAL_OK", callback = function()
							return true
						end},
					},
					function(x,y,w,h,p)
						love.graphics.rectangle("fill", x, y, w, h)
					end, 20
				)
			end},
			{text = "Delete", callback = function(f)
				showPopup(f.name, "Delete \""..f.name.."\"?",
					{
						{sprite = "MENU_NO", callback = function()
							return true
						end},
						{sprite = "TUTORIAL_OK", callback = function()
							return true
						end},
					})
			end},
		}
	},

	scrollto = 0,
	scroll = 0,
}

local dance = 0

function updateSomething(dt)
	local so = something

	--on first load
	if not so.loaded then
		so.loaded = true
		currentTheme = currentTheme or "theme1"
		screen = screen or {top = 0, left = 0}

		res.createAudio("KAKAO_MAP_THEME_HQ.ogg", "somethingTheme")
	end

	--on load
	if not res.isAudioPlaying("somethingTheme") then
		res.stopAllAudio()
		res.playAudio("somethingTheme", 0.5, true)
		so.time = 0

		so.files = reloadSomething(so, so.path)
	end

	time = time or love.timer.getTime()
	cameraShakeX, cameraShakeY = 0, 0

	res.drawString("", "DT "..tostring(dt), 50, 50)
	local dance = math.abs(math.cos(so.time * (123 / 20))) * 100

	screen.top = -400
	screen.left = screen.left + dt * 120
	setWorldScale((0.5 * screenHeight / 400) / (0.66))

	drawBackgroundNative()
	drawForegroundNative()
	setRenderState(0, 0, 1, 1)

	drawRect2(0, 0, 0, .6, 0, 0, screenWidth, screenHeight)

	drawDebugText(so.path or "Files",screenWidth*.5,100, "HCENTER", "FONT_MENU")
	if currentGameMode and currentGameMode == updateSomething then
		drawDebugButton("BUTTON_ARROW_LEFT", 100, 100, 1, function()
			res.stopAudio("somethingTheme")
			currentGameMode = so.pgm
		end, true, "menu_back")
	else
		drawDebugButton("BUTTON_RESTART", 100, 100, .9, function()
			showPopup("Restart", "The game has not been properly loaded.\nRestart the game?",
				{
					{sprite = "BUTTON_RESTART", callback = function()
						love.event.quit()
					end},
					{sprite = "MENU_NO", callback = function()
						return true
					end},
					{sprite = "TUTORIAL_OK", callback = function()
						love.event.quit("restart")
					end},
				})
		end, true, "menu_back")
	end

	local w, h = screenWidth - 400,screenHeight - 300
	local x, y = screenWidth*.5 - w*.5,screenHeight*.5 - h*.5
	drawRect2(10 / 255, 10 / 255,10 / 255, .3, x + 10, y + 10, w, h, 16)
	drawRect2(24 / 255, 50 / 255,75 / 255, 1, x, y, w, h, 16)

	res.setClipRect(x, y, w, h)

	so.scrollto = so.scrollto + cursor.wheel * 48
	so.scroll = (so.scroll * 9 + so.scrollto) * .1
	local yoffset = 0 + so.scroll

	so.cmenu.hovering = so.cmenu.attach and checkBounds(so.cmenu.x, so.cmenu.y, so.cmenu.w, so.cmenu.h, cursor.x, cursor.y)
	if keyPressed.LBUTTON and not so.cmenu.hovering then
		so.cmenu.attach = nil
	end

	for i,v in pairs(so.files) do
		local fx, fy = 250, 230 + yoffset
		local selected = not so.cmenu.hovering and (fy >= y and fy <= y + h) and checkBounds(x, fy - 12, w, 36, cursor.x, cursor.y)
		if selected then
			fx = fx + 10

			if keyPressed.LBUTTON then
				res.playAudio("menu_confirm",1)
				if v.info.type == "directory" then
					so.path = resolvePath(so.path..v.name).."/"
					if so.path == "//" then so.path = "/" end
					so.files = reloadSomething(so, so.path)
				--else
					
				end
				break
			elseif keyPressed.RBUTTON then
				res.playAudio("menu_select", 1)
				so.cmenu.attach = v
				so.cmenu.x, so.cmenu.y = cursor.x, cursor.y
			end
		end

		if v.info.type == "directory" then
			drawFolder(fx,fy)
		else
			drawFile(fx,fy)
		end
		
		if selected then
			drawRect2(.2, .2, .2, .2, x, fy - 12, w, 36)
		end

		drawDebugText(v.name, fx + 30, fy, "LEFT", "FONT_BASIC")
		yoffset = yoffset + 36
	end
	so.scrollto = math.max(so.scrollto, -(yoffset - so.scroll) + h - 72)
	so.scrollto = math.min(so.scrollto, 0)

	love.graphics.setScissor()

	if so.cmenu.attach then
		local attach = so.cmenu.attach
		drawRect2(.2, .2, .2, .2, so.cmenu.x + 8, so.cmenu.y + 8, so.cmenu.w, so.cmenu.h, 5)
		drawRect2(.9, .9, .9, 1, so.cmenu.x, so.cmenu.y, so.cmenu.w, so.cmenu.h, 5)

		local itemy = 0
		for i,v in pairs(so.cmenu.items) do
			if v then
				local ix, iy = so.cmenu.x + 16, itemy + so.cmenu.y
				local selected = so.cmenu.hovering and checkBounds(0, iy + 16, screenWidth, 36, cursor.x, cursor.y)
				if selected then
					ix = ix + 12
					drawRect2(1, 1, 1, 1, so.cmenu.x, iy + 16, so.cmenu.w, 36, 5)
					if keyHold.LBUTTON then
						ix = ix - 12
					end

					if keyReleased.LBUTTON then
						res.playAudio("menu_confirm", 1)
						v.callback(attach)
						so.cmenu.attach = nil
					end
				end

				res.drawString("", v.text, ix, iy, "TOP")
				itemy = itemy + 18
			end
			itemy = itemy + 18
		end
	end
	
	res.drawSprite("SOUNDBOARD_2_BIRD", screenWidth - 100, dance + screenHeight - 200)
	res.drawSprite(g_currentCursorName, cursor.x, cursor.y)

	so.time = so.time + dt
end

function reloadSomething(so,path)
	local items = love.filesystem.getDirectoryItems(path)
	files = {}
	if path ~= "/" then
		table.insert(files, {name = "..", info = {type = "directory"}})
	end

	for i,v in pairs(items) do
		local info = love.filesystem.getInfo(path..v)
		-- if info.type == "symlink" then info.type = "directory" end
		table.insert(files, {name = v, info = info})
	end

	table.sort(files, function(a,b) local a_info, b_info = a.info, b.info
	if a_info.type == "directory" and b_info.type ~= "directory" then --dir and not dir?
		return true
	elseif a_info.type ~= "directory" and b_info.type == "directory" then --not dir and dir?
		return false
	else --fine, sort it by name
		return a.name:lower() < b.name:lower()
	end end)

	return files
end

function drawFolder(x,y)
	local w, h = 30, 20
	love.graphics.rectangle("fill", x - w/2, y - h/2 + 10, w, h, 5)
	love.graphics.rectangle("fill", x - w/2, y - h/2 + 6, w * .4, h * .6, 5, 2)
end

function drawFile(x,y)
	local w, h = 20, 30
	love.graphics.rectangle("fill", x - w/2, y - h/2 + 5, w, h, 3)
	love.graphics.setColor(24 / 255, 50 / 255, 75 / 255, 1)
	-- love.graphics.polygon("fill", x+3,y-6,x+3,y+h/3,x+w*.4,y+h/3)
	love.graphics.rectangle("fill", x, y - 10, 15, 10)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setLineWidth(1)
	love.graphics.line(x, y - 9, x + 9, y + 1)
end

function checkBounds(left, top, w, h, cursorX, cursorY)
	return cursorX >= left and cursorX < left + w and cursorY >= top and cursorY < top + h
end