--classic 3.0.1 and later
--functions with --? need to have their parameters/return values confirmed

function getOSName()
	return love.system.getOS()
end

function getOSVersion()
	return "1.0"
end

function getModel()
	return deviceModel
end

function getDeviceIDHash()
	return "0"
end

function postDownloadTracking()--?
	return
end

function checkInstalledAppsOnline(url)
	return
end

function setChannelCountLimit(channel,limit)
	return
end

function activateDebugConsole()
	return
end

function deactivateDebugConsole()
	return
end

--3.2.0 hd ipad
RovioAds = {}

function RovioAds.show(ad)
	print("Showing RovioAd "..ad)
end

function RovioAds.hide(ad)
	print("Hiding RovioAd "..ad)
end

function RovioAds.addPlacement(ad)
	print("Placing RovioAd "..ad)
end

function RovioAds.addPlacementNative(ad)
	print("Placing RovioAd "..ad)
end

function RovioAds.addPlacementWithGeometry(ad, x, y, w, h) --right parameters?
	print("Placing RovioAd "..ad)
end

function RovioAds.click(ad)
	print("Clicking RovioAd "..ad)
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

function printWarning(...)
	print(...)
end

function printError(...)
	print(...)
end

--hooks: onChannelLoadingFailed() onRemoteNotificationReceived(view?) onChannelShown()
--notifyEventManager(?,?) onChannelClosed() onNewChannelContentUpdated(?) onServiceAvailabilityChanged()

function setRovioShelfAllowed(allowed)
	return
end

--hooks: onPaymentProviderSelected(?) onPurchaseStatusChanged(item,?) onPurchaseHistoryRetrieved(?)
--onRestoreDone(restored) onPaymentError(error)

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

--magic places breaks later versions
magicplaces = nil


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


function disableSpotlight()
	return
end


--5.0.1
native.AssetDownloader = {}

function native.AssetDownloader:requestAssetPack(pack)
	print("requestAssetPack: "..tostring(pack))
end

function native.AssetDownloader:isMetadataAvailable()
	return false
end

function native.AssetDownloader:hasMetadataLoadingFailed()
	return true
end

function native.AssetDownloader.wasMetadataHashUpToDateOnStartup(i) --i don't know, was it?
	return true
end

function native.AssetDownloader.requestAssetPackItem(a, itemId)
	return
end

function native.AssetDownloader.getCloudAssetLoadStatusString(a)
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

function native.AssetDownloader.loadAssetPackLuaFile(a, b, c)
	return
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


function isEditing()
	return false
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
	local px = x * physicsScale
	local py = y * physicsScale
	return px, py
end

function worldToScreenTransform(x, y)
	local screenLeft = renderLeft or screen.left
	local screenTop = renderTop or screen.top
	local worldScale = renderScale or worldScale or 1
	
	local sx = (x - screenLeft) * worldScale
	local sy = (y - screenTop) * worldScale
	return sx, sy
end

function screenToWorldTransform(x, y)
	local screenLeft = renderLeft or screen.left
	local screenTop = renderTop or screen.top
	
	local worldScale = renderScale or worldScale or 1
	local wx = x / worldScale + screenLeft
	local wy = y / worldScale + screenTop
	return wx, wy
end

function physicsToWorldTransform(x, y)
	local wx = x * physicsToWorld
	local wy = y * physicsToWorld
	return wx, wy
end

function physicsToScreenTransform(x, y)
	local wx, wy = physicsToWorldTransform(x, y)
	local sx, sy = worldToScreenTransform(wx, wy)
	return sx, sy
end

function screenToPhysicsTransform(x, y)
	local wx, wy = screenToWorldTransform(x, y)
	local px, py = worldToPhysicsTransform(wx, wy)
	return px, py
end

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
	return loadLuaFileToObject(filename, env, "")
end

function native.loadLuaScript(filename)
	runLuaFile(scriptPath.."/"..filename)
end


AnimationWrapperNative = {}

function AnimationWrapperNative.update(dt)
	return
end


ThemeSystem = {}

ThemeSystem.setTheme = setTheme

ThemeSystem.drawBackground = drawBackgroundNative
ThemeSystem.drawForeground = drawForegroundNative

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
CameraNative.drawGame = drawGameNative

function CameraNative.updateGFXEffects(dt)
	return
end

function screenToWorldDistance(x, y)
	local screenLeft = renderLeft or screen.left
	local screenTop = renderTop or screen.top
	
	local worldScale = renderScale or worldScale or 1
	local wx = x / worldScale-- + screenLeft
	local wy = y / worldScale-- + screenTop
	return wx, wy
end


function createMaskRenderer(name, sprite, texture, collider)
	return
end

function createRendererForGameObject(name, sprite, collider)
	return
end

function createLuaAssetRenderer(a, b, c)
	a.luaAssetRenderer = {}
	return "a"
end

function disposeLuaAssetRenderer(a)
	return
end

function setObjectAsForceAdder(a)--?
	return
end


function setObjectBodyStatic(name)
	setObjectParameter(name, 2, 0)
end

function setObjectBodyDynamic(name)
	setObjectParameter(name, 2, 1)
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


function raycast(x1, y1, x2, y2)
	local hit, name, px, py
	local ray = getRayCastedObjects{x1 = x1, y1 = y1, x2 = x2, y2 = y2}
	hit = ray[1] ~= nil
	name, px, py = ray[1], ray[2], ray[3]
	return hit, name, px, py
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


--stella
function createUniqueShaders(shader, a)
	return {}
end

function onNotificationReceived()
	return
end

function setNotificationCallback(callback)
	return
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
native.RovioShelf.__index = native.RovioShelf

function native.RovioShelf:initialize()
    self.allow = false
	self.inputCapture = false
end

function native.RovioShelf:setAllowed(isAllowed)
    self.allow = isAllowed
end

function native.RovioShelf:setInputCapturing(capture)
    self.inputCapture = capture
end

function native.RovioShelf:isCapturingInput()
    return false
end

function native.RovioShelf:update(dt)
end

function native.RovioShelf:render()
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


IGCItemInfo = {}

setmetatable(IGCItemInfo, {
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
function setFilterGroup()--?
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
	return checkDirectory(datapath.."/"..path)
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

function setObjectColor()--?
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

function setObjectColor(object, r, g, b, a)
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
	objectsSorted = false
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