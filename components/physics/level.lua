--level saving and loading and other things

physicsEnabled = false
physicsWorld = nil

physicsSimulationScale = 0

function gamelua.loadLevel(filename)
	print("Loading level \""..filename..".lua\"...")

	birdTrajectory = {{}, {}, {}}
	gamelua.resetTrajectory()

	if physicsWorld then physicsWorld:destroy() end --clear all the objects before continuing

	physicsWorld = love.physics.newWorld(worldgravity.x, worldgravity.y, true)
	--physicsWorld:setCallbacks(nil,nil,physicsPreSolve,physicsPostSolve)
	physicsWorld:setCallbacks(physicsBeginContact, physicsEndContact, nil, nil)
	collisionsList = {}
	gamelua.loadedObjects = {}
	zOrderedObjects = {}
	activeTeleporters = {}
	
	gamelua.loadLuaFileToObject(filename..".lua", nil, gamelua.loadedObjects)
	
	gamelua.setMaxTranslation(2)
	setupColliders()
	gamelua.clearParticles()
	clearLuaAssetRender()
	LevelParticlesManager.initialized = false
end

local customSerialize
function customSerialize(t, inner)
	local out = ""
	inner = inner or 0

	for k, v in pairs(t) do
		local indent = ("\t"):rep(inner)
		out = out..indent
		
		if type(v) == "table" then
			out = out..(("%s = {\n%s%s}"):format(k, customSerialize(v, inner + 1), indent))
		elseif type(v) == "string" then
			out = out..(("%s = \"%s\""):format(k, v))
		elseif type(v) == "number" then
			out = out..(("%s = %s"):format(k, tostring(v)))
		elseif type(v) == "boolean" then
			out = out..(("%s = %s"):format(k, tostring(v)))
		else
			out = out..(("--%s = \"%s\""):format(k, tostring(v)))
		end
		
		out = out..(("%s\n"):format(inner > 0 and "," or ""))
	end
	
	return out
end

function gamelua.saveLevel(filename)
	print("Saving level \""..filename..".lua\"...")
	love.filesystem.createDirectory(filename:match(".*/") or "")
	love.filesystem.write(filename..".lua", customSerialize(gamelua.objects))
end

function gamelua.setPhysicsSimulationScale(scale)
	physicsSimulationScale = scale
	physicsToWorld = scale
	love.physics.setMeter(physicsSimulationScale * 0.5)
end

function gamelua.setLevelLimits(minx, miny, maxx, maxy)
	objects.limits = {mix = minx, miy = miny, max = maxx, may = maxy}
end

function gamelua.isPhysicsEnabled()
	return physicsEnabled
end

function gamelua.setPhysicsEnabled(enabled)
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

function gamelua.loadLevelFile(levelName, dateString)
    local date = os.time()
    local now = os.date("*t", date)
	local tomorrow = os.time({year = now.year, month = now.month, day = now.day + 1})
	
	local year, month, day = dateString:match("(%d+)-(%d+)-(%d+)")
    local unlockTime = os.time({
        year  = tonumber(year) or 1970,
        month = tonumber(month) or 1,
        day   = tonumber(day) or 1,
    })
	
	local seconds_to_open = os.difftime(unlockTime, date)
	if seconds_to_open <= 0 then
		local level = levelName:match("([^/]+)$")
		status = gamelua.highscores[level] and 2 or 3
	else
		status = -1
		error = NativeCloudAssets.isInternetConnected() and 1 or -1
	end
	
	today = string.format("%d-%d-%d", now.year, now.month, now.day)
	timeToNext = math.max(os.difftime(tomorrow, date), 0)
end

function gamelua.getLoadStatus()
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
