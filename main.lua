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

objects = {}
blockTable = {}
starTable = {}
particleTable = {}


cursor = {x=0,y=0,wheel=0,wheelTriggered=false}
multitouchZoom = {zoomCoolingTime = 0}
multitouchSweep = {isSweepping = false} --minor grammar mistake
maxWorldScale = 0
physicsEnabled = false
physicsWorld = nil

textGroups = {}

-- zoomLevel = 1
-- oldZoomLevel = 1

--options
deviceModel = love._os == "Android" and "android" or "windows"
displayScale = 1
timeScale = 1
audioSpeed = 1
debugPadding = 50
--g_registrationEnabled = true
-- enableHoverScaling = true
gameOptions = {}
autoScale = 0 --0 to disable, anything else as a multiplier
gravity = {x = 0, y = 20}

local drawxo = 0
local drawyo = 0
local drawxscale = 1
local drawyscale = 1
local drawangle = 0
local drawfont = ""
local drawxp,drawyp = 0,0
local audiovolume = 1
local polyverts = {}
local hasfocus = true
local wantedZoomLevel = 0

local joystick = nil
local gpcx,gpcy,gpc = 0,0,0 --gamepad cursor x/y, gamepad cooldown

local audios = {}
fonts = {}
local cachedspshs = {} --spritesheets
cachedimgs = {} --individual sprites
local cachedcs = {} --individual composprites
local cachedaudios = {}
local pausedaudios = {} --thanks love 11
--file manager
local fmOpen = false
local fmPath = nil
local fmItems = {}
local fmPrevDir = ""

local hasLove12 = love._version_major >= 12
local drawSpriteSheetParameter = false
res = {}

local function endswith(str,ending)
	return string.sub(str,-string.len(ending)) == ending
end

--very important in later versions of the game
--pro-tip from halo: this is similar to require
function loadLuaFileToObject(filename,ctx,envKey,lenient)
	local lua = loadstring(love.filesystem.read(filename) or "")
	if lua then
		ctx = ctx or _G

	    local env = nil
	    if type(envKey) == "table" then
	        env = envKey
	    elseif type(envKey) == "string" then
	        ctx[envKey] = ctx[envKey] or {}
	        env = ctx[envKey]
	    else
	        env = ctx
	    end

	    env._G = _G
	    env.gamelua = _G
	    setfenv(lua, env)
	    -- print("loading lua:"..filename.." env:"..tostring(env).." (is _G? "..tostring(env==_G)..")".." ctx:"..tostring(ctx).." (is _G? "..tostring(ctx==_G)..")")
		lua()
	elseif not lenient then
		error("Could not load Lua file: "..filename)
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
	cachedaudios[audio]:play()
end

function res.stopAudio(audio)
	if not cachedaudios[audio] then
		return
	end
	love.audio.stop(cachedaudios[audio])
end

function res.stopAllAudio()
	-- playingaudio = {}
	love.audio.stop()
end

function res.openURL(url)
	love.system.openURL(url)
end

function checkForUpdates()
	print("Checking for updates..")
end


function res.getString(category, key) --return a string from localization
	local group = textGroups[category]
	if group and group.en_EN then
		return group.en_EN[key] and group.en_EN[key]:gsub("%\\0A","\n") or key
	else
		return "nil"
	end
end

