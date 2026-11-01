--handles arguments passed to love at the start of the game, as well as other post-start arguments

local autoboot_path = "autoboot.lua"

datapath_base = ""

--default path that all game saves and decrypted scripts will save into
savePath = ""

function removeAutoboot()
	if mobileDevice then
		pcall(function()
			--clear autoboot if it exists
			if love.filesystem.remove(autoboot_path) then
				print("Removed autoboot file "..autoboot_path)
			end
		end)
	end
end

arguments = {
	{display = "Delete Data", names = {"--deletedata", "-dd"}, args = 0, type = "bool", call = function()
		print("Opening data deletion prompt...")
		
		openPopup("Data",
			"Delete save data?\nThis will reset all progress in the current data path!",
			{
				{icon = "cross", callback = function()
					return true
				end},
				{icon = "check", callback = function()
					local success1 = love.filesystem.remove("settings.lua")
					local success2 = love.filesystem.remove("highscores.lua")
					if success1 or success2 then
						openPopup("Data", "Successfully deleted save data.", nil, true)
					elseif not love.filesystem.exists("settings.lua") and not love.filesystem.exists("highscores.lua") then
						openPopup("Data", "There is no existing save data.", nil, true)
					else
						openPopup("Data", "Could not properly delete save data.", nil, true)
					end
					gamelua.settings, gamelua.highscores = {}, {}

					return true
				end},
			}
		, true)
	end},
	
	{display = "Clear Cache", names = {"--clearcache", "-cc"}, args = 0, type = "bool", call = function()
		print("Clearing dec/...")
		
		--code duplication
		local function del(path)
			if love.filesystem.getInfo(path, "directory") then
				for i, file in ipairs(love.filesystem.getDirectoryItems(path)) do
					del(path.."/"..file)
					love.filesystem.remove(path.."/"..file)
				end
			end
			
			return love.filesystem.remove(path)
		end
		
		local success = del("dec")
		if not success then
			print("Could not clear dec/")
			openPopup("dec", "Could not clear the \"".."dec".."\" folder.")
		else
			print("Cleared dec/")
		end
	end},
	
	{display = "Device Model", names = {"--model", "-m"}, args = 1, type = "string", call = function(arg1)
		gamelua.deviceModel = arg1 or gamelua.deviceModel
		setDeviceModel = true
	end},
	
	{display = "Data Path", names = {"--datapath", "-dp"}, args = 1, type = "string", call = function(arg1)
		something_runFile(arg1 or datapath, arg1 or datapath)
	end},
	
	{display = "No Save", names = {"--nosave", "-ns"}, args = 0, type = "bool", call = function()
		disableSaving = true
	end},
	
	{display = "Run Lua", names = {"--run"}, args = 1, type = "string", call = function(arg1)
		debugExecute(arg1 or "")
	end},
	
	{display = "Cheats", names = {"--cheats", "-c"}, args = 0, type = "bool", call = function()
		--[[releaseBuild = false
		showEditor = true]]
		queueCheatsEnabled = true --look at filesystem.lua
	end},
}

--look recursively for a data folder
--as it varies between different platforms
local look
function look(dir, target)
	--first loop through all the items
	for i, file in ipairs(love.filesystem.getDirectoryItems(dir)) do
		if file:lower():match(target:lower()) then
			--found it already?
			return dir.."/"..file
		else
			--check if it's a folder, and if so, look through that and see if it got anything
			local info = love.filesystem.getInfo(dir.."/"..file)

			if info and info.type == "directory" then
				local found = look(dir.."/"..file, target)

				if found then
					return found
				end
			end
		end
	end
end

--guess the deviceModel from a data path
local function guessModel(dir)
	if endsWith(dir, ".ipa") then
		--make a guess using available image profiles
		--[[
		hatchery: 1024x768
		2.2.0: 480x320 480x320_retina
		hd3.2.0: 1024x768 1024x768_retina
		hd4.3.2: 1024x768
		5.2.0: 480x320 1024x768 themes_ios
		
		shd5.2.5: 1024x768 2048x1536
		]]
		
		local matches = {}
		
		for i, v in ipairs(love.filesystem.getDirectoryItems(datapath.."/"..gamelua.imagePath)) do
			if v == "1024x768" then
				matches.ipad = (matches.ipad or 0) + 1
			elseif v == "1024x768_retina" then
				matches.ipad = (matches.ipad or 0) + 2
			elseif v == "480x320" or v == "480x320_retina" then
				matches.iphone = (matches.iphone or 0) + 2
			
			elseif v == "1024x768_lite" then
				matches.ipad = (matches.ipad or 0) + 2
				gamelua.isLiteVersion = true
			
			elseif v == "2048x1536" then
				matches.ipad = (matches.ipad or 0) + 2
			end
		end
		
		local highest_score, highest_model = 0, "iphone"
		
		for i, v in pairs(matches) do
			if v > highest_score then
				highest_score, highest_model = v, i
			end
		end
		
		return highest_model
	elseif endsWith(dir, ".apk") then
		return "android"
	elseif endsWith(dir, ".bar") then
		return "blackberry"
	elseif endsWith(dir, ".iso") then
		--psp
		gamelua.isPSP = true
		return "iphone"
	elseif endsWith(dir, ".xap") then
		return "wp8"
	end
end

