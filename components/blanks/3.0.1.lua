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