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

openPopups = {}

flurry = {}

enableDebug = false

targetFPS = 1000 --love's love.run function uses 0.001 by default

fione_errorblame_length = 0

function endsWith(str, ending)
	return string.sub(str, -string.len(ending)) == ending
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
		table.insert(debugPrints, 1, prints)
		if #debugPrints > debugPrintsLimit then
			for i = #debugPrints, debugPrintsLimit + 1, -1 do
				table.remove(debugPrints, i)
			end
		end
	end
	orig_print(prints)
end

function love.load()
	 --love.filesystem.exists should no longer be deprecated in 12
	if love.setDeprecationOutput then
		love.setDeprecationOutput(false)
	end
	
	--cache original image path
	local og_imagePath = imagePath
	local og_fontPath = fontPath

	love.filesystem.load(compsPath.."/load_all.lua")()
	handleStartArgs()
	
	updateDisplayScale()
	
	--load only certain properties from config.lua
	local config = {}
	local datapath_base, _ = resolvePath(datapath.."/..")

	if not loadLuaFileToObject(datapath_base.."/config.lua", config, nil, true) then loadLuaFileToObject(datapath.."/config.lua", config, nil, true) end
	imagePath = config.imagePath or imagePath
	fontPath = config.fontPath or fontPath
	audioPath = config.audioPath or audioPath
	localizationPath = config.localizationPath or localizationPath
	levelPath = config.levelPath or levelPath
	scriptPath = config.scriptPath or scriptPath
	--deviceModel = config.deviceModel or deviceModel

	if not checkDirectory(datapath) then
		print("Data path \""..tostring(datapath).."\" wasn't found.\nTry the --datapath argument to specify a custom path.")
	elseif not checkDirectory(datapath.."/"..commonScriptPath) then
		--versions around classic 7.3.0 remove scripts_common again
		commonScriptPath = scriptPath
	end

	local accountId = 0 -- TODO : add account support
	
	--load save data
	if not disableSaving then
		local settingsAccount = "settings_" .. accountId .. ".lua"
		local highscoresAccount = "highscores_" .. accountId .. ".lua"
		
		if checkDirectory(settingsAccount) then
			runLuaFile(settingsAccount, true)
			runLuaFile(highscoresAccount, true)
		else
			runLuaFile("settings.lua", true)
			runLuaFile("highscores.lua", true)
		end
	end
	
	uniqueDeviceId = getDeviceID()
	uniqueInstallationId = ""

	love.graphics.setNewFont(24)

	local function loadlua(filename, ctx, env, lenient)
		loadLuaFileToObject(filename, ctx, env)--, lenient)
	end

	loadLuaFileToObject(scriptPath.."/options.lua", this, nil, true)
	--and now start the actual game
	if gamelogicPath then
		loadlua(gamelogicPath, this, nil, true)
	elseif checkDirectory(datapath.."/"..commonScriptPath .. "/gamelogic.lua") then
		loadlua(commonScriptPath.."/gamelogic.lua", this, nil, true)--, settings)
	end

	-- loadLuaFileToObject(scriptPath .. "/animations.lua", this)
	loadLuaFileToObject(scriptPath.."/particles.lua", this, particleTable, true)
	loadLuaFileToObject(scriptPath.."/starLimits.lua", this, starTable, true)
	blockTable.themes, blockTable.blocks = {}, {}
	
	loadLuaFileToObject(scriptPath.."/blocks.lua", this, blockTable, true)

	loadLuaFileToObject(scriptPath.."/loadlist.lua", this, _G, true)

	loadLuaFileToObject(scriptPath.."/episodes.lua", this, "episodes", true)
	loadLuaFileToObject(scriptPath.."/cutscenes.lua", this, "cutscenes", true)

	--start by setting the background to white and using premultiplied alpha
	setBGColor(255, 255, 255)
	love.graphics.setBlendMode("alpha", "premultiplied")

	--set an icon
	if checkDirectory(datapath_base.."/Icon.png") then
		love.window.setIcon(love.image.newImageData(datapath_base.."/Icon.png"))
	elseif checkDirectory(compsPath.."/icon.png") then
		love.window.setIcon(love.image.newImageData(compsPath.."/icon.png"))
	end

	--editor-specific patch
	keyHold["CONTROL"] = false
	keyHold["SHIFT"] = false
	
	--mobile-specific options
	if love._os == "Android" then
		if gameOptions and gameOptions.ui then
			gameOptions.ui.enableHoverScaling = false
			gameOptions.ui.enableCursor = false
		end

		setFullScreenMode(true)
		autoScale = 720
		enableDebug = false
	end

	if createStartUpAssets then createStartUpAssets() end
	if updateValues then updateValues() end

	gpcx, gpcy = love.mouse.getPosition()

	--override releaseBuild
	--releaseBuild = false
	--showEditor = true

	local uimos = updateItemMouseOverState
	if uimos then
		function updateItemMouseOverState(item,dt)
			if gameOptions and gameOptions.ui and not gameOptions.ui.enableHoverScaling then
				return
			end
			uimos(item, dt)
		end
	end

	--4.0.0 patch
	if RovioAnalytics and RovioAnalytics.logEvent then
		function RovioAnalytics.logEvent(id, params)
			return
		end
	end
	
	toggleZoom_GameLua = toggleZoom2
	
	--windows builds don't use rovio account
	if deviceModel == "windows" then
		RovioAccount = nil
	end
	
	handlePostStartArgs()