function res.createTextGroupSet(texts)
	-- loadLocalizationFile("localization/english.txt")
	print("Loading text group.. "..texts)
	local info = getDatInfo(love.filesystem.read(texts))
	local filename = "" for i,v in texts:gmatch("([^/]+)")do filename = i end

	textGroups[filename:sub(1,#filename-4)] = info.langs
end

function res.createAudioOutput(channels,bitrate,samplerate)
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


function res.createBitmapFont(font)
	print("Loading font file: "..font)
	if checkDirectory(font) then
		local data = getDatInfo(love.filesystem.read(font))
		local spritesheet = data.filename
		if endswith(spritesheet,".pvr") then spritesheet = spritesheet..".png" end
		spritesheet = love.graphics.newImage(font:match("(.+)/[^/]+$").."/"..spritesheet)

		font = font:match("([^/]+)$")

		
		fonts[font:sub(1,-5)] = {leading = data.leading, tracking = data.tracking, spritesheet = spritesheet, chars = {}, height = data.height}

		--for each character, also construct a quad
		for _, char in pairs(data.chars) do
			fonts[font:sub(1,-5)].chars[_] = {quad = love.graphics.newQuad(char.x, char.y, char.width, char.height,spritesheet:getWidth(),spritesheet:getHeight()),
				width = char.width,height = char.height,pivoty = char.pivotY}
		end

	else
		print("Failed to load font file.")
	end
end

function res.useFont(font)
	if fonts[font] then
		drawfont = font
	end
end

function res.drawString(group, text, x, y, aligny, alignx)
	text = tostring(text) or ""
	if group and group~="" then text = res.getString(group,text) end

	local font = fonts[drawfont]
	if font then
		local ax,ay = 0,0
		if alignx=="HCENTER" or aligny=="HCENTER" then ax=-res.getStringWidth(text)/2 end
		if alignx=="RIGHT" or aligny=="RIGHT" then ax=-res.getStringWidth(text) end
		if alignx=="VCENTER" or aligny=="VCENTER" then ay=res.getFontHeight()/4 end
		if alignx=="BOTTOM" or aligny=="BOTTOM" then ay=-res.getFontHeight() end
		if alignx=="TOP" or aligny=="TOP" then ay=res.getFontHeight() end
		local i = 0
		local line = 0
		for c in text:gmatch(".") do
			if c == "\n" then
				i = 0
				line = line + 1
			else
				local char = font.chars[string.format("%04x", string.byte(c))]
				if char then
					local charX = (x + i + ax)
					local charY = (y + ay - char.pivoty + (line * font.leading))
					
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

-- function res.getStringBounds(text)
-- 	text = text or ""
-- 	local font = fonts[drawfont]
-- 	if font then
-- 		local w,h = 0,0
-- 		for c in text:gmatch(".") do
-- 			local char = font.chars[string.format("%04x", string.byte(c))]
-- 			if char then i = i + char.width + font.tracking h = math.max(char.height,h) end
-- 		end
-- 		return w,h
-- 	end
-- 	return 0,0
-- end

function res.getFontHeight()
	local font = fonts[drawfont]
	if font then return font.height end
	return 0
end

function clipText(group,text,size)
	local font = fonts[drawfont]
	clippedText = { lines = {}, widestLine = 0 }
	if font then
		local cline = ""
		local clinewidth = 0
		local widestLine = 0
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

--read 16-bit signed int in big-endian, which is what ka3d uses
local function readInt16(data, index)
	local b1, b2 = data:byte(index, index + 1)
	local unsigned = b1 * 256 + b2
	if unsigned >= 0x8000 then
		return unsigned - 0x10000
	else
		return unsigned
	end
end

--this reads a string
--crazy right?
local function readString(data, index, length)
	return data:sub(index, index + length - 1)
end

--extract data from a ka3d file, it supports sprites, fonts, localizations, and composprites at the moment
--which is basically everything
function getDatInfo(fileData)
	assert(fileData~=nil, "")

	local data = {sprites = {}}
	local pos = 1
	local function skip(length)pos = pos + length end
	--it's important that all the values are in the right place,
	--or else numbers will become huge and strings will become invalid
	assert(readString(fileData,pos,4) == "KA3D", "Wrong DAT format")
	local version = readInt16(fileData,17)

	--skip over KA3D (4), filesize (4), format (4), version (2), and more filesize (4)
	skip(4+4)
	local format = readString(fileData,pos,4)
	skip(4+2+4)
	if format == "SPRT" then --spritesheet
		--length of filename
		local filenameLength = readInt16(fileData, pos)
		data.filename = readString(fileData, pos+2, filenameLength)
		skip(filenameLength+4)

		while pos <= #fileData do
			local spritenameLength = readInt16(fileData, pos)
			skip(2)

			local spritename = readString(fileData, pos, spritenameLength)
			-- print(spritenameLength)
			data.sprites[spritename] = {}
			skip(spritenameLength)

			data.sprites[spritename].x = readInt16(fileData, pos)
			data.sprites[spritename].y = readInt16(fileData, pos + 2)
			data.sprites[spritename].width = readInt16(fileData, pos + 4)
			data.sprites[spritename].height = readInt16(fileData, pos + 6)
			skip(8)

			data.sprites[spritename].pivotX = readInt16(fileData, pos)
			data.sprites[spritename].pivotY = readInt16(fileData, pos+2)

			skip(4)

			-- print(pos,#fileData)
		end
	elseif format == "COMP" then --composprites
		data = {compos = {}}
		skip(2)
		for i=1,readInt16(fileData,pos-2),1 do --each composprite
			local csnameLength = readInt16(fileData,pos)
			local csname = readString(fileData,pos+2,csnameLength)
			data.compos[csname] = {}
			skip(csnameLength+2+2)

			for ii=1,readInt16(fileData,pos-2),1 do --each sprite
				local spritenameLength = readInt16(fileData,pos)
				local spritename = readString(fileData,pos+2,spritenameLength)
				pos = pos + spritenameLength + 2
				data.compos[csname][ii] = {x = readInt16(fileData,pos),
											y = readInt16(fileData,pos+2), n = spritename}
				skip(4)
			end
			if version == 2 then skip(2) end --odd..
		end
	elseif format == "FONT" then --font
		local function bytesToHex(data, index)
			local b1, b2 = data:byte(index, index + 1)
			return string.format("%02x%02x", b1, b2)
		end

		--length of filename
		local filenameLength = readInt16(fileData, pos)
		data.filename = readString(fileData, pos+2, filenameLength)
		skip(filenameLength+4)

		data = {filename = data.filename, chars = {}, height = 0}
		data.leading = readInt16(fileData,pos-2)
		data.tracking = readInt16(fileData,pos)
		skip(4)

		--loop through all the characters
		while pos <= #fileData do
			local char = bytesToHex(readString(fileData,pos,2),1)
			data.chars[char] = {}
			skip(2)

			data.chars[char].x = readInt16(fileData,pos)
			data.chars[char].y = readInt16(fileData,pos+2)
			data.chars[char].width = readInt16(fileData,pos+4)
			data.chars[char].height = readInt16(fileData,pos+6)
			data.chars[char].pivotY = readInt16(fileData,pos+8)
			data.height = math.max(data.chars[char].height,data.height)

			skip(10)
		end
	elseif format == "TEXT" then --localization (by far the hardest one)
		data = {langs = {}}
		local langs = {}
		local texts = {}

		--we landed on a 2nd format value
		assert(readString(fileData,pos,4)=="LDAT","Not localization data..")
		skip(4+4) --skip over format and unknown data
		--now we land on languages amount
		local languagesAmount = readInt16(fileData,pos)
		skip(2)

		for i=1,languagesAmount do
			local langLength = readInt16(fileData,pos)
			if langLength > 64 then error("Language length too long: "..langLength) end
			local lang = readString(fileData,pos+2,langLength)

			-- data.langs[lang] = {}
			langs[i] = lang
			skip(langLength+2)
		end

		assert(readString(fileData,pos,4)=="LIDS","Language IDs in localization file not found.")
		skip(4 + 4) --skip over lids, empty 2 bytes, and 1949 for some reason

		local textsAmount = readInt16(fileData,pos)
		skip(2)

		for i=1,textsAmount do
			local textLength = readInt16(fileData,pos)
			if textLength > 64 then error("Text length too long: "..textLength) end
			local text = readString(fileData,pos+2,textLength)

			table.insert(texts,i,text)
			skip(textLength+2)
		end

		for i,v in ipairs(langs)do
			-- print(readInt16(fileData,pos))
			assert(readString(fileData,pos,4)=="TXGP","TXGP in localization file not found.") --what are these cryptic names
			skip(4 + 4)
			data.langs[v] = {}

			for ii,vv in ipairs(texts) do
				local textLength = readInt16(fileData,pos)
				-- if textLength > 1024 then error("Text length a bit long: "..textLength) end
				local text = readString(fileData,pos+2,textLength)

				data.langs[v][vv] = text
				skip(textLength+2)
			end
		end
	end

	return data
end

function makeImages(force)
	local path = imagePath.."/"..(selectAssetProfile and selectAssetProfile() or "img")
	if love.keyboard.isDown("lctrl") or not checkDirectory("spriteinfo.lua") or force then
		--load all the spritesheets

	    	print("remaking spritesheets..")
		love.graphics.print("Remaking spritesheet and composprite list..", screenWidth/16, screenHeight/16)
		love.graphics.present()
		love.graphics.setBlendMode("alpha","premultiplied")
		cachedimgs = {csprites = {}}
		for i,sprite in pairs(love.filesystem.getDirectoryItems(path)) do
			if endswith(sprite,".dat") then
				local data = love.filesystem.read(path.."/"..sprite)
				local info = getDatInfo(data)
				if info.compos then
					for i,v in pairs(info.compos)do
						cachedimgs.csprites[i] = v
					end
				else
					local spritesheet = love.graphics.newImage(path.."/"..info.filename)
					for i,spr in pairs(info.sprites) do
						cachedimgs[i] = {q=love.graphics.newQuad(spr.x, spr.y, spr.width, spr.height,spritesheet:getWidth(),spritesheet:getHeight()),
							spsh=spritesheet,px=spr.pivotX,py=spr.pivotY,src=path.."/"..sprite:sub(1,-5)..".png"}--imagePath.."/img/"..sprite:sub(1,-5)..".png"}
					end
				end
			end
		end
		
		for i,v in pairs(cachedimgs.csprites)do
			local x0,x1,y0,y1 = 0,0,0,0
			
			for ii,vv in pairs(v)do
				local sprite = cachedimgs[vv.n]
				local _,_,w,h = sprite.q:getViewport()
				x0,x1 = math.min(x0,vv.x - w),math.max(x1,vv.x + w)
				y0,y1 = math.min(y0,vv.y - h),math.max(y1,vv.y + h)
			end
			v.bounds = {x=x1,x0=x0,y=y1,y0=y0}
			cachedimgs.csprites[i] = v
		end
		
		saveLuaFileLocal("spriteinfo.lua",cachedimgs,"cachedimgs2",true,"local q = love.graphics.newQuad\n")
		for i,image in pairs(cachedimgs) do
			if image.q then
				local _,_,w,h = image.q:getViewport()
				cachedimgs[i].w,cachedimgs[i].h = w,h
			end
		end
		cachedimgs2 = cachedimgs
	else
		love.graphics.setBlendMode("alpha","premultiplied")
		loadLuaFileToObject("spriteinfo.lua")
		-- local cursors = love.filesystem.read(imagePath.."/img/".."CURSORS_SHEET_1.dat")
		-- getDatInfo(cursors)
	end
end

oprint = print

function print(...)
	local prints = (... == nil and "nil") or ""
	for i,v in ipairs({...}) do
		prints = prints..tostring(v).."\t"
	end
	if debugPrints then
		debugPrints = prints.."\n"..debugPrints
	end
	oprint(prints)
end

function love.load()
	-- love.graphics.setDefaultFilter("nearest", "nearest")
	love.setDeprecationOutput(false) --love.filesystem.exists will no longer be deprecated in 12
	setBGColor(255,255,255)
	fontPath = "/fonts"--..(gameOptions.ui.useNewFonts and "/angrybirds" or "/onomatoshark")
	-- love.window.updateMode(love.graphics.getWidth(), love.graphics.getHeight(), {resizable=true})
	love.window.setTitle("Loading..")
	-- love.window.updateMode(864, 480, {resizable=true})
	if checkDirectory("icon.png") then
		love.window.setIcon(love.image.newImageData("/icon.png"))
	end

	--fixes editor's bad coding practices
	keyHold["CONTROL"] = false
	keyHold["SHIFT"] = false

	releaseImages = function()end
	loadImages = function()end
	loadCompoSprites = function()end
	releaseCompoSprites = function()end
	res.createSpriteSheet = function()end
	res.createCompoSpriteSet = function()end

	selectFontProfile = function()return "1024x768" end

	if deviceModel == "android" then
		gameOptions.ui.enableHoverScaling = false
		gameOptions.ui.enableCursor = false
		setFullScreenMode(true)
		displayScale = 1.5
	end

	-- love.graphics.setNewFont(24)
	createStartUpAssets()
	makeImages()

	gpcx,gpcy = love.mouse.getPosition()

	-- if hasLove12 then
	-- 	if love.restart then
	-- 		time = love.restart
	-- 		splashTimer = time
	-- 		print(time)
	-- 		-- updateSplashes(time,time)
	-- 	end
	-- end

	releaseBuild = false
	showEditor = true

	if arg then
		for i,v in pairs(arg) do
			if v == "--skipintro" then
				repeat
					update(1,1)
				until currentGameMode ~= updateSplashes
			end
		end
	end
	local uimos = updateItemMouseOverState
	if uimos then updateItemMouseOverState = function(item,dt) if not gameOptions.ui.enableHoverScaling then return end uimos(item,dt) end end

	-- loveinitialized = true
end
-- local function u()update(love.timer.getDelta())

local function registerGamepadKey(joystick,key,button) --bind a gamepad button to a key, run every frame
	local hold = keyHold[key]
	if button == false then keyHold[key] = nil else
	keyHold[key] = button == true and true or joystick:isGamepadDown(button) end

	if keyHold[key] and not hold then keyPressed[key] = true end
	if not keyHold[key] and hold then keyReleased[key] = true end
end

--every frame
function love.update(dt)
	-- if not gameOptions.enableAngryBirds then drawRect(0,0,0,.01,0,0,screenWidth,screenHeight) love.audio.stop() return end

	if love.window.hasFocus() then
		local joysticks = love.joystick.getJoysticks()
		joystick = joysticks[1]

		if not hasfocus then
			for i,v in pairs(pausedaudios)do
				v:play()
			end
			pausedaudios = {}
		end

		hasfocus = true
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

		if particles and not getmetatable(particles) then
			setmetatable(particles,getAddParticles)
		end

		if not joystick then
			cursor.x, cursor.y = love.mouse.getPosition()
			cursor.x = cursor.x / displayScale
			cursor.y = cursor.y / displayScale
		else --gamepad logic


			if physicsEnabled then
				if not levelCompleted and (joystick:getAxis(1) ~= 0 or joystick:getAxis(2) ~= 0) and not cameraTargetObject then
					if currentBirdName ~= nil then
						local obj = objects.world[currentBirdName]
						panToBirdCamera()
						local t_slingshotHitAreaRange = 1.2
						local distanceLimit = t_slingshotHitAreaRange/worldScale * screenWidth/480
						selectedBird = obj
					end
					registerGamepadKey(joystick,"LBUTTON",true)

					local sx,sy = physicsToWorldTransform(levelStartPosition.x,levelStartPosition.y)
					cursor.x, cursor.y = (sx-screen.left)*worldScale + (joystick:getAxis(1) * rubberBandMaximumLength()*20*worldScale),
					(sy-screen.top)*worldScale + (joystick:getAxis(2) * rubberBandMaximumLength()*20*worldScale)
					if joystick:isGamepadDown("a") then registerGamepadKey(joystick,"LBUTTON",false) end
					gpc = .01
				else
					if gpc > 0 then
						-- local sx,sy = physicsToWorldTransform(levelStartPosition.x,levelStartPosition.y)
						-- cursor.x, cursor.y = (sx-screen.left)*drawxscale + (joystick:getAxis(1) * rubberBandMaximumLength()*20*worldScale),
						-- (sy-screen.top)*drawyscale + (joystick:getAxis(2) * rubberBandMaximumLength()*20*worldScale)
						if not joystick:isGamepadDown("a") then
							gpc = gpc - dt
							if currentBirdName then
								gpc = 0
								cancelBirdDrag()
							end
						end
					else
						registerGamepadKey(joystick,"LBUTTON","a")
					end
				end

				gameOptions.ui.enableCursor = false
			else
				--move cursor
				gpcx = math.max(20,math.min(gpcx + (joystick:getAxis(3-2)*800*dt),screenWidth - 20))
				gpcy = math.max(20,math.min(gpcy + (joystick:getAxis(4-2)*800*dt),screenHeight - 20))
				if gpc <= 0 then
					registerGamepadKey(joystick,"LBUTTON","a")
					gameOptions.ui.enableCursor = true
					cursor.x = gpcx
					cursor.y = gpcy
				end
			end
			registerGamepadKey(joystick,"ESCAPE","b")
			registerGamepadKey(joystick,"R","x")
			registerGamepadKey(joystick,"RIGHT","rightshoulder")
			registerGamepadKey(joystick,"LEFT","leftshoulder")
			registerGamepadKey(joystick,"RBUTTON","rightstick")
			
			-- for k = 1,joystick:getButtonCount() do
				-- res.drawString("","Button "..k..": "..joystick:isGamepadDown(GamepadButton[k]), 10, k*30)
			-- end
			-- for i, joystick in ipairs(joysticks) do
			--	 res.drawString("",joystick:getName(), 10, i * 60)
			--	 -- res.drawString("",joystick:getAxis(1), 10, i * 60 + 50)
			-- end
		end

		-- if keyHold["LBUTTON"] then
		-- 	touches[1] = {x=cursor.x,y=cursor.y} --sorry link, i can't give multitouch support.. yet
		-- else
		-- 	touches[1] = nil
		-- end

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

		if keyHold["LALT"] and keyPressed["RETURN"] then setFullScreenMode(not isInFullScreenMode()) end

		-- if not particles.addParticles then
			-- particles.addParticles = 
		-- end

		if mainMenu and not menuItemsEdited then
			menuItemsEdited = true
			local credits = getItemByName(mainMenu.items,"credits")

			-- if hasLove12 then
				-- love.event.restart(time)
				-- credits.callFunction = function()love.event.restart(time)end
			-- end
			-- credits.callFunction = function()love.event.quit("restart")end
		end

		love.graphics.setScissor()

		-- if keyHold["SHIFT"] and keyPressed["F"] then --file manager
		-- 	keyPressed["F"] = nil
		-- 	fmOpen = not fmOpen
		-- 	fmPath = nil
		-- 	fmPrevDir = ""

		-- 	res.playAudio("menu_select", 1, false)
		-- end

		local kp,kr,kh = keyPressed,keyReleased,keyHold
		if debugOpen or fmOpen or optionsOpen then keyPressed,keyReleased,keyHold = {},{},{} end

		dt2 = dt*timeScale*((debugOpen or optionsOpen) and 0.2 or 1)

		update(dt2,dt2)

		if toremove then
			for i,v in pairs(toremove) do
				v:destroy()
			end
			toremove = nil
		end
		
		keyPressed,keyReleased,keyHold = kp,kr,kh


		if physicsEnabled then
			for k, v in _G.pairs(particles) do
				if v ~= particles.addParticles then
					local p = v
					p.time = p.time + dt
					if p.time > p.lifeTime then
						_G.table.remove(particles, k)
						particleAmount = particleAmount - 1
					else
						pt = particleTable.particles[p.type]
						p.xVel = p.xVel + pt.gravityX * dt
						p.yVel = p.yVel + pt.gravityY * dt
						p.x = p.x + p.xVel * dt
						p.y = p.y + p.yVel * dt
						p.angle = p.angle + p.angleVel * dt
						p.scale = p.scaleBegin + (p.scaleEnd - p.scaleBegin) * (p.time / p.lifeTime)
						
						if p.lifeTimeAnimation then
							index = _G.math.ceil(#pt.sprites * (p.time / p.lifeTime))
							if index < 1 then index = 1 end
							if index > #pt.sprites then index = #pt.sprites end
							p.sprite = pt.sprites[index]
							if p.oldSprite ~= p.sprite then
								p.spritePivotX, p.spritePivotY = _G.res.getSpritePivot(p.sheet, p.sprite)
								p.oldSprite = p.sprite
							end
						end
					end
				end
			end

			setRenderState(-screen.left - cameraShakeX, -screen.top - cameraShakeY, worldScale, worldScale, 0)
			physicsWorld:update(dt2)
			hasMovingObjects = false
			-- print(physicsWorld:getBodyCount())
			local cx,cy = cursorPhysics.x,cursorPhysics.y--screenToWorldTransform(cursor.x,cursor.y)
			-- res.drawString("","c",cx,cy)
			for i,v in pairs(objects.world) do
				local obj = objects.world[i]
				if obj.body then
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
					obj.angle = ((obj.body:getAngle()+math.pi)%(math.pi*2))-math.pi

					if not hasMovingObjects and (math.abs(obj.xVel) >= .2 or math.abs(obj.yVel) >= .2) then hasMovingObjects = true end

					if checkObjectBounds(obj.x,obj.y,(obj.width or obj.radius)+5, (obj.height or obj.radius)+5, obj.angle,cx,cy) then
						if keyHold["RBUTTON"] then
							res.drawString("",obj.name,obj.x*20,obj.y*20+50)
							obj.body:setLinearVelocity((cx-obj.x)*4,(cy-obj.y)*4)
						end
					end
				end
			end
		end


		zoomLevel = (zoomLevel * 16 + wantedZoomLevel) / 17
		if currentGameMode ~= updateGame and currentGameMode ~= updateEditor then wantedZoomLevel = 0 end

		if debugOpen then
			updateDebug(dt)
		end

		if optionsOpen then
			updateOptions(dt)
		end
	elseif hasfocus then
		hasfocus = false
		pausedaudios = love.audio.pause()

		gamePaused()
	end
	-- if not cursor.wheelTriggered then
		cursor.wheel = 0
	-- end

	keyPressed = {}
	keyReleased = {}
	-- keyHold = {}
	for i,v in pairs(keyHoldTime) do
		if v > 0 then
			keyHoldTime[i] = v + dt
		end
	end
end

getAddParticles = {__index = function(self,i)
	if i == "addParticles" then
		return function(type, amount, x, y, w, h, angle)
				local pt = particleTable.particles[type]
				if softLimitSimultaneousParticles < particleAmount + amount then
					amount = amount * 0.5
				end
				
				for i = 1, amount, 1 do
					if particleAmount < hardLimitSimultaneousParticles then
						particleAmount = particleAmount + 1
						local p = { }
						p.x = x + (_G.math.random(0, w) - 0.5*w ) -- * cos(angle)
						p.y = y + (_G.math.random(0, h) - 0.5*h ) -- * sin(angle)
						p.xVel = _G.math.random(pt.minVel, pt.maxVel)
						p.yVel = _G.math.random(pt.minVel, pt.maxVel)
						p.angle = _G.math.random(1, 3.14)
						p.angleVel = _G.math.random(pt.minAngleVel, pt.maxAngleVel)
						p.scaleBegin = _G.math.random(pt.minScaleBegin, pt.maxScaleBegin)
						p.scaleEnd = _G.math.random(pt.minScaleEnd, pt.maxScaleEnd)
						p.scale = p.scaleBegin
						p.type = type
						p.sprite = pt.sprites[_G.math.random(1, #pt.sprites)]
						p.sheet = pt.sheet
						p.time = 0
						p.lifeTime = pt.lifeTime
						p.lifeTimeAnimation = pt.animation == "lifeTime"

						if p.lifeTimeAnimation then
							p.sprite = pt.sprites[1]
						end
						p.oldSprite = p.sprite
						p.spritePivotX, p.spritePivotY = _G.res.getSpritePivot(p.sheet, p.sprite)

						_G.table.insert(particles, p)
					end
				end
			end
	end
end}

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
	cursor.wheelTriggered = y~=0--true
	-- cursor.wheelTriggered = -y ~= 0
	cursor.wheel = y

	if not optionsOpen then
		-- zoomLevel = zoomLevel + y/16
		wantedZoomLevel = wantedZoomLevel + y/8

		-- if zoomLevel > 1.5 then zoomLevel = 1.5 end
		if wantedZoomLevel > 1.5 then wantedZoomLevel = 1.5 end
		if wantedZoomLevel < maxWorldScale then wantedZoomLevel = maxWorldScale end
		-- if zoomLevel < -1.1 then zoomLevel = -1.1 end
	end
end

function setMaxWorldScale(s)
	maxWorldScale = s
end

function doesMouseClickSetsTouchCount() --probably returns if on windows
	return true
end

function setIsMultitouchMouseWheelSimulationEnabled()
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
	x1,y1,x2,y2 = math.max(x1,0),math.max(y1,0),math.max(x2,0),math.max(y2,0)
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

function res.getSpriteBounds(sheet,sprite)
	if not sprite then sprite = sheet end
	sprite = checkAndLoadSprite(sprite)
	if sprite then
		return sprite.w,sprite.h
	else
		-- return 150,150
	end
	return 0,0
end

function res.getCompoSpriteBounds(composprite)--string,composprite) --not used in 1.6.3.1
	-- return 0,0,150,150
end

function res.getSpritePivot(sheet,sprite)
	if not sprite then sprite = sheet end
	sprite = checkAndLoadSprite(sprite)
	if sprite then
		return sprite.px or 0,sprite.py or 0
	end
	return 0,0
end

function checkAndLoadSprite(sprite)
	if not cachedimgs[sprite] and not cachedcs[sprite] and sprite then
		if cachedimgs2[sprite] then
			-- print("Debug: Creating image "..sprite.." from "..cachedimgs2[sprite][7])
			local image = cachedimgs2[sprite]
			if not cachedspshs[image.src] then
				cachedspshs[image.src] = love.graphics.newImage(image.src)
			end
			image.spsh = cachedspshs[image.src]
			local _,_,w,h = image.q:getViewport()
			image.w,image.h = w,h
			cachedimgs[sprite] = image
			return image
		elseif cachedimgs2.csprites[sprite] then
			local image = cachedimgs2.csprites[sprite]
			local newimage = {w=image.bounds.x,px=image.bounds.x0,h=image.bounds.y,py=image.bounds.y0,sprites={}}

			for i,v in pairs(image)do
				if i ~= "bounds" then
					newimage.sprites[tonumber(i)] = v
				end
			end
			cachedcs[sprite] = newimage
			return newimage
		else
			cachedimgs[sprite] = 0
			print("Warning: Sprite "..sprite.." not found")
			return nil
		end
	end
	if cachedimgs[sprite]==0 then return nil end
	-- if not cachedimgs[sprite].w then
	-- 	local _,_,w,h = cachedimgs[sprite].q:getViewport()
	-- 	cachedimgs[sprite].w,cachedimgs[sprite].h = w,h
	-- end
	return cachedcs[sprite] or cachedimgs[sprite]
end

function res.drawSprite(sprite,x,y,vanchor,hanchor,iwidth,iheight)--string,sprite,x,y,vanchor,hanchor,iwidth,iheight)
	if sprite == g_currentCursorName and not gameOptions.ui.enableCursor then return end
	local image = checkAndLoadSprite(sprite)

	if image then
		local wm = (iwidth and iwidth/image.w or 1)
		local hm = (iheight and iheight/image.h or 1)

		local xpr,ypr = drawxp or image.px,drawyp or image.py--image[5],image[6]

		if hanchor == "LEFT" or vanchor == "LEFT" then xpr = 0 end
		if hanchor == "RIGHT" or vanchor == "RIGHT" then xpr = image.w end
		
		if vanchor == "TOP" or hanchor == "TOP" then ypr = 0 end
		if vanchor == "BOTTOM" or hanchor == "BOTTOM" then ypr = image.h end

		love.graphics.draw(image.spsh,	--quad
			image.q,		--spritesheet
			x,			--x
			y,			--y
			drawangle,		--angle
			drawxscale*wm,		--x scale
			drawyscale*hm,		--y scale
			xpr,			--x pivot
			ypr)			--y pivot
	end
end

function res.drawCompoSprite(sprite,x,y)
	local image = checkAndLoadSprite(sprite)

	if image then
		for i,v in ipairs(image.sprites)do
			res.drawSprite(v.n,math.floor(x+v.x),math.floor(y+v.y))
		end						--y pivot
	end
end
function getBGColor(r,g,b) --not used, but i found it in ghidra
	return love.graphics.getBackgroundColor()
end
function setBGColor(r,g,b) --set the background color
	love.graphics.setBackgroundColor(r/255,g/255,b/255)
end
function setRenderState(xp,yp,xs,ys,angle,xpi,ypi)
	angle = angle or 0
	love.graphics.origin()
	-- love.graphics.shear((-cursor.x/screenWidth)+.5, 0)
	love.graphics.scale(xs, ys)
	love.graphics.scale(displayScale)
	love.graphics.translate(xp, yp)
	-- love.graphics.rotate(angle)
	-- drawxo = xp
	-- drawyo = yp
	-- drawxscale = xs
	-- drawyscale = ys
	drawangle = angle or 0
	drawxp = xpi ~= 0 and xpi
	drawyp = ypi ~= 0 and ypi
end


function drawThemeLayer(k,v)
	local px, py = res.getSpritePivot("",v[2])
	local w, h = res.getSpriteBounds("",v[2])
	local s = worldScale or 1
	local ext = v[7] or {}
	local scroll = (v.v or 0) * time
	ext.color = ext.color or {1,1,1,1}
	local color = {ext.color[1]*ext.color[4],ext.color[2]*ext.color[4],ext.color[3]*ext.color[4],ext.color[4]} --for premultiply alpha
	local bcolor
	if ext.bcolor then
		bcolor = {ext.bcolor[1]*ext.bcolor[4],ext.bcolor[2]*ext.bcolor[4],ext.bcolor[3]*ext.bcolor[4],ext.bcolor[4]} --for premultiply alpha
	end
	ext.y = ext.y or 0
	
	if w > 0 then
		local cr,cg,cb,ca = love.graphics.getColor()
		love.graphics.setColor(color)
		for x = -1,math.floor(screenWidth/w/s) do
			-- local i = #theme.bgLayers - k
			local xp = w * x + (v[6] or 0)
			local left = (-screen.left * v[3] / v[4] + scroll - cameraShakeX) % w

			setRenderState(xp+left, -screen.top / v[4] - cameraShakeY, s * v[4], s*v[4], 0, px, py)

			if not (x ~= 0 and v[5] == false) then
				if drawSpriteSheetParameter then
					res.drawSprite("",v[2],0,ext.y)
				else
					res.drawSprite(v[2],0,ext.y)
				end
			end
		end
		love.graphics.setColor(cr,cg,cb,ca)
	end

	if ext.bcolor then
		setRenderState(0,-screen.top / v[4] - cameraShakeY,1,s*v[4],0,px,py)
		drawRect2(bcolor[1],bcolor[2],bcolor[3],bcolor[4],0,ext.y + (h-py-1),screenWidth,(screenHeight/s)+screen.top)
		-- extendShader:send("imageHeight",checkAndLoadSprite(v[2]).h)
		-- love.graphics.setShader(extendShader)
	end
	-- love.graphics.setShader()
end

function drawBackgroundNative()
	-- local ctheme = blockTable.themes[currentTheme]
	local theme = blockTable.themes[currentTheme]
	setBGColor(theme.color.r,theme.color.g,theme.color.b)
	for k,v in ipairs(theme.bgLayers) do
		drawThemeLayer(k,v)
	end
end

function drawForegroundNative()
	-- local ctheme = blockTable.themes[currentTheme]
	-- res.drawSprite("",ctheme.fgLayers[1][2],0,0)
	local theme = blockTable.themes[currentTheme]
	local s = worldScale or 1
	setRenderState(0,0,1,1)
	drawRect2(theme.groundColor.r/255,theme.groundColor.g/255,theme.groundColor.b/255,1,0,-screen.top*s,screenWidth,screenHeight+screen.top*s)
	for k,v in ipairs(theme.fgLayers) do
		v[3],v[4] = v[3] or 1,v[4] or 1.5
		drawThemeLayer(k,v)
	end
end

function drawRect(r, g, b, a, x, y, xs, ys, _)
	local r2,y2,b2,a2 = love.graphics.getColor()
	love.graphics.setColor(r, g, b, a)
	xs = xs - x
	ys = ys - y
	love.graphics.rectangle("fill", x, y, xs, ys)
	love.graphics.setColor(r2,y2,b2,a2)
end

function drawRect2(r, g, b, a, x, y, xs, ys)
	local r2,y2,b2,a2 = love.graphics.getColor()
	love.graphics.setColor(r, g, b, a)
	love.graphics.rectangle("fill", x, y, xs, ys)
	love.graphics.setColor(r2,y2,b2,a2)
end

function drawLine2D(lx1,ly1,lx2,ly2,lz,r,g,b,a) --unfinished
	local r2,y2,b2,a2 = love.graphics.getColor()
	love.graphics.push()
	-- love.graphics.origin()
	love.graphics.setColor(r/255, g/255, b/255, a/255)
	love.graphics.setLineWidth(lz)
	-- setRenderState(-screen.left - cameraShakeX, -screen.top - cameraShakeY, worldScale, worldScale, 0)
	-- love.graphics.scale(worldScale)
	-- love.graphics.translate(-screen.left - cameraShakeX, -screen.top - cameraShakeY)
	-- love.graphics.rotate(drawangle)
	-- print(x1,y1,x2,y2)
	love.graphics.line((lx1+drawxo), (ly1+drawyo), (lx2+drawxo), (ly2+drawyo))
	love.graphics.setColor(r2,y2,b2,a2)
	love.graphics.pop()
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

	love.graphics.push()
	-- love.graphics.origin()
	local texture = blockTable.themes[currentTheme].texture

	love.graphics.stencil(function()
		for i,v in pairs(objects.world) do
			if v.texture then drawangle = v.angle local x,y = physicsToWorldTransform(v.x,v.y) res.drawSprite(v.sprite,x,y) end
		end end, "replace", 1)
	love.graphics.setStencilTest("greater", 0)
	-- love.graphics.scale(2)
	-- drawangle = 0
	setRenderState(0,0,worldScale,worldScale)
	local w,h = res.getSpriteBounds("",texture)
	if w > 0 then
		for i=-1,(screenWidth/worldScale)/w do
			for ii=-1,(screenHeight/worldScale)/h do
				local x = (w - screen.left)%(w) + (i*w)
				local y = (h - screen.top)%(h) + (ii*h)
				res.drawSprite(texture,x,y)
			end
		end
	end
	love.graphics.setStencilTest()
	love.graphics.pop()

	for i,v in pairs(objects.world) do
		if not v.texture then
			-- if v.controllable then print(v.body:getX()) end
			local x,y = physicsToWorldTransform(v.x,v.y)--v.x,v.y--worldToScreenTransform(v.x,v.y)
			-- print(x)
			-- setRenderState(0,0,0,0)
			drawangle = v.angle--body:getAngle()
			-- res.drawSprite("",v.sprite,x,y)--v.sprite,x,y)
			res.drawSprite(v.sprite,x,y)--v.sprite,x,y)
			drawangle = 0
			-- res.drawString("",v.angle,v.x*20,v.y*20)
		end
	end

	for k, p in _G.pairs(particles) do
		if p ~= particles.addParticles then
			setRenderState(-screen.left/p.scale, -screen.top/p.scale, worldScale*p.scale, worldScale*p.scale, p.angle, p.spritePivotX, p.spritePivotY)
			_G.res.drawSprite(p.sprite, p.x/p.scale, p.y/p.scale)--p.sheet, p.sprite, p.x/p.scale, p.y/p.scale)
		end
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
	toremove = nil
	if physicsWorld then physicsWorld:destroy() end --clear all the objects before continuing

	physicsWorld = love.physics.newWorld(gravity.x, gravity.y, true)
	physicsWorld:setCallbacks(nil,nil,physicsPostSolve,nil)
	loadedObjects = {}
	loadLuaFileToObject(filename..".lua",this,loadedObjects)
