--level saving and loading and other things

function loadLevel(filename)
	print("Loading level: "..filename..".lua")
	trajectory = {{{},{},{}}}
	toremove = nil
	if physicsWorld then physicsWorld:destroy() end --clear all the objects before continuing

	physicsWorld = love.physics.newWorld(worldgravity.x, worldgravity.y, true)
	physicsWorld:setCallbacks(nil,nil,physicsPreSolve,physicsPostSolve)
	collisionsList = {}
	loadedObjects = {}
	loadLuaFileToObject(filename..".lua",this,loadedObjects)
	table.sort(loadedObjects.world,function(a,b)return (a.z_order or 0)<(b.z_order or 0)end)

	--don't worry about it
	-- sonc = {
    --     y = -30,
    --     x = 15.8932,
    --     name = "sonc",
    --     angle = 0,
    --     definition = "sonc",
    --     strength = 1000,
    --     defence = 1000,
    --     sprite = "sonc_idle",
    --     powerup_scale = 3,
    --     xVel = 0,
    --     yVel = 0,
    --     w=2,
    --     h=5,
    --     yp=32,
    --     flipx = false,
    -- }
	-- sonc.body = love.physics.newBody(physicsWorld, sonc.x, sonc.y, "dynamic")
	-- sonc.shape = love.physics.newRectangleShape(sonc.w, sonc.h)
	-- sonc.fixture = love.physics.newFixture(sonc.body, sonc.shape, 4)

	-- sonc.fixture:setRestitution(0+2)
	-- sonc.fixture:setFriction(0)
	-- sonc.fixture:setUserData(sonc)

	-- sonc.body:setAngularDamping(1)
	-- _,_,sonc.mass,_ = sonc.shape:computeMass(1)
	-- sonc.mass = sonc.mass*100
end

function saveLevel(filename)
	print("Saving level: "..filename..".lua")
	saveLuaFile(dataPath..filename..".lua","objects",nil,nil,true)
end

function setPhysicsSimulationScale(scale)
	love.physics.setMeter(scale*.5)
end

function setWorldScale(num)
	worldScale = num
end

function setMaxWorldScale(s)
	maxWorldScale = s
end

function setLevelLimits(minx,miny,maxx,maxy)
	objects.limits = {mix = minx, miy = miny, max = maxx, may = maxy}
end

function isPhysicsEnabled()
	return physicsEnabled
end

function setPhysicsEnabled(enabled)
	physicsEnabled = enabled
end

--massive thanks halo
function addToTrajectory(index, x, y)
	table.insert(trajectory[#trajectory][index], {x = x, y = y})
end

function addPuffToTrajectory(index, x, y)
	table.insert(trajectory[#trajectory][index], {x = x, y = y, s = "BIRD_SPECIAL"})
end
function startNewTrajectory()
	table.insert(trajectory, {{},{},{}})
	if #trajectory > 2 then
		table.remove(trajectory, 1)
	end
end