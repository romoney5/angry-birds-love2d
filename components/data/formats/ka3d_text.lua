--localization

function readText(fileData,head)
	data = {langs = {}}
	local langs = {}
	local texts = {}

	--we landed on a 2nd format value
	if head=="KA3D"then assert(readString(fileData,pos,4)=="LDAT","Not localization data..") end
	skip(4+4) --skip over format and unknown data
	if head ~= "KA3D"then pos = 6-1 end
	--now we land on languages amount
	local languagesAmount
	if head=="KA3D"then languagesAmount=readInt(fileData,pos) else languagesAmount=read8Int(fileData,pos+1) end
	skip(2)
	
	for i=1,languagesAmount do
		local langLength = readInt(fileData,pos)
		if langLength > 64 then error("Language length too long: "..langLength) end
		local lang = readString(fileData,pos+2,langLength)

		-- data.langs[lang] = {}
		langs[i] = lang
		skip(langLength+2)
	end

	if head=="KA3D"then assert(readString(fileData,pos,4)=="LIDS","Language IDs in localization file not found.") skip(4+4) end
	--skip(4 + 4) --skip over lids, empty 2 bytes, and 1949 for some reason

	local textsAmount = readInt(fileData,pos)
	skip(2)

	for i=1,textsAmount do
		local textLength = readInt(fileData,pos)
		if textLength > 64 then error("Text length too long: "..textLength) end
		local text = readString(fileData,pos+2,textLength)

		table.insert(texts,i,text)
		skip(textLength+2)
	end

	if head ~= "KA3D"then skip(read32Int(fileData,pos)+4) end

	for i,v in ipairs(langs)do
		-- print(readInt16(fileData,pos))
		if head=="KA3D"then assert(readString(fileData,pos,4)=="TXGP","TXGP in localization file not found.") skip(4 + 4) end --what are these cryptic names
		data.langs[v] = {}

		for ii,vv in ipairs(texts) do
			local textLength = readInt(fileData,pos)
			-- if textLength > 1024 then error("Text length a bit long: "..textLength) end
			local text = readString(fileData,pos+2,textLength)

			data.langs[v][vv] = text
			skip(textLength+2)
		end
	end
	return data
end