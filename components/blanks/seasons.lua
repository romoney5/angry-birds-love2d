-- seasons 4.2.0
NativePlatformScore = {}

function NativePlatformScore.getPerformanceScore()
    return 2 
end

function NativePlatformScore.getMemoryScore()
    return 2 
end

function createDynamicHandler(name)
	local handler = {}
	local requirements = {}
	local selectAssetProfile = selectAssetProfile or (platform and platform.Profiles and platform.Profiles.selectAssetProfile)

	local loadlists = {loadlist = {}, neatLoadlist = {}}
	local loadlistNames = {"loadlist", "neatLoadlist"}

	local ingameLoadlist --hacky; for loadInGame
	local ingameProfile --hacky; for loadInGame
	
	--TODO: queue and asset freeing
	local function loadFromLoadlist(list, profile, group)
		for _, asset in ipairs(list[group]) do
			if asset[2] ~= 1 then
				res.createSpriteSheet(imagePath.."/"..profile.."/"..asset[1])
			else
				res.createCompoSpriteSet(imagePath.."/"..profile.."/"..asset[1])
			end
		end
	end
	
	local function load(group)
		if requirements[group] then
			for i, v in pairs(requirements[group]) do
				local profile = selectAssetProfile(v)
				-- print("pr", v, profile)
				if endsWith(profile, "_cloud") then
					profile = profile:sub(1, #profile - 6)
				end
				
				for i, list in ipairs(loadlistNames) do
					if not loadlists[list][profile] then
						loadLuaFile(imagePath.."/"..profile.."/"..list..".lua")

						--json loadlists
						if checkDirectory(imagePath.."/"..profile.."/"..list..".json") then
							assetLoadList = assetLoadList or {}
							for profileName, profileValue in pairs(readJSONToLuaTable(imagePath.."/"..profile.."/"..list..".json")) do
								for groupName, groupValue in pairs(profileValue) do
									assetLoadList[profile][groupName] = assetLoadList[profile][groupName] or {}
									for i, v in pairs(groupValue) do
										table.insert(assetLoadList[profile][groupName], {v.filename, v.type})
									end
								end
							end
						end

						if not assetLoadList then break end

						loadlists[list][profile] = assetLoadList[profile]
					end

					local dat = loadlists[list] and loadlists[list][profile]
					if dat and dat[v] then
						-- print("yes", profile, v)
						loadFromLoadlist(dat, profile, v)

						if dat.INGAME then
							ingameLoadlist = dat
							ingameProfile = profile
						end
					-- else
					-- 	print("no", profile, v)
					end
				end
			end
		end
	end
	
	function handler.addreq(...)
		print("addreq:")
		for i, v in pairs{...} do
			if type(v) == "table" then
				for i, v in pairs(v) do
					requirements[i] = v
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
		print("handler.getRequirements:", ...)
		return {} 
    end
	
	function handler:delayrelease(...) end

	function handler.load(...)
		print("handler.load:", ...)
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
	function handler.release(...) end
	function handler.isLoaded(...) return true end
	
	function handler.loadInGame(sprites, theme)--?
		-- handler.load{"ingame"}
		-- error()
		loadFromLoadlist(ingameLoadlist, ingameProfile, "INGAME")
	end
	
	function handler.enterIngame(a, theme)
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
		print("cacheProfiles:")
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
		return collectgarbage("count") * 1024
	end

	--5.2.5
	function handler.isLoadgroupLoaded()--?
		return true --trust
	end

	--5.3.1
	function handler.loadAssets()--?
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

	_G[name] = handler
	--print("platform is", tostring(platform))
	
	return handler
end

function flashAnimationPreLoad()--?
	return
end

function flashAnimationLoad()--?
	return
end

function flashAnimationReplaceImage()--?
	return
end

function flashAnimationStart()--?
	return
end

function flashAnimationSetAnimationParameters()--?
	return
end

function updateFlashAnimation()--?
	return
end

function drawFlashAnimation()--?
	return
end

function flashAnimationClose()--?
	return
end

function flashAnimationPauseToLast()--?
	return
end


function checkLevelAvailabilityOnline()--?
	return
end

function getOnlineCheckStatus(a)--?
	return
end

function enablePigDaysVignette(enabled)--?
	return
end

function setThemeWithWater(theme)
	setTheme(theme)
end


function drawAdditiveShaders()--?
	return
end


function getCameraTopLeft()--?
	return screen.top, screen.left
end

function setCameraViewport(a, b, c, d)--?
	setTopLeft(a, b)
end


function refreshRovioCloudManager()
	return
end

RovioAssetService = {}

function RovioAssetService.loadAssets(a)
	return
end

native.GetTimeStamp = {}

function native.GetTimeStamp.fetchTimeStamp()--?
	return 0
end

function native.GetTimeStamp.getTimeStamp()--?
	return 0
end

function native.GetTimeStamp.hasResult()
	return false
end

function native_reloadIngameSprites()--?
	return
end

NativeCloudAssets = {}
--NativeCloudPayment = true

local downloads = {}
local downloadStatus = {}
local blacklisted = {}
NativeCloudAssets.allowNewBackgroundThread = nil --function returns boolean

function NativeCloudAssets.loadAsset(pack)-- there seems to be evidence that this can load levels
	--UNKNOWN, IDLE, NO CONNECTION, FAILURE, QUEUED, DOWNLOADING, DOWNLOADED, PROCESSING, READY
	local url = cloudDomain .. "/" .. pack
	
	local save = "cdn/"..pack
	
	print(string.format("Downloading asset '%s' ...", pack))
	downloadStatus[pack] = "QUEUED"
	
	local function success(data)
		local fileData = love.filesystem.newFileData(data, pack)
		local source = love.sound.newSoundData(fileData)
		
		downloads[pack] = { package = data, source = source }
		downloadStatus[pack] = "SUCCESS"
	end
	
	if checkDirectory(save) then
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
function createAudioFromAppData(asset, clipName)
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

NativeCloudAssets.getAssetStatus = NativeCloudAssets.getPackStatus

cloudDomain = "http://raw.githubusercontent.com/HaloGuy345/cloud_assets/main"
CLOCK_URL_BASE = ""


function readJSONToLuaTable(filename, export)
	local newname, paths = findCaseInsensitive(datapath.."/"..filename)

	if not newname then
		print("readJSONToLuaTable: json file \""..tostring(sheet).."\" not found")
		return {}
	end

	print("Loading JSON file \""..tostring(newname).."\"...")

	local data = love.filesystem.read(newname or "")
	local dec = json.decode(decryptSrc(newname, data))

	if export then
		_G[export] = dec
	end

	return dec --for dynamic handler
end


function createProfileTable()
	return {}
end

function initLocales()
	return
end

function getHardwareModel()
	return "" --2.4.0 checks for iPhone1,2 iPhone2,1 iPod2,1
end

--g_requestingInterstitial, g_interstitialReady
function requestInterstitial()
	return
end

function showInterstitial()
	return
end

--does not show up at all in luadec
function updateThemeSprite(dt)
	return
end

function loadLevelEditor(name)
	return
end

MedioEvents = {}

function MedioEvents.logEvent(text, params)
	print("Logging MedioEvent: "..text)
end

function MedioEvents.getMedioAnonymousId()
	return "0"
end


--5.3.1

setPhysicsEnabledNative = setPhysicsEnabled

function drawScreenParticlesWithId(particles, bool, number)
	return
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
	
	local angleDelta = self.sourceAngle - self.destAngle
	
	if isLargerAngle then
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
		
		transformedVelocity.x = angleReflected.x * cosAngle + angleReflected.y * sinAngle
		transformedVelocity.y = angleReflected.y * cosAngle - angleReflected.x * sinAngle
		print("false", newAngle)
	end
	
	if speed < self.minSpeed then
		local scale = self.minSpeed / speed
		transformedVelocity.x = transformedVelocity.x * scale
		transformedVelocity.y = transformedVelocity.y * scale
	end
	
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
					setVisible(self.object, false)
					self.active = true
					
					return false
				else
					self:applyTeleportTransform()
					objectExitingThroughPortal(self.object.name)
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
			objectExitingThroughPortal(self.object.name)
			
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
	setVisible(self.object, true)
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

function getSystemTimeStamp()
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


function printAutomation(a)
	return
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

function native.TimeStamp.checkIfDatePassed(year, month, day)
	return 0
end

function native.TimeStamp.getSecondsToDate(year, month, day)
	return 0
end


function RovioChannel.isChannelSupported()--?
	return false
end


function flashAnimationSetShader(tag, shader)
	return
end

function flashAnimationSetSpeed(tag, speed)
	return
end

function flashAnimationSeek(tag, seek)
	return
end


--isn't actually necessary for the loading screen to work
function setLoadingScreenActive(active)
	return
end


--backgrounds


--5.2.5

function NativeCloudAssets.startLoading()--?
	return
end

function NativeCloudAssets.isPackAccessible()--?
	return false
end

setThemeWithCrossFade = setTheme