end

function saveLevel(filename)
	print("Saving level: "..filename..".lua")
	saveLuaFile(filename..".lua","objects",nil,nil,true)
end

function addToTrajectory(index, x, y)
	-- return
	-- table.insert(birdTrajectory[index],{x=x,y=y})
end

function addPuffToTrajectory(index, x, y)
	-- return
	-- table.insert(birdTrajectory[index],{x=x,y=y,p=1})
end
function startNewTrajectory()
	-- return
	
end

function setPhysicsSimulationScale(scale)
	love.physics.setMeter(scale*.5)
end

function physicsPostSolve(obj1,obj2,contact) --most work in progress thing ever
	local nx,ny = contact:getNormal()
	local vx1,vy1 = obj1:getBody():getLinearVelocity()
	local vx2,vy2 = obj2:getBody():getLinearVelocity()
	-- local veloc = math.abs((math.abs(vx1)+math.abs(vy1))-(math.abs(vx2)+math.abs(vy2)))
	-- local veloc = normali*20
	local o1,o2

	if math.abs(vx1)+math.abs(vy1) < math.abs(vx2)+math.abs(vy2) then
		o1,o2 = obj2:getUserData(),obj1:getUserData()
	else
		o1,o2 = obj1:getUserData(),obj2:getUserData() --to get the physics.world object
	end
    -- if veloc > .1 then
    -- 	print(veloc,o1.name,o2.name)
    -- end
    local relVelX = vx2 - vx1
    local relVelY = vy2 - vy1
    local veloc = ((relVelX * nx) + (relVelY * ny))*.5--0

	if o1.deleted or o2.deleted then return end

	if o1.controllable and o1.damageFactors and o2.material then veloc = veloc * (blockTable.damageFactors[o1.damageFactors].damageMultiplier[o2.material] or 1) end

	
	local damaged = false

	if o2.strength and o2.defence and o2.defence < veloc then
		-- contact:setEnabled(false)
		damaged = true
		if not o2.controllable then
			o2.strength = o2.strength - veloc * (o1.defence or 1) * o1.mass
		end
		if not o1.controllable then
			o1.strength = o1.strength - veloc * (o2.defence or 1) * o2.mass
		end
		
		if o2.strength <= 0 and o1.controllable then
			contact:setEnabled(false) --make object 1 go through object 2
		end
	end
	
	if objects.world[o1.name] and objects.world[o2.name] then
		if o1.controllable then
			birdCollision(o1.name,o2.name,veloc,math.floor(veloc*o1.mass))
			if joystick and veloc >= 12 then
				joystick:setVibration(.9,.9,.1)
			end
		else
			blockCollision(o1.name,o2.name,math.floor(veloc*o1.mass),damaged)
		end
	end
	removeBlocks()
