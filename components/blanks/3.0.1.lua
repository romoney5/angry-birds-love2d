--classic 3.0.1 and later

function getCurrentLocale()
	return
end

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

function setThemeForegroundOffsetY(index, y)
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

--[[magicplaces = {}

function magicplaces.gameMenuInitialised()
	return true
end

function magicplaces.numOfVisitedPlaces()
	return 0
end

function magicplaces.openMapView(width, height)
	return
end]]


function setGCPopupAllowed(allowed)
	return
end

--4.0.0 pc
native = {}

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

RovioAccount.profile = {id = 0}

function loadTableFromFile(filename, tosave)
	return
end

function RovioAccount.native_isLoggedIn()
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

CloudSync = {}

function CloudSync.combineSettings(settings, settings, bool)
	return
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
	local sx = (x - screen.left) * worldScale
	local sy = (y - screen.top) * worldScale
	return sx, sy
end

function screenToWorldTransform(x, y)
	local wx = x / worldScale + screen.left
	local wy = y / worldScale + screen.top
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