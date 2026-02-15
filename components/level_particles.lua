LevelParticlesManager = {}

local weatherParticles = {}

function LevelParticlesManager.getLevelParticles()
	return objects.levelParticles or objects.levelWeather
end

function LevelParticlesManager.getWeatherParticles()
	return weatherParticles
end

function LevelParticlesManager.firstFrame()
	local levelParticles = LevelParticlesManager.getLevelParticles()
	local particle = particleTable.particles[levelParticles.particles]
	
	if not particle then
		return
	end
	
	weatherParticles.particles = levelParticles.particles
	weatherParticles.looping = particle.looping
	weatherParticles.isCloudEmitter = particle.isCloudEmitter
	
	local bcd = objects.birdCameraData[deviceModel]
	local ccd = objects.castleCameraData[deviceModel]
	
	if weatherParticles.looping then
		weatherParticles.x = screenWidth * 0.5 + screen.left
		weatherParticles.y = screenHeight * 0.5 + screen.top
		weatherParticles.width = (screen.right - screen.left) * 1.04
		weatherParticles.height = (screen.bottom - screen.top) * 1.04
		
		_G.assert(particle.density ~= nil, "Looping particle effects need a \'density\'")
		weatherParticles.amount = particle.density / 100000 * screenWidth * screenHeight
	elseif weatherParticles.isCloudEmitter then
		local reference = particle.reference
		
		weatherParticles.x = objects.leftLimit - screenWidth * 0.1
		weatherParticles.y = reference.y
		weatherParticles.width = reference.width
		weatherParticles.height = reference.height
		
		particle.lifeTime = (objects.rightLimit - objects.leftLimit + screenWidth * 0.2) / particle.emitter_box.minVelX
		weatherParticles.lifeTime = particle.lifeTime
		weatherParticles.interval = reference.delay
	else
		weatherParticles.x = (ccd.px + screenWidth / ccd.sx + bcd.px - screenWidth * 0.5 / bcd.sx) / 2
		weatherParticles.width = ccd.px + ccd.screenWidth / ccd.sx - bcd.px - bcd.screenWidth / bcd.sx
		
		if levelParticles.startAtGroundLevel then
			weatherParticles.y = 0
		elseif g_levelParticlesEnabled then
			weatherParticles.y = _G.math.min(ccd.py, ccd.py) - screenHeight * 0.5 / screenHeight * minWorldScale / screenWidth
			weatherParticles.x = weatherParticles.x + _G.math.abs(weatherParticles.y) * 0.5
			weatherParticles.width = weatherParticles.width + _G.math.abs(weatherParticles.y) * 0.5
			if particle.reference then
				weatherParticles.interval = 1 / particle.reference.amount
			else
				weatherParticles.firstFrame = true
			end
		else -- legacy
			weatherParticles.y = _G.math.max(ccd.py - ccd.screenHeight / ccd.sy, bcd.py - bcd.screenHeight / bcd.sy) - groundLimit
			weatherParticles.width = weatherParticles.width + (particle.maxVelX or particle.emitter_circle.maxVel or 0)
			weatherParticles.firstFrame = true
		end
		weatherParticles.height = 0
		weatherParticles.lifeTime = particle.lifeTime
	end
	
	print(weatherParticles.x, weatherParticles.y, weatherParticles.width, weatherParticles.height)
	print(levelParticles.x, levelParticles.y, levelParticles.width, levelParticles.height)
	
	LevelParticlesManager.initialized = true
end

local function update(delta)
	local weather = weatherParticles
	_G.assert(weather.timer ~= nil, "LevelParticlesManager.start has not been called")
	weather.timer = weather.timer + delta
	if weather.interval <= weather.timer then
		local min, max = _G.math.modf(weather.timer / weather.interval)
		particles.addParticles(weather.particles, min, weather.x, weather.y, weather.width, weather.height, 0, false, false)
		weather.timer = max
	end
end

function LevelParticlesManager.start()
	local levelParticles = LevelParticlesManager.getLevelParticles()
	local weather = weatherParticles
	
	weather.timer = 0
	if weather.looping then
		particles.addParticles(weather.particles, weather.amount, weather.x, weather.y, weather.width, weather.height, 0, true, false)
		LevelParticlesManager.firstFrame()
	else
		if weather.firstFrame ~= nil then
			if weather.firstFrame then
				weather.amount = levelParticles.settingsBegin.amount
				weather.ignoreLimits = levelParticles.settingsBegin.ignoreLimits
				weather.firstFrame = false
			else
				weather.amount = levelParticles.settingsFrame.amount
				weather.ignoreLimits = levelParticles.settingsFrame.ignoreLimits
			end
			
			weather.interval = 1 / weather.amount
		end
		
		local delay = 0
		while delay < weather.lifeTime do
		    local interval = weather.interval
		    update(interval)
		    delay = delay + interval
		end
	end
end