--mounts a given file path and searches for a data path
--returns
function findDataPath(file)
	local info
	
	--accepts both a string and a file object
	if type(file) == "string" then
		info = love.filesystem.getInfo(file)
	else
		info = {type = "file"}
	end

	if not info then
		return false, "No such file or directory."
	end

	if info.type == "file" then
		--let's assume it's a zip/ipa/apk file, or something openable by mount
		local mount_file = love.filesystem.newFileData(file)
		local name = "__"
		local success = love.filesystem.mount(mount_file, name)
		
		if success then
			local found = look(name, "^data")
			love.filesystem.unmount(mount_file)
			
			if not found then
				return false, "Failed to find a valid data path.\nDoes the archive contain a folder called \"data?\""
			end

			return true, found:sub(name:len() + 1), mount_file
		else
			return false, "Failed to mount the file.\nIs the file a valid ZIP?"
		end
	elseif info.type == "directory" or info.type == "symlink" then
		--assume it's right
		return true, "", file
	end
end

--called after findDataPath, uses a data path
--path is the path to use, mount_file is a mountable file, base_path is the base filename for reference
function setDataPath(path, mount_file, base_path)
	--TODO: move zip handling to another file
	
	--accepts both a string and a file object
	if type(base_path) ~= "string" then
		local _, paths = resolvePath(base_path:getFilename())
		
		base_path = "dropped_"..paths[#paths]
	end
	
	path = base_path..path
	print(("Using data path \"%s\"..."):format(path))
	
	--if it's a folder then skip it
	local success = mount_file == base_path or love.filesystem.mount(mount_file, base_path)

	if success == false then --???
		return false, tostring(mount_file)..", "..tostring(base_path)
	end

	datapath = path
	datapath_base = base_path
	table.insert(mounted_paths, mount_file)
		
	openedDatapath = true

	--make a guess
	local model = guessModel(base_path)

	if model then
		gamelua.deviceModel = model
		print("Guessed device model "..tostring(model))
	end
	
	--write to autoboot.lua to make playing on mobile less of a hassle
	if mobileDevice then
		love.filesystem.write(autoboot_path,
([[--Auto-generated autoboot file.
--This file will be run and overridden on next launch.

local path = "%s"
local success, newpath, mount_path = findDataPath(path)
setDataPath(newpath, mount_path, path)]]):format(base_path))
	end
	
	savePath = "/saves/"..base_path.."/"

	return true
end

function processArgsTable(restart)
	if restart and type(restart) == "table" then
		if restart.runfilePath then
			something_runFile(restart.runfilePath[1], restart.runfilePath[2])
		end
		
		if restart.arg then
			for i, arg in ipairs(restart.arg) do
				local v = arguments[i]
				
				if v.type == "bool" then
					if arg.value then
						v.call()
					end
				elseif v.type == "string" then
					if arg.value ~= "" then
						v.call(arg.value)
					end
				end
			end
		end
	end
end

--this is only called at boot
function handleStartArgs()
	local function process(arg)
		if arg then
			local skip = 0
			for i, name in ipairs(arg) do
				if skip > 0 then
					skip = skip - 1
				else
					if name:sub(1, 1) == "+" then --run lua, alt syntax (srb2)
						debugExecute(name:sub(2))
					else
						for _, v in ipairs(arguments) do
							local matches = false
							for _, match in ipairs(v.names) do
								if match == name then
									matches = true
									break
								end
							end
							
							if matches then
								if v.call then
									v.call(unpack(arg, i + 1, i + v.args))
								end
								
								skip = v.args
								
								break
							end
						end
					end
				end
			end
		end
	end
	
	process(arg)

	processArgsTable(love.restart)
	
	--automatically boot to the last datapath on mobile systems that don't have an accessible file manager
	if mobileDevice and love.filesystem.exists(autoboot_path) and not openedDatapath and not ranAutoboot then
		ranAutoboot = true
		gamelua.runLuaFile(autoboot_path)
	end
end

function handlePostStartArgs()
	if arg then
		for i, v in ipairs(arg) do
			if v == "--skipintro" or v == "-si" then --skip splash screens
				local attempts = 20
				repeat
					if gamelua.update then gamelua.update(1, 1) end
					attempts = attempts - 1
				until love.audio.getActiveSourceCount() > 0 or gamelua.currentGameMode ~= gamelua.updateSplashes or attempts <= 0
			end
		end
	end
end

--callback upon dropping in a file
function love.filedropped(file)
	local name, paths = resolvePath(file:getFilename())
	local last_name = paths[#paths]
	
	local links = {
		{label = "Run",
			callback = function(self)
				something_runFile(file, last_name)
				debugOpen = false
				
				return true
			end,
		},
		{label = "Run Advanced...",
			callback = function(self)
				something_runFileParams(file, last_name)
				debugOpen = false
				
				return true
			end,
		},
		{label = "Copy Here",
			callback = function(self)
				if not something.on then
					openPopup("System", "Open the File Manager before doing this action.")
					
					return true
				end
				
				--allow saving it to the save directory even if the path is in the base dir
				love.filesystem.createDirectory(something.path)
				local success, message = love.filesystem.write(something.path..last_name, file:read("data"))
				
				if not success then
					openPopup("System", "Failed to copy the file.\n"..tostring(message))
					
					return true
				end
				
				--openPopup("System", "File was copied successfully.")
				something.files = something:reload(something.path)
				
				return true
			end,
		},
	}
	
	openPopup(
		"System",
		"What do you want to do with\n\""..name.."\"?",
		{
			{icon = "cross", callback = function()
				return true
			end},
		},
		false,
		function(x, y, w, h, p)
			local opened
			
			local total_height = 0
			
			for i, button in ipairs(links) do
				button.layer = button.layer or p
				opened = opened or CUI.Button(button, x + w / 2, y + 50 + (i - 1) * 90, w, 75)
				
				total_height = i * 90
			end
			
			p.h = total_height - 100
			
			return opened
		end
	)
end
