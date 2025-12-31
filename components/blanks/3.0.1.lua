--classic 3.0.1/4.0.0

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
		objects.world[name].damageSprite = obj.damageSprite
		setRotation(name, obj.angle)
		setVelocity(name, obj.xVel, obj.yVel)
		setMaterial(name, obj.material)
		if obj.controllable then
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