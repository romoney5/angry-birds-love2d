--something

function sgm()
	something.on = true
end

local function close()
	something.on = false
end

local android = love._os == "Android"

local options = {}
local function optionsMenu(f)
	local buttons = {
		{label = "Customization (beta)", callback = function(self)
			return options.customization(f)
		end},
	}
	
	openPopup(
		"Options",
		"Notice: Any options here do not currently save.",
		{
			{icon = "cross", callback = function()
				return true
			end},
		},
		false,
		function(x, y, w, h, p)
			local opened
			
			local total_height = 0
			
			for i, button in ipairs(buttons) do
				opened = opened or CUI.Button(button, x + w / 2, y + 50 + (i - 1) * 90, w, 75)
				
				total_height = i * 90
			end
			
			p.h = total_height - 100
			
			return opened
		end
	)
end

function options.customization(f)
	local colorselectState = {}
	colorselectState.value = {red = CUI.AccentColor_BG[1],
		green = CUI.AccentColor_BG[2], blue = CUI.AccentColor_BG[3]}
	
	local textboxState2 = {}
	textboxState2.placeholder = "Destination"
	
	openPopup(
		"Customization (beta)",
		"Select your accent color.",
		{
			{icon = "check", callback = function()
				return true
			end},
		}, false,
		function(x,y,w,h,p)
			CUI.ColorSelect(colorselectState, x, y, 150, 150)
			--CUI.Textbox(textboxState2, x, y + 40, w, 30)
			--CUI.Checkbox(checkboxState, x, y + 80, 50, 50, "Writeable")
			
			CUI.AccentColor_BG[1], CUI.AccentColor_BG[2], CUI.AccentColor_BG[3] =
				colorselectState.value.red, colorselectState.value.green, colorselectState.value.blue
			
			p.h = 128
		end, 20
	)
end

