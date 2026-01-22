--create box, circle, etc

--funky
function createJoint(joint)
	local name, end1, end2, type, coordType, x1, y1, x2, y2, collideConnected, limit, motor, maxTorque, lowerLimit, upperLimit, motorSpeed, destroyTimer =
		joint.name,joint.end1,joint.end2,joint.type,joint.coordType,joint.x1,joint.y1,joint.x2,joint.y2,joint.collideConnected,
		joint.limit,joint.motor,joint.maxTorque,joint.lowerLimit,joint.upperLimit,joint.motorSpeed,joint.destroyTimer
	local obj1, obj2 = objects.world[end1], objects.world[end2]

	if not obj1 or not obj2 then return end

	local newJoint
	
	if type == 1 then --distance joint
		local anchorAX, anchorAY, anchorBX, anchorBY
		
		joint.frequency = frequency or 4.0
		joint.dampingRatio = dampingRatio or 0.5
		
		if coordType == 0 then
			anchorAX, anchorAY = obj1.body:getPosition()
			anchorBX, anchorBY = obj2.body:getPosition()
		elseif coordType == 1 then
			anchorAX, anchorAY = x1, y1
			anchorBX, anchorBY = x2, y2
		elseif coordType == 2 then
			anchorAX, anchorAY = obj1.body:getWorldPoint(x1, y1)
			anchorBX, anchorBY = obj2.body:getWorldPoint(x2, y2)
		end
		
		newJoint = love.physics.newDistanceJoint(obj1.body, obj2.body, 
			anchorAX, anchorAY, 
			anchorBX, anchorBY, 
			collideConnected)
		
		if newJoint.setFrequency then -- backwards compability
			newJoint:setFrequency(joint.frequency)
		else
			newJoint:setStiffness(joint.frequency)
		end
		
		if newJoint.setDampingRatio then
			newJoint:setDampingRatio(joint.dampingRatio)
		else
			newJoint:setDamping(joint.dampingRatio)
		end
		
	elseif type == 2 then --weld joint
		local anchorAX, anchorAY = obj1.body:getWorldPoint(x1, y1)
		local anchorBX, anchorBY = obj2.body:getWorldPoint(x2, y2)
		
		local x = anchorAX + (anchorBX - anchorAX) * 0.5
		local y = anchorAY + (anchorBY - anchorAY) * 0.5
		
		newJoint = love.physics.newWeldJoint(obj1.body, obj2.body, x, y, collideConnected)
	elseif type == 3 then --revolute joint
		local anchorX, anchorY = obj1.body:getWorldPoint(x1, y1)
		
		newJoint = love.physics.newRevoluteJoint(obj1.body, obj2.body, anchorX, anchorY, collideConnected)
		
		joint.motorSpeed = motorSpeed or 0.0
		joint.lowerLimit = lowerLimit or 0.0
		joint.upperLimit = upperLimit or math.pi

		joint.motor = motor or false
		joint.maxTorque = maxTorque or 10000.0
		joint.limit = limit or false
		
        if joint.backAndForth then
            joint.direction = 1
			joint.motorSpeed = math.rad(joint.motorSpeed)
        end
		
		newJoint:setMotorEnabled(joint.motor)
		newJoint:setMotorSpeed(joint.motorSpeed)
		newJoint:setMaxMotorTorque(joint.maxTorque)
		newJoint:setLimitsEnabled(joint.limit)
		newJoint:setLimits(joint.lowerLimit, joint.upperLimit)
		
	elseif type == 4 then --prismatic joint
		local anchorX, anchorY = obj1.body:getWorldPoint(x1, y1)
		
		newJoint = love.physics.newPrismaticJoint(obj1.body, obj2.body,
			anchorX, anchorY,
			joint.worldAxisX or 0.0,
			joint.worldAxisY or 0.0,
			collideConnected
		)
		
		joint.motorSpeed = motorSpeed or 0.0
		joint.lowerLimit = lowerLimit or 0.0
		joint.upperLimit = upperLimit or 5.0

		joint.motor = motor or true
		joint.maxTorque = maxTorque or 10000.0
		joint.limit = limit or true
		
        if joint.backAndForth then
            joint.direction = 1
			joint.motorSpeed = math.rad(joint.motorSpeed)
        end
		
		newJoint:setMotorEnabled(joint.motor)
		newJoint:setMotorSpeed(joint.motorSpeed)
		newJoint:setMaxMotorForce(joint.maxTorque) --equivalent to setMaxMotorTorque?
		newJoint:setLimitsEnabled(joint.limit)
		newJoint:setLimits(joint.lowerLimit, joint.upperLimit)
		
	elseif type == 5 then --annihilation joint
		local anchorAX, anchorAY = obj1.body:getWorldPoint(x1, y1)
		local anchorBX, anchorBY = obj2.body:getWorldPoint(x2, y2)
		
		local x = anchorAX + (anchorBX - anchorAX) * 0.5
		local y = anchorAY + (anchorBY - anchorAY) * 0.5

		joint.destroyTimer = destroyTimer or 1.0
		
		newJoint = love.physics.newWeldJoint(obj1.body, obj2.body, x, y, collideConnected)
	end

	objects.joints[name] = joint
	joint.joint = newJoint
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

