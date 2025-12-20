--this file is basically ka3d

io.stdout:setvbuf('no')

dataPath = "/data"
scriptPath = "/scripts"
commonScriptPath = "/scripts_common"
audioPath = "/audio"
levelPath = "/levels"
imagePath = "/images"
localizationPath = "/localization"
fontPath = "/fonts"

compsPath = "/components"

settings = {}
highscores = {}
screenWidth = love.graphics.getWidth()
screenHeight = love.graphics.getHeight()
keyPressed = {}
keyReleased = {}
keyHold = {}

nuked = {} --nuked

objects = {}
blockTable = {}
starTable = {}
particleTable = {}

touches = {}
touchcount = 0

cursor = {x = 0, y = 0, wheel = 0, wheelTriggered = false, dx = 0, dy = 0}
multitouchZoom = {zoomCoolingTime = 0}
multitouchSweep = {isSweepping = false}
maxWorldScale = 0
physicsEnabled = false
physicsWorld = nil

textGroups = {}

trajectory = {{{}, {}, {}}}
alpha = 1
drawangle = 0
drawfont = ""
audiovolume = 1

currentPopup = {}

cachedspshs = {} --spritesheets
cachedcs = {} --individual composprites
cachedimgs = {} --individual sprites
cachedaudios = {}
audios = {}
fonts = {}
flurry = {}

dmonitor = nil

enableDebug = false

local hasLove12 = love._version_major >= 12

function endsWith(str,ending)
	return string.sub(str, -string.len(ending)) == ending
end

--load either plain text lua or a precompiled chunk with fione
function makeChunk(src)
	if not src then
		print("makeChunk: src is nil")
		return
	end
	if src:sub(1, 4) == "\27Lua" then --it's bytecode!
		return pcall(loadbytecode, src)
	else --that's just plain old lua.. boring..
		return pcall(loadstring, src)
	end
end

--very important in later codebases
function loadLuaFileToObject(filename, ctx, envKey, lenient)
	local lua, e
	filename = resolvePath(dataPath.."/"..filename)
	print(filename)
	_, lua, e = makeChunk(love.filesystem.read(filename))
	
	print(lua)

	if lua and _ then
		ctx = ctx or _G

		local env = nil
		if type(envKey) == "table" then
			env = envKey
		elseif type(envKey) == "string" and envKey ~= "" then
			ctx[envKey] = {}
			env = ctx[envKey]
		else
			env = ctx
		end
		
		--emulate scope behavior
		setmetatable(env, {
			__index = function(self, k)
				if k == "_G" or k == "gamelua" then
					return _G
				elseif k == "this" then
					return env
				end
			end,
			__newindex = function(self, k, v)
				if k ~= "filename" then
					rawset(self, k, v)
				end
			end
		})

	    setfenv(lua, env)
		lua()
	elseif not lenient then
		-- local _,r = pcall(loadstring(love.filesystem.read(filename)))
		-- print()
		if checkDirectory(filename) then
			error("Could not load Lua file: "..filename.."\n"..tostring(e))
		else
			showPopup("Warning",
					"Could not load Lua file: "..filename.."\n"..tostring(e),
					{
						{sprite = "TUTORIAL_OK", callback = function()
							return true
						end},
					}
				) currentPopup.important = true
		end
	else
		return tostring(e)
	end
end

--also used in some versions
function loadLuaFile(filename,envKey,lenient)
	local _, lua, e
	filename = resolvePath(dataPath.."/"..filename)
	_, lua, e = makeChunk(love.filesystem.read(filename))

	if lua then
		setfenv(lua, _G[envKey] or _G)
		return lua()
	elseif not lenient then
		-- error("Could not load Lua file: "..filename)
		if not checkDirectory(filename) then
			e = "File does not exist."
		end
		print("Could not load Lua file: "..filename.." - "..tostring(e))
	end
end

function runLuaFile(filename,lenient)
	local lua,e
	filename = resolvePath(filename)
	lua,e = love.filesystem.load(filename)

	if lua then
		return lua()
	elseif not lenient then
		-- error("Could not load Lua file: "..filename)
		if not checkDirectory(filename)then e = "File does not exist." end
		print("Could not load Lua file: "..filename.." - "..tostring(e))
	end
