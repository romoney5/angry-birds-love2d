--classic 3.0.1 and later
--functions with --? need to have their parameters/return values confirmed

function gamelua.getOSName()
	return love.system.getOS()
end

function gamelua.getOSVersion()
	return "1.0"
end

function gamelua.getModel()
	return gamelua.deviceModel
end

function gamelua.getDeviceID()
	return "00-00-00-00-00-00;00-00-00-00-00-00"
end

function gamelua.areDeviceIDsEqual(id1, id2)
	return id1 == id2
end

function gamelua.getDeviceIDHash()
	return "0"
end

function postDownloadTracking()--?
	return
end

function gamelua.checkInstalledAppsOnline(url)
	return
end

function gamelua.activateDebugConsole()
	return
end

function gamelua.deactivateDebugConsole()
	return
end


function gamelua.getCurrentTime()
	local t = os.date("*t")
	return {year = t.year, month = t.month, day = t.day, hour = t.hour, minutes = t.min, seconds = t.sec}
end

function gamelua.getStampTime(stamp)
	--months technically not accurate
	return {years = stamp / 60 / 60 / 24 / 365, months = stamp / 60 / 60 / 24 / 30, days = stamp / 60 / 60 / 24,
		hours = stamp / 60 / 60, minutes = stamp / 60, seconds = stamp}
end

function gamelua.timeToStamp(t)
	return os.time{year = t.year, month = t.month, day = t.day, hour = t.hour, min = t.minutes, sec = t.seconds}
end

function gamelua.getTimeDifferenceInSeconds(time1, time2)
	time1, time2 = gamelua.timeToStamp(time1), gamelua.timeToStamp(time2)
	
	return math.abs(time2 - time1)
end

function gamelua.getTimeDifference(time1, time2)
	time1, time2 = gamelua.timeToStamp(time1) or 0, gamelua.timeToStamp(time2) or 0
	
	return gamelua.getStampTime(math.abs(time2 - time1))
end

function gamelua.setWorldGravity(x, y)
	gravity.x, gravity.y = x, y
end

--i forgot which version this was found in

flurry = {}

function flurry.logEvent(self, text, text2)
	logFlurryEventWithParams(text, text2)
end

--3.2.0 hd ipad
RovioAds = {}

function RovioAds.show(ad)
	print("RovioAds.show(): "..ad)
end

function RovioAds.hide(ad)
	print("RovioAds.hide(): "..ad)
end

function RovioAds.addPlacement(ad)
	print("RovioAds.addPlacement(): "..ad)
end

function RovioAds.addPlacementNative(ad)
	print("RovioAds.addPlacementNative(): "..ad)
end

function RovioAds.addPlacementWithGeometry(ad, x, y, w, h) --right parameters?
	print("RovioAds.addPlacementWithGeometry(): "..ad)
end

function RovioAds.click(ad)
	print("RovioAds.click(): "..ad)
end

function RovioAds.refresh()
	return
end

function RovioAds.trackConversion()
	return
end

function RovioAds.startSession()
	return
end


function RovioAds.isAdManagerReady()
	return false
end

--hooks: adStateChanged(ad,state) adSizeChanged(ad,w,h) adOpenToons() serviceAvailable()
--onRenderableAdReady(ad) onShow(ad) onHide(ad)

--toons.tv
RovioChannel = {}

function RovioChannel.openChannelView(gameId, variant, getLocale, width, height, options, entryPoint)
	print("Opening RovioChannel")
end

function RovioChannel.isAvailable()
	return true
end

function RovioChannel.numOfNewContent()
	return 0
end

function RovioChannel.updateNewContent()
	return
end

function RovioChannel.cancelChannelViewLoading()
	return
end

function RovioChannel.onMenuInitialised()
	return
end

function RovioChannel.isChannelViewOpened()
	return false
end

function gamelua.printWarning(...)
	print(...)
end

function gamelua.printError(...)
	print(...)
end

--hooks: onChannelLoadingFailed() onRemoteNotificationReceived(view?) onChannelShown()
--notifyEventManager(?,?) onChannelClosed() onNewChannelContentUpdated(?) onServiceAvailabilityChanged()

function setRovioShelfAllowed(allowed)
	return
end

--hooks: onPaymentProviderSelected(?) onPurchaseStatusChanged(item,?) onPurchaseHistoryRetrieved(?)
--onRestoreDone(restored) onPaymentError(error)

