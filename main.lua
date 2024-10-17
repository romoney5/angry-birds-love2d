--this file contains all the stuff (native functions, bonus options) that interacts with gamelogic and makes it function

io.stdout:setvbuf('no')

scriptPath = "/scripts"
audioPath = "/audio"
levelPath = "/levels"--_dec"
imagePath = "/images"
localizationPath = "/localization"

settings = {}
highscores = {}
screenWidth = love.graphics.getWidth()
screenHeight = love.graphics.getHeight()
keyPressed = {}
keyReleased = {}
keyHold = {}
keyHoldTime = {}
doubleClickTimer = 0
splashTimer = nil
assetLoadList = {}

-- clippedText = {lines={},widestLine=1}
-- g_cameraProfileList = {"iphone,ipad"}
-- loadedObjects = {}
objects = {}
blockTable = {}
starTable = {}
particleTable = {}
particles = {}
cursor = {x=0,y=0,wheel=0,wheelTriggered=false}
touches = {}
-- g_mouseOrTouchStates = {}
multitouchZoom = {zoomCoolingTime = 0}
multitouchSweep = {isSweepping = false} --minor grammar mistake
assetLoadList = {}
physicsEnabled = false

physicsWorld = nil

-- zoomLevel = 1
-- oldZoomLevel = 1

--options
deviceModel = love._os == "Android" and "android" or "windows"--"android"--"windows"
displayScale = 1
timeScale = 1
audioSpeed = 1
debugPadding = 50
-- g_registrationEnabled = true
enableHoverScaling = true
enableCursor = true
useNewFonts = false
autoScale = 0 --0 to disable, anything else as a multiplier
editorPages = 50 --amount of pages shown in the editor, default 50

fontPath = "/fonts"..(useNewFonts and "/angrybirds" or "/onomatoshark")
local drawxo = 0
local drawyo = 0
local drawxscale = 1
local drawyscale = 1
local drawangle = 0
local drawfont = ""
local audiovolume = 1
local polyverts = {}

local audios = {}
local fonts = {}
local cachedspshs = {} --spritesheets
local cachedimgs = {} --individual sprites
-- local cachedcsprs = {} --individual composprites
local cachedaudios = {}
local playingaudio = {}
--debug menu
local debugOpen = false
local debugText = ""
local debugCursorPosition = 0
local debugCursorBlink = 0
local debugPrevious = {}
local debugPreviousIndex = 1
local debugPrints = ""
--file manager
local fmOpen = false
local fmPath = nil
local fmItems = {}
local fmPrevDir = ""
res = {}

local function endswith(str,ending)
	return string.sub(str,-string.len(ending)) == ending
end

--override run function to allow drawing in the update hook
function love.run()
	if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then love.timer.step() end

	local dt = 0

	-- Main loop time.
	return function()
		-- Process events.
		if love.event then
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						return a or 0
					end
				end
				love.handlers[name](a,b,c,d,e,f)
			end
		end

		-- Update dt, as we'll be passing it to update
		if love.timer then dt = love.timer.step() end

		-- Call update and draw
		if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled

		if love.graphics and love.graphics.isActive() then
			if love.draw then love.draw() end

			love.graphics.present()
		end

		if love.timer then love.timer.sleep(0.001) end
	end
end


function love.errorhandler(msg)
	local utf8 = require("utf8")
	msg = tostring(msg)

	print((debug.traceback("Error: " .. tostring(msg), 1+(layer or 1)):gsub("\n[^\n]+$", "")))

	if not love.window or not love.graphics or not love.event then
		return
	end

	if not love.graphics.isCreated() or not love.window.isOpen() then
		local success, status = pcall(love.window.setMode, 800, 600)
		if not success or not status then
			return
		end
	end

	-- Reset state.
	if love.mouse then
		love.mouse.setVisible(true)
		love.mouse.setGrabbed(false)
		love.mouse.setRelativeMode(false)
		if love.mouse.isCursorSupported() then
			love.mouse.setCursor()
		end
	end
	if love.joystick then
		-- Stop all joystick vibrations.
		for i,v in ipairs(love.joystick.getJoysticks()) do
			v:setVibration()
		end
	end
	-- if love.audio then love.audio.stop() end

	love.graphics.reset()
	love.graphics.setBlendMode("alpha","premultiplied")
	-- local font = love.graphics.setNewFont(24)

	love.graphics.setColor(1, 1, 1)

	local trace = debug.traceback()

	love.graphics.origin()

	local sanitizedmsg = {}
	for char in msg:gmatch(utf8.charpattern) do
		table.insert(sanitizedmsg, char)
	end
	sanitizedmsg = table.concat(sanitizedmsg)

	local err = {}

	table.insert(err, sanitizedmsg)

	if #sanitizedmsg ~= #msg then
		table.insert(err, "Invalid UTF-8 string in error message.")
	end

	table.insert(err, "\n")

	for l in trace:gmatch("(.-)\n") do
		if not l:match("boot.lua") then
			l = l:gsub("stack traceback:", "Traceback\n")
			table.insert(err, l)
		end
	end

	local exited = false

	local p = table.concat(err, "\n")

	p = p:gsub("\t", "")
	p = p:gsub("%[string \"(.-)\"%]", "%1")

	setTheme("theme"..math.random(1,15))

	local function draw()
		if not love.graphics.isActive() then return end
		local pos = 70
		love.graphics.clear(love.graphics.getBackgroundColor())
		screenHeight = love.graphics.getHeight()
		local topCamera = (-2*screenHeight) / (screenHeight / (450 * currentZoomLevelMainMenu * 0.585)) + ((111 * 1.6  )/ (screenHeight / (450 * currentZoomLevelMainMenu * 0.5)))
		screen.top = topCamera
		setWorldScale((0.5 * screenHeight / 400) / (currentZoomLevelMainMenu * 0.66))
		drawBackgroundNative()
		drawForegroundNative()

		screen.left = screen.left + 1
		-- love.graphics.printf(p, pos, pos, love.graphics.getWidth() - pos)
		setRenderState(pos*2,pos*2,worldScale*.6,worldScale*.6)
		res.useFont("FONT_MENU")
		love.graphics.setColor(0, 0, 0,.2)
		res.drawString("",p,pos+(worldScale*16),pos+(worldScale*16))
		love.graphics.setColor(1, 1, 1,1)
		res.drawString("",p,pos,pos)
		love.graphics.present()
	end

	local fullErrorText = p

	return function()
		love.event.pump()

		for e, a, b, c in love.event.poll() do
			if e == "quit" then
				return 1
			elseif e == "keypressed" and a == "escape" then
				return 1
				-- love.event.quit("restart")
			elseif e == "keypressed" and a == "c" and love.keyboard.isDown("lctrl", "rctrl") then
				-- copyToClipboard()
			elseif e == "touchpressed" then
				local name = love.window.getTitle()
				if #name == 0 or name == "Untitled" then name = "Game" end
				local buttons = {"OK", "Cancel"}
				if love.system then
					buttons[3] = "Copy to clipboard"
				end
				local pressed = love.window.showMessageBox("Quit "..name.."?", "", buttons)
				if pressed == 1 then
					return 1
				elseif pressed == 3 then
					-- copyToClipboard()
				end
			end
		end

		draw()

		if love.timer then
			love.timer.sleep(0.01)
		end
	end

