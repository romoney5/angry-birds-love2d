-- seasons 4.2.0

local isOffline = true

NativePlatformScore = {}

function NativePlatformScore.getPerformanceScore()
    return 2 
end

function NativePlatformScore.getMemoryScore()
    return 2 
end

--dynamic assets handler, this was also used for classic but seasons did it way earlier so it's here
function gamelua.createDynamicHandler(name)
	local handler = {}
	local requirements = {}
	
	--selectAssetProfile and Profiles.selectAssetProfile are actually found in the binary
	--right next to other dynamic handler strings in fact
	local selectAssetProfile = gamelua.selectAssetProfile or (_G.platform and _G.platform.Profiles and _G.platform.Profiles.selectAssetProfile)

	--ONLY seasons 4.2.0 uses neatLoadlist
	local loadlists = {loadlist = {}, neatLoadlist = {}}
	local loadlistNames = {"loadlist", "neatLoadlist"}

	local ingameLoadlist --hacky; for loadInGame
	local ingameProfile --hacky; for loadInGame
	
	local graphics_stats = {} --for love.graphics.getStats()
	
	--loads spritesheets from a table
	--TODO: queue and asset freeing
	local function loadFromLoadlist(list, profile, group)
		print("loadFromLoadlist():", profile, group)
		for _, asset in ipairs(list[group]) do
			if asset[2] ~= 1 then
				res.createSpriteSheet(gamelua.imagePath.."/"..profile.."/"..asset[1])
			else
				res.createCompoSpriteSet(gamelua.imagePath.."/"..profile.."/"..asset[1])
			end
		end
	end
	
	local function load(group)
		if requirements[group] then
			for i, v in pairs(requirements[group]) do
				local profile = selectAssetProfile(v)
				
				for i, list_name in ipairs(loadlistNames) do
					if not loadlists[list_name][profile] then
						gamelua.loadLuaFile(gamelua.imagePath.."/"..profile.."/"..list_name..".lua")

						if gamelua.assetLoadList then
							loadlists[list_name][profile] = gamelua.assetLoadList[profile]
						end
					end

					local dat = loadlists[list_name] and loadlists[list_name][profile]
					
					if dat and dat[v] then
						loadFromLoadlist(dat, profile, v)

						if not ingameLoadlist and dat.INGAME then
							ingameLoadlist = dat
							ingameProfile = profile
							--print("handler.load(): ingame is "..tostring(ingameLoadlist))
						end
					end
				end
			end
		end
	end
	
	--[[e.g. [1] = {
		["theme27"] = {
			"THEME_CHERRY",
		},
		["theme16"] = {
			"THEME_HALLOWEEN",
		},
		["theme28"] = {
			"THEME_MOVIE",
		},
	]]
	function handler.addreq(...)
		print("handler.addreq: ".."{\n"..serializeTable{...}.."}")
		
		for i, v in pairs{...} do
			if type(v) == "table" then
				for i, v in pairs(v) do
					requirements[i] = v
				end
			end
		end
		
		return
	end
	
	function handler.getRequirements(...)
		print("handler.getRequirements: ".."{\n"..serializeTable{...}.."}")
		return requirements
    end
	
	function handler.delayrelease(...)
		print("handler.delayrelease: ".."{\n"..serializeTable{...}.."}")
	end

	function handler.load(...)
		print("handler.load: ".."{\n"..serializeTable{...}.."}")
		
		for i, v in pairs{...} do
			if type(v) == "table" then
				for ii, vv in pairs(v) do
					print("DYNAMIC: loading "..i.."/"..vv)
					load(vv)
				end
			else
				print("DYNAMIC: loading "..v)
				load(v)
			end
		end
	end
	function handler.release(...)
		print("handler.release:", ...)
	end
	function handler.isLoaded(...)
		print("handler.isLoaded:", ...)
		return true
	end
	
	--used in editor
	function handler.loadAllThemes()
		print("handler.loadAllThemes")
		return
	end
	
	--this is supposed to load certain block sprites from a table
	--but how do you do that?
	function handler.loadInGame(sprites, theme)--?
		print("handler.loadInGame: ".."{\n"..serializeTable{sprites, theme}.."}")
		--handler.load{"ingame"}
		-- error()
		loadFromLoadlist(ingameLoadlist, ingameProfile, "INGAME")
	end
	
	function handler.enterIngame(a, theme)
		print("handler.enterIngame:", a, theme)
		return
	end

	--2.4.0
	function handler.delayclear()
		return
	end

	function handler.clear()
		return
	end

	--4.3.2
	function handler.cacheProfiles(...)
		print("handler.cacheProfiles: ".."{\n"..serializeTable{...}.."}")
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
	end
	
	function handler.releaseInGame(a, theme)
		return
	end
	
	function handler.totalmemory()
		--return collectgarbage("count") * 1024
		--return graphics memory instead of lua memory
		love.graphics.getStats(graphics_stats)
		
		return graphics_stats.texturememory * 1024
	end
	
	--5.1.0
	function handler.loadAsset(asset, _)
		print("handler.loadAsset:", asset, _)
		return
	end

	--5.2.5
	function handler.isLoadgroupLoaded(...)--?
		print("handler.isLoadgroupLoaded:", ...)
		return true --trust
	end

	--5.3.1
	function handler.loadAssets(...)--?
		print("handler.loadAssets:", ...)
		return
	end
	
	function handler.queueload(...)--?
		print("handler.queueload: ".."{\n"..serializeTable{...}.."}")
		
		--load the it
		handler.load(...)
		
		return
	end
	
	
	--classic 6.3.0
	function handler.loadAvatarSheets()--?
		return
	end
	
	function handler.releaseAvatarSheets()--?
		return
	end
	
	
	--classic 8.0.3
	handler.queue = handler.load
	handler.queueAssets = handler.load
	function handler.queueInGame(a)
		--a contains sprite names in the level
		print("handler.queueInGame")
		handler.load{"ingame"}
	end
	handler.releaseAssetGroup = handler.release


	--time travel
	function handler.loadBdAdsPictureSheets()--?
		return
	end

	function handler.releaseBdAdsPictureSheets()--?
		return
	end

	gamelua[name] = handler
	--print("platform is", tostring(platform))
	
	return handler
end

--called for all animations at the start of the game
local anims = {}
local preloaded = {}
function gamelua.flashAnimationPreLoad(name, filename, bundlename)
	preloaded[name] = gamelua.readJSONToLuaTable(filename)
end

--tag is a unique name, animName is the animation filename
function gamelua.flashAnimationLoad(tag, animName)
	anims[tag] = {
		name = animName,
		playing = false,
		playing_mode = nil,
		playAction = nil,
		playClip = nil,
		data = preloaded[animName],
		replacements = {},
		time = 0,
		speed = 1,
		shader = nil,
		duration = 0,
		x = 0,
		y = 0,
		rotation = 0,
		sx = 1,
		sy = 1,
	}
end

function gamelua.flashAnimationReplaceImage(tag, target, dest)
	local anim = anims[tag]
	anim.replacements[target] = dest
	
	--print("gamelua.flashAnimationReplaceImage:", tag, target, dest)
end

function gamelua.flashAnimationStart(tag, playAction, mode)
	--flashAnimation1, start, once
	print("gamelua.flashAnimationStart:", tag, playAction, mode)
	assert(anims[tag])
	
	anims[tag].playing = true
	anims[tag].playing_mode = mode --"once" or "repeat"
	anims[tag].playAction = playAction
	
	--there's seemingly no other way to tell the clip name (aside from using the filename but eh)
	for k, v in pairs(anims[tag].data.comps[1].data.actions[playAction].clips) do
		anims[tag].playClip = v
		
		break
	end
	
	--calculate the duration using a similarly sketchy method
	local duration = 0
	
	for k, target in pairs(anims[tag].playClip.targets) do
		for k2, property in pairs(target) do
			duration = math.max(property.keyframes[#property.keyframes][1], duration)
		end
	end
	
	anims[tag].duration = duration
	
	return duration
end

function gamelua.flashAnimationStop(tag, a)
	return
end

function gamelua.flashAnimationSetAnimationParameters(tag, x, y, rotation, sx, sy)
	local anim = anims[tag]
	
	anim.x, anim.y = x, y
	anim.rotation = rotation
	anim.sx, anim.sy = sx, sy
	--print("gamelua.flashAnimationSetAnimationParameters:", tag, x, y, rotation, sx, sy)
end

--gamelua.flashAnimationSetTranslation(r0_12.tag, x, y)

function gamelua.updateFlashAnimation(dt)
	for i, anim in pairs(anims) do
		if anim.playing then
			anim.time = anim.time + dt * anim.speed
			
			if anim.playing_mode == "repeat" then
				anim.time = anim.time % anim.duration
			end
		end
	end
end

local function handleKeyframes(property, time, easing)
	if not property then return end
	
	local keys = property.keyframes
	local last_key = keys[#keys] --used for end behavior (e.g. looping or not)
	local after = property.after
	
	--loop the animation in REPEAT mode
	if after == "REPEAT" then
		time = time % last_key[1]
	end

	for i, key in ipairs(keys) do
		local keytime = key[1]
		if time < keytime then break end
		local nextkey = keys[i + 1]
		
		if nextkey and time >= keytime and time < nextkey[1] then
			local t = (time - keytime) / (nextkey[1] - keytime)
			local target = key[2]
			local dest = nextkey[2]
			
			local target_type = type(target)
			
			--different keyframe types behave differently
			--(i.e. you can't interpolate a string)
			if target_type == "number" then
				return ease.linear(t, target, dest)
			elseif target_type == "string" then
				return target
			elseif target_type == "table" then
				local final = {}
				for i, v in ipairs(target) do
					final[i] = ease.linear(t, target[i], dest[i])
				end
				
				return final
			elseif target_type == "nil" then
				return
			else
				error("target_type is invalid, "..target_type)
			end
		end
	end
	
	--fall back to the last one (TODO: "after": "REPEAT")
	return last_key[2]
end

local vector2_empty = {0, 0}
local vector2_one = {1, 1}

--keyframe types: translation, scale, rotation, alpha, sprite
local anim_draw
function anim_draw(v, clip, anim)
	--TODO: move logic to update
	love.graphics.push()
	if v.name and clip then
		local target = clip.targets[v.name]
		local translation = handleKeyframes(target.translation, anim.time, easing) or vector2_empty
		local scale = handleKeyframes(target.scale, anim.time, easing) or vector2_one
		local alpha = handleKeyframes(target.alpha, anim.time, easing) or 1
		local sprite = handleKeyframes(target.sprite, anim.time, easing) or anim.replacements[v.name] or v.name
		local rotation = handleKeyframes(target.rotation, anim.time, easing) or 0
		
		gamelua.setAlpha(alpha)
		love.graphics.translate(translation[1], translation[2])
		love.graphics.scale(scale[1], scale[2])
		love.graphics.rotate(rotation)
		
		--[[
		gamelua.drawRect(1, 1, 1, 1, -5, -5, 5, 5, true)
		res.drawString("", anim.replacements[v.name] or v.name, 0, 0)
		]]
		
		res.drawSprite(sprite, 0, 0)
	end
	
	if v.children then
		for i, vv in ipairs(v.children) do
			anim_draw(vv, clip, anim)
		end
	end
	love.graphics.pop()
end

function gamelua.drawFlashAnimation(tag)
	love.graphics.push("all")
	local anim = anims[tag]
	--gamelua.setRenderState(anim.x, anim.y, anim.sx, anim.sy)
	love.graphics.translate(anim.x, anim.y)
	love.graphics.scale(anim.sx, anim.sy)
	love.graphics.rotate(anim.rotation) --untested
	
	if anim.shader == "additiveBlending" then
		love.graphics.setBlendMode("add", "premultiplied")
	end
	
	local data = anim.data
	local clip = anim.playClip
	
	anim_draw(data, clip, anim)
	
	love.graphics.pop()
	gamelua.setAlpha(1)
end

function gamelua.flashAnimationClose(tag)
	return
end

function gamelua.flashAnimationPauseToLast(tag)
	return
end

--5.1.0 flash anims
function gamelua.flashAnimationSetShader(tag, shader)
	anims[tag].shader = shader
end

function gamelua.flashAnimationSetSpeed(tag, speed)
	anims[tag].speed = speed
end

function gamelua.flashAnimationSeek(tag, seek)
	anims[tag].time = seek
end


function checkLevelAvailabilityOnline()--?
	return
end

function getOnlineCheckStatus(a)--?
	return
end

function gamelua.enablePigDaysVignette(enabled)--?
	return
end

function gamelua.drawPigDaysVignette(a)--?
	return
end

function gamelua.setThemeWithWater(theme)
	setTheme(theme)
end


function gamelua.drawAdditiveShaders()--?
	return
end


function gamelua.getCameraTopLeft()--?
	return renderTop, renderLeft
end

function gamelua.setCameraViewport(a, b, c, d)--?
	gamelua.setTopLeft(a, b)
end


function gamelua.refreshRovioCloudManager()
	return
end

RovioAssetService = {}

function RovioAssetService.loadAssets(a)
	return
end

native.GetTimeStamp = {}

--these functions are probably called in order
function native.GetTimeStamp.fetchTimeStamp(_, uid)
	return
end

function native.GetTimeStamp.hasResult()
	return true
end

function native.GetTimeStamp.getTimeStamp()
	--status can return BadReturnException, NotYetStartedException, or nil for no error
	local status = nil
	local stamp = gamelua.getCurrentTime()
	stamp.secondsToNext = 1
	return stamp, status
end


NativeCloudPayment = {}
local iapHasPaymentProvider = false

NativeCloudPayment.PURCHASE_ERROR_UNKNOWN = 1
NativeCloudPayment.PURCHASE_ERROR_NOT_ALLOWED = 2
NativeCloudPayment.VOUCHER_ALREADY_HANDLED = 3 --5.3.1

function NativeCloudPayment.isInitialized()
	return iapHasPaymentProvider
end

--NativeCloudPayment.onInitialized()
--NativeCloudPayment.onProductPurchased(product)
--NativeCloudPayment.onProductPurchasePending(product)
--NativeCloudPayment.onPurchaseLimitExceeded()
--NativeCloudPayment.onPurchaseCanceled(product)
--NativeCloudPayment.onPurchaseFailed(product, reason)
--NativeCloudPayment.onRestoreComplete(product) --..is empty
--NativeCloudPayment.userHasNonConsumable(product)

--called after everything is set up
function NativeCloudPayment.ready()
	iapHasPaymentProvider = true
	if NativeCloudPayment.onInitialized then
		NativeCloudPayment.onInitialized()
	end
end

function NativeCloudPayment.getLocalizedPrices()
	local prices = {}

	setmetatable(prices, {
		__index = function(self, k)
			return "$0.00"
		end
	})

	return prices
end

function NativeCloudPayment.redeemCode(code, callback)
	local success = 0 --redirects to the shop
	local invalid = -1 or -5 --everything else shows an error popup
	local already_used = -3 or -4

	if code == "ANGRY-BIRDS" then

	end

	callback(success)
end

function NativeCloudPayment.getAvailableProducts()
	local products = {}

	setmetatable(products, {
		__index = function(self, k)
			return {price = 12}
		end
	})

	return products
end

function NativeCloudPayment.restorePurchases() --5.2.5 hd --?
	return
end

function NativeCloudPayment.getProductDescriptions() --5.3.1
	local descriptions = {}

	setmetatable(descriptions, {
		__index = function(self, k)
			return "a"
		end
	})

	return descriptions
end

function NativeCloudPayment.getProductDatas() --5.3.1
	local datas = {}

	setmetatable(datas, {
		__index = function(self, k)
			return {items = {}}
		end
	})

	return datas
end

function NativeCloudPayment.hasAutomaticRestore()
	return false
end

function NativeCloudPayment.isProductAvailableForPurchase(product)
	return true --i guess
end

local statuses_new = {
	PAYMENT_SUCCEEDED = 0,
	PAYMENT_FAILED = 1,
	PAYMENT_CANCELLED = 2,
	PAYMENT_PENDING = 3,
	PAYMENT_REFUNDED = 4,
	PAYMENT_RESTORED = 5,
}

function NativeCloudPayment.buyProduct(product)
	gamelua.iapBuyItem(product, function(product, reason)
		if reason == statuses_new.PAYMENT_SUCCEEDED then
			NativeCloudPayment.onProductPurchased(product)
		elseif reason == statuses_new.PAYMENT_CANCELLED then
			NativeCloudPayment.onPurchaseCanceled(product)
		end
	end, statuses_new)
end


function gamelua.native_reloadIngameSprites()--? --4.3.2, when exiting shop from the level failed screen
	return
end

NativeCloudAssets = {}

local downloads = {}
local downloadStatus = {}
local blacklisted = {}
NativeCloudAssets.allowNewBackgroundThread = nil --function returns boolean

function NativeCloudAssets.loadAsset(pack)-- there seems to be evidence that this can load levels
	--UNKNOWN, IDLE, NO CONNECTION, FAILURE, QUEUED, DOWNLOADING, DOWNLOADED, PROCESSING, READY
	if isOffline then return end
	
	local url = gamelua.cloudDomain .. "/" .. pack
	
	local save = "cdn/"..pack
	
	print(string.format("Downloading asset '%s' ...", pack))
	downloadStatus[pack] = "QUEUED"
	
	local function success(data)
		local fileData = love.filesystem.newFileData(data, pack)
		local source = love.sound.newSoundData(fileData)
		
		downloads[pack] = { package = data, source = source }
		downloadStatus[pack] = "SUCCESS"
	end
	
	if love.filesystem.exists(save) then
		success(love.filesystem.read(save))
		
		return
	end
	
	fetch(url, {}, function(res)
		local body = res.body
		local code = res.code
		local header = res.header
		local status = res.status
		
		downloadStatus[pack] = "DOWNLOADING"
		
		if code == 200 then
			local data = body
			
			local dataSize = math.floor(#data / 1000 * 100) / 100
			print(string.format("Downloaded '%s', %d kB", pack, dataSize))
			
			love.filesystem.createDirectory("cdn")
			love.filesystem.write(save, data)
			
			success(data)
		else
			print(("Failed to download '%s':"):format(pack), code, status)
			if code == 404 then blacklisted[pack] = true end
			
			if NativeCloudAssets.isInternetConnected() then
				downloadStatus[pack] = "FAILURE"
			else
				downloadStatus[pack] = "NO CONNECTION"
			end
		end
	end)
end

function NativeCloudAssets.packStep(episode, b, c)
	--downloads[episode] = {progress = 0, processing = false}
end

function NativeCloudAssets.isProcessing()
	return false
end

function NativeCloudAssets.cancelPackOperation(pack)
	return
end

function NativeCloudAssets:onInitialized()
	return
end

function NativeCloudAssets.getPackStatus(asset)
    if downloads[asset] then
        return "CACHED"
	else
		if not downloadStatus[asset] and not blacklisted[asset] then
			local connected = NativeCloudAssets.isInternetConnected()
			if connected and CloudDownloadIndicator.isVisible then
				downloadStatus[asset] = "PROCESSING"
				NativeCloudAssets.loadAsset(asset)
			end
		end
    end
    
    if downloadStatus[asset] then
        return downloadStatus[asset]
    end
    
    return "IDLE"
end

function NativeCloudAssets.deleteAllCloudData()
	for i, file in love.filesystem.getDirectoryItems("cdn") do
		NativeCloudAssets.removeAsset(file)
	end
end
-- NOTE : the game cashes the data in its settings folder as a fallback
function gamelua.createAudioFromAppData(asset, clipName)
    if downloads[asset] and downloads[asset].source then
        res.createAudio(downloads[asset].source, clipName, false, true)
        print(clipName .. " created!")
    end
end

--4.2.0
function NativeCloudAssets.getAssetPath(asset)
    if downloads[asset] then
        return asset
    end
    return nil
end

-- connect to a dummy network, and check if there's any feedback
function NativeCloudAssets.isInternetConnected()
	if isOffline then return false end

	local socket = require("socket")
    local tcp = socket.tcp()
    tcp:settimeout(2)
    local result = tcp:connect("8.8.8.8", 53)
    tcp:close()
    return result ~= nil
end

function NativeCloudAssets.removeAsset(asset)
    downloads[asset] = nil
    downloadStatus[asset] = nil
	love.filesystem.remove("cdn/" .. asset)
end

function NativeCloudAssets.getAssetStatus(asset)
	local status = NativeCloudAssets.getPackStatus(asset)
	if status == "QUEUED" then status = "DOWNLOADING" end
	if status == "NO CONNECTION" then status = "FAILURE" end
	return status
end

function NativeCloudAssets.deleteAllCloudData() --5.0.0
	return
end

gamelua.cloudDomain = "http://raw.githubusercontent.com/HaloGuy345/cloud_assets/main"
CLOCK_URL_BASE = ""


function gamelua.readJSONToLuaTable(filename, export)
	local newname, paths = findCaseInsensitive(datapath.."/"..filename)

	if not newname then
		print("readJSONToLuaTable: json file \""..tostring(sheet).."\" not found")
		return {}
	end

	print("Loading JSON file \""..tostring(newname).."\"...")

	local data = love.filesystem.read(newname or "")
	local dec = json.decode(decryptSrc(newname, data))

	if export then
		gamelua[export] = dec
	end

	return dec --for dynamic handler
end


function createProfileTable()
	return {}
end

function gamelua.initLocales()
	return
end

function gamelua.getHardwareModel()
	return "" --2.4.0 checks for iPhone1,2 iPhone2,1 iPod2,1
end

--g_requestingInterstitial, g_interstitialReady
function gamelua.requestInterstitial()
	return
end

function gamelua.showInterstitial()
	return
end

function loadLevelEditor(name)
	return
end

--this library is unique in being placed in gamelua
gamelua.MedioEvents = {}

function gamelua.MedioEvents.logEvent(text, params)
	print("Logging MedioEvent: "..text)
end

function gamelua.MedioEvents.getMedioAnonymousId()
	return "0"
end


--5.3.1

gamelua.setPhysicsEnabledNative = gamelua.setPhysicsEnabled

function gamelua.drawScreenParticlesWithId(particles, bool, number)
	return
end

gamelua.g_iap_item_info = {}

function gamelua.getProductWithIapId(id)
	local type = "specialOffer"
	return {price = {coins = math.random() * 100}, purchaseType = "coins", amount = 1}, type--nil
end

setmetatable(gamelua.g_iap_item_info, {
	__index = function(self, k)
		return gamelua.getProductWithIapId(id)
	end
})

function gamelua.addFlashAnimation(definition, tag) --gameslogics
	return
end

function gamelua.drawWorldParticlesWithId() --? --scripts_common/powerups/Powerup_Teleport.lua
	return
end


--5.4.0

function gamelua.hasCloudDirForPack(pack) --e.g. "specialOffer"
	return false
end


--portals
PortalObjectTeleporter = {}
-- TODO : fix angles + collision detection
function PortalObjectTeleporter:recalculateLinearVelocity()
	local vx, vy = self.object.body:getLinearVelocity()
	local speed = math.sqrt(vx * vx + vy * vy)
	
	local EPSILON = 1.1920929e-07
	
	if speed < EPSILON then
		return
	end
	
	local deltaTime = dt2 * (physicsTimeScale or 1)
	local portalAngleDiff = math.acos(self.destAngleCos * self.sourceAngleCos + self.destAngleSin * self.sourceAngleSin)
							
	local isLargerAngle = math.pi / 2 * deltaTime < portalAngleDiff
	
	local transformedVelocity = {x = 0, y = 0}
	
	local angleDelta = self.sourceAngle + self.destAngle
	
	--[[if isLargerAngle then
		local velAngle = math.atan2(vy, vx)
		local newAngle = velAngle + deltaTime - angleDelta

		newAngle = math.atan2(math.sin(newAngle), math.cos(newAngle))
		
		transformedVelocity.x = math.cos(newAngle) * speed
		transformedVelocity.y = math.sin(newAngle) * speed
		print("true", newAngle, velAngle, angleDelta)
	else
		local normalX = self.sourceAngleCos
		local normalY = self.sourceAngleSin
		local dotProduct = normalX * vx + normalY * vy
		local angleReflected = {
			x = vx - 2.0 * dotProduct * normalX,
			y = vy - 2.0 * dotProduct * normalY,
		}
		
		local newAngle = portalAngleDiff
		if self.sourceAngle <= self.destAngle and angleDelta >= deltaTime then
			newAngle = -newAngle
		end
		
		local cosAngle = math.cos(newAngle)
		local sinAngle = math.sin(newAngle)
		
		transformedVelocity.x = angleReflected.x * cosAngle - angleReflected.y * sinAngle
		transformedVelocity.y = angleReflected.y * cosAngle + angleReflected.x * sinAngle
		print("false", newAngle, self.destAngle)
	end
	
	if speed < self.minSpeed then
		local scale = self.minSpeed / speed
		transformedVelocity.x = transformedVelocity.x * scale
		transformedVelocity.y = transformedVelocity.y * scale
	end]]
	
	--romoney5: test
	local angle = (math.atan2(vy, vx) - self.sourceAngle) + self.destAngle - math.pi
	
	transformedVelocity.x = math.cos(angle) * speed
	transformedVelocity.y = math.sin(angle) * speed
	
	self.velocityX = transformedVelocity.x
	self.velocityY = transformedVelocity.y
end

function PortalObjectTeleporter:new(object, x, y, angle, minSpeed, sourcePath, entryX, entryY, sourceX, sourceY, 
	sourceAngle, destPath, destX, destY, destAngle, portalDelay, effect)
	
	local portal = {}
	
	portal.object = object
	portal.x = x
	portal.y = y
	portal.angle = angle
	portal.minSpeed = minSpeed
	
	portal.sourceName = sourcePath
	portal.sourceX = sourceX
	portal.sourceY = sourceY
	portal.sourceAngle = sourceAngle
	portal.sourceAngleSin = math.sin(sourceAngle)
	portal.sourceAngleCos = math.cos(sourceAngle)
	
	portal.entryX = entryX
	portal.entryY = entryY
	
	portal.destName = destPath
	portal.destX = destX
	portal.destY = destY
	portal.destAngle = destAngle
	portal.destAngleSin = math.sin(destAngle)
	portal.destAngleCos = math.cos(destAngle)
	
	portal.portalDelay = portalDelay
	portal.effect = effect
	portal.needsVelocityRecalc = true
	
	self.active = false
	self.effectsFinished = false
	
	self.finished = false
	setmetatable(portal, self)
	self.__index = self
	
	--portal:recalculateLinearVelocity()
	
	return portal
end

function PortalObjectTeleporter:update(dt)
	if self.finished then
		return false
	end
	
	if self.active ~= true then
		
		local body = self.object.body
		local vx, vy = body:getLinearVelocity()
		local speed = math.sqrt(vx * vx + vy * vy)
		
		if speed > 0.0 then
			local normalizedSpeed = (vx * self.sourceAngleCos + vy * self.sourceAngleSin) / speed
			local velocityAngle = math.acos(normalizedSpeed)
			
			local angleThreshold = math.pi / 2 * dt
			
			if angleThreshold < velocityAngle then
				if self.needsVelocityRecalc then
					self:recalculateLinearVelocity()
					self.needsVelocityRecalc = false
				end
				
				local x, y = body:getPosition()
				local dx = x - self.entryX
				local dy = y - self.entryY
				local distanceToEntry = math.sqrt(dx * dx + dy * dy)
				
				if distanceToEntry <= 0.0 then
					return false
				end
				
				local approachDot = (dx * self.sourceAngleCos + dy * self.sourceAngleSin) / distanceToEntry
				local approachAngle = math.acos(approachDot)
				
				if approachAngle < angleThreshold then
					return false
				end
				
				local portalPassages = incrementPortalPingPongCount(self.object, self.sourceName, self.destName)
				
				if portalPassages > 10 then
					self.effectsFinished = true
					objectTeleportationAborted(self.object.name)
					removeObject(self.object.name)
					
					return true
				end
				
				self:playEffects(true)
				
				if self.portalDelay > 0.0 then
					self:applyTeleportTransform()
					body:setActive(false)
					gamelua.setVisible(self.object, false)
					self.active = true
					
					return false
				else
					self:applyTeleportTransform()
					gamelua.objectExitingThroughPortal(self.object.name)
					return true
				end
			end
		end
		
		self.needsVelocityRecalc = true
		return false
	else
		self.portalDelay = self.portalDelay - dt
		
		if self.portalDelay <= 0.0 then
			self:restoreObject()
			gamelua.objectExitingThroughPortal(self.object.name)
			
			return true
		end
		
		return false
	end
	
	return false
end

function PortalObjectTeleporter:applyTeleportTransform()
	local body = self.object.body
	body:setTransform(self.x, self.y, self.angle)
	body:setLinearVelocity(self.velocityX, self.velocityY)
end

function PortalObjectTeleporter:restoreObject()
	local body = self.object.body
	body:setActive(true)
	gamelua.setVisible(self.object, true)
	self:playEffects(false)
end

function PortalObjectTeleporter:playEffects(isEntry)
	local index = 1
	while index <= #self.effect do
		local effect = self.effect[index]
		
		local direction = effect.direction
		local playSound = (direction == "both") or 
                          (isEntry and direction == "in") or 
                          (not isEntry and direction == "out")
		
		if playSound then
			local assetName = effect.id
			
			if type(assetName) == "table" then
				assetName = assetName[math.random(1, #assetName)]
			end
			
			local effectType = effect.type
			
			if effectType == "particle" then
				local x, y = self.object.x, self.object.y
				
				if effect.positionFromPortal then
					x = self.entryX
					y = self.entryY
				end
				
				local rotation = 0.0
				if not effect.positionFromPortal then
					rotation = self.destAngle	
					if isEntry then
						rotation = self.sourceAngle	
					end
				end
				
				x = x * physicsToWorld
				y = y * physicsToWorld
				
				_G.particles.addParticles(assetName, 1, x, y, 0, 0, rotation, false, false)
			elseif effectType == "sound" then
				local volume = effect.volume or 1.0
				res.playAudio(assetName, volume, false, 0)
			end
		end

		index = index + 1
	end
end

function PortalObjectTeleporter:isComplete()
    return self.finished
end


--5.1.0

function gamelua.getSystemTimeStamp()
	return 0
end


function NativeCloudAssets.onInitDone()--?
    return
end

function NativeCloudAssets.getCloudDataVersionString()
    return "" --apparently
end

function NativeCloudAssets.hasUnlockDates()
    return false
end

function NativeCloudAssets.isPackInstalled()--?
	return false
end

function NativeCloudAssets.syncInstallPack()--?
	return
end


function gamelua.printAutomation(a)
	print(a)
end

native.TimeStamp = {}

function native.TimeStamp.isTimeStampAvailable()
	return false
end

function native.TimeStamp.getCurrentYear()
	return 1970
end

function native.TimeStamp.getCurrentMonth()
	return 1
end

function native.TimeStamp.getCurrentDay()
	return 1
end

function native.TimeStamp.getCurrentSecondsToNext()
	return 1
end

function native.TimeStamp.checkIfDatePassed(year, month, day)
	return 0
end

function native.TimeStamp.getSecondsToDate(year, month, day)
	return 0
end


function RovioChannel.isChannelSupported()--?
	return false
end



--isn't actually necessary for the loading screen to work in 5.1.0
function gamelua.setLoadingScreenActive(active)
	return
end

function gamelua.useAdditiveBlendingForObject(name)--?
    local obj = objects.world[name]
    if obj then
		return
    end
end


--backgrounds


--5.2.5

function NativeCloudAssets.startLoading()--?
	return
end

function NativeCloudAssets.isPackAccessible()--?
	return false
end

gamelua.setThemeWithCrossFade = gamelua.setTheme

--ipad, this might be in way earlier versions but ipad versions haven't really been checked until now
function gamelua.postHighscore(leaderboardid, score, isLevelScore)
	return
end


--1.5.1

WebView = {}

WebView.LOAD_PAGE_INTO_EXTERNAL_BROWSER = 1

function WebView.new(x, y, height, width)
	local view = {}

	function view:setOnLinkClickedCallback(callback)
		--[[
		local onLinkClicked = function(view, url)
			return _G.WebView.LOAD_PAGE_INTO_EXTERNAL_BROWSER
		end
		]]
		return
	end

	function view:setOnPageLoadedCallback(callback)
		--[[
		local onPageLoaded = function(view, success, pageTitle)
			if success and pageTitle == "Rovio News [hjsdu]" then
				rovioNewsIsLoaded = true
				if rovioNewsShowWhenLoaded then
					hideAd()
					view:show()
					rovioNewsIsShown = true
				end
			end
		end
		]]
		return
	end

	function view:loadPage(url)
		return
	end

	function view:hide()
		return
	end

	function view:show()
		return
	end

	return view
end