end

function clearVertices()
	polyverts = {}
end

function addVertex(x, y)
	table.insert(polyverts,x)
	table.insert(polyverts,y)
	-- return
end

function createJoint(name, end1, end2, type, coordType, x1, y1, x2, y2)
	-- objects.world[name] = {name = name, sprite = sprite, y = ypos, x = xpos, width = w, height = h or w, density = density,
	-- 	friction = friction, restitution = restitution, collision = collision, controllable = controllable or false, z_order = z_order, mass = 1, xVel = 0, yVel = 0}
	-- local obj = objects.world[name]

	-- obj.body = love.physics.newBody(physicsWorld, xpos, ypos, density == 0 and "static" or "dynamic") --dynamic is very important!!
	-- obj.shape = love.physics.newPolygonShape(polyverts)
	-- obj.fixture = love.physics.newFixture(obj.body, obj.shape, density)

	-- obj.fixture:setRestitution(restitution)
	-- obj.fixture:setFriction(friction)
	-- obj.fixture:setUserData(obj)
end

function createPolygon(name, sprite, xpos, ypos, w, h, density, friction, restitution, collision, controllable, z_order)
	objects.world[name] = {name = name, sprite = sprite, y = ypos, x = xpos, width = w, height = h or w, density = density,
		friction = friction, restitution = restitution, collision = collision, controllable = controllable or false, z_order = z_order, mass = 1, xVel = 0, yVel = 0, angle = 0}
	local obj = objects.world[name]

	obj.body = love.physics.newBody(physicsWorld, xpos, ypos, density == 0 and "static" or "dynamic") --dynamic is very important!!
	obj.shape = love.physics.newPolygonShape(polyverts)
	obj.fixture = love.physics.newFixture(obj.body, obj.shape, density)

	obj.fixture:setRestitution(restitution)
	obj.fixture:setFriction(friction)
	obj.fixture:setUserData(obj)

	_,_,obj.mass,_ = obj.shape:computeMass(density)
	obj.mass = obj.mass*100