--magic places support breaks later versions as it's not supposed to be defined
--[[
magicplaces = {}

function magicplaces.gameMenuInitialised()
	return true
end

function magicplaces.numOfVisitedPlaces()
	return 0
end

function magicplaces.openMapView(width, height)
	return
end
]]


function setGCPopupAllowed(allowed)
	return
end

--4.0.0 pc
native = native or {}

--comment this portion out to disable apprater support
-- native.apprater = {}
-- function native.apprater.showAlert(msg)
-- 	print("Apprater alert "..tostring(msg))
-- end

debugUtils = {}

function debugUtils.update(dt, realDt)
	return
end

function debugUtils.draw()
	return
end

Editor = {}

function Editor:new()
	return
end


--found in level_effects.lua
function gamelua.disableSpotlight()
	return
end


--5.0.1
native.AssetDownloader = {}

function native.AssetDownloader.requestAssetPack(pack)
	print("native.AssetDownloader.requestAssetPack: "..tostring(pack))
end

function native.AssetDownloader.isMetadataAvailable()
	print("native.AssetDownloader.isMetadataAvailable: returning true")
	return true
end

function native.AssetDownloader.hasMetadataLoadingFailed()
	print("native.AssetDownloader.hasMetadataLoadingFailed: returning false")
	return false
end

function native.AssetDownloader.wasMetadataHashUpToDateOnStartup(i) --i don't know, was it?
	print("native.AssetDownloader.wasMetadataHashUpToDateOnStartup: returning true")
	return true
end

function native.AssetDownloader.requestAssetPackItem(packId, itemId)
	print("native.AssetDownloader.requestAssetPackItem: "..packId..", "..itemId)

	if native.AssetDownloader.onAssetPackItemAvailable then
		native.AssetDownloader.onAssetPackItemAvailable(packId, itemId)
	end
end

function native.AssetDownloader.getCloudAssetLoadStatusString(a)
	print("native.AssetDownloader.getCloudAssetLoadStatusString: "..a)
	return
end

function native.AssetDownloader.loadAssetPackImage(a, b)
	return
end

function native.AssetDownloader.releaseAssetPackImage(a, b)
	return
end

function native.AssetDownloader.releaseAllAssetPackImages(a)
	return
end

local assets = {
	["force_update.zip"] = {
		["versionInfo.lua"] = {enabled = true}
	}
}

function native.AssetDownloader.loadAssetPackLuaFile(a, b, c)
	print("native.AssetDownloader.loadAssetPackLuaFile: "..tostring(a)..", "..tostring(b)..", "..tostring(c))

	local result = assets[a] and assets[a][b] or "--dummy file from native.AssetDownloader.loadAssetPackLuaFile"

	return result
end

--AssetDownloadSystem.lua injects the following callback functions into native.AssetDownloader:
--(the arguments are passed in as varargs)
--onAssetPackItemAvailable(a, b), onAssetPackItemNotAvailable(a, b), onAssetPackAvailable(a),
--onCloudAssetLoadStart(a), onCloudAssetLoadSuccess(a), onCloudAssetLoadError(a),
--onCloudMetadataLoadSuccess(), onCloudMetadataLoadError()

--i'm pretty sure 5.0.1's menu_flow.lua doesn't break on fusion due to tostring actually working properly
--vararg functions, etc.
local _tostring = tostring

function tostring(a)
	return _tostring(a)
end


function native_initializeCloudServices()
	return
end

function native_getUnlockRequestChecksum(id, code)
	return
end


--spirit account?
RovioAccount = {}

RovioAccount.profile = {id = 0, isConnectedToSocialNetwork = true, isGuest = false}

function loadTableFromFile(filename, tosave)
	return
end

function RovioAccount.native_isLoggedIn()
	return false
end

function RovioAccount.isLoggedIn()
	return false
end

function RovioAccount.native_isAvailable()--?
	return false
end

function RovioAccount.native_getProfileID()
	return 0
end

function RovioAccount.native_isLoginInProgress()
	return false
end

function RovioAccount.native_isCloudSyncInProgress()
	return false
end

function RovioAccount.shouldCloudOverwriteLocalSave()
	return false
end

function RovioAccount.isProcessing()
	return false
end

--rovio account can prevent settings.lua from saving properly
--but is also required in later (mobile) versions
-- RovioAccount = nil

CloudSync = {}

