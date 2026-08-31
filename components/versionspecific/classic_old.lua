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


function isMouseCaptured()
	return true
end

function captureMouse(bool)
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

function native_requestBannerAd()
	return
end

function native_requestExpandableAd()
	return
end

function native_requestInterstitialAd()
	print("native_requestInterstitialAd() called")
end


function avoidCrystalBackgroundActivity(avoid)
	return
end


function gamelua.setEditing(enabled)
	return
end

--hatchery, in-between 1.6.3 and 2.0.0

function requestCurrentTimeOnServer()
	return
end

function hasLocationCapability()
	return false
end

function wasKeyReleased(key)
	return keyReleased[key]
end

--1.7.0

function initGameCenter()
	return
end

function showLeaderboards()
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
function addNotificationAfter(id, time, text)
	print("addNotificationAfter(): queued notification \""..tostring(id).."\" after "..(tonumber(time) or 0) / (60).." minutes:\n"..tostring(text))
end

function removeNotification(id)
	print("removeNotification(): removed notification \""..tostring(id).."\"")
end

function removeAllNotifications()
	print("removeAllNotifications() called")
end

--crystal
function isCrystalUIShowing()
	return false
end

function activateCrystalUI()
	return
end

function deactivateCrystalUI()
	return
end

function showCrystalSplash()
	return
end

function userEnabledCrystal()
	return true
end

function activateCrystalUIAtProfile()
	return
end

function unlockAchievement(id, desc)
	return
end


--2.2.0 registration

function verifyDeviceID(hwid)
	return true
end