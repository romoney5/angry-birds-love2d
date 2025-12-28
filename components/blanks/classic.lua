--1.6.3.1

function logFlurryEvent(text)
	print("Logging flurry event: "..text)
end

function logFlurryEventWithParam(text,text2,text3)
	print("Logging flurry event with param: "..text..", "..text2..", "..text3)
end

function logFlurryEventWithParams(text, text2)
	print("Logging flurry event with params: "..text..", "..text2)
end

function logFlurryTimerEvent(text)
	print("Logging flurry timer event: "..text)
end


function isMouseCaptured()
	return true
end

function captureMouse(bool)
	return
end


function checkForUpdates()
	print("checkForUpdates: No updates")
end


function requestAd()
	print("Ad requested")
end

function requestVideoAd()
	print("Video Ad requested")
end

function requestAndShowVideo()
	print("Video requested")
end

function checkMainMenuAd(url)
	return
end

function native_requestBannerAd()
	print("Banner Ad requested")
end

function native_requestExpandableAd()
	print("Expandable Ad requested")
end

function native_requestInterstitialAd()
	requestVideoAd()
end


function avoidCrystalBackgroundActivity(avoid)
	return
end


function setEditing(isediting)
	return
end

--hatchery

function requestCurrentTimeOnServer()
	return
end

function hasLocationCapability()
	return false
end

--1.7.0

function initGameCenter()
	return
end

function showLeaderboards()
	return
end

function requestBannerAd()
	print("Banner Ad requested")
end

function requestExpandableAd()
	print("Expandable Ad requested")
end

function requestInterstitialAd()
	requestVideoAd()
end

--found in ghidra: addNotificationAfter(float,int,string) removeNotification(string) removeAllNotifications()
--setNotificationCallback(function,string) hasLocationCapability()=0 openProgram(string)=bool
--canOpenProgram(string)=bool getManufacturer()=? printGlobals() playVideo(string) setMaxTranslation(float)
--other hatchery functions