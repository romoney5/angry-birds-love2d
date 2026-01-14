--level saving and loading and other things

physicsSimulationScale = 0

function loadLevel(filename)
	print("Loading level \""..filename..".lua\"...")
	trajectory = {{{}, {}, {}}}
	if physicsWorld then physicsWorld:destroy() end --clear all the objects before continuing

	physicsWorld = love.physics.newWorld(worldgravity.x, worldgravity.y, true)
	--physicsWorld:setCallbacks(nil,nil,physicsPreSolve,physicsPostSolve)
	physicsWorld:setCallbacks(physicsBeginContact, nil, nil, nil)
	collisionsList = {}
	loadedObjects = {}
	loadLuaFileToObject(filename..".lua", this, loadedObjects)
	setMaxTranslation(2)

	if loadedObjects.world then
		table.sort(loadedObjects.world, function(a, b)
			return (a.z_order or 0) < (b.z_order or 0)
		end)
	end

	--restore particle functions
	if particles and not getmetatable(particles) then
		setmetatable(particles, getParticles)
	end
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

function getLoadStatus()
	--0=not finished, 1 or 2=finished, 3=christmas?
	return {status = 1}
end