--main.lua: contains basic functions to load and set up the game
--as well as some other functions just left here

--this was used for sublime text
--io.stdout:setvbuf('no')

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

nuked = {} --nuked

objects = {}
blockTable = {}
starTable = {}
particleTable = {particles = {}}

enableDebug = false


function requestExit()
	print("Quitting...")
	love.event.quit()
end


--override print to work with the debug console
--this needs to be here because other stuff is loaded before console.lua
local orig_print = print

debugPrints = {}
debugPrintsLimit = 200

function print(...)
	orig_print(...)

	local prints = (... == nil and "nil") or ""

	for i = 1, select("#", ...) do
		prints = prints..tostring(select(i, ...)).."\t"
	end

	table.insert(debugPrints, 1, prints)
	if #debugPrints > debugPrintsLimit then
		for i = #debugPrints, debugPrintsLimit + 1, -1 do
			table.remove(debugPrints, i)
		end
	end
end

--find and set an icon from the data path
local function loadIcon(datapath_base)
	local icon_paths = {
		--ios
		datapath_base.."/Icon.png",
		datapath_base.."/Icon-72.png",
		--android
		datapath_base.."/../res/drawable-xxxhdpi-v4/icon.png",
		datapath_base.."/../res/drawable-hdpi/icon.png", --classic 1.3.5
		--fallback
		compsPath.."/icon.png",
	}

	for i, path in ipairs(icon_paths) do
		local new_path = resolvePath(path)
		
		if checkDirectory(resolvePath(new_path)) then
			love.window.setIcon(love.image.newImageData(new_path))
			print("Using icon "..tostring(new_path))

			break
		end
	end
end