end

--also used in some versions
function requireFile(filename)
	if not loadLuaFile(scriptPath.."/"..filename, nil, true) then loadLuaFile(commonScriptPath.."/"..filename) end
end

function resolvePath(path)
	local resolved = {}
	for part in path:gmatch("[^/]+") do
		if part == ".." then
			table.remove(resolved)
		elseif part ~= "." and part ~= "" then
			table.insert(resolved, part)
		end
	end
	return "/"..table.concat(resolved, "/")
end


function checkDirectory(directory)
	return love.filesystem.exists(directory)
end

function createDirectory(directory)
	love.filesystem.createDirectory(directory)
end

function requestExit()
	print("Quitting...")
	love.event.quit()
end

function string.insert(str1, str2, pos)
	return str1:sub(1, pos)..str2..str1:sub(pos + 1)
end

function string.back(str1, pos)
	pos = pos + 1
	if pos <= 1 or pos > #str1 + 1 then
		return str1
	end
	return str1:sub(1, pos - 2)..str1:sub(pos)
end

function getDeviceID()
	return "00-00-00-00-00-00;00-00-00-00-00-00"
end
function areDeviceIDsEqual(id1, id2)
	return id1 == id2
end


local orig_print = print

function print(...)
	local prints = (... == nil and "nil") or ""
	for i,v in ipairs{...} do
		prints = prints..tostring(v).."\t"
	end
	if debugPrints then
		debugPrints = prints.."\n"..debugPrints
	end
	orig_print(prints)
end

function love.load()
	 --love.filesystem.exists should no longer be deprecated in 12
	if love.setDeprecationOutput then
		love.setDeprecationOutput(false)
	end

	runLuaFile(compsPath.."/load_all.lua")
	
	uniqueDeviceId = getDeviceID()
	local loadedImages, errored
	handleStartArgs()

	love.graphics.setNewFont(24)

	local function loadlua(filename, ctx, env, lenient)
		local r = loadLuaFileToObject(filename, ctx, env, lenient)
		if r and not errored then
			print("showing error")
			errored = true
			showPopup("Error",
					"A script could not be loaded.\n"..filename.."\n"..r.."\n\nOpen the decompiler?",
					{
						{sprite = "MENU_NO", callback = function()
							return true
						end},
						{sprite = "TUTORIAL_OK", callback = function()
							showPopup("Decompiler",
								"														",{},
								function(x,y,w,h,p)
									drawDebugText("bir",x,y)
									drawDebugButton("TUTORIAL_OK",x+w+20,y+h+20,1,function()end,true)
								end,200)
							currentPopup.important = true
						end},
					}
				) currentPopup.important = true
		end
	end

	-- makeImages()
	loadlua(scriptPath.."/options.lua", this, nil, true)
	--and now start the actual game
	if checkDirectory(dataPath..scriptPath.."/gamelogic.lua") then
		loadlua(scriptPath.."/gamelogic.lua", this, nil, true)--, settings)
	elseif checkDirectory(dataPath..commonScriptPath .. "/gamelogic.lua") then
		loadlua(commonScriptPath.."/gamelogic.lua", this, nil, true)--, settings)
	end

	-- loadLuaFileToObject(scriptPath .. "/animations.lua", this)
	loadlua(scriptPath.."/particles.lua", this, particleTable, true)
	loadlua(scriptPath.."/starLimits.lua", this, starTable)
	blockTable.themes, blockTable.blocks = {}, {}
	loadlua(scriptPath.."/blocks.lua", this, blockTable, true)

	loadlua(scriptPath.."/loadlist.lua", this, _G, true)

	loadLuaFileToObject(scriptPath.."/episodes.lua", this, "episodes", true)
	loadLuaFileToObject(scriptPath.."/cutscenes.lua", this, "cutscenes", true)

	local sfp = selectFontProfile
	function selectFontProfile()
		-- deviceModel = "windows"
		local font = sfp and sfp()
		if font and not checkDirectory(dataPath..fontPath.."/"..font) then
			font = "1024x768"
		end
		return font
	end

	local sap = selectAssetProfile
	function selectAssetProfile(a)
		local asset = sap and sap(a)
		if asset and not checkDirectory(dataPath..imagePath.."/"..asset) then
			asset = sap and string.upper(sap(a))
		end
		
		if not asset or asset == "" then
			asset = "1024x768" --hack that i can't do anything about
		end
		return asset
	end

	--function loadImages()
		--if not loadedImages then
			--loadedImages = true
			--makeImages()
		--end
	--end

	--function loadLoadList(a)
		--loadlist[a] = {}
	--end

	setBGColor(255,255,255)
	love.graphics.setBlendMode("alpha","premultiplied")

	if checkDirectory(compsPath.."/icon.png") then
		love.window.setIcon(love.image.newImageData(compsPath.."/icon.png"))
	end

	--fixes editor's bad coding practices
	keyHold["CONTROL"] = false
	keyHold["SHIFT"] = false
	
	if deviceModel == "android" then
		if gameOptions and gameOptions.ui then
			gameOptions.ui.enableHoverScaling = false
			gameOptions.ui.enableCursor = false
		end
		setFullScreenMode(true)
		-- displayScale = 1.5
		autoScale = 640
		enableDebug = false
	end

	if createStartUpAssets then createStartUpAssets() end

	--if not loadedImages then loadImages() end

	gpcx,gpcy = love.mouse.getPosition()

	releaseBuild = false
	showEditor = true

	local uimos = updateItemMouseOverState
	if uimos then
		function updateItemMouseOverState(item,dt)
			if not gameOptions.ui.enableHoverScaling then
				return
			end
			uimos(item,dt)
		end
	end
	
	if errored then return end
	handlePostStartArgs()
