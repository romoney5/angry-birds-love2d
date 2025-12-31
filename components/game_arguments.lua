--handles arguments passed to love at the start of the game

function handleStartArgs()
	if arg then
		for i,v in ipairs(arg) do
			if v == "--deletedata" or v == "-dd" then --delete all save data
				print("Opening data deletion prompt...")
				
				showPopup("Data",
					"Delete all data?\nThis will reset all progress!",
					{
						{sprite = "MENU_NO", callback = function()
							return true
						end},
						{sprite = "TUTORIAL_OK", callback = function()
							local success1 = love.filesystem.remove("settings.lua")
							local success2 = love.filesystem.remove("highscores.lua")
							if success1 and success2 then
								showPopup("Data", "Successfully deleted settings and highscores.", nil, true)
							else
								showPopup("Data", "Could not properly delete settings and/or highscores.", nil, true)
							end
							settings, highscores = {}, {}

							return true
						end},
					}
				, true)
			elseif v == "--model" or v == "-m" then --override deviceModel
				deviceModel = arg[i + 1] or deviceModel
			elseif v == "--gamelogic" or v == "-gl" then --override gamelogic.lua path
				gamelogicPath = arg[i + 1] or gamelogicPath
			elseif v == "--datapath" or v == "-dp" then --override datapath and set save directory
				datapath = arg[i + 1] or datapath
				love.filesystem.setIdentity(love.filesystem.getIdentity().."/DATA_"..datapath)
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
			elseif v == "--run" then --run lua
				debugExecute(arg[i + 1] or "")
			elseif v:sub(1, 1) == "+" then --run lua, alt syntax (srb2)
				debugExecute(v:sub(2))
			end
		end
	end
end