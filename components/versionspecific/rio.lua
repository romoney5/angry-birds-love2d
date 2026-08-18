--rio and related games
function logMedioEvent()
end

function logMedioAnonymousIDtoFlurry()
end

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

function requestAndShowInterstitialAd()

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
	for jointName, joint in pairs(objects.joints) do
		if joint.end1 == name or joint.end2 == name then
			destroyJoint(jointName)
		end
	end
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

--1.0.0

function createRovioNews(x, y, width, height)
	return
end

function loadRovioNewsContent(rovioNewsURL)
	return
end

function getTimeDifference(a, b)
	local function getDate(t)
		local timestamp = t
		timestamp.hour = timestamp.hour or t.hours
		timestamp.min = t.minutes
		timestamp.sec = t.seconds
		return os.time(timestamp)
	end
	
	local timeDiff = getDate(b) - getDate(a)
	local direction = 0
	
	if timeDiff > 0 then direction = 1
	elseif timeDiff < 0 then direction = -1 end
	
	return {
		days = math.floor(timeDiff / 86400),
		hours = math.floor((timeDiff % 86400) / 3600),
		minutes = math.floor((timeDiff % 3600) / 60),
		seconds = math.floor(timeDiff % 60),
		diff = timeDiff, direction = direction }
end

function getTimeDifferenceInCalendarDays(a, b)
	local timeDiff = getTimeDifference(a, b).diff
	return math.floor(timeDiff / 86400 + 0.5)
end

--epacs

drawForeground = drawForegroundNative

function setPivotOffset(object, x, y)
	return
end

function setDecorationObjects(name)
	return
end

function renderGravityVisualsNative(v, sx, sy, worldScale)
	return --8532
end

function setAimingAidSprite(aimingAidSprite)
	return
end

function ClearSimulationTrajectory()
	return
end

function clearAimingAid(num)
	return
end

function populateAimingAid()
	return
end

function setObjectGravityCategory(str, category)
	return
end

function setSelectedBirdDuringSimulation(name)
	return
end

function updateBirdTrajectoryTable()
	return --5393
end

function setNormalTrailSprite(normalTrailSprite)
	return
end

function setSpecialTrailSprite(specialTrailSprite)
	return
end

function getAimingTime()
	return 0
end