end

function clamp(v, max)
	if v > max then return max end
	if v < -max then return -max end
	return v
end

function setMusicVolume(vol)
	audiovolume = vol
end

function setEffectsVolume(vol)
	audiovolume = vol
end

function setTheme(theme)
	currentTheme = theme
	objects.theme = theme
end

--enable/disable screensaver
function setGameOn(on)
	love.window.setDisplaySleepEnabled(not on)
end

function createThemeSprite(name, spr, x, y, speedX, scaleX, scaleY, angle, layer)
	return
end

function setTopLeft(left,top)
	screen.left = left
	screen.top = top
end

function serializeTable(t, indent, noIndexes)
	local serialized = ""
	indent = indent or ""

	for key, value in pairs(t) do
		local formattedKey = tostring(key).." = "
		if (noIndexes and type(value) ~= "table" and not key:find(" ") and not key:find(";")) or tonumber(key) then
			formattedKey = key.."="
		elseif noIndexes or (key:find(" ") or key:find(";")) then
			formattedKey = "[\""..tostring(key).."\"] = "
		end
		
		if tonumber(key) then
			formattedKey = "["..key.."] = "
		end

		if type(value) == "table" then
			serialized = serialized..indent..formattedKey.."{\n"..serializeTable(value, indent.."\t", noIndexes)..indent.."}"..(indent==""and""or",").."\n"
		else
			local formattedValue = tostring(value)
			if type(value) == "string" then
				formattedValue = "\""..formattedValue.."\""
			end

			if type(value) == "userdata" then
				if value:type() == "Quad" then
					local x, y, w, h = value:getViewport()
					local rw, rh = value:getTextureDimensions()
					serialized = serialized..indent..formattedKey.."q("..x..","..y..", "..w..","..h..", "..rw..","..rh.."),\n"
				end
			else
				serialized = serialized..indent..(tonumber(key) and "" or formattedKey)..formattedValue..""..(indent == "" and "" or ",").."\n"
			end
		end
	end

	return serialized
end

function saveLuaFile(fileName, tableName, appData, noIndexes, noWrap)
	local tableToSave = _G[tableName]
	assert(tableToSave and type(tableToSave) == "table", "Table "..tableName.." does not exist.")
	
	local serializedData
	if not noWrap then
		serializedData = tableName.." = {\n"..serializeTable(tableToSave, "\t", noIndexes).."}"
	else
		serializedData = serializeTable(tableToSave, "", noIndexes)
	end

	local s1, m1 = love.filesystem.createDirectory(fileName:match(".*/") or "")
	local s, m = love.filesystem.write(fileName, serializedData)
	if s then
		print("\""..tableName.."\" was saved to "..fileName)
	else
		print("\""..tableName.."\" failed to save to "..fileName.." ("..(m or "Unknown error")..")")
	end
