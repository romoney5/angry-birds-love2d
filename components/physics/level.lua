--level saving and loading and other things

physicsSimulationScale = 0

function loadLevel(filename)
	print("Loading level \""..filename..".lua\"...")

	birdTrajectory = {{}, {}, {}}
	trajectory = {{{}, {}, {}}}

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

function setWorldScale(num)
	worldScale = num
end

function setMaxWorldScale(s)
	maxWorldScale = s
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

function loadLevelFile(filename, date)
	loadLevel(filename)
end
-- check if this works
function getLoadStatus()
	--0=not finished, 1 or 2=finished, 3=christmas?
	--timetonext can be a number
	--today: "yyyy-mm-dd"
	local today = bi_data.last_launch_date
	today.min = today.minutes
	today.sec = today.seconds
	
	local function formatDate(t)
		return string.format("%04d-%02d-%02d", t.year, t.month, t.day)
	end
	
	local tomorrow = {year = today.year, month = today.month, day = today.day + 1}
	local time_for_next = os.difftime(os.time(tomorrow), os.time(today))
	
	local tomorrow_string = formatDate(tomorrow)
	local current_today = os.date("%Y-%m-%d")
	local status = (current_today == tomorrow_string) and 1 or 0
	
	return {status = status, timeToNext = time_for_next, today = formatDate(today)}
end

--4.3.1

function removeTemporaryLevel()--?
	return
end