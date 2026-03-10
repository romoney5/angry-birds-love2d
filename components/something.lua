--something

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
		w = 0,
		h = 0,
		x = 0,
		y = 0,
		anim = 0,

		items = {
			{text = "Open with..", callback = function()
				openPopup("Something", "Not implemented.")
			end},
			{text = "Run File", callback = function(f)
				local path = f.path
				local ogDatapath = datapath
				local openedDatapath = openedDatapath
				local success = setDataPathFromFile(path)

				if not success then
					openPopup(f.name, "Could not find a valid data path in \""..f.name.."\".", nil)
					datapath = ogDatapath
					return
				end

				if openedDatapath then
					love.event.restart({runfilePath = path})
					datapath = ogDatapath
					return
				end

				--go!
				res.stopAudio("somethingTheme")
				currentGameMode = something.pgm
				loadGameFiles()
			end},
			{text = "Run File params", callback = function(f)
				local states = {}
				openPopup(
					"Run File with Params",
					"Choose extra parameters to launch \""..f.name.."\"...",
					{
						{sprite = "MENU_NO", callback = function()
							return true
						end},
						{sprite = "TUTORIAL_OK", callback = function()
							local path = f.path
							local ogDatapath = datapath
							local openedDatapath = openedDatapath
							local success = setDataPathFromFile(path)

							if not success then
								openPopup(f.name, "Could not find a valid data path in \""..f.name.."\".", nil)
								datapath = ogDatapath
								return true
							end

							if openedDatapath then
								love.event.restart{runfilePath = path, arg = states}
								datapath = ogDatapath
								return true
							end

							--go!
							res.stopAudio("somethingTheme")
							currentGameMode = something.pgm
							processArgsTable{arg = states}
							loadGameFiles()
							return true
						end},
					}, false,
					function(x,y,w,h,p)
						local totaly = 0
						for i, v in ipairs(arguments) do
							if v.type == "bool" then
								states[i] = states[i] or {}
								CUI.Checkbox(states[i], x, totaly + y, 50, 50, v.display)
								totaly = totaly + 60
							elseif v.type == "string" then
								states[i] = states[i] or {}
								states[i].placeholder = v.display
								CUI.Textbox(states[i], x, totaly + y, w, 30, v.display)
								totaly = totaly + 40
							elseif v.type == "number" then
								states[i] = states[i] or {}
								states[i].placeholder = v.display
								states[i].numeric = true
								CUI.Textbox(states[i], x, totaly + y, w, 30, v.display)
								totaly = totaly + 40
							else
								error("something: unknown type for game argument" + v.type)
							end
						end
						
						p.h = p.h + totaly * .75
								--CUI.Textbox(textboxState, x, y, w, 30, "Device Model")
					end, 20
				)
			end},
			false,
			{text = "Rename", callback = function(f)
				local textboxState = {}
				textboxState.value = f.name
				
				openPopup(
					"Rename",
					"Rename \""..f.name.."\" to...",
					{
						{sprite = "MENU_NO", callback = function()
							return true
						end},
						{sprite = "TUTORIAL_OK", callback = function()
							local name = textboxState.value
							local realDir = love.filesystem.getRealDirectory(f.path)
							
							if not realDir then
								openPopup(f.name, "Could not rename to \""..textboxState.value.."\":\ndoes not exist.\nChoose a different name.")
								return
							end
							
							local success, failure = os.rename(realDir.."/"..f.path, realDir.."/"..f.folder..name)
							if not success then
								openPopup(f.name, "Could not rename to \""..textboxState.value.."\":\n"..tostring(failure)..".\nChoose a different name.")
								return
							end
							
							return true
						end},
					}, false,
					function(x,y,w,h,p)
						--love.graphics.rectangle("fill", x, y, w, h) --text field?
						CUI.Textbox(textboxState, x, y, w, 30)
					end, 20
				)
			end},
			{text = "Delete", callback = function(f)
				openPopup(f.name, "Permanently delete \""..f.name.."\"?",
					{
						{sprite = "MENU_NO", callback = function()
							return true
						end},
						{sprite = "TUTORIAL_OK", callback = function()
							if not love.filesystem.getRealDirectory(f.path) then
								openPopup(f.name, "Could not delete \""..f.name.."\":\ndoes not exist.")
								return true
							end
							
							--inspired by https://love2d.org/wiki/love.filesystem.remove
							local function del(path)
								if love.filesystem.getInfo(path, "directory") then
									for i, file in ipairs(love.filesystem.getDirectoryItems(path)) do
										del(path.."/"..file)
										love.filesystem.remove(path.."/"..file)
									end
								end
								
								return love.filesystem.remove(path)
							end
							
							local success = del(f.path)
							if not success then
								openPopup(f.name, "Could not delete \""..f.name.."\".\nThe file could be in the base directory.")
								return true
							end
							
							return true
						end},
					}
				)
			end},
			false,
			{text = "New file", callback = function(f)
				local textboxState = {}
				
				openPopup(
					"New File",
					"Create file in the save directory...",
					{
						{sprite = "MENU_NO", callback = function()
							return true
						end},
						{sprite = "TUTORIAL_OK", callback = function()
							local name = textboxState.value
							
							local success, failure = love.filesystem.write(f.folder..name, "")
							if not success then
								openPopup(f.name, "Could not create file \""..textboxState.value.."\":\n"..tostring(failure)..".\nChoose a different name.")
								return
							end
							
							return true
						end},
					}, false,
					function(x,y,w,h,p)
						--love.graphics.rectangle("fill", x, y, w, h) --text field?
						CUI.Textbox(textboxState, x, y, w, 30)
					end, 20
				)
			end},
		}
	},

	scrollto = 0,
	scroll = 0,
}