end

function loadLuaFileToObject(filename,currentscript,table)
	if table then
		local lua = loadstring(love.filesystem.read(filename) or "")
		if lua then
			setfenv(lua,table)
			lua()
		else
			print("Could not load Lua file: "..filename)
		end
	else
		loadstring(love.filesystem.read(filename) or "")()
	end
end


function checkDirectory(directory)
	return love.filesystem.exists(directory)
end

function createDirectory(directory)
	love.filesystem.createDirectory(directory)
end

function res.createAudio(rpath,name)
	audios[name] = rpath
end

function res.isAudioPlaying(audio)
	if audios[audio] and cachedaudios[audio] then
		-- return playingaudio[audio]==true
		return cachedaudios[audio]:isPlaying()
	end
	return false
end

function res.playAudio(audio, volume, loop, _number)
	if not audios[audio] then return end
	if cachedaudios[audio] == 0 then return end
	
	if not cachedaudios[audio] then
		if not checkDirectory(audios[audio]) then
			cachedaudios[audio] = 0
			love.window.showMessageBox("Angry Birds", "Audio "..audios[audio].." not found.")
			return
		end
		cachedaudios[audio] = love.audio.newSource(audios[audio], loop and "stream" or "static") --for long looping sounds, stream from disk rather than in memory
	end

	cachedaudios[audio]:setLooping(loop or false)
	cachedaudios[audio]:setPitch(audioSpeed)
	cachedaudios[audio]:setVolume(volume)
	love.audio.stop(cachedaudios[audio])
	love.audio.play(cachedaudios[audio])
end

function res.stopAudio(audio)
	if not cachedaudios[audio] then
		return
		-- cachedaudios[audio] = love.audio.newSource(audios[audio], "stream")
	end
	love.audio.stop(cachedaudios[audio])
end

function res.stopAllAudio()
	playingaudio = {}
	love.audio.stop()
end

function res.openURL(url)
	love.system.openURL(url)
end

function loadLocalizationFile(filePath) --load localization
	local localizationTable = {}

	-- Open the file
	-- local file = love.filesystem.lines(filePath)
	if not checkDirectory(filePath) then
		error("Localization file not found: " .. filePath)
	end

	for line in love.filesystem.lines(filePath) do
		line = line:match("^%s*(.-)%s*$")

		if line ~= "" and not line:match("^#") then
			local key, value = line:match("^(.+)%=(.+)$")

			if key and value then
				local category = "TEXTS_BASIC"
				local subkey = key
				if category and subkey then
					localizationTable[category] = localizationTable[category] or {}
					localizationTable[category][subkey] = value
				else
					error("Invalid key format in localization file: " .. key)
				end
			end
		end
	end
	localizationData = localizationTable
end
-- Load the localization file

function _G.res.getString(category, key) --return a string from localization
	if localizationData and localizationData[category] then
		return localizationData[category][key] and localizationData[category][key]:gsub("%\\0A","\n") or key
	else
		return "Category not found"
	end
end

function res.createTextGroupSet(texts)
	loadLocalizationFile("localization/english.txt")
end

function res.createAudioOutput(channels,_,samplerate)
	print("Audio output \"created\" with "..channels.." channels and "..samplerate.."Hz")
end


function requestExit()
	love.event.quit()
end

function string.insert(str1, str2, pos)
	return str1:sub(1,pos)..str2..str1:sub(pos+1)
end

function string.back(str1, pos)
	pos = pos + 1
	if pos <= 1 or pos > #str1 + 1 then
		return str1
	end
	return str1:sub(1, pos - 2)..str1:sub(pos)
end

function getDeviceID() return "00-00-00-00-00-00;00-00-00-00-00-00" end
function areDeviceIDsEqual(id1,id2) return id1==id2 end

-- love.window.updateMode(love.graphics.getWidth(), love.graphics.getHeight(), {resizable=true})
love.window.setTitle("Loading..")
-- love.window.updateMode(864, 480, {resizable=true})
love.window.setIcon(love.image.newImageData(imagePath.."/icon.png"))

function res.createBitmapFont(font)
	font = font:sub(1,-5) --originally specified with .dat format, i can't use it right now
	print("Loading font file: "..font..".xml")
	if checkDirectory(font..".xml") then
		local xml = love.filesystem.read(font..".xml")
		local chars = {}
		local leading = tonumber(xml:match('leading="(.-)"')) or 0
		local tracking = tonumber(xml:match('tracking="(.-)"')) or 0
		local spritesheet = xml:match('texture="(.-)"') or ""
		if endswith(spritesheet,".pvr") then spritesheet = spritesheet..".png" end
		spritesheet = love.graphics.newImage(fontPath.."/"..spritesheet)

		font = font:sub(string.len(fontPath)+2)
		fonts[font] = {leading = leading, tracking = tracking, spritesheet = spritesheet, chars = {}}

		for tag in xml:gmatch("<character.-/>") do
			local char = tag:match('char="(.-)"') or ""
			local x = tonumber(tag:match('x="(.-)"')) or 0
			local y = tonumber(tag:match('y="(.-)"')) or 0
			local width = tonumber(tag:match('width="(.-)"')) or 0
			local height = tonumber(tag:match('height="(.-)"')) or 0
			local pivotY = tonumber(tag:match('pivotY="(.-)"')) or 0
			
			table.insert(chars, { char = char, x = x, y = y, width = width, height = height, pivotY = pivotY })
		end

		--for each character, also construct a quad
		for _, char in ipairs(chars) do
			-- fonts[font] = {}
			-- cachedimgs[spr.name] = quad
			fonts[font].chars[char.char] = {quad = love.graphics.newQuad(char.x, char.y, char.width, char.height,spritesheet:getWidth(),spritesheet:getHeight()),
				width = char.width,height = char.height,pivoty = char.pivotY}
		end

	else
		print("Failed to load font file.")
	end
end

function res.useFont(font)
	drawfont = font
end