end

function createBox(name, sprite, xpos, ypos, w, h, density, friction, restitution, collision, controllable, z_order)
	-- density = density or 1
	objects.world[name] = {name = name, sprite = sprite, y = ypos, x = xpos, width = w, height = h or w, density = density,
		friction = friction, restitution = restitution, collision = collision, controllable = controllable or false, z_order = z_order, mass = 1, xVel = 0, yVel = 0, angle = 0}
	local obj = objects.world[name]

	obj.body = love.physics.newBody(physicsWorld, xpos, ypos, density == 0 and "static" or "dynamic") --dynamic is very important!!
	obj.shape = love.physics.newRectangleShape(w, h)
	obj.fixture = love.physics.newFixture(obj.body, obj.shape, density)

	obj.fixture:setRestitution(restitution)
	obj.fixture:setFriction(friction)
	obj.fixture:setUserData(obj)

	_,_,obj.mass,_ = obj.shape:computeMass(density)
	obj.mass = obj.mass*100
end

function createCircle(name, sprite, xpos, ypos, w, density, friction, restitution, controllable, z_order)
	objects.world[name] = {name = name, sprite = sprite, y = ypos, x = xpos, radius = w, height = w, density = density,
		friction = friction, restitution = restitution, controllable = controllable, z_order = z_order, mass = 1, xVel = 0, yVel = 0, angle = 0}
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
	obj.mass = obj.mass*100