end

function setLevelEffects(theme)
	return
end

function updateLevelEffects(dt, realDt) --right parameters?
	return
end

--enable/disable screensaver
function setGameOn(on)
	love.window.setDisplaySleepEnabled(not on)
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
	if disableSaving then
		print("Tried saving \""..tableName.."\" but saving is disabled")
		return
	end

	local tableToSave = _G[tableName]
	assert(tableToSave and type(tableToSave) == "table", "Table "..tableName.." does not exist.")

	if not tableToSave then return end
	
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

local registered
function openRegistrationDialog(message, validationURL, registrationURL, fullGame)
	local returnedKey = ""

	showPopup(
		message,
		"The game is not registered.\nRegister now?",
		{
			{sprite = "MENU_NO", callback = function()
				return true
			end},
			{sprite = "TUTORIAL_OK", callback = function()
				returnedKey = true
				registered = true
				showPopup("Registration", "Full game registered.", nil, true)

				return true
			end},
		},
		true
	)
	return returnedKey
end

registerKey = openRegistrationDialog
--returns finished, valid
function checkRegistrationResult()
	local finished = openPopups[1] == nil
	local valid = registered
	registered = nil
	return finished, valid
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
	love.window.updateMode(w * displayScale * love.graphics.getDPIScale(), h * displayScale * love.graphics.getDPIScale())
	updateDisplayScale()
end

--classic 3.0.1 only

function getCurrentTime()
	local t = os.date("*t")
	return {year = t.year, month = t.month, day = t.day, hour = t.hour, minutes = t.min, seconds = t.sec}
end

function getStampTime(stamp)
	--months technically not accurate
	return {years = stamp / 60 / 60 / 24 / 365, months = stamp / 60 / 60 / 24 / 30, days = stamp / 60 / 60 / 24,
		hours = stamp / 60 / 60, minutes = stamp / 60, seconds = stamp}
end

function timeToStamp(t)
	return os.time{year = t.year, month = t.month, day = t.day, hour = t.hour, min = t.minutes, sec = t.seconds}
end

function getTimeDifferenceInSeconds(time1, time2)
	time1, time2 = timeToStamp(time1), timeToStamp(time2)
	
	return math.abs(time2 - time1)
end

function getTimeDifference(time1, time2)
	time1, time2 = timeToStamp(time1) or 0, timeToStamp(time2) or 0
	
	return getStampTime(math.abs(time2 - time1))
end

function setWorldGravity(x, y)
	gravity.x, gravity.y = x, y
end

--hatchery

function wasKeyReleased(key)
	return keyReleased[key]
end

--space
function performBitwiseOr(a,b)
	return bit.bor(a,b)
end

--not absw
function setDeltaTimeMultiplier(dt)
	physicsTimeScale = dt
end

--override run function to allow drawing in the update hook
function loveUpdate(pause, freeze)
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
	--don't step if the game should be paused while resizing
	local dt = love.timer.step()
	if love.update and not freeze then love.update(pause and 0 or dt) end

	if love.graphics and love.graphics.isActive() then
		if love.draw then love.draw() end
	end

	if love.timer then love.timer.sleep(1 / targetFPS) end
end

function love.run()
	if love.load then love.load(love.arg.parseGameArguments(arg), arg) end
	if love.timer then love.timer.step() end

	return loveUpdate
end


function showPopup(title, text, buttons, pause, extra, height)
	keyReleased.LBUTTON = false

	if audiochannels then
		res.playAudio("noteG", .7)
	end

	--default button set
	buttons = buttons or {
		{sprite = "TUTORIAL_OK", callback = function()
			return true
		end},
	}

	--add a popup at the end of the queue
	table.insert(openPopups, {title = title, text = text, buttons = buttons, extra = extra, h = height, pause = pause})

	--if it's important then run it immediately
	if pause and #openPopups == 1 then
		updatePopup()
	end
end
