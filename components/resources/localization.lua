--localization

function res.getString(category, key) --return a string from localization
	local group = textGroups[category]
	if group and group.en_EN then
		return group.en_EN[key] and group.en_EN[key]:gsub("%\\0A","\n") or key
	else
		return key
	end
end

function getLocalizationString(key)
	for i,group in pairs(textGroups)do
		if group.en_EN and group.en_EN[key] then
			return group.en_EN[key]:gsub("%\\0A","\n") or key
		end
	end
	return key
end

function res.createTextGroupSet(texts)
	print("Loading text group.. "..texts)
	local info = getDatInfo(love.filesystem.read(dataPath.."/"..texts),dataPath.."/"..texts,"TEXT")
	local filename = "" for i,v in texts:gmatch("([^/]+)")do filename = i end

	textGroups[filename:sub(1,#filename-4)] = info.langs
end

function res.loadLocale(texts,locale)
	return
end

function res.useLocale(locale)
	return
end

function res.getLocale()
	return "en_US"
end