function res.drawString(group, text, x, y, aligny, alignx)
	text = tostring(text) or ""
	if group and group~="" then text = res.getString(group,text) end

	local font = fonts[drawfont]
	if font then
		local ax,ay = 0,0
		if alignx=="HCENTER" or aligny=="HCENTER" then ax=-res.getStringWidth(text)/2 end
		if alignx=="RIGHT" or aligny=="RIGHT" then ax=-res.getStringWidth(text) end
		if alignx=="BOTTOM" or aligny=="BOTTOM" then ay=-res.getFontLeading()/2 end
		if alignx=="TOP" or aligny=="TOP" then ay=res.getFontLeading() end
		
		local i = 0
		local line = 0
		for c in text:gmatch(".") do
			if c == "\n" then
				i = 0
				line = line + 1
			else
				local char = font.chars[string.format("%04x", string.byte(c))]
				if char then
					local charX = (x + drawxo + i + ax) * drawxscale
					local charY = (y + drawyo + ay - char.pivoty + (line * font.leading)) * drawyscale
					
					love.graphics.draw(font.spritesheet, char.quad, math.floor(charX), math.floor(charY), drawangle, drawxscale, drawyscale)
					i = i + (char.width + font.tracking) --math.floor for crisp text
				end
			end
		end
	end
end

function res.getFontLeading()
	local font = fonts[drawfont]
	if font then return font.leading end
	return 0
end

function res.getFontMaxAscending()
	local font = fonts[drawfont]
	if font then return font.leading end
	return 0
end

function res.getFontMaxDescending()
	local font = fonts[drawfont]
	if font then return -font.leading end
	return 0
end

function res.getStringWidth(text)
	text = text or ""
	local font = fonts[drawfont]
	if font then
		local i = 0
		for c in text:gmatch(".") do
			local char = font.chars[string.format("%04x", string.byte(c))]
			if char then i = i + char.width + font.tracking end
		end
		return i
	end
	return 0
	-- local font = love.graphics.getFont()
	-- return font:getWidth(text)
	-- return screenWidth*.75
end

function res.getFontHeight()
	local font = fonts[drawfont]
	if font then return font.leading end
	return 0
end

function clipText(group,text,size)
	local font = fonts[drawfont]
	if font then
		local cline = ""
		local clinewidth = 0
		local widestLine = 0
		clippedText = { lines = {}, widestLine = 0 }
		if group and group~="" then text = res.getString(group,text) end

		local function getWordWidth(word)
			local wordWidth = 0
			for c in word:gmatch(".") do
				local char = font.chars[string.format("%04x", string.byte(c))]
				if char then
					wordWidth = wordWidth + char.width + font.tracking
				end
			end
			return wordWidth - font.tracking
		end

		for word in text:gmatch("%S+%s*") do
			local newlineIndex = word:find("\n")
			if newlineIndex then
				local beforeNewline = word:sub(1, newlineIndex - 1)
				local afterNewline = word:sub(newlineIndex + 1)

				local wordWidth = getWordWidth(beforeNewline)
				if clinewidth + wordWidth > size then
					table.insert(clippedText.lines, cline)
					widestLine = math.max(widestLine, clinewidth)
					cline = beforeNewline
					clinewidth = wordWidth
				else
					cline = cline .. beforeNewline
					clinewidth = clinewidth + wordWidth
				end

				table.insert(clippedText.lines, cline)
				widestLine = math.max(widestLine, clinewidth)
				cline = ""
				clinewidth = 0

				word = afterNewline

				while word:find("\n") do
				table.insert(clippedText.lines, "")
					word = word:sub(word:find("\n") + 1)
				end
			end

			local wordWidth = getWordWidth(word)
			if clinewidth + wordWidth > size then
				table.insert(clippedText.lines, cline)
				widestLine = math.max(widestLine, clinewidth)
				cline = word
				clinewidth = wordWidth
			else
				cline = cline .. word
				clinewidth = clinewidth + wordWidth
			end
		end

		if cline ~= "" then
			table.insert(clippedText.lines, cline)
			widestLine = math.max(widestLine,clinewidth)
		end
		clippedText.widestLine = widestLine
	end
end

function makeImages()
	if love.keyboard.isDown("lctrl") then
		--load all the spritesheets
		love.graphics.print("Remaking spritesheet list..", 0, 0)
		for i,sprite in pairs(love.filesystem.getDirectoryItems(imagePath.."/img")) do
			if endswith(sprite,".png") then
				cachedspshs[sprite] = love.graphics.newImage(imagePath.."/img/"..sprite)
			elseif endswith(sprite,".xml") then
				if not sprite:find("COMPOSPRITES") then
					local spritesheet = cachedspshs[sprite:sub(1,-5)..".png"]
					if checkDirectory(imagePath.."/img/"..sprite:sub(1,-5)..".png") then--imagePath.."/img/spritesheets/"..v..".png")
						local xml = love.filesystem.read(imagePath.."/img/"..sprite)
						local sprites = {}

						for spriteTag in xml:gmatch("<sprite.-/>") do
							local name = spriteTag:match('name="(.-)"') or ""
							local x = tonumber(spriteTag:match('x="(.-)"')) or 0
							local y = tonumber(spriteTag:match('y="(.-)"')) or 0
							local width = tonumber(spriteTag:match('width="(.-)"')) or 0
							local height = tonumber(spriteTag:match('height="(.-)"')) or 0
							local pivotX = tonumber(spriteTag:match('pivotX="(.-)"')) or 0
							local pivotY = tonumber(spriteTag:match('pivotY="(.-)"')) or 0
							
							table.insert(sprites, { name = name, x = x, y = y, width = width, height = height, pivotX = pivotX, pivotY = pivotY })
						end

						--for each sprite construct a quad
						for _, spr in ipairs(sprites) do
							local quad = {love.graphics.newQuad(spr.x, spr.y, spr.width, spr.height,spritesheet:getWidth(),spritesheet:getHeight()),
								spr.width,spr.height,spritesheet,spr.pivotX,spr.pivotY,sprite:sub(1,-5)..".png"}--imagePath.."/img/"..sprite:sub(1,-5)..".png"}--, spritesheetImage:getDimensions())
							cachedimgs[spr.name] = quad
						end
					else
						print("WARNING: Spritesheet "..sprite..".png not found")
					end
				end
			end
		end
		saveLuaFileLocal("spriteinfo.lua",cachedimgs,"cachedimgs2",true)
		cachedimgs2 = cachedimgs
	else
		loadLuaFileToObject("spriteinfo.lua")
	end
end

oprint = print

function print(...)
	local prints = (... == nil and "nil") or ""
	for i,v in ipairs({...}) do
		prints = prints..tostring(v).."\t"
	end
	debugPrints = prints.."\n"..debugPrints
	oprint(prints)
end

function love.load()
	-- love.graphics.setDefaultFilter("nearest", "nearest")
	love.setDeprecationOutput(false) --love.filesystem.exists will no longer be deprecated in 12
	love.graphics.setBlendMode("alpha","premultiplied")

	releaseImages = function()end
	loadImages = function()end
	loadCompoSprites = function()end
	releaseCompoSprites = function()end
	res.createSpriteSheet = function()end
	res.createCompoSpriteSet = function()end

	if deviceModel == "android" then
		enableHoverScaling = false
		enableCursor = false
		setFullScreenMode(true)
		displayScale = 1.5
	end

	-- love.graphics.setNewFont(24)
	createStartUpAssets()
	makeImages()

	-- loveinitialized = true