local CATEGORY_IMMOVABLE = 0x0001
local CATEGORY_SENSOR = 0x0002
local CATEGORY_BLOCK = 0x0004
local CATEGORY_BIRD = 0x0008
local CATEGORY_EAGLE = 0x0010

function createPolygon(name, sprite, xpos, ypos, w, h, density, friction, restitution, collision, controllable, z_order)
	local verts = polyverts
	if z_order then --1.6.3.1 and below
		objects.world[name] = {name = name, sprite = sprite, y = ypos, x = xpos, width = w, height = h or w, density = density,
			friction = friction, restitution = restitution, controllable = controllable or false, z_order = z_order, mass = 1, xVel = 0, yVel = 0, angle = 0}
	else --3.0.1
		objects.world[name] = {name = name, sprite = sprite, y = ypos, x = xpos, width = 1, height = 1, density = h,
			friction = density, restitution = friction, controllable = collision or false, z_order = controllable, mass = 1, xVel = 0, yVel = 0, angle = 0}
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
	obj.fixture:setCategory(CATEGORY_BLOCK)
	
	if collision ~= false then
		obj.fixture:setCategory(CATEGORY_SENSOR)
	end

	obj.body:setAngularDamping(2)

	addObjectToRenderQueue(name)

	--set type
	obj.type = "polygon"

	updateObjectMass(name)
end

function createBox(name, sprite, xpos, ypos, w, h, density, friction, restitution, collision, controllable, z_order)
	objects.world[name] = {name = name, sprite = sprite, y = ypos, x = xpos, width = w, height = h or w, density = density,
		friction = friction, restitution = restitution, controllable = controllable or false, z_order = z_order, mass = 1, xVel = 0, yVel = 0, angle = 0}
	local obj = objects.world[name]

	obj.body = love.physics.newBody(physicsWorld, xpos, ypos, density == 0 and "static" or "dynamic") --dynamic is very important!!
	obj.shape = love.physics.newRectangleShape(w, h)
	obj.fixture = love.physics.newFixture(obj.body, obj.shape, density)
	
	obj.fixture:setCategory(CATEGORY_BLOCK)
	
	if density == 0 then 
		obj.density = 1
		if name ~= "ground" then
			obj.fixture:setCategory(CATEGORY_IMMOVABLE)
			obj.fixture:setMask(CATEGORY_EAGLE)
		end
	end
	
	if controllable then
		obj.fixture:setCategory(CATEGORY_BIRD)
	end
	
	if collision ~= true then
		obj.fixture:setFilterData(1, 0, 0)
	end

	obj.fixture:setRestitution(restitution)
	obj.fixture:setFriction(friction)
	obj.fixture:setUserData(obj)
	
	obj.body:setAngularDamping(2)

	addObjectToRenderQueue(name)

	--set type
	obj.type = "box"

	updateObjectMass(name)
end

function createCircle(name, sprite, xpos, ypos, w, density, friction, restitution, controllable, z_order)
	objects.world[name] = {name = name, sprite = sprite, y = ypos, x = xpos, radius = w, height = w, density = density,
		friction = friction, restitution = restitution, controllable = controllable, z_order = z_order, mass = 1, xVel = 0, yVel = 0, angle = 0}
	local obj = objects.world[name]

	-- if controllable then obj.density = obj.density * 100 end

	obj.body = love.physics.newBody(physicsWorld, xpos, ypos, obj.density <= 0 and "static" or "dynamic")
	obj.shape = love.physics.newCircleShape(w or 1)
	obj.fixture = love.physics.newFixture(obj.body, obj.shape, obj.density)
	if density == 0 then obj.density = 1 end

	obj.fixture:setRestitution(restitution)
	obj.fixture:setFriction(friction)
	obj.fixture:setUserData(obj)

	obj.body:setAngularDamping(2)

	addObjectToRenderQueue(name)

	if tonumber(z_order) and z_order >= 999 then
		obj.isBackground = true
		obj.fixture:setCategory(CATEGORY_EAGLE)
		obj.fixture:setMask(CATEGORY_IMMOVABLE)
	elseif controllable then
		obj.fixture:setCategory(CATEGORY_BIRD)
	else
		obj.fixture:setCategory(CATEGORY_BLOCK)
	end

	--set type
	obj.type = "circle"

	updateObjectMass(name)
end

function addObjectToRenderQueue(name)
	local obj = objects.world[name]
	obj.z_order = obj.z_order or 0
	
	local z = math.floor(obj.z_order)
	zOrderedObjects[z] = zOrderedObjects[z] or {}
	table.insert(zOrderedObjects[z], {name = name, z_order = obj.z_order})
	objectsSorted = false
end

--absw
function createJoints(joints)
	for k, v in pairs(joints) do
		createJoint(v)
	end
end