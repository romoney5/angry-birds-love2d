--localization

locale = "en_EN"

function res.getString(category, key) --return a string from localization
	local group = textGroups[category]
	if group and group[locale] then
		return group[locale][key] or key
	else
		return key
	end
end

function res.createTextGroupSet(texts)
	local path = datapath.."/"..texts
	print("Loading text group set \""..texts.."\"...")
	
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

function getCurrentLocale()
	return locale
end