end
-- local function u()update(love.timer.getDelta())end

--every frame
function love.update(dt)
	if love.window.hasFocus() then
		if love.graphics and love.graphics.isActive() then
			love.graphics.origin()
			love.graphics.clear(love.graphics.getBackgroundColor())
		end

		love.audio.setVolume(audiovolume)

		-- displayScale = math.cos((time or 0)*64)*.7 + .9
		if autoScale > 0 then
			displayScale = (0.5 * love.graphics.getHeight() / 400) / ((currentZoomLevelMainMenu or 1) * 0.66) * autoScale
			if displayScale >= .9 and displayScale <= 1.15 then displayScale = 1 end --snap to 1 for clearer images
		end
		love.graphics.scale(displayScale)
		-- if keyHold["SHIFT"] then return end

		screenWidth = math.floor(love.graphics.getWidth()/displayScale)
		screenHeight = math.floor(love.graphics.getHeight()/displayScale)
		love.window.setTitle("Angry Birds ("..screenWidth.."x"..screenHeight..")")

		cursor.x, cursor.y = love.mouse.getPosition()
		cursor.x = cursor.x / displayScale
		cursor.y = cursor.y / displayScale

		if keyHold["LBUTTON"] then
			touches[1] = {x=cursor.x,y=cursor.y} --sorry link, i can't give multitouch support.. yet
		else
			touches[1] = nil
		end

		if (keyHold["SHIFT"] and keyPressed["D"]) or (keyPressed["LBUTTON"] and cursor.x >= screenWidth-20 and cursor.y >= screenHeight-20) or (debugOpen and keyPressed["ESCAPE"]) then
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

		if keyHold["LALT"] and keyPressed["RETURN"] then
			setFullScreenMode(not isInFullScreenMode())
		end

		if not particles.addParticles then
			particles.addParticles = function(type, amount, x, y, w, h, angle)
				return --add to particles table?
			end
		end

		love.graphics.setScissor()

		if keyHold["SHIFT"] and keyPressed["F"] then --file manager
			keyPressed["F"] = nil
			fmOpen = not fmOpen
			fmPath = nil
			fmPrevDir = ""

			res.playAudio("menu_select", 1, false)
		end

		local kp,kr,kh = keyPressed,keyReleased,keyHold
		if debugOpen or fmOpen then keyPressed,keyReleased,keyHold = {},{},{} end

		dt2 = dt*timeScale*(debugOpen and 0.2 or 1)

		update(dt2,dt2)
		
		keyPressed,keyReleased,keyHold = kp,kr,kh

		if physicsEnabled then
			-- if not objects.world["c"] then
			-- 	print("making the c")
			-- 	objects.world["c"] = {name = "c", sprite = "BIRD_YELLOW", y = -200, x = 50, width = 50, height = 50, density = 1,
			-- 		friction = .5, restitution = .5, controllable = false, z_order = 1, mass = 1}
			-- 	local obj = objects.world["c"]

			-- 	obj.body = love.physics.newBody(physicsWorld, 50, -20, "dynamic")
			-- 	obj.shape = love.physics.newRectangleShape(50, 50)
			-- 	obj.fixture = love.physics.newFixture(objects.world["c"].body, objects.world["c"].shape)--, density)
			-- 	obj.body:setLinearVelocity(10,0)

			-- 	res.playAudio("special_group",1,false,0)
			-- end

			setRenderState(-screen.left - cameraShakeX, -screen.top - cameraShakeY, worldScale, worldScale, 0)
			physicsWorld:update(dt2)
			hasMovingObjects = false
			-- print(physicsWorld:getBodyCount())
			local cx,cy = cursorPhysics.x,cursorPhysics.y--screenToWorldTransform(cursor.x,cursor.y)
			-- res.drawString("","c",cx,cy)
			for i,v in pairs(objects.world) do
				local obj = objects.world[i]
				if obj.body then
					-- if not obj.controllable then
					-- 	-- obj.x = 0
					-- end
					-- if obj.name == "c" then
					-- 	-- print(obj.body:getY())
					-- 	-- obj.body:setLinearVelocity(10,0)
					-- 	res.drawString("",obj.body:getLinearVelocity(),obj.body:getX()*20,obj.body:getY()*20+50)
					-- end
					-- print(obj.body:getY())
					-- res.drawString("",tostring(obj.body:getY()),obj.body:getX()*20,obj.body:getY()*20)
					obj.x,obj.y = obj.body:getPosition()
					if obj.x < objects.limits.mix then obj.body:setX(objects.limits.mix)
					elseif obj.x > objects.limits.max then obj.body:setX(objects.limits.max) end
					if obj.y < objects.limits.miy then obj.body:setY(objects.limits.miy)
					elseif obj.y > objects.limits.may then obj.body:setY(objects.limits.may) end
					obj.x,obj.y = obj.body:getPosition()
					-- obj.body:setLinearVelocity(-10,0)
					-- obj.body:setX(10)
					-- if obj.controllable then print(obj.body:getX()) end
					obj.xVel,obj.yVel = obj.body:getLinearVelocity()
					obj.angle = obj.body:getAngle()

					if not hasMovingObjects and (math.abs(obj.xVel) >= .2 or math.abs(obj.yVel) >= .2) then hasMovingObjects = true end

					if checkObjectBounds(obj.x,obj.y,(obj.width or obj.radius)+5, (obj.height or obj.radius)+5, obj.angle,cx,cy) then
						if keyHold["RBUTTON"] then
							res.drawString("",obj.name,obj.body:getX()*20,obj.body:getY()*20+50)
							obj.body:setLinearVelocity((cx-obj.x)*4,(cy-obj.y)*4)
						end
					end
				end
			end
		end

		-- if not cursor.wheelTriggered then
			cursor.wheel = 0
		-- end

		if fmOpen then
			local fmPadding = 75
			drawBox(tutorialBoxSprites or {},"",fmPadding,fmPadding,screenWidth-fmPadding*2,screenHeight-fmPadding*2)

			res.useFont("FONT_MENU")
			res.drawString("","File Manager",screenWidth/2,fmPadding*1.25,"HCENTER")

			res.useFont("FONT_BASIC")
			-- love.graphics.setColor(0, 0, 0, .6)
			-- love.graphics.rectangle("fill", 25, 25, screenWidth-50, screenHeight-50, 16)
			-- love.graphics.setColor(1, 1, 1, 1)
			-- drawBox(page.backgroundBox.sprites, sheet, _G.math.floor(x), _G.math.floor(y), _G.math.floor(page.backgroundBox.width), _G.math.floor(page.backgroundBox.height), page.backgroundBox.hanchor, page.backgroundBox.vanchor, nil)
			if not fmPath then
				fmPath = ""
				updateFm()
			end

			res.setClipRect(fmPadding,fmPadding,screenWidth-fmPadding*2,screenHeight-fmPadding*2)
			local folder = checkAndLoadSprite("ICON_FM_FOLDER")
			local file = checkAndLoadSprite("ICON_FM_FILE")
			for i,v in pairs(fmItems)do
				-- print(i,v)
				local x = fmPadding
				local y = fmPadding+(i*res.getFontHeight())
				if checkBounds(x,y-fmPadding/3,screenWidth-fmPadding*2,res.getFontHeight(),cursor.x,cursor.y)then
					x = x + 15
					if keyPressed["LBUTTON"] then
						res.playAudio("menu_confirm", 1, false)
						if v[2].type == "directory" then
							fmPrevDir = fmPath
							fmPath = fmPath..v[1].."/"
							updateFm()
						end
						break
					end
				end

				love.graphics.draw(folder[4],	--quad
					v[2].type == "directory" and folder[1] or file[1],					--spritesheet
					x,							--x
					y-24,							--y
					drawangle,					--angle
					.25,						--x scale
					.25)						--y scale
				res.drawString("",v[1],x+144/4,y)
			end

			love.graphics.setScissor()
		end

		if debugOpen then
			updateDebug(dt)
		end
	end

	keyPressed = {}
	keyReleased = {}
	-- keyHold = {}
	for i,v in pairs(keyHoldTime) do
		if v > 0 then
			keyHoldTime[i] = v + dt
		end
	end