end

function removeObject(name)
	local obj = objects.world[name]
	if not toremove and obj then toremove = {obj.body} elseif obj then table.insert(toremove, obj.body) end
	--i gotta try to see what a metatable is

	-- local removedi = 0
	-- for i,v in pairs(objects.world)do
	-- 	if i == name then objs[i] = v end
	-- end
	objects.world[name] = nil
	-- for i,v in pairs(objects.world)do
	-- 	if i ~= name then objs[i] = v end
	-- end
	-- objects.world = objs
	-- objects.world[name].deleted = true --boo, lazy
	-- table.remove(objects.world, name)
	-- obj.shape:release()
	-- obj.fixture:destroy()
	-- objects.world[name] = nil
end

function setRotation(object,rotation)
	objects.world[object].angle = (rotation%(math.pi*2))
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
	if objects.world[object].body then
		objects.world[object].body:setPosition(x,y)
		setVelocity(object,0,0)
	end
end

function setSleeping(object,dozing)
	if objects.world[object].body then
		objects.world[object].body:setAwake(not dozing)
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
		obj.body:applyLinearImpulse(x/100,y/100,xp,yp)--objects.world[object].width)
	end
end

function applyForce(object,x,y,xp,yp)
	local obj = objects.world[object]
	if obj.body then
		local mass = obj.mass-- / 20
		obj.body:applyForce(x/100, y/100, xp, yp)
		-- drawfont = "FONT_BASIC"
		-- res.drawString("",y,obj.x*20,obj.y*20)
		-- res.drawString("",obj.name,obj.x*20,obj.y*20+50)
		-- print(y)
	end
