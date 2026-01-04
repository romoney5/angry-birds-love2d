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

function checkInstalledAppsOnline(url)
	return
end

function setChannelCountLimit(channel,limit)
	return
end

function loadParticleFile() --it's already loaded though
	return
end

function clearParticles()
	return
end

function drawMenuParticlesInAdvance() --what is it with particles
	return
end

function activateDebugConsole()
	return
end

function resizeCircle(name, radius)
	local obj = objects.world[name]
	local x, y = obj.body:getPosition()
	removeObject(name)

	if obj.body then
		createCircle(name, obj.sprite, x, y, radius, obj.density, obj.friction, obj.restitution, obj.controllable, obj.z_order)
		objects.world[name].definition = obj.definition
		objects.world[name].strength = obj.strength
		objects.world[name].defence = obj.defence
		objects.world[name].damageSprite = obj.sprite
		setRotation(name, obj.angle)
		setVelocity(name, obj.xVel, obj.yVel)
		setMaterial(name, obj.material)
		if obj.controllable then
			objects.world[name].animTimer = obj.animTimer
			objects.world[name].jumpTimer = obj.jumpTimer
			objects.world[name].shot = obj.shot
			objects.world[name].damageFactors = obj.damageFactors
			objects.world[name].useLegacyCollisionPath = obj.useLegacyCollisionPath
			objects.world[name].recordTrajectory = obj.recordTrajectory
			birds[name] = objects.world[name]
			if flyingBird ~= nil and flyingBird.name == name then
				flyingBird = birds[name]
			end
		end
	end
end

function setScale(name, scale)
	local fixture = objects.world[name].fixture
	local userData = fixture:getUserData()
	userData.scale = scale
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

--TODO: iap.lua?
Payment = {}

function Payment.iapInitPayment()
	print("Init IAP payment")
end

function Payment.iapHasPaymentProvider()
	return true
end

Payment.iapBuyItem = iapBuyItem
Payment.iapRestoreItems = iapRestoreItems

function Payment.getIapProducts()
	return {} --price:string
end

--hooks: onPaymentProviderSelected(?) onPurchaseStatusChanged(item,?) onPurchaseHistoryRetrieved(?)
--onRestoreDone(restored) onPaymentError(error)

magicplaces = {}

function magicplaces.gameMenuInitialised()
	return
end

function magicplaces.numOfVisitedPlaces()
	return 0
end


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