--below 3.x misc functions, most of these are dummies for long-dead online features

function gamelua.logFlurryEvent(text)
	print("Logging flurry event: "..text)
end

function gamelua.logFlurryEventWithParam(text,text2,text3)
	print("Logging flurry event with param: "..text..", "..text2..", "..text3)
end

function gamelua.logFlurryEventWithParams(text, text2)
	print("Logging flurry event with params: "..text..", "..text2)
end

function gamelua.logFlurryTimerEvent(text)
	print("Logging flurry timer event: "..text)
end


function gamelua.isMouseCaptured()
	return true
end

function gamelua.captureMouse(bool)
	return
end


function gamelua.checkForUpdates()
	print("checkForUpdates() called")
end


function gamelua.requestAd()
	print("requestAd() called")
end

function gamelua.requestVideoAd()
	print("requestVideoAd() called")
end

function gamelua.requestAndShowVideo()
	print("requestAndShowVideo() called")
end

function gamelua.checkMainMenuAd(url)
	return
end

function gamelua.native_requestBannerAd()
	return
end

function gamelua.native_requestExpandableAd()
	return
end

function gamelua.native_requestInterstitialAd()
	print("native_requestInterstitialAd() called")
end


function gamelua.avoidCrystalBackgroundActivity(avoid)
	return
end


local editing = false

function gamelua.setEditing(enabled)
	editing = enabled
end

function gamelua.isEditing()
	return editing
end

--hatchery, in-between 1.6.3 and 2.0.0

function gamelua.requestCurrentTimeOnServer()
	return
end

function gamelua.hasLocationCapability()
	return false
end

function gamelua.wasKeyReleased(key)
	return keyReleased[key]
end

--1.7.0

function gamelua.initGameCenter()
	return
end

function gamelua.showLeaderboards()
	return
end

function gamelua.requestBannerAd()
	print("requestBannerAd() called")
end

function gamelua.requestExpandableAd()
	print("requestExpandableAd() called")
end

function gamelua.requestInterstitialAd()
	print("requestInterstitialAd() called")
end

--found in ghidra but seemingly unused:
--setNotificationCallback(function,string) hasLocationCapability()=0 openProgram(string)=bool
--canOpenProgram(string)=bool getManufacturer()=? printGlobals() playVideo(string)
--other hatchery functions

--notifications
function gamelua.addNotificationAfter(id, time, text)
	print("addNotificationAfter(): queued notification \""..tostring(id).."\" after "..(tonumber(time) or 0) / (60).." minutes:\n"..tostring(text))
end

function gamelua.removeNotification(id)
	print("removeNotification(): removed notification \""..tostring(id).."\"")
end

function gamelua.removeAllNotifications()
	print("removeAllNotifications() called")
end

--crystal
function gamelua.isCrystalUIShowing()
	return false
end

function gamelua.activateCrystalUI()
	return
end

function gamelua.deactivateCrystalUI()
	return
end

function gamelua.showCrystalSplash()
	return
end

function gamelua.userEnabledCrystal()
	return true
end

function gamelua.activateCrystalUIAtProfile()
	return
end

function gamelua.unlockAchievement(id, desc)
	return
end


--2.2.0 registration

function gamelua.verifyDeviceID(hwid)
	return true
end

--enable/disable screensaver
function gamelua.setGameOn(on)
	love.window.setDisplaySleepEnabled(not on)
end

local registered
function gamelua.openRegistrationDialog(message, validationURL, registrationURL, fullGame)
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

gamelua.registerKey = gamelua.openRegistrationDialog
--returns finished, valid
function gamelua.checkRegistrationResult()
	local finished = openPopups[1] == nil
	local valid = registered
	registered = nil
	return finished, valid
end

function gamelua.requestExit()
	print("Quitting...")
	love.event.quit()
end

--unknown source
function gamelua.setLevelEffects(theme)
	return
end

function gamelua.updateLevelEffects(dt, realDt) --right parameters?
	return
end