end

function setAngularVelocity(object,a)
	local obj = objects.world[object]
	-- objects.world[object].xVel = objects.world[object].xVel + x
	-- objects.world[object].yVel = objects.world[object].yVel + y
	if obj.body then
		obj.body:setAngularVelocity(a)--objects.world[object].width)
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

function serializeTable(t, indent, noIndexes)
	-- table.sort(t)

	local serialized = ""
	indent = indent or ""

	for key, value in pairs(t) do
		local formattedKey = tostring(key).." = "
		if noIndexes and type(value) ~= "table" then formattedKey = key.."="
		elseif noIndexes then formattedKey = "[\""..tostring(key).."\"] = " end

		if type(value) == "table" then
			serialized = serialized .. indent .. formattedKey .. "{\n" .. serializeTable(value, indent .. "\t", noIndexes) .. indent .. "}"..(indent==""and""or",").."\n"
		else
			local formattedValue = tostring(value)
			if type(value) == "string" then
				formattedValue = "\"" .. formattedValue .. "\""
			end

			if type(value) == "userdata" then
				if value:type() == "Quad" then
					local x, y, w, h = value:getViewport()
					local rw, rh = value:getTextureDimensions()
					serialized = serialized..indent..formattedKey.."q("..x..","..y..", "..w..","..h..", "..rw..","..rh.."),\n"
				else--if value:type() == "Image" then
					-- serialized = serialized..indent..formattedKey.."nil,\n"
				end
			else
				serialized = serialized .. indent .. (tonumber(key)and "" or formattedKey) .. formattedValue .. ""..(indent==""and""or",").."\n"
			end
		end
	end

	return serialized