--almost certainly not right but..
function CloudSync.combineSettings(cloud, loc, bool)
	local out = {}
	
	if cloud then for k, v in pairs(cloud) do out[k] = v end end
	if loc then for k, v in pairs(loc or {}) do out[k] = v end end

	return out
end

function CloudSync.removeSyncableSettings(settings)
	return
end


function setNotificationsEnabled(enabled)
	return
end

--short fuse
function useAsBackgroundMask()--?
	return
end

--math
native.MathUtils = {}

function native.MathUtils.isPointInRect(point, rect)
	if not (point.x >= rect.x - rect.w / 2 and point.x <= rect.x + rect.w / 2) then return false end
	if not (point.y >= rect.y - rect.h / 2 and point.y <= rect.y + rect.h / 2) then return false end
	return true
end

--lifted from 1.6.3.1
function worldToPhysicsTransform(x, y)
	local px = x / physicsSimulationScale
	local py = y / physicsSimulationScale
	return px, py
end
gamelua.worldToPhysicsTransform = worldToPhysicsTransform

function worldToScreenTransform(x, y)
	local screenLeft = renderLeft
	local screenTop = renderTop
	local worldScale = renderScale
	
	local sx = (x - screenLeft) * worldScale
	local sy = (y - screenTop) * worldScale
	return sx, sy
end
gamelua.worldToScreenTransform = worldToScreenTransform

function screenToWorldTransform(x, y)
	local screenLeft = renderLeft
	local screenTop = renderTop
	
	local worldScale = renderScale
	local wx = x / worldScale + screenLeft
	local wy = y / worldScale + screenTop
	return wx, wy
end
gamelua.screenToWorldTransform = screenToWorldTransform

function physicsToWorldTransform(x, y)
	local wx = x * physicsSimulationScale
	local wy = y * physicsSimulationScale
	return wx, wy
end
gamelua.physicsToWorldTransform = physicsToWorldTransform

function physicsToScreenTransform(x, y)
	local wx, wy = physicsToWorldTransform(x, y)
	local sx, sy = worldToScreenTransform(wx, wy)
	return sx, sy
end
gamelua.physicsToScreenTransform = physicsToScreenTransform

function screenToPhysicsTransform(x, y)
	local wx, wy = screenToWorldTransform(x, y)
	local px, py = worldToPhysicsTransform(wx, wy)
	return px, py
end
gamelua.screenToPhysicsTransform = screenToPhysicsTransform

function checkObjectBounds(x, y, width, height, angle, cursorX, cursorY)	 
	local cx = cursorX - x
	local cy = cursorY - y
	
	local tcx = cx * _G.math.cos(angle) + cy * _G.math.sin(angle)
	local tcy = -cx * _G.math.sin(angle) + cy * _G.math.cos(angle)

	local halfWidth = width * 0.5
	local halfHeight = height * 0.5
	
	local left = -halfWidth
	local top = -halfHeight
	local right = halfWidth
	local bottom = halfHeight
	
	if tcx >= left and tcx < right then
		if tcy >= top and tcy < bottom then
			return true
		end
	end
	return false
end

--5.1.0
function native.loadLuaTable(filename, env, a)
	return gamelua.loadLuaFileToObject(filename, env, "")
end

function native.loadLuaScript(filename)
	gamelua.runLuaFile(gamelua.scriptPath.."/"..filename)
end


--presumably used for rmf but i'm not sure because i had this in iap.lua for WHATEVER reason
function gamelua.setOffsetedViewport(x, y)
	return
end


AnimationWrapperNative = {}

function AnimationWrapperNative.update(dt)
	return
end


ThemeSystem = {}

ThemeSystem.setTheme = gamelua.setTheme

ThemeSystem.drawBackground = gamelua.drawBackgroundNative
ThemeSystem.drawForeground = gamelua.drawForegroundNative

function ThemeSystem.getThemeLayerOffset()--?
	return {x = 0, y = 0}
end

function ThemeSystem.setThemeLayerOffset()--?
	return
end


ServerTime = {}

function ServerTime.getStatus()
	return 1
end

function ServerTime.getServerTimeInLocalTimeZone(a)
	return 1
end

function ServerTime.getServerTimeInSeconds(a)--?
	return 1
end


CameraNative = {}

--CameraNative.setCameraZoomScale = setWorldScale
function CameraNative.setCameraZoomScale(scale)
	renderScale = scale
	--setWorldScale(scale)
