--main function for reading dat files

pos = 0
function getDatInfo(fileData,fn,fallback)
	assert(fileData~=nil, "DAT is empty (file: "..tostring(fn)..")")

	local data = {}
	pos = 1
	local version,format = 0,""
	-- assert(readString(fileData,pos,4) == "KA3D", "Wrong DAT format (file: "..tostring(fn)..")")
	local head = readString(fileData,pos,4)
	if head == "KA3D" or head == "RVIO" then
		version = readInt(fileData,17)

		--skip over KA3D (4), filesize (4), format (4), version (2), and more filesize (4)
		skip(4+4)
		format = readString(fileData,pos,4)
		skip(4+2+4)
	else --ancient dat format missing all of the ka3d header (seems to hopefully only be used for sprites) (it's also used by fonts in 1.0)
		format = fallback
	end

	if format == "SPRT" and fn:sub(1,5)~="FONT_" and fn:sub(1,6)~="TEXTS_" then --spritesheet
		data = readSprt(fileData)
	elseif format == "COMP" then --composprites
		data = readComp(fileData,head,version)
	elseif format == "FONT" then --font
		data = readFont(fileData)
	elseif format == "TEXT" then --localization (by far the hardest one)
		data = readText(fileData,head)
	end

	return data
end