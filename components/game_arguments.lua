--handles arguments passed to love at the start of the game

function handleStartArgs()
	if arg then
		for i,v in pairs(arg) do
			if v == "--deletecache" or v == "-dc" then
				print("Opening delete spriteinfo prompt..")

				local msg = love.window.showMessageBox(love.window.getTitle(), "Really delete spriteinfo.lua?", {"OK", "Cancel", enterbutton = 1, escapebutton = 2}, "warning")
				if msg == 1 then
					local success = love.filesystem.remove("spriteinfo.lua")
					if success then
						love.window.showMessageBox(love.window.getTitle(), "Successfully deleted spriteinfo.lua", "info")
					else
						love.window.showMessageBox(love.window.getTitle(), "Could not delete spriteinfo.lua.", "error")
					end
				end
			elseif v == "--deletedata" or v == "--dd" then
				print("Opening delete data prompt..")
				
				showPopup("Data",
					"Really delete data?\nThis will reset all of your progress!",
					{
						{sprite = "MENU_NO", callback = function()
							return true
						end},
						{sprite = "TUTORIAL_OK", callback = function()
							settings,highscores = {},{}
							local success1 = love.filesystem.remove("settings.lua")
							local success2 = love.filesystem.remove("highscores.lua")
							if success1 and success2 then
								showPopup("Data","Successfully deleted settings and highscores.",true)
							else
								showPopup("Data","Could not properly delete settings and/or highscores.",true)
							end
							currentPopup.important = true
						end},
					}
				) currentPopup.important = true
			elseif v == "--model" or v == "-m" then
				deviceModel = arg[i+1] or deviceModel
			elseif v == "--makeimages" or v == "-mi" then
				makeImages(true,arg[i+1])
			end
		end
	end
end

function handlePostStartArgs()
	if arg then
		for i,v in pairs(arg) do
			if v == "--skipintro" then
				repeat
					update(1,1)
				until love.audio.getActiveSourceCount()>0 or currentGameMode ~= updateSplashes
			end
		end
	end
end