--load everything!
function loadGameFiles()
	--cache original image path
	local og_imagePath = imagePath
	local og_fontPath = fontPath
	
	--load only certain properties from config.lua
	local config = {}
	local datapath_base, _ = resolvePath(datapath.."/..")

	--needed for some later versions
	BEACON = true

	if not loadLuaFileToObject(datapath_base.."/config.lua", config, nil, true) then
		loadLuaFileToObject(datapath.."/config.lua", config, nil, true)
	end
	
	imagePath = config.imagePath or imagePath
	fontPath = config.fontPath or fontPath
	audioPath = config.audioPath or audioPath
	localizationPath = config.localizationPath or localizationPath
	levelPath = config.levelPath or levelPath
	scriptPath = config.scriptPath or scriptPath
	--deviceModel = config.deviceModel or deviceModel

	--start by setting the background to white and using premultiplied alpha
	setBGColor(255, 255, 255)
	love.graphics.setBlendMode("alpha", "premultiplied")
	blockTable.themes, blockTable.blocks = {}, {}

	if not checkDirectory(datapath) or datapath == "" then
		--notify the user that no data path is available
		print("NOTICE: Data path \""..tostring(datapath).."\" was not found.\nTry the --datapath argument to specify a custom path,\nor use the File Manager to launch games.")
		
		debugOpen = true
		
		return
	elseif not checkDirectory(datapath.."/"..scriptPath) then
		--classic 1.0
		commonScriptPath = ""
		scriptPath = ""
		audioPath = ""
		imagePath = ""
		levelPath = ""
	elseif not checkDirectory(datapath.."/"..commonScriptPath) then
		--versions around classic 7.3.0 remove scripts_common again
		commonScriptPath = scriptPath
	end
	
	loadIcon(datapath_base)

	local accountId = RovioAccount and RovioAccount.profile.id or "0" -- TODO : add account support
	
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

	loadLuaFileToObject(scriptPath.."/options.lua", nil, nil, true)
	
	--look around for block files to load in rio, etc.
	local rootPath = datapath .. "/" .. scriptPath
	local rootPathAppend = ""
	
	if checkDirectory(rootPath.."/definitions") then
		rootPathAppend = rootPathAppend.."/definitions"
		rootPath = rootPath..rootPathAppend
	end
	
	local blocksExists = checkDirectory(rootPath .. "/blocks.lua")
	
	if not blocksExists then
		blockTable = { blocks = { Ground = { type = "box", material = "staticGround", } } }
		local extras = {"birds.lua", "scoreobjects.lua", "levelgoals.lua"}
		setmetatable(extras, { __index = function(t, id) for _, k in ipairs(t) do if k == id then return k end end end })
		
		for i, file in ipairs(love.filesystem.getDirectoryItems(rootPath)) do
			if file:match("blocks_") or extras[file] then
				local temp = {}
				loadLuaFileToObject(scriptPath .. rootPathAppend .. "/" .. file, this, temp, true)
				
				for n, key in pairs(temp) do
					if type(key) == "table" and key[1] and key[1].definition then
						for k, v in ipairs(key) do
							blockTable.blocks[v.definition] = v
						end
					end
				end
			end
		end
		
		loadLuaFileToObject(scriptPath .. rootPathAppend .. "/damagefactors.lua", blockTable, "damageFactors", true)
		loadLuaFileToObject(scriptPath .. rootPathAppend .. "/materials.lua", blockTable, "materials", true)
		loadLuaFileToObject(scriptPath .. rootPathAppend .. "/themes.lua", blockTable, "themes", true)
	end
	
	--and now start the actual game
	if gamelogicPath then
		loadLuaFileToObject(gamelogicPath, nil, nil)
	elseif checkDirectory(datapath.."/"..commonScriptPath .. "/gamelogic.lua") then
		loadLuaFileToObject(commonScriptPath.."/gamelogic.lua", nil, nil)
	elseif checkDirectory(datapath.."/".."common/scripts/game" .. "/gamelogic.lua") then
		commonScriptPath = "common/scripts/game"
		loadLuaFileToObject(commonScriptPath.."/gamelogic.lua", nil, nil)
	end
	
	if blocksExists then
		loadLuaFileToObject(scriptPath .. "/blocks.lua", nil, blockTable, true)
	end

	loadLuaFileToObject(scriptPath.."/particles.lua", nil, particleTable, true)
	loadLuaFileToObject(scriptPath.."/starLimits.lua", nil, starTable, true)

	loadLuaFileToObject(scriptPath.."/loadlist.lua", nil, _G, true)

	loadLuaFileToObject(scriptPath.."/episodes.lua", nil, "episodes", true)
	loadLuaFileToObject(scriptPath.."/cutscenes.lua", nil, "cutscenes", true)
	
	--mobile-specific options
	if love._os == "Android" then
		setFullScreenMode(true)
		autoScale = 720
	end

	--4.0.0 hack
	--TODO: consider killing this after the script env reorganization
	if RovioAnalytics and RovioAnalytics.logEvent then
		function RovioAnalytics.logEvent(id, params)
			return
		end
	end

	if Analytics and Analytics.logEvent then
		function Analytics.logEvent(id, params)
			return
		end
	end

	if createStartUpAssets then createStartUpAssets() end
	if showSplashScreens then showSplashScreens() end --kakao
	if updateValues then updateValues() end
	
	toggleZoom_GameLua = toggleZoom2
	
	--windows builds don't use rovio account
	if deviceModel == "windows" then
		RovioAccount = nil
	end
	
	handlePostStartArgs()
end

function love.load()
	--love.filesystem.exists is no longer deprecated in love 12
	--TODO: remove this when love 12 releases
	if love.setDeprecationOutput then
		love.setDeprecationOutput(false)
	end

	love.filesystem.load(compsPath.."/load_all.lua")()
	handleStartArgs()
	
	updateDisplayScale()

	love.graphics.setNewFont(24)
	
	loadGameFiles()
end

--TODO: consider killing this after the script env reorganization
function kak()
	RovioAccount.profile.isConnectedToSocialNetwork = true
	g_rovio_account_available = true
	skipSocialLogin = true
	for i = 1, 5 do initialize() end
	startMenuFlow()
end

function kak2()
	gamelua.notificationsFrame:removeChild(gamelua.notificationsFrame:getChild("KakaoNetworkErrorDialog"))
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

local registered
function openRegistrationDialog(message, validationURL, registrationURL, fullGame)
	local returnedKey = ""

	openPopup(
		message,
		"The game is not registered.\nRegister now?",
		{
			{sprite = "MENU_NO", callback = function()
				return true
			end},
			{sprite = "TUTORIAL_OK", callback = function()
				returnedKey = true
				registered = true
				openPopup("Registration", "Full game registered.", nil, true)

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

--space
function performBitwiseOr(a,b)
	return bit.bor(a,b)
end

--not absw
function setDeltaTimeMultiplier(dt)
	physicsTimeScale = dt
end
