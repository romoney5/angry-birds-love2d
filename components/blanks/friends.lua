--amigos

facebook = {}

function facebook.setTournamentTimeoutCallback()--?
	print("facebook.setTournamentTimeoutCallback")
	return
end

function facebook.setProfilePictureCallback()--?
	print("facebook.setProfilePictureCallback")
	return
end

function res.getAvailableSystemFonts()--?
	return {}
end

function res.createSystemFont()--?
	return
end

function facebook.setErrorCallback()--?
	print("facebook.setErrorCallback")
	return
end

function facebook.setVersionUpdateCallback()--?
	print("facebook.setVersionUpdateCallback")
	return
end

function facebook.setStartupFailCallback()--?
	print("facebook.setStartupFailCallback")
	return
end

function facebook.setNetworkRetryViewCallback(a)--?
	print("facebook.setNetworkRetryViewCallback")
	a()
	return
end

function facebook.testNetwork()--?
	print("facebook.testNetwork")
	return false
end

function facebook.isOnlineMode()--?
	print("facebook.isOnlineMode")
	return false
end

function facebook.hasToken()--?
	print("facebook.hasToken")
	return false
end

function facebook.isFacebookSessionOpen()--?
	print("facebook.isFacebookSessionOpen")
	return false
end

function facebook.startOfflineSession(callback)
	print("facebook.startOfflineSession")
	callback()
end

function facebook.openFacebookSession(callback)--?
	print("facebook.openFacebookSession")
	callback(true)
end

function facebook.getStoredUser()--?
	print("facebook.getStoredUser")
	return
end

function facebook.resolveIdentity(callback)--?
	print("facebook.resolveIdentity")
	--resolved
	callback(true)
end

function facebook.initTournament(callback)--?
	print("facebook.initTournament")
	--success
	callback(true)
end

function facebook.refreshTournament(callback)
	print("facebook.refreshTournament")
	-- error()
	--success
	callback(true)
end

function facebook.isUnknownMode()
	print("facebook.refreshTournament")
	return false
end

function facebook.getTournamentLevels()
	print("facebook.getTournamentLevels")
	return {levels = {{code = "2000-1"}}}
end

function facebook.useDynamicLevelLoading()
	print("facebook.useDynamicLevelLoading")
	return true
end

function facebook.getNumberOfPendingGifts()--?
	print("facebook.getNumberOfPendingGifts")
	return 0
end

function facebook.getNumberOfPendingBrags()--?
	print("facebook.getNumberOfPendingBrags")
	return 0
end

function facebook.setTournamentPlayerUpdateCallback(callback)--?
	print("facebook.setTournamentPlayerUpdateCallback")
	callback()
	return
end

function facebook.removeTournamentPlayerUpdateCallback()--?
	print("facebook.removeTournamentPlayerUpdateCallback")
	return
end

function facebook.pollRequests()--?
	print("facebook.pollRequests")
	return
end

function facebook.hasDailyReward()--?
	print("facebook.hasDailyReward")
	return false
end

function facebook.getTournamentScoreCount()--?
	print("facebook.getTournamentScoreCount")
	return 0
end

function facebook.getTournamentScores()--?
	print("facebook.getTournamentScores")
	return {}
end

function facebook.getOwnUserInfo()--?
	print("facebook.getOwnUserInfo")
	return {id = 1}
end

function facebook.hasLastTournamentResult()--?
	print("facebook.hasLastTournamentResult")
	return false
end

function facebook.leaveCurrentGameSession()--?
	print("facebook.leaveCurrentGameSession")
	return
end

tutorial = {}

function tutorial.getState()
	return 0 --START
end

function tutorial.isTutorialMode()
	return true
end