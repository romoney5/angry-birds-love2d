--level saving and loading and other things

physicsSimulationScale = 0

function loadLevel(filename)
	print("Loading level \""..filename..".lua\"...")

	birdTrajectory = {{}, {}, {}}
	resetTrajectory()

	if physicsWorld then physicsWorld:destroy() end --clear all the objects before continuing

	physicsWorld = love.physics.newWorld(worldgravity.x, worldgravity.y, true)
	--physicsWorld:setCallbacks(nil,nil,physicsPreSolve,physicsPostSolve)
	physicsWorld:setCallbacks(physicsBeginContact, physicsEndContact, nil, nil)
	collisionsList = {}
	loadedObjects = {}
	zOrderedObjects = {}
	activeTeleporters = {}
	loadLuaFileToObject(filename..".lua", this, loadedObjects)
	setMaxTranslation(2)
	setupColliders()
	clearParticles()
	clearLuaAssetRender()
	LevelParticlesManager.initialized = false
end

function saveLevel(filename)
	print("Saving level \""..filename..".lua\"...")
	saveLuaFile(filename..".lua","objects", nil, nil, true)
end

function setPhysicsSimulationScale(scale)
	physicsSimulationScale = scale
	love.physics.setMeter(physicsSimulationScale * 0.5)
end

function setLevelLimits(minx, miny, maxx, maxy)
	objects.limits = {mix = minx, miy = miny, max = maxx, may = maxy}
end

function isPhysicsEnabled()
	return physicsEnabled
end

function setPhysicsEnabled(enabled)
	physicsEnabled = enabled
end

--lite
--[[ for testing purposes
local realTime = os.time
fakeTime = 0

function os.time(t)
    if t then return realTime(t) end
    return 1291161600 + fakeTime -- dec 1st, 2010
end
]]

local status, timeToNext, today, error

function loadLevelFile(levelName, dateString)
    local date = os.time()
    local now = os.date("*t", date)
	local tomorrow = os.time({year = now.year, month = now.month, day = now.day + 1})
	
	local year, month, day = dateString:match("(%d+)-(%d+)-(%d+)")
    local unlockTime = os.time({
        year  = tonumber(year),
        month = tonumber(month),
        day   = tonumber(day),
    })
	
	local seconds_to_open = os.difftime(unlockTime, date)
	if seconds_to_open <= 0 then
		local level = levelName:match("([^/]+)$")
		status = highscores[level] and 2 or 3
	else
		status = -1
		error = NativeCloudAssets.isInternetConnected() and 1 or -1
	end
	
	today = string.format("%d-%d-%d", now.year, now.month, now.day)
	timeToNext = math.max(os.difftime(tomorrow, date), 0)
end

function getLoadStatus()
	return {
		status = status,
		timeToNext = timeToNext,
		today = today,
		error = error
	}
end

--4.3.1

function removeTemporaryLevel()--?
	return
end
