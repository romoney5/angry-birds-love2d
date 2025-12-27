--this file is basically ka3d

io.stdout:setvbuf('no')

datapath = "data"
scriptPath = "scripts"
commonScriptPath = "scripts_common"
audioPath = "audio"
levelPath = "levels"
imagePath = "images"
localizationPath = "localization"
fontPath = "fonts"

compsPath = "components"

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

targetFPS = 1000 --love's love.run function uses 0.001 by default

local hasLove12 = love._version_major >= 12

function endsWith(str,ending)
	return string.sub(str, -string.len(ending)) == ending
end

--load either plain text lua or a precompiled chunk with fione
function makeChunk(filename)
	local src = love.filesystem.read(filename)
	if not src then
		return nil, nil, "No source"
	end
	
	if src:sub(1, 4) == "\27Lua" then --it's bytecode!
		print("Loading compiled Lua \""..filename.."\"...")
		return pcall(loadbytecode, src, nil, filename)
	else --that's just plain old lua.. boring..
		print("Loading Lua \""..filename.."\"...")
		return pcall(love.filesystem.load, filename)
	end
end

--very important in later codebases
function loadLuaFileToObject(filename, ctx, envKey, lenient)
	local loaded, lua
	filename = resolvePath(datapath.."/"..filename)
	loaded, lua = makeChunk(filename)

	if lua and loaded then
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
			error("Could not load Lua file: "..filename.."\n"..tostring(lua))
		else
			print("Could not load Lua file: "..filename.."\n"..tostring(lua))
			showPopup("Warning",
					"Could not load Lua file: "..filename.."\n"..tostring(lua),
					{
						{sprite = "TUTORIAL_OK", callback = function()
							return true
						end},
					}
				) currentPopup.important = true
		end
	else
		return tostring(lua)
	end
end

--also used in some versions
function loadLuaFile(filename, envKey, lenient)
	local loaded, lua
	filename = resolvePath(datapath.."/"..filename)
	loaded, lua = makeChunk(filename)

	if loaded and lua then
		setfenv(lua, _G[envKey] or _G)
		return lua()
	elseif not lenient then
		-- error("Could not load Lua file: "..filename)
		if not checkDirectory(filename) then
			lua = "File does not exist."
		end
		print("Could not load Lua file: "..filename.."\n"..tostring(lua))
	end
end

function runLuaFile(filename, lenient)
	local loaded, lua
	filename = resolvePath(filename)
	loaded, lua = makeChunk(filename)

	if loaded and lua then
		return lua()
	elseif not lenient then
		-- error("Could not load Lua file: "..filename)
		if not checkDirectory(filename) then
			lua = "File does not exist."
		end
		error("Could not load Lua file: "..filename.."\n"..tostring(lua))
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
	handleStartArgs()

	--load save data
	runLuaFile("settings.lua", true)
	runLuaFile("highscores.lua", true)
	
	uniqueDeviceId = getDeviceID()

	love.graphics.setNewFont(24)

	local function loadlua(filename, ctx, env, lenient)
		loadLuaFileToObject(filename, ctx, env)--, lenient)
	end

	-- makeImages()
	loadlua(scriptPath.."/options.lua", this, nil, true)
	--and now start the actual game
	if gamelogicPath then
		loadlua(gamelogicPath, this, nil, true)
	elseif checkDirectory(datapath.."/"..scriptPath.."/gamelogic.lua") then
		loadlua(scriptPath.."/gamelogic.lua", this, nil, true)--, settings)
	elseif checkDirectory(datapath.."/"..commonScriptPath .. "/gamelogic.lua") then
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
	function selectFontProfile(...)
		-- deviceModel = "windows"
		local font = sfp and sfp(...)
		if font and not checkDirectory(datapath.."/"..fontPath.."/"..font) then
			font = "1024x768" --just default to the pc version
		end
		return font
	end

	local sap = selectAssetProfile
	function selectAssetProfile(...)
		local asset = sap and sap(...)
		if asset and not checkDirectory(datapath.."/"..imagePath.."/"..asset) then
			asset = sap and string.upper(sap(...)) --try uppercase version then..
		end
		
		if not asset or asset == "" then
			asset = "1024x768"
		end
		return asset
	end

	--start by setting the background to white and using premultiplied alpha
	setBGColor(255, 255, 255)
	love.graphics.setBlendMode("alpha", "premultiplied")

	--set an icon
	if checkDirectory(compsPath.."/icon.png") then
		love.window.setIcon(love.image.newImageData(compsPath.."/icon.png"))
	end

	--editor-specific patch
	keyHold["CONTROL"] = false
	keyHold["SHIFT"] = false
	
	--mobile-specific options
	if deviceModel == "android" then
		if gameOptions and gameOptions.ui then
			gameOptions.ui.enableHoverScaling = false
			gameOptions.ui.enableCursor = false
		end

		setFullScreenMode(true)
		autoScale = 640
		enableDebug = false
	end

	--[[setmetatable(_G, {__index = function(_, i)
		print("tried to index "..tostring(i))
		--print(debug.traceback())
		--return rawget(_, i)
	end})]]
	if createStartUpAssets then createStartUpAssets() end

	gpcx, gpcy = love.mouse.getPosition()

	--override releaseBuild
	releaseBuild = false
	showEditor = true

	local uimos = updateItemMouseOverState
	if uimos then
		function updateItemMouseOverState(item,dt)
			if not gameOptions.ui.enableHoverScaling then
				return
			end
			uimos(item, dt)
		end
	end
	
	handlePostStartArgs()
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

			if type(value) ~= "userdata" then
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

function savePersistentLuaFile(fileName, tableName)
	saveLuaFile(fileName, tableName)
end

function storePersistentData()
	return
end

function checkForLuaFile(filename)
	return love.filesystem.exists(datapath.."/"..filename)
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

function setResolution(w, h)
	screenWidth = w
	screenHeight = h
	love.window.updateMode(w * displayScale * love.graphics.getDPIScale(), h * displayScale * love.graphics.getDPIScale())
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

function setWorldGravity(x, y)
	gravity.x, gravity.y = x, y
end

function drawRubberband(x1, y1, x2, y2, width, sprite)
	return
end

--hatchery

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

		if love.timer then love.timer.sleep(1 / targetFPS) end
	end
end


function showPopup(title,desc,buttons,extra,height)
	keyReleased.LBUTTON = false

	if audiochannels then
		res.playAudio("noteG", .7)
	end

	if buttons == nil then
		buttons = {
			{sprite = "TUTORIAL_OK", callback = function()
				return true
			end},
		}
	end
	currentPopup = {open = true, title = title, text = desc, buttons = buttons, extra = extra, h = height}
end