end
function CameraNative.setCameraTopLeft(left, top)
	renderLeft = left
	renderTop = top
	--setTopLeft(left, top)
end
CameraNative.drawGame = gamelua.drawGameNative

function CameraNative.updateGFXEffects(dt)
	return
end

function gamelua.screenToWorldDistance(x, y)
	local screenLeft = renderLeft or screen.left
	local screenTop = renderTop or screen.top
	
	local worldScale = renderScale or worldScale or 1
	local wx = x / worldScale-- + screenLeft
	local wy = y / worldScale-- + screenTop
	return wx, wy
end


function gamelua.createMaskRenderer(name, sprite, texture, collider)
	return
end

function gamelua.createRendererForGameObject(name, sprite, collider)
	return
end

function gamelua.createLuaAssetRenderer(a, b, c)
	a.luaAssetRenderer = {}
	return "a"
end

function gamelua.disposeLuaAssetRenderer(a)
	return
end

function gamelua.setObjectAsForceAdder(a)--?
	return
end


function gamelua.setObjectBodyStatic(name)
	gamelua.setObjectParameter(name, 2, 0)
end

function gamelua.setObjectBodyDynamic(name)
	gamelua.setObjectParameter(name, 2, 1)
end

function toggleZoom(a, b)--?
	wantedZoomLevel = a
end

function toggleZoom_GameLua(a, b)--?
	wantedZoomLevel = a
end

function toggleZoom2(a, b)--?
	wantedZoomLevel = a
end

--used for the slingshot camera
function gamelua.raycast(x1, y1, x2, y2)
	local hit, hit_name, hit_x, hit_y = false, nil, nil, nil

    physicsWorld:rayCast(x1, y1, x2, y2, function(fixture, x, y, xn, yn, fraction)
		local userdata = fixture and fixture:getUserData()
		local name = userdata and userdata.name

		if name then
			hit, hit_name, hit_x, hit_y = true, name, x, y

			return 0
		end
	end)

	return hit, hit_name, hit_x, hit_y
end

function raycastAll(info)
	local results = getRayCastedObjects(info)
	local hits = {}
	for i = 1, #results do
		local target = results[i]
		local dx = target.x - info.x1
		local dy = target.y - info.y1
		local dist = math.sqrt(dx*dx+dy*dy)
		table.insert(hits, {contactPointX = target.x, contactPointY = target.y, distance = dist})
	end
	
	return hits
end

native.FileSystem = {}
native.FileSystem.TYPE_FILE = "file"

function native.FileSystem.enumerate(path, a, type, recursive)
	local newpath = datapath.."/"..path
	local files = love.filesystem.getDirectoryItems(newpath)
	local output = {}
	
	for i, file in ipairs(files) do
		local filetype = love.filesystem.getInfo(newpath.."/"..file).type
		if recursive and filetype == "directory" then
			for file2, v in pairs(native.FileSystem.enumerate(path.."/"..file, a, type, recursive)) do
				output[file.."/"..file2] = v
			end
		else
			output[file] = filetype
		end
	end
	
	return output
end

--6.0.1

native.Time = {}

native.Time.Status = {STATUS_OK = 1, STATUS_FETCHING = 2,}

function native.Time.getStatus()
	return 0
end

function native.Time.getServerTime(a)
	return 0
end

function native.Time.synchronizeServerTime(a)
	return
end


native.Account = {}

native.Account.Error = nil

function native.Account.initialize()--?
	return
end

function native.Account.isLoggedIn()--?
	return false
end

function native.Account.login()--?
	return false
end

function native.Account.register()--?
	return false
end

function native.Account.getAccountId()--?
	return RovioAccount.profile.id
end


native.Notifications = {}

function native.Notifications.initialize()--?
	return
end

function native.Notifications.register()--?
	return
end

function native.Notifications.unregister()--?
	return
end


native.Cloud = {}

function native.Cloud.setLoginSucceededListener()--?
	return
end

native.RovioShelf = {}

function native.RovioShelf.initialize()
    native.RovioShelf.allow = false
	native.RovioShelf.inputCapture = false
end

function native.RovioShelf.setAllowed(isAllowed)
    native.RovioShelf.allow = isAllowed
end

function native.RovioShelf.setInputCapturing(capture)
    native.RovioShelf.inputCapture = capture
end

