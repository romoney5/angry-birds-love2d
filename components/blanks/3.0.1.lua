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

--rovio account can prevent settings.lua from saving properly
--but is also required in later (mobile) versions
-- RovioAccount = nil

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
	return
end


CameraNative = {}

CameraNative.setCameraZoomScale = setWorldScale
CameraNative.setCameraTopLeft = setTopLeft
CameraNative.drawGame = drawGameNative

function CameraNative.updateGFXEffects(dt)
	return
end

screenToWorldDistance = screenToWorldTransform


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


function raycast(x1, y1, x2, y2)
	return getRayCastedObjects{x1 = x1, y1 = y1, x2 = x2, y2 = y2}
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
-- seasons 4.2.0
NativePlatformScore = {}

function NativePlatformScore.getPerformanceScore()
    return 100 
end

function NativePlatformScore.getMemoryScore()
    return 100 
end

function createDynamicHandler(name)
	local handler = {}
	
	local function load(group)
		assert(profile)
		if loadlist[group] then
			for i, v in pairs(loadlist[group]) do
				res.createSpriteSheet(imagePath.."/"..profile.."/"..v..".dat")
			end
		end
	end
	
	function handler.addreq(...)
		print("addreq")
		for i, v in pairs{...} do
			if type(v) == "table" then
				for i, v in pairs(v) do
					loadlist[i] = v
				end
			end
		end
		for i, v in pairs{...} do
			if type(v) == "table" then
				print(i..":")
				for i, v in pairs(v) do
					if type(v) == "table" then
						print("", i..":")
						for i, v in pairs(v) do
							print("", "", i, v)
						end
					else
						print("", i, v)
					end
				end
			else
				print(v)
			end
		end
		return 
	end
	
	function handler.getRequirements(...)
		print("getRequirements")
		return {} 
    end
	
	function handler:delayrelease(...) end

	function handler.load(...)
		profile = (selectAssetProfile and selectAssetProfile()) or (platform and platform.Profiles and platform.Profiles.selectAssetProfile and platform.Profiles.selectAssetProfile())
		print("profile", profile)
		print("loading", ...)
		for i, v in pairs{...} do
			if type(v) == "table" then
				for i, v in pairs(v) do
					load(v)
				end
			else
				load(v)
			end
		end
	end
	function handler:release(...) end
	function handler:isLoaded(...) return true end

	_G[name] = handler
	
	return handler
end

function flashAnimationPreLoad()--?
	return
end

function getCameraTopLeft()--?
	return screen.top, screen.left
end

function setCameraViewport(a, b, c, d)--?
	return
end

native.GetTimeStamp = {}

function native.GetTimeStamp.fetchTimeStamp()--?
	return 0
end

function native.GetTimeStamp.hasResult()
	return false
end

cloudDomain = ""