end

function updateFm()
	local items = love.filesystem.getDirectoryItems(fmPath)
	fmItems = {}
	for i,v in pairs(items)do
		table.insert(fmItems, {v,love.filesystem.getInfo(fmPath..v)})
	end

	table.sort(fmItems,function(a,b) local a_info,b_info = a[2],b[2]
	if a_info.type == "directory" and b_info.type ~= "directory" then --dir and not dir?
		return true
	elseif a_info.type ~= "directory" and b_info.type == "directory" then --not dir and dir?
		return false
	else --fine, sort it by name
		return a[1]:lower() < b[1]:lower()
	end end)
end

function updateDebug(dt)
	debugCursorBlink = debugCursorBlink + dt
	-- local font = love.graphics.getFont()
	
	if keyPressed["BACKSPACE"] or (keyHoldTime["BACKSPACE"]and keyHoldTime["BACKSPACE"] >= .5 and keyHoldTime["BACKSPACE"]%.04 <= dt) then
		res.playAudio("menu_back", 1, false)
		debugText = string.back(debugText,debugCursorPosition)
		debugCursorPosition = math.max(debugCursorPosition - 1, 0)
		debugCursorBlink = 0
	end
	if keyPressed["DELETE"] or (keyHoldTime["DELETE"]and keyHoldTime["DELETE"] >= .5 and keyHoldTime["DELETE"]%.04 <= dt) then
		res.playAudio("menu_back", 1, false)
		debugText = string.back(debugText,debugCursorPosition + 1)
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
					print("Error while running command: "..re)
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
	if keyPressed["LEFT"] or (keyHoldTime["LEFT"]and keyHoldTime["LEFT"] >= .5 and keyHoldTime["LEFT"]%.03 <= dt) then
		res.playAudio("menu_select", 1, false)
		debugCursorPosition = math.max(debugCursorPosition - 1, 0)
		debugCursorBlink = 0
	end
	if keyPressed["RIGHT"] or (keyHoldTime["RIGHT"]and keyHoldTime["RIGHT"] >= .5 and keyHoldTime["RIGHT"]%.03 <= dt) then
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
	res.drawString("",debugText,debugPadding,debugPadding)
	-- love.graphics.printf((debugCursorBlink%.5 <= .25 and "|" or ""), res.getStringWidth(debugText:sub(1, debugCursorPosition)) + debugPadding - 3, (debugPadding + 0.5), screenWidth)-- + (textLines * font:getHeight()), screenWidth)
	res.drawString("",(debugCursorBlink%.5 <= .25 and "|" or ""), res.getStringWidth(debugText:sub(1, debugCursorPosition)) + debugPadding, (debugPadding+3))

	-- love.graphics.printf(debugPrints, debugPadding, debugPadding * 2 + 70, screenWidth - debugPadding*2)-- + (#linesTotal * font:getHeight()), screenWidth - debugPadding * 2)
	res.drawString("",debugPrints, debugPadding, debugPadding * 2 + 70)
end

function love.textinput(key)
	-- print(key)
	if debugOpen then
		res.playAudio("menu_confirm", 1, false)
		debugText = string.insert(debugText,key,debugCursorPosition)
		debugCursorPosition = debugCursorPosition + 1
		debugCursorBlink = 0
	end
end
function love.keypressed(key)
	if key == "lshift" then key = "shift" end
	if key == "lctrl" then key = "control" end

	keyPressed[string.upper(key)] = true
	keyHoldTime[string.upper(key)] = 0.01
	keyHold[string.upper(key)] = true
end
function love.keyreleased(key, scancode)
	if key == "lshift" then key = "shift" end
	if key == "lctrl" then key = "control" end

	keyReleased[string.upper(key)] = true
	keyHoldTime[string.upper(key)] = 0
	keyHold[string.upper(key)] = false
end
function love.mousepressed(x, y, button, istouch, presses)
	if button == 1 then
		keyPressed["LBUTTON"] = true
		keyHoldTime["LBUTTON"] = 0.01
		keyHold["LBUTTON"] = true
	elseif button == 2 then
		keyPressed["RBUTTON"] = true
		keyHoldTime["RBUTTON"] = 0.01
		keyHold["RBUTTON"] = true
	elseif button == 3 then
		keyPressed["MBUTTON"] = true
		keyHoldTime["MBUTTON"] = 0.01
		keyHold["MBUTTON"] = true
	end
end
function love.mousereleased(x, y, button, istouch, presses)
	if button == 1 then
		keyReleased["LBUTTON"] = true
		keyHoldTime["LBUTTON"] = 0
		keyHold["LBUTTON"] = false
	elseif button == 2 then
		keyReleased["RBUTTON"] = true
		keyHoldTime["RBUTTON"] = 0
		keyHold["RBUTTON"] = false
	elseif button == 3 then
		keyReleased["MBUTTON"] = true
		keyHoldTime["MBUTTON"] = 0
		keyHold["MBUTTON"] = false
	end
end


function love.wheelmoved(x, y)
	cursor.wheelTriggered = true
	-- cursor.wheelTriggered = -y ~= 0
	cursor.wheel = -y

	zoomLevel = zoomLevel + y/16
end

function doesMouseClickSetsTouchCount() --probably returns if on windows
	return true
end

function setObjectParameter(object,parameter,value)
	return
end

function res.stopAudioOutput()
	return
end

function res.startAudioOutput()
	return
end

function setMusicVolume(vol)
	audiovolume = vol
end

function setEffectsVolume(vol)
	audiovolume = vol
end

function res.setTrackVolume(vol)
	audiovolume = vol
	-- love.audio.setVolume(vol)
end

function res.getTrackVolume(track)
	return love.audio.getVolume()
end

function res.setClipRect(x1,y1,x2,y2)
	love.graphics.setScissor(x1 * displayScale, y1 * displayScale, x2 * displayScale, y2 * displayScale)
end

function setEditing(isediting)
	return
end

function isPhysicsEnabled()
	return physicsEnabled
end

function setPhysicsEnabled(enabled)
	physicsEnabled = enabled
end

function requestAd()
	print("Ad requested")
end
function requestVideoAd()
	print("Video Ad requested")
end
function requestAndShowVideo()
	print("Video requested")
end

function setTheme(theme)
	currentTheme = theme
	objects.theme = theme
end

function setGameOn(on) --supposed to enable/disable screensaver
	-- print("Game mode "..(on and "on" or "off"))
	-- return
	love.window.setDisplaySleepEnabled(not on)
end

function avoidCrystalBackgroundActivity(avoid)
	return
end

function res.getSpriteBounds(string,sprite)
	sprite = checkAndLoadSprite(sprite)
	if sprite then
		return sprite[2],sprite[3]
	end
	return 0,0
end

function res.getCompoSpriteBounds(string,composprite)
	return 0,0,0,0
end

function res.getSpritePivot(sheet,sprite)
	sprite = checkAndLoadSprite(sprite)
	if sprite then
		return sprite[5],sprite[6]
	end
	return 0,0
end

function checkAndLoadSprite(sprite)
	if not cachedimgs[sprite] and sprite then
		if cachedimgs2["index_"..sprite] then
			-- print("Debug: Creating image "..sprite.." from "..cachedimgs2["index_"..sprite][7])
			local image2 = cachedimgs2["index_"..sprite]
			if not cachedspshs[image2[7]] then
				cachedspshs[image2[7]] = love.graphics.newImage(imagePath.."/img/"..image2[7])
			end
			image2[4] = cachedspshs[image2[7]]
			cachedimgs[sprite] = image2
			return image2
		else
			cachedimgs[sprite] = 0
			print("Warning: Sprite "..sprite.." not found")
			return nil
		end
	end
	if cachedimgs[sprite]==0 then return nil end
	return cachedimgs[sprite]
end

function res.drawSprite(string,sprite,x,y,vanchor,hanchor,iwidth,iheight)
	local image = checkAndLoadSprite(sprite)

	if image then
		local wm = (iwidth and iwidth/image[2] or 1)
		local hm = (iheight and iheight/image[3] or 1)

		x = (x + drawxo)
		y = (y + drawyo)
		
		local xp = image[2]/2
		local yp = image[3]/2
		local xpr = image[2]/2
		local ypr = image[3]/2
		if hanchor == "LEFT" or vanchor == "LEFT" then xp = image[5] xpr = 0 end
		if hanchor == "RIGHT" or vanchor == "RIGHT" then xp = image[2] end
		
		if vanchor == "TOP" or hanchor == "TOP" then yp = image[6] ypr = 0 end
		if vanchor == "BOTTOM" or hanchor == "BOTTOM" then yp = image[3] end

		love.graphics.draw(image[4],		--quad
			image[1],						--spritesheet
			(x-image[5] + xp)*drawxscale,	--x
			(y-image[6] + yp)*drawyscale,	--y
			drawangle,						--angle
			drawxscale*wm,					--x scale
			drawyscale*hm,					--y scale
			xpr,							--x pivot
			ypr)							--y pivot
	end
end

function res.drawCompoSprite(string,sprite,x,y,ypivot,xpivot,iwidth,iheight)
	return
end
function getBGColor(r,g,b) --not used, but i found it in ghidra
	return love.graphics.getBackgroundColor()
end
function setBGColor(r,g,b) --set the background color
	love.graphics.setBackgroundColor(r/255,g/255,b/255)
end
function setRenderState(xp,yp,xs,ys,angle)
	drawxo = xp
	drawyo = yp
	drawxscale = xs
	drawyscale = ys
	drawangle = angle or 0
end

function drawBackgroundNative()
	-- local ctheme = blockTable.themes[currentTheme]
	local theme = blockTable.themes[currentTheme]
	setBGColor(theme.color.r,theme.color.g,theme.color.b)
	for k,v in ipairs(theme.bgLayers) do
		local px, py = res.getSpritePivot("",v[2])
		local w, h = res.getSpriteBounds("",v[2])
		local s = worldScale or 1
		
		if w > 0 then
			for x = -1,math.floor(screenWidth/w/s) do
				-- local i = #theme.bgLayers - k
				local xp = w * x
				local left = (-screen.left * v[3] / v[4] - cameraShakeX) % w

				if v.v then
					left = left + time * v.v
				end
				setRenderState(xp+left, -screen.top / v[4] - cameraShakeY, s * v[4], s*v[4], 0, px, py)

				if not (x ~= 0 and v[5] == false) then
					res.drawSprite("",v[2],0,0)
				end
			end
		end
	end
end

function drawForegroundNative()
	-- local ctheme = blockTable.themes[currentTheme]
	-- res.drawSprite("",ctheme.fgLayers[1][2],0,0)
	local theme = blockTable.themes[currentTheme]
	local s = worldScale or 1
	drawRect(theme.groundColor.r/255,theme.groundColor.g/255,theme.groundColor.b/255,1,0,(-screen.top/1.5-cameraShakeY)*s*1.5,screenWidth,screenHeight)
	for k,v in ipairs(theme.fgLayers) do
		local px, py = res.getSpritePivot("",v[2])
		local w, h = res.getSpriteBounds("",v[2])
		v[3],v[4] = 1,1.5

		if w > 0 then
			for x = -1,math.floor(screenWidth/w/s) do
				-- local i = #theme.fgLayers - k
				local xp = w * x
				local left = (-screen.left * v[3] / v[4] - cameraShakeX) % w

				if v.v then
					left = left + time * v.v
				end
				setRenderState(xp+left, -screen.top / v[4] - cameraShakeY, s * v[4], s*v[4], 0, px, py)

				if not (x ~= 0 and v[5] == false) then
					res.drawSprite("",v[2],0,0)
				end
			end
		end
	end
end

function drawRect(r, g, b, a, x, y, xs, ys, _)
	local r2,y2,b2,a2 = love.graphics.getColor()
	love.graphics.setColor(r, g, b, a)
	love.graphics.rectangle("fill", x, y, xs, ys)
	love.graphics.setColor(r2,y2,b2,a2)
end

function drawLine2D(lx1,ly1,lx2,ly2,lz,r,g,b,a)
	local r2,y2,b2,a2 = love.graphics.getColor()
	love.graphics.setColor(r/255, g/255, b/255, a/255)
	love.graphics.setLineWidth(lz*drawxscale)
	-- print(x1,y1,x2,y2)
	love.graphics.line((lx1+drawxo)*drawxscale, (ly1+drawyo)*drawyscale, (lx2+drawxo)*drawxscale, (ly2+drawyo)*drawyscale)
	love.graphics.setColor(r2,y2,b2,a2)
end

--physics

function drawGameNative() --work in progress
	-- return
	if cameraTargetObject then
		local obj = cameraTargetObject
		local y,x = 0,0
		if keyHold["UP"] then y = y - 1 end
		if keyHold["DOWN"] then y = y + 1 end
		if keyHold["LEFT"] then x = x - 1 end
		if keyHold["RIGHT"] then x = x + 1 end

		if y ~= 0 or x ~= 0 then
			setVelocity(obj.name,x*20,y*20)
			setRotation(obj.name,math.atan2(obj.yVel or 0, obj.xVel or 1))
		end
	end

	for i,v in pairs(objects.world) do
		-- if v.controllable then print(v.body:getX()) end
		local x,y = physicsToWorldTransform(v.x,v.y)--v.x,v.y--worldToScreenTransform(v.x,v.y)
		-- print(x)
		-- setRenderState(0,0,0,0)
		drawangle = v.angle

		res.drawSprite("",v.sprite,x,y)--v.sprite,x,y)
		drawangle = 0
	end
	-- debugWorldDraw(physicsWorld,0,-500,screenWidth*20,screenHeight*20)
