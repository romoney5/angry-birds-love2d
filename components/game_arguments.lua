--handles arguments passed to love at the start of the game, as well as other post-start arguments

local identity = love.filesystem.getIdentity()

autoboot_path = "autoboot.lua"

arguments = {
	{display = "Delete Data", names = {"--deletedata", "-dd"}, args = 0, type = "bool", call = function()
		print("Opening data deletion prompt...")
		
		openPopup("Data",
			"Delete save data?\nThis will reset all progress in the current data path!",
			{
				{sprite = "MENU_NO", callback = function()
					return true
				end},
				{sprite = "TUTORIAL_OK", callback = function()
					local success1 = love.filesystem.remove("settings.lua")
					local success2 = love.filesystem.remove("highscores.lua")
					if success1 or success2 then
						openPopup("Data", "Successfully deleted save data.", nil, true)
					elseif not checkDirectory("settings.lua") and not checkDirectory("highscores.lua") then
						openPopup("Data", "There is no existing save data.", nil, true)
					else
						openPopup("Data", "Could not properly delete save data.", nil, true)
					end
					settings, highscores = {}, {}

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
			openPopup("dec", "Could not clear the \"".."dec".."\"folder.")
		else
			print("Cleared dec/")
		end
	end},
	
	{display = "Device Model", names = {"--model", "-m"}, args = 1, type = "string", call = function(arg1)
		deviceModel = arg1 or deviceModel
	end},
	
	{display = "Data Path", names = {"--datapath", "-dp"}, args = 1, type = "string", call = function(arg1)
		setDataPathFromFile(arg1 or datapath)
	end},
	
	{display = "Blame Length", names = {"--blamelength", "-bl"}, args = 1, type = "number", call = function(arg1)
		fione_errorblame_length = tonumber(arg1) or fione_errorblame_length
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
		queueCheatsEnabled = true --filesystem.lua
	end},
}

function setDataPathFromFile(file)
	--TODO: move zip handling to another file
	love.filesystem.setIdentity(identity)
	local info = love.filesystem.getInfo(file)
	if info and info.type == "file" then
		print("Opening \""..file.."\" as a ZIP file...")
		
		--let's assume it's a zip/ipa/apk file
		local src = love.filesystem.newFileData(file)
		local success = love.filesystem.mount(src, file)

		datapath = file
		if success then
			--look recursively for a data folder,
			--it varies between pc installations, ipas, and apks
			local function look(dir, target)
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
			
			--make a guess
			--TODO: make a better guess by looking at the binary
			if endsWith(datapath, ".ipa") then
				deviceModel = "iphone"
			elseif endsWith(datapath, ".apk") then
				deviceModel = "android"
			end
			
			local found = look(datapath, "^data")
			
			if not found then
				love.filesystem.unmount(file)
				return false
			end
			
			datapath = found

			openedDatapath = true
		else
			return false
		end
	elseif info and (info.type == "directory" or info.type == "symlink") then
		print("Opening \""..file.."\" as a folder...")
		if file ~= "" then
			openedDatapath = true
		end
		
		datapath = file
	else
		datapath = file
		
		return false
	end
	
	--write to autoboot.lua to make playing on mobile less of a hassle
	if mobileDevice then
		love.filesystem.write(autoboot_path,
([[--Auto-generated autoboot file.
--This file will be run and overridden on next launch.
setDataPathFromFile("%s")]]):format(file))
	end
	
	if file ~= "data" and file ~= "" then
		love.filesystem.setIdentity(identity.."/DATA_"..file)
	end

	return true
end

function processArgsTable(restart)
	if restart and type(restart) == "table" then
		if restart.runfilePath then
			setDataPathFromFile(restart.runfilePath or datapath)
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
	
	--automatically boot to the last datapath on mobile systems that don't have an accessible file manager
	if mobileDevice and checkDirectory(autoboot_path) and not openedDatapath then
		ranAutoboot = true
		loadLuaFile(autoboot_path)
	end
	
	process(arg)

	processArgsTable(love.restart)
end

function handlePostStartArgs()
	if arg then
		for i,v in ipairs(arg) do
			if v == "--skipintro" or v == "-si" then --skip splash screens
				local attempts = 20
				repeat
					update(1, 1)
					attempts = attempts - 1
				until love.audio.getActiveSourceCount() > 0 or currentGameMode ~= updateSplashes or attempts <= 0
			end
		end
	end
end
