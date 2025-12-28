--composprites (both formats)

function readComp(fileData,head,version)
	data = {compos = {}}
	skip(2)
	if head == "RVIO" then
		--new composprite
		data.rvio = true

		for i=1,readInt(fileData,pos-2),1 do --each composprite
			local csnameLength = readInt(fileData,pos)
			local csname = readString(fileData,pos+2,csnameLength)
			data.compos[csname] = {}
			skip(csnameLength+2+2)

			for ii=1,readInt(fileData,pos-2),1 do --each sprite
				local spritenameLength = readInt(fileData,pos)
				local spritename = readString(fileData,pos+2,spritenameLength)
				pos = pos + spritenameLength + 2
				local sheetnameLength = readInt(fileData,pos)
				local sheetname = sheetnameLength>0 and readString(fileData,pos+2,sheetnameLength) or ""
				pos = pos + sheetnameLength + 2
				data.compos[csname][ii] = {sheet = sheetname,
											x = readInt(fileData,pos),
											y = readInt(fileData,pos+2),
											sx = readFloat(fileData,pos+4),
											sy = readFloat(fileData,pos+8),
											a = readFloat(fileData,pos+12),
											flip = {x=readBool(fileData,pos+16),y=readBool(fileData,pos+17)},
											n = spritename}
				skip(18)
			end
		end
	else
		--older composprite
		for i=1,readInt(fileData,pos-2),1 do --each composprite
			local csnameLength = readInt(fileData,pos)
			local csname = readString(fileData,pos+2,csnameLength)
			data.compos[csname] = {}
			skip(csnameLength+2+2)

			for ii=1,readInt(fileData,pos-2),1 do --each sprite
				local spritenameLength = readInt(fileData,pos)
				local spritename = readString(fileData,pos+2,spritenameLength)
				skip(spritenameLength + 2)
				data.compos[csname][ii] = {x = readInt(fileData,pos),
											y = readInt(fileData,pos+2), n = spritename}
				skip(4)
			end
			if version == 2 then skip(2) end --odd..
		end
	end
	return data
end