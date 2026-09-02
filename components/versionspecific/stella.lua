--stella


--stella
function gamelua.createUniqueShaders(shader, a) --scripts/Slingshot.lua
	return {}
end

function gamelua.onNotificationReceived() --scripts/notifications.lua
	return
end

function gamelua.setNotificationCallback(callback) --scripts/notifications.lua
	return
end


function gamelua.fileExistsInAppData(path) --scripts/characters.lua
	return false
end

function gamelua.copyFileFromBundleToAppData(dest, target) --scripts/characters.lua
	return
end


--Telepods is different from _G.Telepods
Telepods = {}

function Telepods.loadConfiguration(a, b) --scripts/characters.lua
	return
end


--capitalism.
--scripts/economy_parameters.lua
EconomyParameters = {}

function EconomyParameters.loadConfiguration(path) --e.g. "assets_service/economy.dat"
	return
end


function gamelua.native_getOSName() --scripts/game_init.lua
	return "Windows"
end


AnimationWrapperNative = {}

function AnimationWrapperNative.loadFromBundle(tag, a)
	return
end

function AnimationWrapperNative.clearCache()
	return
end

function AnimationWrapperNative.update(dt)
	return
end


Analytics = {}

function Analytics.logTimerEvent(a) --scripts/menus/StartSequencePage.lua
	print("Analytics.logTimerEvent(): "..tostring(a))
end

function Analytics.logEvent(a) --seasons 5.1.0
	print("Analytics.logEvent(): "..tostring(a))
end


Align = {}

function Align.getPositionAndScale(r34_4, referenceScreenX, referenceScreenY, screenWidth, screenHeight) --scripts_common/ui_components/Frame.lua
	return 0, 0, 1, 1
end


function gamelua.native_drawNotificationParticles() --gameslogics
	return
end