end

function setTopLeft(left,top)
	screen.left = left
	screen.top = top
end
function setWorldScale(num)
	worldScale = num
end

function setLevelLimits(minx,miny,maxx,maxy)
	objects.limits = {mix = minx, miy = miny, max = maxx, may = maxy}
end

function loadLevel(filename)
	print("Loading level: "..filename..".lua")
	if physicsWorld then physicsWorld:destroy() end --clear all the objects before continuing

	physicsWorld = love.physics.newWorld(-5*0, 20, true)
	physicsWorld:setCallbacks(nil,nil,physicsStartContact,nil)
	loadedObjects = {}
	loadLuaFileToObject(filename..".lua",this,loadedObjects)
end

function saveLevel(filename)
	print("Saving level: "..filename..".lua")
	saveLuaFile(filename,"objects")
end

function addToTrajectory(index, x, y)
	return
end

function addPuffToTrajectory(index, x, y)
	return
end
function startNewTrajectory()
	return
end

function setPhysicsSimulationScale(scale)
	love.physics.setMeter(scale*.5)
end

function physicsStartContact(obj1,obj2,contact)
	local vx1,vy1 = obj1:getBody():getLinearVelocity()
	local vx2,vy2 = obj2:getBody():getLinearVelocity()
	local veloc = (math.abs(vx1)+math.abs(vy1)-(math.abs(vx2)+math.abs(vy2)))

	if math.abs(vx1)+math.abs(vy1) < math.abs(vx2)+math.abs(vy2) then obj1,obj2 = obj2,obj1 end

	local o1,o2 = obj1:getUserData(),obj2:getUserData() --to get the angry birds world object, rather than the physics world object
	if o1.deleted or o2.deleted then return end

	-- if math.abs((math.abs(vx1)+math.abs(vy1))-(math.abs(vx2)+math.abs(vy2))) >= 5 then --math.abs
		-- print(o1.name)
		-- if o1.controllable then
		-- 	print("controllable "..o2.name)
		-- 	birdCollision(o1.name,o2.name,10,10)
		-- elseif o2.controllable then
		-- 	print("controllable "..o1.name)
		-- 	birdCollision(o2.name,o1.name,10,10)
		-- else
			if veloc >= 5 then

			end
			if o1.controllable and o1.damageFactors and o2.material then veloc = veloc * (blockTable.damageFactors[o1.damageFactors].damageMultiplier[o2.material] or 0) end

			-- if o1.strength and not o1.controllable and o1.defence and o1.defence < veloc then
			-- 	o1.strength = o1.strength - veloc + o1.defence
			-- end
				-- print(o1.name,o2.name)
			-- if o1.name == "RedBird_1" then
			-- 	res.drawString("",o1.name,o2.x*20,o2.y*20)
			-- end
			local damaged = false
			if o2.strength and not o2.controllable and o2.defence and o2.defence < veloc then
				-- contact:setEnabled(false)
				damaged = true
				o2.strength = o2.strength - veloc + o2.defence
				-- print(veloc)
				if o2.strength <= 0 then
					contact:setEnabled(false)
				end
			end

			if objects.world[o1.name].body and objects.world[o2.name].body then
				blockCollision(o1.name,o2.name,veloc/10,damaged)
			end
			removeBlocks()
		-- end
	-- end
