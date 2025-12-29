--create box, circle, etc

--funky
function createJoint(joint)
	local name, end1, end2, type, coordType, x1, y1, x2, y2, collideConnected, limit, motor, maxTorque, lowerLimit, upperLimit, motorSpeed =
		joint.name,joint.end1,joint.end2,joint.type,joint.coordType,joint.x1,joint.y1,joint.x2,joint.y2,joint.collideConnected,
		joint.limit,joint.motor,joint.maxTorque,joint.lowerLimit,joint.upperLimit,joint.motorSpeed
	local obj1, obj2 = objects.world[end1], objects.world[end2]

	local joint
	if type == 1 then
		joint = love.physics.newDistanceJoint(obj1.body, obj2.body, x1, y1, x2, y2, collideConnected)
	elseif type == 2 then
		joint = love.physics.newWeldJoint(obj1.body, obj2.body, x1, y1, x2, y2, collideConnected)
	elseif type == 3 then
		joint = love.physics.newRevoluteJoint(obj1.body, obj2.body, x1, y1, x2, y2, collideConnected, math.atan2(y2-y1, x2-x1))
		joint:setLimitsEnabled(limit)
		joint:setMotorEnabled(motor)
		joint:setMaxMotorTorque(maxTorque)
		joint:setLimits(lowerLimit,upperLimit)
		joint:setMotorSpeed(motorSpeed)
	end

	objects.joints[name] = joint
	-- obj.fixture:setUserData(obj)
end

local polyverts = {}

function addVertex(x, y)
	table.insert(polyverts,x)
	table.insert(polyverts,y)
end

function clearVertices()
	polyverts = {}
end

function updateObjectMass(name)
	local obj = objects.world[name]
	if obj and obj.shape then
		local _, _, mass, _ = obj.shape:computeMass(obj.density)
		mass = mass * 100
		--mass = math.floor(mass * 100000) / 100000 --round to the 5th decimal for 32-bit accuracy
		obj.mass = mass
	end
end

local CATEGORY_STATIC = 2
local CATEGORY_BACKGROUND = 3
local CATEGORY_NORMAL = 1

function createPolygon(name, sprite, xpos, ypos, w, h, density, friction, restitution, collision, controllable, z_order)
	local verts = polyverts
	if z_order then --1.6.3.1 and below
		objects.world[name] = {name = name, sprite = sprite, y = ypos, x = xpos, width = w, height = h or w, density = density,
			friction = friction, restitution = restitution, collision = collision, controllable = controllable or false, z_order = z_order, mass = 1, xVel = 0, yVel = 0, angle = 0}
	else --3.0.1
		objects.world[name] = {name = name, sprite = sprite, y = ypos, x = xpos, width = 1, height = 1, density = h,
			friction = density, restitution = friction, collision = restitution, controllable = collision or false, z_order = controllable, mass = 1, xVel = 0, yVel = 0, angle = 0}
		verts = {}
		for _, v in pairs(w) do
			table.insert(verts, v.x)
			table.insert(verts, v.y)
		end

		density,friction,restitution = h,density,friction
	end

	local obj = objects.world[name]
	obj.body = love.physics.newBody(physicsWorld, xpos, ypos, density == 0 and "static" or "dynamic") --dynamic is very important!!
	obj.shape = love.physics.newPolygonShape(verts)
	obj.fixture = love.physics.newFixture(obj.body, obj.shape, density)
	if density == 0 then obj.density = 1 end

	obj.fixture:setRestitution(restitution)
	obj.fixture:setFriction(friction)
	obj.fixture:setUserData(obj)
	obj.fixture:setCategory(CATEGORY_NORMAL)

	obj.body:setAngularDamping(1)

	--set type
	obj.type = "polygon"

	updateObjectMass(name)
end

function createBox(name, sprite, xpos, ypos, w, h, density, friction, restitution, collision, controllable, z_order)
	objects.world[name] = {name = name, sprite = sprite, y = ypos, x = xpos, width = w, height = h or w, density = density,
		friction = friction, restitution = restitution, collision = collision, controllable = controllable or false, z_order = z_order, mass = 1, xVel = 0, yVel = 0, angle = 0}
	local obj = objects.world[name]

	obj.body = love.physics.newBody(physicsWorld, xpos, ypos, density == 0 and "static" or "dynamic") --dynamic is very important!!
	obj.shape = love.physics.newRectangleShape(w, h)
	obj.fixture = love.physics.newFixture(obj.body, obj.shape, density)
	
	obj.fixture:setCategory(CATEGORY_NORMAL)
	if density == 0 then
		obj.density = 1
		if name ~= "ground" then
			obj.fixture:setCategory(CATEGORY_STATIC)
			obj.fixture:setMask(CATEGORY_BACKGROUND)
		end
	end

	obj.fixture:setRestitution(restitution)
	obj.fixture:setFriction(friction)
	obj.fixture:setUserData(obj)
	
	obj.body:setAngularDamping(1)

	--set type
	obj.type = "box"

	updateObjectMass(name)
end

function createCircle(name, sprite, xpos, ypos, w, density, friction, restitution, controllable, z_order)
	objects.world[name] = {name = name, sprite = sprite, y = ypos, x = xpos, radius = w, height = w, density = density,
		friction = friction, restitution = restitution, controllable = controllable, z_order = z_order, mass = 1, xVel = 0, yVel = 0, angle = 0}
	local obj = objects.world[name]

	-- if controllable then obj.density = obj.density * 100 end

	obj.body = love.physics.newBody(physicsWorld, xpos, ypos, obj.density == 0 and "static" or "dynamic")
	obj.shape = love.physics.newCircleShape(w or 1)
	obj.fixture = love.physics.newFixture(obj.body, obj.shape, obj.density)
	if density == 0 then obj.density = 1 end

	obj.fixture:setRestitution(restitution)
	obj.fixture:setFriction(friction)
	obj.fixture:setUserData(obj)

	obj.body:setAngularDamping(1)
	
	if z_order >= 999 then
		obj.isBackground = true
		obj.fixture:setCategory(CATEGORY_BACKGROUND)
		obj.fixture:setMask(CATEGORY_STATIC)
	else
		obj.fixture:setCategory(CATEGORY_NORMAL)
	end

	--set type
	obj.type = "circle"

	updateObjectMass(name)
end