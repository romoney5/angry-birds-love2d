--localization

local textGroups = {}
local locale = "en_EN"

--return a string from localization
function res.getString(category, key)
	local group = textGroups[category]
	
	if group then
		local set = group[locale] or group.default
		
		if set and set[key] then
			return set[key]
		end
	end
	
	return key
end

function res.createTextGroupSet(texts)
	local path = datapath.."/"..texts
	print("Loading localization file \""..texts.."\"...")
	
	if not love.filesystem.exists(path) then
		print("Localization file \""..texts.."\" not found.")
		return
	end
	
	local info = getDatInfo(love.filesystem.read(path), path, "TEXT")
	local filename = ""
	for i, v in texts:gmatch("([^/]+)") do
		filename = i
	end

	textGroups[filename:sub(1, #filename - 4)] = info.langs
end

function res.loadLocale(texts,locale)
	return
end

function res.useLocale(uselocale)
	locale = uselocale
end

function res.getLocale()
	return locale
end

function gamelua.getCurrentLocale()
	return locale
end

--seasons 6.1.1
NativeLocalization = {}

function NativeLocalization.loadTextGroup(fileName, groupName)
	print("Loading localization file \""..fileName.."\"...")
	
	local newname, paths = findCaseInsensitive(datapath.."/"..fileName)
	
	if not newname then
		print("Localization file \""..fileName.."\" not found.")
		
		return
	end
	
	local jsondata = json.decode(decryptSrc(newname))
	
	textGroups[groupName] = jsondata.locales
end
