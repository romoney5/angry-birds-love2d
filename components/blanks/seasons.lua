-- seasons 4.2.0
NativePlatformScore = {}

function NativePlatformScore.getPerformanceScore()
    return 2 
end

function NativePlatformScore.getMemoryScore()
    return 2 
end

function createDynamicHandler(name)
	local handler = {}
	local loadlist = {}
	local selectAssetProfile = selectAssetProfile or (platform and platform.Profiles and platform.Profiles.selectAssetProfile)

	local loadlists = {loadlist = {}, neatLoadlist = {}}
	
	--TODO: queue and asset freeing
	
	local function load(group)
		if loadlist[group] then
			for i, v in pairs(loadlist[group]) do
				local profile = selectAssetProfile(v)
				
				for i, list in ipairs{"loadlist", "neatLoadlist"} do
					if not loadlists[list][profile] then
						loadLuaFile(imagePath.."/"..profile.."/"..list..".lua")
						loadlists[list][profile] = assetLoadList[profile]
					end
					
					local dat = loadlists[list][profile][v]
					if dat then
						for _, asset in ipairs(dat) do
							if asset[2] ~= 1 then
								res.createSpriteSheet(imagePath.."/"..profile.."/"..asset[1])
							else
								res.createCompoSpriteSet(imagePath.."/"..profile.."/"..asset[1])
							end
						end
					end
				end
			end
		end
	end
	
	function handler.addreq(...)
		print("addreq:")
		for i, v in pairs{...} do
			if type(v) == "table" then
				for i, v in pairs(v) do
					loadlist[i] = v
				end
			end
		end
		for i, v in pairs{...} do
			if type(v) == "table" then
				print(i..":")
				for i, v in pairs(v) do
					if type(v) == "table" then
						print("", i..":")
						for i, v in pairs(v) do
							print("", "", i, v)
						end
					else
						print("", i, v)
					end
				end
			else
				print(v)
			end
		end
		return
	end
	
	function handler.getRequirements(...)
		print("handler.getRequirements:", ...)
		return {} 
    end
	
	function handler:delayrelease(...) end

	function handler.load(...)
		print("handler.load:", ...)
		for i, v in pairs{...} do
			if type(v) == "table" then
				for i, v in pairs(v) do
					load(v)
				end
			else
				load(v)
			end
		end
	end
	function handler.release(...) end
	function handler.isLoaded(...) return true end
	
	function handler.loadInGame(a, theme)--?
		return 
	end
	
	function handler.enterIngame(a, theme)
		return 
	end	
	
	function handler.releaseInGame(a, theme)
		return 
	end

	_G[name] = handler
	--print("platform is", tostring(platform))
	
	return handler
end

function flashAnimationPreLoad()--?
	return
end

function flashAnimationLoad()--?
	return
end

function flashAnimationReplaceImage()--?
	return
end

function flashAnimationStart()--?
	return
end

function flashAnimationSetAnimationParameters()--?
	return
end

function updateFlashAnimation()--?
	return
end

function drawFlashAnimation()--?
	return
end

function flashAnimationClose()--?
	return
end

function flashAnimationPauseToLast()--?
	return
end


function enablePigDaysVignette(enabled)--?
	return
end


function drawAdditiveShaders()--?
	return
end


function getCameraTopLeft()--?
	return screen.top, screen.left
end

function setCameraViewport(a, b, c, d)--?
	setTopLeft(a, b)
end

RovioAssetService = {}

function RovioAssetService.loadAssets(a)
	return
end

native.GetTimeStamp = {}

function native.GetTimeStamp.fetchTimeStamp()--?
	return 0
end

function native.GetTimeStamp.hasResult()
	return false
end

cloudDomain = ""