end

function clearVertices()
	polyverts = {}
end

function addVertex(x, y)
	table.insert(polyverts,x)
	table.insert(polyverts,y)
	-- return
end

function createPolygon(name, sprite, xpos, ypos, w, h, density, friction, restitution, collision, controllable, z_order)
	objects.world[name] = {name = name, sprite = sprite, y = ypos, x = xpos, width = w, height = h or w, density = density,
		friction = friction, restitution = restitution, collision = collision, controllable = controllable or false, z_order = z_order, mass = 1, xVel = 0, yVel = 0}
	local obj = objects.world[name]

	obj.body = love.physics.newBody(physicsWorld, xpos, ypos, density == 0 and "static" or "dynamic") --dynamic is very important!!
	obj.shape = love.physics.newPolygonShape(polyverts)
	obj.fixture = love.physics.newFixture(obj.body, obj.shape, density)

	obj.fixture:setRestitution(restitution)
	obj.fixture:setFriction(friction)
	obj.fixture:setUserData(obj)
end

function createBox(name, sprite, xpos, ypos, w, h, density, friction, restitution, collision, controllable, z_order)
	-- density = density or 1
	objects.world[name] = {name = name, sprite = sprite, y = ypos, x = xpos, width = w, height = h or w, density = density,
		friction = friction, restitution = restitution, collision = collision, controllable = controllable or false, z_order = z_order, mass = 1, xVel = 0, yVel = 0}
	local obj = objects.world[name]

	obj.body = love.physics.newBody(physicsWorld, xpos, ypos, density == 0 and "static" or "dynamic") --dynamic is very important!!
	obj.shape = love.physics.newRectangleShape(w, h)
	obj.fixture = love.physics.newFixture(obj.body, obj.shape, density)

	obj.fixture:setRestitution(restitution)
	obj.fixture:setFriction(friction)
	obj.fixture:setUserData(obj)

	_,_,obj.mass,_ = obj.shape:computeMass(density)
end

