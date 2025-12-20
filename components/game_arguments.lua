--handles arguments passed to love at the start of the game

function handleStartArgs()
	if arg then
		for i,v in pairs(arg) do
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
								showPopup("Data", "Successfully deleted settings and highscores.")
							else
								showPopup("Data", "Could not properly delete settings and/or highscores.")
							end
							currentPopup.important = true
							settings, highscores = {}, {}
						end},
					}
				)
				currentPopup.important = true
			elseif v == "--model" or v == "-m" then --override deviceModel
				deviceModel = arg[i + 1] or deviceModel
			--elseif v == "--makeimages" or v == "-mi" then --remake image cache (same as deletecache?) TODO: sprite groups were implemented in the og game for a reason
				--makeImages(true, arg[i + 1])
			end
		end
	end
end

function handlePostStartArgs()
	if arg then
		for i,v in pairs(arg) do
			if v == "--skipintro" or v == "-si" then
				local attempts = 20
				repeat
					update(1, 1)
					attempts = attempts - 1
				until love.audio.getActiveSourceCount() > 0 or currentGameMode ~= updateSplashes or attempts <= 0
			end
		end
	end
end