something = {
	loaded = false,
	pgm = nil,
	
	on = false,

	starttime = 0,
	time = 0,

	path = "/",
	files = {},
	
	code = {
		on = false,
	},
	
	cmenu = {
		attach = nil,
		hovering = false,
		w = 0,
		h = 0,
		x = 0,
		y = 0,
		anim = 0,

		items = {
			{text = "Open with...", callback = function(f)
				local code_button = {label = "Code Editor", callback = function(self)
					something.code.on = true
					
					something.code.data = love.filesystem.read(f.path) or ""
					something.code.textboxState = nil
					
					return true
				end}
				
				openPopup(
					"Open With",
					"Open \""..f.name.."\" with...",
					{
						{icon = "cross", callback = function()
							return true
						end},
					},
					false,
					function(x, y, w, h, p)
						local opened
						
						opened = opened or CUI.Button(code_button, x + 150 / 2, y + 100 / 2 + 25, 150, 100)
						
						return opened
					end
				)
			end},
			{text = "Run File", callback = function(f)
				local path = f.path
				local success, reason = findDataPathFromFile(path)

				if not success then
					openPopup(f.name, reason, nil)
					return
				end

				local ogDatapath = datapath
				local openedDatapath = openedDatapath
				local success = setDataPathFromFile(path)

				if not success then
					openPopup(f.name, "Could not open \""..f.name.."\".", nil)
					datapath = ogDatapath
					return
				end

				if openedDatapath then
					love.event.restart({runfilePath = path})
					datapath = ogDatapath
					return
				end

				--go!
				close()
				loadGameFiles()
			end},
			{text = "Run File Params", callback = function(f)
				local path = f.path
				local success, reason = findDataPathFromFile(path)

				if not success then
					openPopup(f.name, reason, nil)
					return
				end

				local states = {}
				openPopup(
					"Run File with Params",
					"Choose extra parameters to launch \""..f.name.."\"...",
					{
						{icon = "cross", callback = function()
							return true
						end},
						{icon = "check", callback = function()
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
							close()
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
					f.name,
					"Rename \""..f.name.."\" to...",
					{
						{icon = "cross", callback = function()
							return true
						end},
						{icon = "check", callback = function()
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
						{icon = "cross", callback = function()
							return true
						end},
						{icon = "check", callback = function()
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
			{text = "New...", callback = function(f)
				local textboxState = {}
				local state2 = {value = false}
				
				openPopup(
					"New File",
					"Create file in the save directory...",
					{
						{icon = "cross", callback = function()
							return true
						end},
						{icon = "check", callback = function()
							local name = textboxState.value
							
							local success, failure
							if state2.value then --folder
								success, failure = love.filesystem.createDirectory(f.folder..name)
							else --file
								success, failure = love.filesystem.write(f.folder..name, "")
							end
							
							if not success then
								openPopup("New File", "Could not create file \""..textboxState.value.."\":\n"..tostring(failure)..".\nChoose a different name.")
								return
							end
							
							--auto-scroll to the file you just made
							something.files = something:reload(something.path)
							
							local yoffset = 0
							for i, file in ipairs(something.files) do --distinguish files/folders?
								local fx, fy = 200, -yoffset
								
								if file.name == name then
									something.scrollto = fy
									break
								end
								
								yoffset = yoffset + 36
							end
							
							return true
						end},
					}, false,
					function(x,y,w,h,p)
						CUI.Textbox(textboxState, x, y, w, 30)
						CUI.Checkbox(state2, x, y + 40, 50, 50, "Folder")
					end, 20
				)
			end},
			{text = "Mount...", callback = function(f)
				if not love.filesystem.mountFullPath then
					openPopup("Mount", "love.filesystem.mountFullPath does not exist.\nPlease make sure you are using at least LÖVE 12.0.", nil)
					return
				end

				local textboxState = {}
				textboxState.placeholder = "Target"
				local textboxState2 = {}
				textboxState2.placeholder = "Destination"
				--local checkboxState = {}
				--checkboxState.value = true --i might have deleted some of my c drive using this
				
				openPopup(
					"Mount",
					"Mount a path as a temporary folder...",
					{
						{icon = "cross", callback = function()
							return true
						end},
						{icon = "check", callback = function()
							local name = textboxState.value
							local dest = textboxState2.value
							
							local success = love.filesystem.mountFullPath(name, dest, --[[checkboxState.value and "readwrite" or]] "read")
							
							if not success then
								openPopup("Mount", "Could not mount file \""..name.."\".\nChoose a different name.")
								return
							end
							
							--auto-scroll to the file you just made
							something.files = something:reload(something.path)
							
							local yoffset = 0
							for i, file in ipairs(something.files) do --distinguish files/folders?
								local fx, fy = 200, -yoffset
								
								if file.name == dest then
									something.scrollto = fy
									break
								end
								
								yoffset = yoffset + 36
							end
							
							return true
						end},
					}, false,
					function(x,y,w,h,p)
						CUI.Textbox(textboxState, x, y, w, 30)
						CUI.Textbox(textboxState2, x, y + 40, w, 30)
						--CUI.Checkbox(checkboxState, x, y + 80, 50, 50, "Writeable")
					end, 20
				)
			end},
			false,
			{text = "Options", callback = optionsMenu},
		}
	},

	--scrollto = 0,
	--scroll = 0,
	scroll = {},
}

local function updateCode()
	local so = something
	
	local screenWidth, screenHeight = gamelua.screenWidth, gamelua.screenHeight

	local padding = math.min(200, math.min(screenWidth, screenHeight) / 4)
	local w, h = screenWidth - padding, screenHeight - padding
	local x, y = screenWidth*.5 - w*.5, screenHeight*.5 - h*.5
	drawRect2(10 / 255, 10 / 255, 10 / 255, .3, x + 10, y + 10, w, h, 16)
	drawRect2(CUI.AccentColor_BG[1], CUI.AccentColor_BG[2], CUI.AccentColor_BG[3], 1, x, y, w, h, 16)
	
	local innerPadding = 60
	
	local code = so.code
	code.textboxState = code.textboxState or {}
	code.textboxState.value = code.textboxState.value or code.data or ""
	code.textboxState.multiline = true
	code.textboxState.font = mono_font_small
	
	CUI.Textbox(code.textboxState, x + innerPadding, y + innerPadding, w - innerPadding * 2, h - innerPadding * 2)
	
	code.back_button = code.back_button or {icon = "left", callback = function(self)
		openPopup("Code", "Save changes?",
			{
				{icon = "left", callback = function()
					return true
				end},
				{icon = "cross", callback = function()
					code.on = false
					return true
				end},
				{icon = "check", callback = function()
					code.on = false
					return true
				end},
			})
	end}
	
	local radius = 100 / 2
	CUI.Button(code.back_button, math.max(padding / 3, radius), math.max(padding / 3, radius), radius * 2, radius * 2)
	
	if keyReleased.F5 then
		openPopup("Code", "Run file?",
			{
				{icon = "cross", callback = function()
					return true
				end},
				{icon = "check", callback = function()
					local success, ret = pcall(loadstring(code.textboxState.value))
					
					if not success then
						openPopup("Code", "Error running file:\n"..tostring(ret))
					end
					
					return true
				end},
			})
	end
end

--draw basic file/folder icons
local function drawFolder(x, y)
	local w, h = 30, 20
	love.graphics.rectangle("fill", x - w/2, y - h/2 + 10, w, h, 5)
	love.graphics.rectangle("fill", x - w/2, y - h/2 + 6, w * .4, h * .6, 5, 2)
end

local function drawFile(x, y)
	local w, h = 20, 30
	love.graphics.rectangle("fill", x - w/2, y - h/2 + 5, w, h, 3)
	love.graphics.setColor(CUI.AccentColor_BG[1], CUI.AccentColor_BG[2], CUI.AccentColor_BG[3], 1)
	-- love.graphics.polygon("fill", x+3,y-6,x+3,y+h/3,x+w*.4,y+h/3)
	love.graphics.rectangle("fill", x, y - 10, 15, 10)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setLineWidth(1)
	love.graphics.line(x, y - 9, x + 9, y + 1)
end

local https

function openDownloadPopup(url, callback)
	openPopup("Downloader", "Download file\n\""..url.."\"\nfrom the internet?",
	{
		{icon = "cross", callback = function()
			return true
		end},
			https = https or require("https")
		{icon = "check", callback = function()
			
			local code, body = https.request(url)
			
			if not body then
				openPopup("Downloader", "Failed to download file. Try again later.")
				
				return true
			end
			
			print(("Downloaded file (%d bytes)"):format(body:len()))
			
			callback(code, body)
			
			return true
		end},
	})
end

--add a link to download libcrypto.so on android for ease of use (wip)
if mobileDevice then
	table.insert(something.cmenu.items,
		false
	)
	
	table.insert(something.cmenu.items,
		{text = "Download libcrypto...", callback = function(f)
			local path = "downloaded_libs/libcrypto.so"
			
			if love.filesystem.exists(path) then
				openPopup("Download libcrypto", "You already have this file.", nil)
				return
			end
			
			openDownloadPopup("https://github.com/christian-mv/android-and-linux-openssl-binaries/raw/refs/heads/master/android/openssl-1.1.1c/arm64/libcrypto.so",
				function(code, body)
					love.filesystem.createDirectory("downloaded_libs")
					love.filesystem.write(path, body)
				end
			)
		end}
	)
end


function something:update(dt)
	res.useFont(nil)

	--on first load
	if not self.loaded then
		self.loaded = true

		if android and love.filesystem.mountFullPath then
			--TODO: should this be writeable?
			local success = love.filesystem.mountFullPath("/storage/emulated/0", "sdcard", "readwrite")
			
			if not success then
				openPopup("Notice", "Couldn't mount /storage/emulated/0 for reading/writing.\nMake sure the \"all files access\" permission is enabled for the app.")
			end
		end

		self.files = self:reload(self.path)
	end
	
	local screenWidth, screenHeight = gamelua.screenWidth, gamelua.screenHeight

	time = time or love.timer.getTime()

	renderLeft = renderLeft + dt * 120

	gamelua.drawBackgroundNative()
	gamelua.drawForegroundNative()
	gamelua.setRenderState(0, 0, 1, 1)

	drawRect2(CUI.AccentColor_BG[1], CUI.AccentColor_BG[2], CUI.AccentColor_BG[3], .6, 0, 0, screenWidth, screenHeight)
	
	if self.code.on then
		updateCode()
		return
	end

	local padding = math.min(200, math.min(screenWidth, screenHeight) / 4)
	local w, h = screenWidth - padding,screenHeight - padding
	local x, y = screenWidth*.5 - w*.5,screenHeight*.5 - h*.5
	drawRect2(CUI.AccentColor_BG[1], CUI.AccentColor_BG[2], CUI.AccentColor_BG[3], 1, x, y, w, h, 16)

	res.setClipRect(x, y, w, h)

	--touch scrolling
	self.scroll.height = h
	local scroll, disable = CUI.HandleScroll(self.scroll, dt)
	local yoffset = 0 + scroll

	self.cmenu.hovering = self.cmenu.attach and checkBounds(self.cmenu.x, self.cmenu.y, self.cmenu.w, self.cmenu.h, cursor.x, cursor.y)

	--draw all files
	for i, v in ipairs(self.files) do
		local fx, fy = x + 60, y + 60 + yoffset

		--drawing a lot of text can lag
		if fy + 36 >= y and fy - 12 < y + h then
			local selected = not self.cmenu.hovering and not self.cmenu.attach and (fy >= y and fy <= y + h) and checkBounds(x, fy - 12, w, 36, cursor.x, cursor.y)
			selected = selected and not disable and not debugOpen and not openPopups[1]
			if selected then
				--fx = fx + 10
				
				v.presstime = v.presstime or 0
				if keyReleased.RBUTTON or v.presstime >= .35 then
					res.playAudio("menu_select", 1)
					v.presstime = 0
					self.cmenu.attach = v
					self.cmenu.noClose = keyHold.LBUTTON
					self.cmenu.x, self.cmenu.y = cursor.x + 5, cursor.y + 5 --nudge by a couple pixels to make clicking out easier
				elseif keyHold.LBUTTON then
					v.presstime = v.presstime + dt
				else
					v.presstime = 0
					if keyReleased.LBUTTON then
						res.playAudio("menu_confirm",1)
						if v.info.type == "directory" or v.info.type == "up" then
							self.path = (resolvePath(self.path..v.name).."/"):sub(2)
							self.files = self:reload(self.path)
							
							self.scroll.overscroll = .5 / 2
							self.scroll.scroll = 60 * 4
							self.scroll.overscrollPosition = self.scroll.scroll
							self.scroll.overscrollDest = 0
							--[[self.scrollto = 0
							self.scroll = 60]]
						--else
							
						end
						--break
					end
				end
			end
			
			if v.info.type == "directory" or v.info.type == "up" then
				drawFolder(fx, fy)
			else
				drawFile(fx, fy)
			end
			
			if selected then
				local padding = 10
				if keyHold.LBUTTON then
					drawRect2(1, 1, 1, .1, x + padding, fy - 12, w - padding * 2, 36, 5)
				else
					drawRect2(1, 1, 1, .2, x + padding, fy - 12, w - padding * 2, 36, 5)
				end
			end

			drawDebugText(v.name, fx + 30, fy - 12, "LEFT", nil)
		end
		
		yoffset = yoffset + 36
	end

	self.scroll.contentHeight = yoffset - scroll
	--print(so.scroll.height, so.scroll.contentHeight)

	--scroll bar indicator
	local f_padding = 50
	CUI.ScrollbarFromScrollState(self.scroll, --scroll state
		screenWidth - padding / 2 - f_padding / 2, --x
		padding / 2 + f_padding / 2, --y
		screenHeight - padding / 2 * 2 - f_padding / 2 * 2, --height
		yoffset - scroll) --content height

	love.graphics.setScissor()
	
	if keyReleased.LBUTTON and not self.cmenu.hovering then
		if not self.cmenu.noClose then
			self.cmenu.attach = nil
		end
		
		self.cmenu.noClose = nil
	end

	if self.cmenu.attach or self.cmenu.anim > 0 then
		local attach = self.cmenu.attach
		local width, height = 0, 0
		
		self.cmenu.anim = math.min(math.max(self.cmenu.anim + (attach and dt or -dt * 2), 0), 1 / 4)
		
		for i, v in ipairs(self.cmenu.items) do
			if v then
				width = math.max(width, res.getStringWidth(v.text) + 16 + 16)
				height = height + 18
			end
			height = height + 18
		end
		
		height = height + 16 + 16
		
		local scale = ease.outCubic(self.cmenu.anim / (1 / 4), .7, 1)
		self.cmenu.w, self.cmenu.h = width, height
		self.cmenu.x = math.min(self.cmenu.x, screenWidth - width * scale)
		self.cmenu.y = math.min(self.cmenu.y, screenHeight - height * scale)
		
		love.graphics.push()
		love.graphics.translate(self.cmenu.x, self.cmenu.y)
		love.graphics.scale(scale)
		love.graphics.translate(-self.cmenu.x, -self.cmenu.y)
		
		local red, green, blue = table.unpack(CUI.AccentColor_BG)
		drawRect2(red * .8, green * .8, blue * .8, 1, self.cmenu.x, self.cmenu.y, width, height, 5)

		local itemy = 0
		for i, v in ipairs(self.cmenu.items) do
			if v then
				local ix, iy = self.cmenu.x + 16, itemy + self.cmenu.y + 16
				local selected = self.cmenu.hovering and checkBounds(0, iy, screenWidth, 36, cursor.x, cursor.y) and attach ~= nil
				if selected then
					--ix = ix + 12
					local padding = 5
					if keyHold.LBUTTON then
						drawRect2(1, 1, 1, .1, self.cmenu.x + padding, iy, width - padding * 2, 36, 5)
					else
						drawRect2(1, 1, 1, .2, self.cmenu.x + padding, iy, width - padding * 2, 36, 5)
					end
					
					if keyHold.LBUTTON then
						--ix = ix - 12
					end

					if keyReleased.LBUTTON then
						res.playAudio("menu_confirm", 1)
						v.callback(attach)
						self.cmenu.attach = nil
					end
				end

				drawDebugText(v.text, ix, iy)
				itemy = itemy + 18
			end
			itemy = itemy + 18
		end
		
		love.graphics.pop()
	end

	--draw the title
	love.graphics.push()
	love.graphics.translate(screenWidth * .5, math.min(padding / 2, 100))
	love.graphics.scale(1.25)
	drawDebugText(self.path or "Files", 0, 0, "HCENTER", nil, w)
	love.graphics.pop()
	
	self.back_button = self.back_button or {icon = "left", callback = function(_self)
		self.on = false
	end}
	
	local radius = 100 / 2
	CUI.Button(self.back_button, math.max(padding / 3, radius), math.max(padding / 3, radius), radius * 2, radius * 2)

	local dance = math.abs(math.cos(self.time * (123 / 20))) * 100
	
	res.drawSprite("SOUNDBOARD_2_BIRD", screenWidth - 100, dance + screenHeight - 200)
	res.drawSprite(g_currentCursorName, cursor.x, cursor.y)

	self.time = self.time + dt
end

function something:reload(path)
	local items = love.filesystem.getDirectoryItems(path)
	local files = {}
	
	if path ~= "/" then
		table.insert(files, {name = "..", info = {type = "up"}, folder = path})
	end

	for i,v in ipairs(items) do
		local info = love.filesystem.getInfo(path..v)
		-- if info.type == "symlink" then info.type = "directory" end
		local outpath = path
		if outpath:sub(1, 1) == "/" then outpath = outpath:sub(2) end
		
		if info then
			table.insert(files, {name = v, info = info, path = outpath..v, folder = outpath})
		end
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

function checkBounds(left, top, w, h, cursorX, cursorY)
	return cursorX >= left and cursorX < left + w and cursorY >= top and cursorY < top + h
end