function native.RovioShelf.isCapturingInput()
    return false
end

function native.RovioShelf.update(dt)
end

function native.RovioShelf.render()
end

native.RovioChannel = {}

function native.RovioChannel.numOfNewContent()--?
	return 0
end

function native.RovioChannel.initialize()--?
	return
end

function native.RovioChannel.setOnShownCallback()--?
	return
end

function native.RovioChannel.setOnChannelLoadingFailed()--?
	return
end

function native.RovioChannel.setOnChannelClosed()--?
	return
end

function native.RovioChannel.setOnChannelCancelled()--?
	return
end

function native.RovioChannel.openChannelViewWithSize()--?
	return
end

function native.RovioChannel.cancelChannelViewLoading()--?
	return
end

function native.RovioChannel.isChannelViewOpened()--?
	return false
end


native.Ads = {}

function native.Ads.initialize()--?
	return
end

function native.Ads.refresh()--?
	return
end

function native.Ads.hide()--?
	return
end

function native.Ads.show()--?
	return
end


native.AgeGenderQuery = {}

function native.AgeGenderQuery.initialize()--?
	return
end


native.Storage = {}

function native.Storage.initialize()--?
	return
end


ThemeSystem.createThemeSprite = createThemeSprite
ThemeSystem.removeThemeSprite = removeThemeSprite
ThemeSystem.modifyThemeSprite = modifyThemeSprite


CLOUD_SERVER = "CLOUD_SERVER"


native.Device = {}

function native.Device.getDeviceId()
	return "0"
end

function native.Device.getAdvertisementId()
	return "0"
end


--mighty leg (6.3.0 talkweb)

native.ModernLeague = {}

function native.ModernLeague.setSeverURL()--?
	return
end

function native.ModernLeague.getTimeStamp(a)--?
	return "0000-00-00" --yyyy-mm-dd
end

function native.ModernLeague.getGlobalLeaderboard()--?
	return
end

function native.ModernLeague.getAccountId()--?
	return 0
end

function native.ModernLeague.cancelActiveCalls()--?
	return
end

function native.ModernLeague.getMessageOfTheDay()--?
	return "r"
end

function native.ModernLeague.setLoginParameters(login)--?
	return
end

function native.ModernLeague.getBoosterTimeLeft(item)
	return {days = 0, hours = 0, minutes = 0}
end


remoteConfigTable_ml = {}
remoteConfigTable_ml.VariousRules = {}


gamelua.IGCItemInfo = {}

setmetatable(gamelua.IGCItemInfo, {
	__index = function(a)
		return {iconId = "BIRD_RED", analyticsType = "", analyticsName = "", type = "dummy"}
	end
})


native.IngameCurrency = {}

function native.IngameCurrency.justSync()--?
	return
end

function native.IngameCurrency.getBoosterValue(k)
	return
end


function drawSpriteWithShader()--?
	return
end


function shortenString(a, b)--?
	return a:sub(1, b)
end


--another file?
function gamelua.setFilterGroup()--?
	return
end


--7.0.0

native.LeagueCloud = {}

function native.LeagueCloud.setLoginParams()--?
	return
end

function native.LeagueCloud.setLoginCallbacks()--?
	return
end

function native.LeagueCloud.getCurrentDay()--?
	return 0
end

function native.LeagueCloud.getLoginStatus()--?
	return
end

function native.LeagueCloud.isConnectedToFacebook()--?
	return false
end

function native.LeagueCloud.getFriendsWithData()--?
	return
end

function native.LeagueCloud.steadyTimerReset()--?
	return
end

function native.LeagueCloud.getMessageOfTheDay()--?
	return "r"
end


function native.Time.initialize()--?
	return
end


function native.RovioChannel.openChannelView()--?
	return
end


--8.0.3
function native.FileSystem.exists(path)--?
	return gamelua.checkDirectory(datapath.."/"..path)
end


function native.IngameCurrency.getIGCValue()
	return 0
end

function native.IngameCurrency.addIGCValue()--?
	return
end


function native.Account.checkTermsAndErasure()--?
	return
end


function native.ModernLeague.timeToMidnight()--?
	return 0--{days = 0, hours = 0, minutes = 0}
end

function native.ModernLeague.loadAvailableAvatars()--?
	return
end

function native.ModernLeague.isConnectedToFacebook()--?
	return false
end

function native.ModernLeague.isLoggedInFacebook()--?
	return false
