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

--replace a missing filename due to case sensitivity
function findCaseInsensitive(dir)
	local dir, paths = resolvePath(dir)

	if checkDirectory(dir) then
		--it's there already
		return dir, paths
	elseif dir and dir ~= "" then
		if #paths == 0 then return "" end

		local name = paths[#paths] --get the filename now

		for lookfor_i = 1, #paths - 1 do
			local lookfor = table.concat(paths, "/", 1, lookfor_i)
			for _, f in ipairs(love.filesystem.getDirectoryItems(lookfor)) do
				if lookfor_i == #paths - 1 then
					if f:lower() == name:lower() then
						local output = lookfor.."/"..f
						local _, paths = resolvePath(output)
						return output, paths --return that and do ANOTHER resolvepath
					end
				else
					if f:lower() == paths[lookfor_i + 1]:lower() then
						paths[lookfor_i + 1] = f
						break
					end
				end
			end
		end
	end

	-- print("findCaseInsensitive: could not find "..dir)
	return nil, nil
end

--load either plain text lua, a precompiled chunk with fione,
--a 7-zipped file, an aes-256 encrypted file, or all of the above
--TODO: move lua script handling over to another file

--cache decrypted files in the save directory to speed up loading dramatically
local ALLOW_LUA_CACHE = true

function identifySrc(src)
	--lzma support?
	if src:sub(1, 6) == "7z\xbc\xaf\x27\x1c" then return "7z" end
	if src:sub(2, 5) == "LZMA" then return "lzma" end
	if src:sub(1, 4) == "\27Lua" then return "lua" end
	if src:sub(1, 64):find("[\128-\255]") then return "binary" end
	return "plain" --what we want
end

function decryptSrc(filename, src)
	src = src or love.filesystem.read(filename)

	if not src then return end

	--temporary file for use in 7-zip
	local function temp_file()
		local dec_filename = "/dec/"..filename
		love.filesystem.createDirectory(dec_filename:match(".*/") or "")
		
		local success, message = love.filesystem.write(dec_filename, src)
		if not success then
			print("decryptSrc: writing to temporary file failed ("..tostring(message)..")")
			return
		end
		
		return dec_filename
	end
	
	local kind = identifySrc(src)
	
	if kind == "binary" then --it's probably encrypted..
		--let's use libcrypto as a dll/so
		if AES then
			local iv = nil --iv is always nil
			local key = AES.FindKey(src, AES.Keys.Assets, iv)
			src = AES.Decrypt(src, key, iv)
			--equivalent to openssl enc -aes-256-cbc -d -K <key> -iv 0 -in <file>

			--make sure it worked..
			assert(src, "decryptSrc: libcrypto failure")
			
			--reidentify it
			kind = identifySrc(src)
		else
			print("decryptSrc: Could not run libcrypto")
			return --just don't bother trying to run an encrypted file
		end
	end
	
	if kind == "7z" or kind == "lzma" then --looks like it's 7-zipped too
		--because 7-zip sucks we have to do file operations first
		local dec_filename = temp_file()
		
		--now use 7-zip with stdin and open it in binary mode on windows
		local mode = love._os == "Windows" and "rb" or "r"
		local file = io.popen("7z e -so -t7z \""..love.filesystem.getSaveDirectory()..dec_filename.."\"", mode) --no -si
		if file then
			src = file:read("*a")
			file:close()
			
			--did it do anything?
			assert(src and src:len() > 0, "decryptSrc: 7-zip returned nothing")
			
			--reidentify it
			kind = identifySrc(src)
		else
			print("decryptSrc: Could not run 7-zip")
		end
	end
	
	if ALLOW_LUA_CACHE then
		temp_file()
	end
	
	--now it shouldn't be binary
	--assert(kind ~= "binary", "decryptSrc: file is binary")

	return src
end

function makeChunk(filename, env)
	local decinfo = ALLOW_LUA_CACHE and love.filesystem.getInfo("/dec/"..filename)
	local info = decinfo and love.filesystem.getInfo(filename)
	
	if decinfo and decinfo.modtime and info and info.modtime and decinfo.modtime >= info.modtime then
		src = love.filesystem.read("/dec/"..filename)
	else
		--we need runnable lua code
		src = decryptSrc(filename)
	end

	if not src then
		return nil, nil, "No source"
	end

	local kind = identifySrc(src)

	if kind == "lzma" then
		error("LZMA is not supported currently.\nTried loading "..tostring(filename))
	end
	
	if kind == "lua" then --it's bytecode!
		print("Loading compiled Lua \""..filename.."\"...")
		return true, pcall(loadbytecode, src, env, filename)
	elseif kind == "plain" then --that's just plain old lua.. boring..
		print("Loading Lua \""..filename.."\"...")
		return false, pcall(loadstring, src, filename)
	end
end

--very important in later codebases
function loadLuaFileToObject(filename, ctx, key, lenient)
	local newname, paths = findCaseInsensitive(datapath.."/"..filename)
	filename = newname or filename

	local compiled, loaded, lua

	ctx = ctx or _G

	local env
	if type(key) == "table" then
		env = key
	elseif type(key) == "string" and key ~= "" then
		--make a new table in ctx with the name of key (this, "ui")
		ctx[key] = ctx[key] or {}
		env = ctx[key]
	else
		--use ctx table (this.ui, "")
		env = ctx
	end

	compiled, loaded, lua = makeChunk(filename, env)

	if lua and loaded then
		--fione needs the env on script loading so this should only work on plaintext luas
		if not compiled then
			setfenv(lua, env)
		end

		
		--emulate scope behavior
		if not getmetatable(env) then
			setmetatable(env, {
				__index = function(self, k)
					if k == "_G" or k == "gamelua" then
						return _G
					elseif k == "this" then
						return self
					end
				end,
				__newindex = function(self, k, v)
					if k ~= "filename" then
						rawset(self, k, v)
					end
				end
			})
		end

		lua()
	elseif not lenient then
		if checkDirectory(filename) then
			error("Could not load Lua file: "..filename.."\n"..tostring(lua))
		else
			print("Could not load Lua file: "..filename.."\n"..tostring(lua))
			if enableDebug then
				showPopup("Warning",
						"Could not load Lua file: "..filename.."\n"..tostring(lua),
						{
							{sprite = "TUTORIAL_OK", callback = function()
								return true
							end},
						}
					, true)
			end
		end
	else
		return tostring(lua)
	end
end

--also used in some versions
--absw: blocks makes the file load into .blocks, unpack unpacks all tables inside
function loadLuaFile(filename, envKey, blocks, unpack, lenient)
	local newname, paths = findCaseInsensitive(datapath.."/"..filename)
	filename = newname or filename

	local loaded, lua
	local env = _G[envKey] or _G
	local og_env = env

	compiled, loaded, lua = makeChunk(filename, env)

	if loaded and lua then
		if not compiled and not blocks then
			setfenv(lua, env)
		end

		if blocks and not unpack then
			blockTable[envKey] = blockTable[envKey] or {}
			env = blockTable[envKey]
		elseif blocks and unpack then
			env.blocks = env.blocks or {}
			env = env.blocks
		end

		if blocks then
			og_env = {}

			if not compiled then
				setfenv(lua, og_env)
			end

			local _mt = {
				__newindex = function(self, k, v)
					if type(v) == "table" then
						if unpack then
							for kk, vv in pairs(v) do
								if type(vv) == "table" then
									kk = vv.definition or kk
									rawset(env, kk, vv)
								end
							end
						else
							rawset(env, k, v)
						end
					else
						rawset(self, k, v)
					end
				end
			}

			setmetatable(og_env, _mt)
		end
		
		return lua()
	elseif not lenient then
		-- error("Could not load Lua file: "..filename)
		if not checkDirectory(filename) then
			lua = "File does not exist."
		end
		print("Could not load Lua file: "..filename.."\n"..tostring(lua))
	end

	return false
end

function runLuaFile(filename, lenient)
	local newname, paths = findCaseInsensitive(datapath.."/"..filename)
	filename = newname or filename

	local loaded, lua
	compiled, loaded, lua = makeChunk(filename)

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
local alreadyloaded = {}
function requireFile(filename)
	if alreadyloaded[filename] then return end

	if loadLuaFile(scriptPath.."/"..filename, nil, nil, nil, true) == false and loadLuaFile(commonScriptPath.."/"..filename) == false then
		print("Could not load Lua file: "..filename)
		return
	end

	alreadyloaded[filename] = true
end

--debugging function to decrypt and save a lua file into the save directory
function exportLua(filename)
	local newname, paths = findCaseInsensitive(datapath.."/"..filename)
	filename = newname or filename

	local src = decryptSrc(filename)
	if src then
		--findCaseInsensitive
		-- paths = resolvePath(newname)
		local exportname = paths[#paths]..".dec"
		love.filesystem.write(exportname, src)

		print("Decrypted file \""..filename.."\" into \""..exportname.."\"")
	else
		print("Could not decrypt file \""..filename.."\"")
	end
end

--strips .. and separates directories into a table
function resolvePath(path)
	local resolved = {}
	for part in path:gmatch("[^/]+") do
		if part == ".." then
			table.remove(resolved)
		elseif part ~= "." and part ~= "" then
			table.insert(resolved, part)
		end
	end
	return "/"..table.concat(resolved, "/"), resolved
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

	runLuaFile(compsPath.."/load_all.lua")
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
	end

	--load save data
	if not disableSaving then
		runLuaFile("settings.lua", true)
		runLuaFile("highscores.lua", true)
	end
	
	uniqueDeviceId = getDeviceID()
	uniqueInstallationId = ""

	love.graphics.setNewFont(24)

	local function loadlua(filename, ctx, env, lenient)
		loadLuaFileToObject(filename, ctx, env)--, lenient)
	end

	-- makeImages()
	loadLuaFileToObject(scriptPath.."/options.lua", this, nil, true)
	--and now start the actual game
	if gamelogicPath then
		loadlua(gamelogicPath, this, nil, true)
	elseif checkDirectory(datapath.."/"..scriptPath.."/gamelogic.lua") then
		loadlua(scriptPath.."/gamelogic.lua", this, nil, true)--, settings)
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
		autoScale = 640
		enableDebug = false
	end

	--[[setmetatable(_G, {__index = function(_, i)
		print("tried to index "..tostring(i))
		--print(debug.traceback())
		--return rawget(_, i)
	end})]]
	useDynamicAssets = false
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
