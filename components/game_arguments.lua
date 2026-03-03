--handles arguments passed to love at the start of the game

function handleStartArgs()
	if arg then
		for i,v in ipairs(arg) do
			if v == "--deletedata" or v == "-dd" then --delete all save data
				print("Opening data deletion prompt...")
				
				showPopup("Data",
					"Delete save data?\nThis will reset all progress in the current data path!",
					{
						{sprite = "MENU_NO", callback = function()
							return true
						end},
						{sprite = "TUTORIAL_OK", callback = function()
							local success1 = love.filesystem.remove("settings.lua")
							local success2 = love.filesystem.remove("highscores.lua")
							if success1 or success2 then
								showPopup("Data", "Successfully deleted save data.", nil, true)
							elseif not checkDirectory("settings.lua") and not checkDirectory("highscores.lua") then
								showPopup("Data", "Save data does not exist.", nil, true)
							else
								showPopup("Data", "Could not properly delete save data.", nil, true)
							end
							settings, highscores = {}, {}

							return true
						end},
					}
				, true)
			elseif v == "--model" or v == "-m" then --override deviceModel
				deviceModel = arg[i + 1] or deviceModel
			elseif v == "--datapath" or v == "-dp" then --override datapath and set save directory
				datapath = arg[i + 1] or datapath
				love.filesystem.setIdentity(love.filesystem.getIdentity().."/DATA_"..datapath)

				--TODO: move zip handling to another file
				local info = love.filesystem.getInfo(datapath)
				if info and info.type == "file" then
					print("Opening \""..datapath.."\" as a ZIP file...")
					
					--let's assume it's a zip/ipa/apk file
					local src = love.filesystem.newFileData(datapath)
					local success = love.filesystem.mount(src, datapath)

					if success then
						datapath = datapath

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
						if endsWith(datapath, ".ipa") then
							deviceModel = "iphone"
						elseif endsWith(datapath, ".apk") then
							deviceModel = "android"
						end
						
						datapath = look(datapath, "^data")
					end
				end
			elseif v == "--blamelength" or v == "-bl" then --length of fione bytecode traceback (disabled by default)
				fione_errorblame_length = tonumber(arg[i + 1]) or fione_errorblame_length
			elseif v == "--nosave" or v == "-ns" then --prevent saving any data
				disableSaving = true
			elseif v == "--run" then --run lua
				debugExecute(arg[i + 1] or "")
			elseif v:sub(1, 1) == "+" then --run lua, alt syntax (srb2)
				debugExecute(v:sub(2))
			elseif v == "--cheats" or v == "-c" then
				--[[releaseBuild = false
				showEditor = true]]
				queueCheatsEnabled = true --filesystem.lua
			end
		end
	end
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