end

function native.ModernLeague.getServerEnvironment()--?
	return ""
end


function setShaderToGameObject()--?
	return
end


newPlayerRules = {}

IGCKeyNames = {} --ipairs

--loaded from a file?
remoteConfigTable = {
	VariousRules = {
		unlimitedTickets = false,
	},
	
	reward_config = {
		star_rewards = {0, 0, 0},
		reward_video_multiplier = 1,
	},
	
	shopLayouts = {
		layout_currency_popup = {tabs = {}},
	},
}

EmblemConfig = {}


ShopLayoutTable = {}

ShopLayoutTable.sub_layouts = {}


native.SpecialOffer = {}

function native.SpecialOffer.hasSpecialOfferAssets()--?
	return false
end

function setShaderToGameObject(object, shader)
	local obj = objects.world[object]
	if obj then
		-- FIXME : love doesn't support the input shader format, and so the data must be parsed.
		obj.shader = love.graphics.newShader(shader)
	end
end

function gamelua.setObjectColor(object, r, g, b, a)
	local obj = objects.world[object]
	if obj then
		local r, g, b, a = r / 255, g / 255, b / 255, a / 255
		obj.colors = {r * a, g * a, b * a, a}
	end
end

function hasBody(object)
	return objects.world[object] ~= nil
end

native.luaRenderBuffer = {}
-- special drawing routine for later versions
function createLuaAssetRenderer(self, sprite, zOrder)
	local renderer = {
		sprite = sprite,
		z = zOrder,
		position = {x = 0, y = 0},
		startPosition = {x = 0, y = 0},
		angle = 0,
		scale = {x = 1, y = 1},
		visible = true,
	}

	self.luaAssetRenderer = renderer
	
	local id = tostring(self.luaAssetRenderer) .. "_" .. sprite
	native.luaRenderBuffer[id] = {owner = self, renderer = renderer}

	insertSortedByDepth(zOrder, renderer)
	
	return id
end

function disposeLuaAssetRenderer(renderId)
	local render = native.luaRenderBuffer[renderId]
	if render then
		render.owner.luaAssetRenderer = nil
		native.luaRenderBuffer[renderId] = nil
	end
end

function clearLuaAssetRender()
	for renderId, _ in pairs(native.luaRenderBuffer) do
		disposeLuaAssetRenderer(renderId)
	end
end

specialOfferMeta = {}


--time travel

function native_startURLTWPostThread()--?
	return
end


--kakao
--NOTE: showSplashScreens() must be called on launch

function res.createSystemFontWithStroke()--?
	return
end

function addLocalNotificationAfter()--?
	return
end

function removeLocalNotification(name)
	return
end

function getReceivedLocalNotifications()--?
	return
end

function clearReceivedLocalNotifications()--?
	return
end

function addTimeDifferenceToLocalTime()--?
	return
end

-- function testTournaments()--?
-- 	return
-- end

function ServerTime.getTournamentStart(a, b, c)
	return
end

function ServerTime.getServerTimeInUTC()
	return {year = 0, month = 0, day = 0, hour = 0, minutes = 0, seconds = 0}
end

function ServerTime.hasPeriodAfterTimeInUTCPassed(a, time)--?
	return true
end

function RovioAccount.native_isSocialLoginInitiated()--?
	return true
end

function RovioAccount.native_isLoginInitiated()--?
	return true
end

function RovioAccount.native_refreshFriends()--?
	return
end

function RovioAccount.native_saveFriendProfile()--?
	return
end


RovioAssetService = {}

function RovioAssetService.loadAssets(a)
	return
end


--flash animations?
function cutsceneLoad(a)--?
	return
end

function cutsceneSeek()--?
	return
end

function updateCutscene()--?
	return
end

function drawCutscene()--?
	return
end

function cutsceneSetTranslation()--?
	return
end

function cutsceneSetRotation()--?
	return
end

function cutsceneSetScale()--?
	return
end

function cutsceneClose(a)--?
	return
end

function res.getCompoSpriteEntry(composprite, sprite)
	composprite = checkSprite(composprite)

	if composprite then
		for i, v in pairs(composprite.items) do
			if v.n == sprite then
				return v
			end
		end
	end
end


RovioMessagingService = {}

function RovioMessagingService.native_syncMailbox()--?
	return
end

function RovioMessagingService.native_getReceivedMessages()--?
	return
end