end

function saveLuaFile(fileName, tableName, appData, noIndexes, noWrap)
	local tableToSave = _G[tableName]
	
	if not tableToSave or type(tableToSave) ~= "table" then
		error("Table "..tableName.." does not exist")
	end

	local serializedData
	if not noWrap then
		serializedData = tableName.." = {\n" .. serializeTable(tableToSave,"\t",noIndexes) .. "}"
	else
		serializedData = serializeTable(tableToSave,"",noIndexes)
	end

	-- local file = io.open(fileName, "w")
	-- if not file then
	--	 error("Could not open file: " .. fileName)
	-- end

	-- file:write(serializedData)
	-- file:close()
	love.filesystem.write(fileName, serializedData)

	print("Table "..tableName.." saved to "..fileName)
end

function saveLuaFileLocal(fileName, table, tableName, noIndexes, prefix)
	if not table or type(table) ~= "table" then
		error("Table "..tableName.." does not exist")
	end

	local serializedData = tableName.." = {\n" .. serializeTable(table,"\t",noIndexes) .. "}"

	love.filesystem.write(fileName, (prefix or "")..serializedData)
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

function setResolution(w,h)
	screenWidth = w
	screenHeight = h
	love.window.updateMode(w, h)
end

function isMouseCaptured()
	return true
end

function captureMouse(bool)
	return
end

-- load global options from separate file
-- loadLuaFileToObject(scriptPath .. "/options.lua", this)--, "options")
loadLuaFileToObject("settings.lua", this,nil,true)--, settings)
loadLuaFileToObject("highscores.lua", this,nil,true)--, settings)
--load debug code
loadLuaFileToObject("debug.lua", this)--, settings)

--and now start the actual game
loadLuaFileToObject(scriptPath .. "/gamelogic.lua", this)--, settings)

loadLuaFileToObject(scriptPath .. "/animations.lua", this)--, "animations")
loadLuaFileToObject(scriptPath .. "/particles.lua", this, particleTable)--, "particles")
loadLuaFileToObject(scriptPath .. "/starLimits.lua", this, starTable)--, "starLimits")
loadLuaFileToObject(scriptPath .. "/blocks.lua", this, blockTable)

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


function drawLevelSelectionMenuBackground(page)
	-- draw main menu theme according to the last theme played, halloween theme is an exception see above
	animateBirds(love.timer.getDelta())
	episode4BGCranes = { startX = 64 }
	local bW, bH = _G.res.getSpriteBounds("","BUTTON_EMPTY")
	local worldScale = 0.5 * screenHeight / 320
	--if worldScale > 0.75 then
		--worldScale = 0.75
	--end
	local worldScale = (0.5 * screenHeight / 400) / (currentZoomLevelMainMenu * 0.66)
	local topCamera = (-2*screenHeight) / (screenHeight / (450 * currentZoomLevelMainMenu * 0.585)) + ((bH * 1.6  )/ (screenHeight / (450 * currentZoomLevelMainMenu * 0.5)))
	setTopLeft(50*time,topCamera )
	setWorldScale(worldScale)
	
	setTheme(currentMainMenuTheme)
	if not g_gfxLowQuality then
		drawBackgroundNative()	
	end
	-- setWorldScale(0.5)
	-- setTopLeft(50*time,-2*screenHeight + bH * 1.6 )
	-- end of main menu draw for every theme but halloween
	
	--the birds were too small, so we added those multipliers for the scaling factors, indexed by the layer numbers
	if g_birdAnimationScaleMultipliers == nil then
		g_birdAnimationScaleMultipliers = {}
		g_birdAnimationScaleMultipliers[3] = 1.5
		g_birdAnimationScaleMultipliers[4] = 1.3
		g_birdAnimationScaleMultipliers[5] = 1
	end
	
		
	-- draw birds, rewards..
		for k, v in _G.pairs(birdAnimations) do
			if v.layer == 3  then
				local scale = v.scale * g_birdAnimationScaleMultipliers[v.layer]
				setRenderState(0, 0, scale, scale, v.angle, _G.res.getSpritePivot(v.sheet, v.sprite))
				_G.res.drawSprite(v.sprite, _G.math.floor(v.x/scale), _G.math.floor(v.y/scale - screenHeight * 0.2 / scale))
			end
		end	
		
	
		for k, v in _G.pairs(birdAnimations) do
			if v.layer == 4 then
				local scale = v.scale  * g_birdAnimationScaleMultipliers[v.layer]
				setRenderState(0, 0, scale, scale, v.angle, _G.res.getSpritePivot(v.sheet, v.sprite))
				_G.res.drawSprite(v.sprite, _G.math.floor(v.x/scale), _G.math.floor(v.y/scale - screenHeight * 0.125 / scale))
			end
		end		
		
		
		for k, v in _G.pairs(birdAnimations) do
			if v.layer == 5 then
				local scale = v.scale  * g_birdAnimationScaleMultipliers[v.layer]
				setRenderState(0, 0,scale, scale, v.angle, _G.res.getSpritePivot(v.sheet, v.sprite))
				_G.res.drawSprite(v.sprite, _G.math.floor(v.x/scale), _G.math.floor(v.y/scale))
			end
		end		
		
	drawForegroundNative()				
	xs = 1
	ys = 1
	
	setRenderState(0, 0, 1, 1, 0, 0, 0)
end