function createCircle(name, sprite, xpos, ypos, w, density, friction, restitution, controllable, z_order)
	objects.world[name] = {name = name, sprite = sprite, y = ypos, x = xpos, radius = w, height = w, density = density,
		friction = friction, restitution = restitution, controllable = controllable, z_order = z_order, mass = 1, xVel = 0, yVel = 0}
	local obj = objects.world[name]

	-- if controllable then obj.density = obj.density * 100 end

	obj.body = love.physics.newBody(physicsWorld, xpos, ypos, obj.density == 0 and "static" or "dynamic")
	obj.shape = love.physics.newCircleShape(w or 1)
	obj.fixture = love.physics.newFixture(obj.body, obj.shape, obj.density)

	obj.fixture:setRestitution(restitution)
	obj.fixture:setFriction(friction)
	obj.fixture:setUserData(obj)

	obj.body:setAngularDamping(1)

	_,_,obj.mass,_ = obj.shape:computeMass(obj.density)
end

function removeObject(name)
	local obj = objects.world[name]

	obj.body:destroy()
	objects.world[name].deleted = true --boo, lazy
	-- obj.shape:release()
	-- obj.fixture:destroy()
	-- objects.world[name] = nil
end

function setRotation(object,rotation)
	objects.world[object].angle = rotation
	if objects.world[object].body then
		objects.world[object].body:setAngle(rotation)
		objects.world[object].body:setAngularVelocity(0)
	end
end

function getAngle(object)
	return objects.world[object].angle
end

function setPosition(object,x,y)
	objects.world[object].x = x
	objects.world[object].y = y
	-- if object == "RedBird_1" then print(x..time) end
	if objects.world[object].body then
		objects.world[object].body:setPosition(x,y)
		setVelocity(object,0,0)
	end
end

function setVelocity(object,x,y)
	objects.world[object].xVel = x
	objects.world[object].yVel = y
	if objects.world[object].body then
		objects.world[object].body:setLinearVelocity(x,y)
	end
end

function applyImpulse(object,x,y,xp,yp)
	local obj = objects.world[object]
	-- objects.world[object].xVel = objects.world[object].xVel + x
	-- objects.world[object].yVel = objects.world[object].yVel + y
	if obj.body then
		obj.body:applyLinearImpulse(x,y,xp,yp)--objects.world[object].width)
	end
end

function setMaterial(object,material)
	objects.world[object].material = material
end

function setTexture(object,texture)
	return
end

function setSprite(object,sprite)
	-- return
	-- print(object)
	objects.world[object].sprite = sprite
end

-- local function removeFromTable(table,name)
-- 	local tab = table
-- 	for i,v in pairs(tab)do
-- 		if i==name then table.remove(table, pos)
-- end

local function serializeTable(t, indent, noIndexes)
	local serialized = ""
	indent = indent or ""

	for key, value in pairs(t) do
		local formattedKey = tostring(key).." = "
		if noIndexes and tonumber(tostring(key)) then formattedKey = ""
		elseif noIndexes then formattedKey = "index_"..tostring(key).." = " end

		if type(value) == "table" then
			serialized = serialized .. indent .. formattedKey .. "{\n" .. serializeTable(value, indent .. "\t", noIndexes) .. indent .. "},\n"
		else
			local formattedValue = tostring(value)
			if type(value) == "string" then
				formattedValue = "\"" .. formattedValue .. "\""
			end

			if type(value) == "userdata" then
				if value:type() == "Quad" then
					local x, y, w, h = value:getViewport()
					local rw, rh = value:getTextureDimensions()
					serialized = serialized..indent..formattedKey.."love.graphics.newQuad("..x..","..y..","..w..","..h..","..rw..","..rh.."),\n"
				else--if value:type() == "Image" then
					serialized = serialized..indent..formattedKey.."nil,\n"
				end
			else
				serialized = serialized .. indent .. formattedKey .. formattedValue .. ",\n"
			end
		end
	end

	return serialized
end

function saveLuaFile(fileName, tableName, appData, noIndexes)
	local tableToSave = _G[tableName]
	
	if not tableToSave or type(tableToSave) ~= "table" then
		error("Table "..tableName.." does not exist")
	end

	local serializedData = tableName.." = {\n" .. serializeTable(tableToSave,"\t",noIndexes) .. "}"

	-- local file = io.open(fileName, "w")
	-- if not file then
	--	 error("Could not open file: " .. fileName)
	-- end

	-- file:write(serializedData)
	-- file:close()
	love.filesystem.write(fileName, serializedData)

	print("Table "..tableName.." saved to "..fileName)
end

function saveLuaFileLocal(fileName, table, tableName, noIndexes)
	if not table or type(table) ~= "table" then
		error("Table "..tableName.." does not exist")
	end

	local serializedData = tableName.." = {\n" .. serializeTable(table,"\t",noIndexes) .. "}"

	local file = io.open(fileName, "w")
	if not file then
		error("Could not open file: " .. fileName)
	end

	file:write(serializedData)
	file:close()
	print("Table "..tableName.." saved to "..fileName)
end

function checkForLuaFile(filename)
	return love.filesystem.exists(filename)
end

function openRegistrationDialog(message, validationURL, registrationURL, fullGame)
	-- local register = keyHold["R"]
	local choice = love.window.showMessageBox("Angry Birds", message.."\n\nThe game is not activated.\nRegister now?", {"Yes","No"}, "error")
	if choice == 1 then
		love.window.showMessageBox("Angry Birds", "Full game unlocked.")
		return "A"
	end
	-- love.window.showMessageBox("Angry Birds", message.."\n\nIf key R is held, then the game will be activated.")
	-- if register then
	-- 	love.window.showMessageBox("Angry Birds", "Full game unlocked.")
	-- end
	return ""
end

function logFlurryEvent(text)
	print("Logging flurry event: "..text)
end

function logFlurryEventWithParam(text,text2,text3)
	print("Logging flurry event with param: "..text..", "..text2..", "..text3)
end

function logFlurryEventWithParams(text, text2)
	print("Logging flurry event with params: "..text..", "..text2)
end

function isInFullScreenMode()
	local fs,fst = love.window.getFullscreen()
	return fs
end
function setFullScreenMode(mode)
	love.window.setFullscreen(mode)
end

function isMouseCaptured()
	return true
end

function captureMouse(bool)
	return
end

-- load global options from separate file
-- loadLuaFileToObject(scriptPath .. "/options.lua", this)--, "options")
loadLuaFileToObject(scriptPath .. "/animations.lua", this)--, "animations")
loadLuaFileToObject(scriptPath .. "/particles.lua", this, particleTable)--, "particles")
loadLuaFileToObject(scriptPath .. "/starLimits.lua", this, starTable)--, "starLimits")
loadLuaFileToObject(scriptPath .. "/blocks.lua", this, blockTable)
loadLuaFileToObject("settings.lua", this)--, settings)
loadLuaFileToObject("highscores.lua", this)--, settings)
setBGColor(255,255,255)
-- love.graphics.setDefaultFilter("nearest","linear")

--and now start the actual game
loadLuaFileToObject(scriptPath .. "/gamelogic.lua", this)--, settings)