local dance = 0

function updateSomething(dt, cx, cy)
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

	-- res.drawString("", "DT "..tostring(dt), 50, 50)
	local dance = math.abs(math.cos(so.time * (123 / 20))) * 100

	screen.top = -400
	screen.left = screen.left + dt * 120
	setWorldScale((0.5 * screenHeight / 400) / (0.66))

	drawBackgroundNative()
	drawForegroundNative()
	setRenderState(0, 0, 1, 1)

	drawRect2(0, 0, 0, .6, 0, 0, screenWidth, screenHeight)

	local padding = math.min(200, math.min(screenWidth, screenHeight) / 4)
	local w, h = screenWidth - padding,screenHeight - padding
	local x, y = screenWidth*.5 - w*.5,screenHeight*.5 - h*.5
	drawRect2(10 / 255, 10 / 255, 10 / 255, .3, x + 10, y + 10, w, h, 16)
	drawRect2(24 / 255, 50 / 255, 75 / 255, 1, x, y, w, h, 16)

	res.setClipRect(x, y, w, h)

	--touch scrolling
	if (keyHold.LBUTTON or keyReleased.LBUTTON) and not keyPressed.LBUTTON then --try not to snap the cursor on touchscreens
		so.scrollto = so.scrollto + (cursor.y - cy) * 1.2
		so.curscroll = so.curscroll or 0
		so.curscroll = so.curscroll + (cursor.y - cy)
		so.highscroll = so.highscroll or 0
		so.highscroll = math.max(so.highscroll, math.abs(so.curscroll))
	else
		so.curscroll = nil
		so.highscroll = nil
	end

	so.scrollto = so.scrollto + cursor.wheel * 48
	so.scroll = ease.linear(dt * 16, so.scroll, so.scrollto)
	local yoffset = 0 + so.scroll

	so.cmenu.hovering = so.cmenu.attach and checkBounds(so.cmenu.x, so.cmenu.y, so.cmenu.w, so.cmenu.h, cursor.x, cursor.y)

	for i, v in pairs(so.files) do
		local fx, fy = 200, 190 + yoffset

		--drawing a lot of text can lag
		if fy + 36 >= y and fy - 12 < y + h then
			local selected = not so.cmenu.hovering and not so.cmenu.attach and (fy >= y and fy <= y + h) and checkBounds(x, fy - 12, w, 36, cursor.x, cursor.y)
			selected = selected and not (so.highscroll and so.highscroll >= 10) and not debugOpen and not openPopups[1]
			if selected then
				--fx = fx + 10

				if keyReleased.LBUTTON then
					res.playAudio("menu_confirm",1)
					if v.info.type == "directory" or v.info.type == "up" then
						so.path = (resolvePath(so.path..v.name).."/"):sub(2)
						so.files = reloadSomething(so, so.path)
						so.scrollto = 0
						so.scroll = 60
					--else
						
					end
					--break
				elseif keyReleased.RBUTTON then
					res.playAudio("menu_select", 1)
					so.cmenu.attach = v
					so.cmenu.x, so.cmenu.y = cursor.x + 1, cursor.y + 1 --nudge by 1 pixel to make clicking out easier
				end
			end
			
			if v.info.type == "directory" or v.info.type == "up" then
				drawFolder(fx,fy)
			else
				drawFile(fx,fy)
			end
			
			if selected then
				if keyHold.LBUTTON then
					drawRect2(.1, .1, .1, .1, x, fy - 12, w, 36)
				else
					drawRect2(.2, .2, .2, .2, x, fy - 12, w, 36)
				end
			end

			drawDebugText(v.name, fx + 30, fy, "LEFT", "FONT_BASIC")
		end
		
		yoffset = yoffset + 36
	end

	local maxscroll = -(yoffset - so.scroll) + h - 190
	so.scrollto = math.max(so.scrollto, maxscroll)
	so.scrollto = math.min(so.scrollto, 0)

	--scroll bar indicator
	local f_padding = 50
	CUI.Scrollbar(
		screenWidth - padding / 2 - f_padding / 2,
		padding / 2 + f_padding / 2,
		10,
		screenHeight - padding / 2 * 2 - f_padding / 2 * 2,
		so.scroll,
		maxscroll,
		yoffset - so.scroll)

	love.graphics.setScissor()
	
	if keyReleased.LBUTTON and not so.cmenu.hovering then
		so.cmenu.attach = nil
	end

	if so.cmenu.attach or so.cmenu.anim > 0 then
		local attach = so.cmenu.attach
		local width, height = 0, 0
		
		so.cmenu.anim = math.min(math.max(so.cmenu.anim + (attach and dt or -dt * 2), 0), 1 / 4)
		
		for i, v in ipairs(so.cmenu.items) do
			if v then
				width = math.max(width, res.getStringWidth(v.text) + 16 + 16)
				height = height + 18
			end
			height = height + 18
		end
		
		height = height + 16 + 16
		
		so.cmenu.w, so.cmenu.h = width, height
		
		love.graphics.push()
		love.graphics.translate(so.cmenu.x, so.cmenu.y)
		love.graphics.scale(ease.outCubic(so.cmenu.anim / (1 / 4), .7, 1))
		love.graphics.translate(-so.cmenu.x, -so.cmenu.y)
		
		drawRect2(10 / 255, 10 / 255, 10 / 255, 10 / 255, so.cmenu.x + 8, so.cmenu.y + 8, width, height, 5)
		drawRect2(48 / 255, 60 / 255, 75 / 255, 1, so.cmenu.x, so.cmenu.y, width, height, 5)

		local itemy = 0
		for i, v in ipairs(so.cmenu.items) do
			if v then
				local ix, iy = so.cmenu.x + 16, itemy + so.cmenu.y + 16
				local selected = so.cmenu.hovering and checkBounds(0, iy, screenWidth, 36, cursor.x, cursor.y) and attach ~= nil
				if selected then
					--ix = ix + 12
					if keyHold.LBUTTON then
						drawRect2(60 / 255 / 2, 80 / 255 / 2, 100 / 255 / 2, 1 / 2, so.cmenu.x, iy, width, 36, 5)
					else
						drawRect2(60 / 255, 80 / 255, 100 / 255, 1, so.cmenu.x, iy, width, 36, 5)
					end
					
					if keyHold.LBUTTON then
						--ix = ix - 12
					end

					if keyReleased.LBUTTON then
						res.playAudio("menu_confirm", 1)
						v.callback(attach)
						so.cmenu.attach = nil
					end
				end

				drawDebugText(v.text, ix, iy + 10)
				itemy = itemy + 18
			end
			itemy = itemy + 18
		end
		
		love.graphics.pop()
	end

	drawDebugText(so.path or "Files", screenWidth * .5, math.min(padding / 2, 100), "HCENTER", "FONT_MENU", w)
	if currentGameMode and currentGameMode == updateSomething then
		drawDebugButton("BUTTON_ARROW_LEFT", padding / 3, padding / 3, nil, nil, 1, function()
			res.stopAudio("somethingTheme")
			currentGameMode = so.pgm
		end, true, "menu_back")
	else
		drawDebugButton("BUTTON_RESTART", padding / 3, padding / 3, nil, nil, .9, function()
			openPopup("Restart", "The game has not been properly loaded.\nRestart the game?",
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
	
	res.drawSprite("SOUNDBOARD_2_BIRD", screenWidth - 100, dance + screenHeight - 200)
	res.drawSprite(g_currentCursorName, cursor.x, cursor.y)

	so.time = so.time + dt
end

function reloadSomething(so,path)
	local items = love.filesystem.getDirectoryItems(path)
	files = {}
	if path ~= "/" then
		table.insert(files, {name = "..", info = {type = "up"}})
	end

	for i,v in pairs(items) do
		local info = love.filesystem.getInfo(path..v)
		-- if info.type == "symlink" then info.type = "directory" end
		local outpath = path
		if outpath:sub(1, 1) == "/" then outpath = outpath:sub(2) end
		
		table.insert(files, {name = v, info = info, path = outpath..v, folder = outpath})
	end

	table.sort(files, function(a,b) --TODO: sorting table
		local a_info, b_info = a.info, b.info
		if a_info.type == "up" and b_info.type ~= "up" then --..
			return true
		elseif a_info.type ~= "up" and b_info.type == "up" then --..
			return false
		elseif a_info.type == "directory" and b_info.type ~= "directory" then --dir and not dir?
			return true
		elseif a_info.type ~= "directory" and b_info.type == "directory" then --not dir and dir?
			return false
		else --fine, sort it by name
			return a.name:lower() < b.name:lower()
		end
	end)

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