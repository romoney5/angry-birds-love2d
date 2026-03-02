--rio and related games

function setRetinaResolution(retina)
	print("Retina is now set to "..tostring(retina))
end

function setGameParameters(params)
	return
end

function toggleNFC(nfc)
	print("NFC is now set to "..tostring(nfc))
end

function enableSmoothZooming(smoothzooming)
	print("Smooth zooming is now set to "..tostring(smoothzooming))
end

function updateBackgroundAndForegroundScrollingNative(dt, _bool)
	return
end

function setParticleSystemLimits(leftLimit, rightLimit)
	return
end

function setCollisionEnabled(object, enabled)
	local obj = objects.world[object]
	if obj and obj.fixture then
		local categories, _, group = obj.fixture:getFilterData()
		obj.fixture:setFilterData(categories, enabled and 1 or 0, group)
	end
end

--updateThemeSpriteAnimations
function rotateThemeSprites(dt)
	return
end

function removeJointsFromObject(name)
	return
end

--latest pc version
function getGameTimer()
	return love.timer.getTime()
end

function getGameTimerMillis()
	return love.timer.getTime() / 1000
end

function updateMenuParticlesNative()
	return
end

function drawMenuParticlesNative()
	return
end

function clearMenuParticlesNative()
	return
end

--absw
function native_setWaterDensity(name, density)
	return
end

function setSensorGravityMask(name, mask)
	return
end

function setCameraLimits(limit)
	return
end

function ClearSimulationTrajectory()
	return
end

function resetMouseWheelScale(scale)
	return
end

function enableInGameParticlesNative(enabled)
	return
end

function clearAimingAid(clear)
	return
end

function enableAimingAid(enabled)
	return
end

function setThemeOffsetY(theme, y)
	return
end

function clearParticlesNative()
	return
end

--implementable
function setTextureScale(name, textureScale)
	return
end

function setSpriteRotation(name, angle)
	return
end

function checkJointLimits(name)
	return
end