end

function saveLuaFileLocal(fileName, table, tableName, noIndexes, prefix)
	assert(table and type(table) == "table", "Table "..tableName.." does not exist")

	local serializedData = tableName.." = {\n"..serializeTable(table, "\t", noIndexes).."}"

	local s1, m1 = love.filesystem.createDirectory(fileName:match(".*/") or "")
	local s, m = love.filesystem.write(fileName, (prefix or "")..serializedData)
	if s then
		print("\""..tableName.."\" was saved to "..fileName)
	else
		print("\""..tableName.."\" failed to save to "..fileName.." ("..(m or "Unknown error")..")")
	end
end

function savePersistentLuaFile(fileName, tableName)
	saveLuaFile(fileName, tableName)
end

function storePersistentData()
	return
end

function checkForLuaFile(filename)
	return love.filesystem.exists(dataPath..filename)
end

function openRegistrationDialog(message, validationURL, registrationURL, fullGame)
	showPopup(
		message,
		"The game is not registered.\nRegister now?",
		{
			{sprite = "MENU_NO", callback = function()
				return true
			end},
			{sprite = "TUTORIAL_OK", callback = function()
				g_isGameUnlocked = true
				
				table.insert(settings.license.registeredKeyTypes, g_registrationKeys.fullGame)
				
				settings.license.hardwareID = getDeviceID()
				if mainMenu and mainMenu.items and getItemByName then
					local t_button = getItemByName(mainMenu.items, "buttonActivateFullVersion")	
					if t_button then
						t_button.visible = (g_isGameUnlocked == false)
					end
				end

				showPopup("Registration", "Full game registered.")
			end},
		}
	)
	return ""
end

function flurry.logEvent(self, text, text2)
	logFlurryEventWithParams(text, text2)
end

function isInFullScreenMode()
	local fs, fst = love.window.getFullscreen()
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

--classic 3.0.1 only

function getCurrentTime()
	local t = os.date("*t")
	return {year = t.year, month = t.month, day = t.day, hour = t.hour, minutes = t.min, seconds = t.sec}
end

function getStampTime(stamp)
	local t = os.date("*t", stamp)
	return {years = t.year, months = t.month, days = t.day, hours = t.hour, minutes = t.min, seconds = t.sec}
end

function timeToStamp(t)
	return os.time{year = t.year, month = t.month, day = t.day, hour = t.hour, min = t.minutes, sec = t.seconds}
end

function getTimeDifferenceInSeconds(time1, time2)
	time1,time2 = timeToStamp(time1), timeToStamp(time2)
	
	return math.abs(time1 - time2)
end

function getTimeDifference(time1, time2)
	time1,time2 = timeToStamp(time1), timeToStamp(time2)
	
	return getStampTime(math.abs(time1 - time2))
end

function setWorldGravity(x,y)
	gravity.x, gravity.y = x, y
end

function drawRubberband(x1, y1, x2, y2, width, sprite)
	return
end

function requestCurrentTimeOnServer() --hatchery
	return
end

function hasLocationCapability()
	return false
end

function wasKeyReleased(key)
	return keyReleased[key]
end

--space
function performBitwiseOr(a,b)
	return bit.bor(a,b)
end

--not starwars
function setDeltaTimeMultiplier(dt)
	physicsTimeScale = dt
end

--override run function to allow drawing in the update hook
function love.run()
	if love.load then love.load(love.arg.parseGameArguments(arg), arg) end
	if love.timer then love.timer.step() end

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

		-- Call update and draw
		if love.update then love.update(love.timer.step()) end

		if love.graphics and love.graphics.isActive() then
			if love.draw then love.draw() end
		end

		if love.timer then love.timer.sleep(0.001) end
	end
end


function showPopup(title,desc,buttons,extra,height)
	keyReleased.LBUTTON = false
	res.playAudio("noteG",.7)
	if buttons == nil then
		buttons = {
			{sprite = "TUTORIAL_OK", callback = function()
				return true
			end},
		}
	end
	currentPopup = {open = true, title = title, text = desc, buttons = buttons, extra = extra, h = height}
end