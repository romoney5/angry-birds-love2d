--build all spritesheets and composprites to a spriteinfo.lua file

function makeImages(force,path)
	local path = path or dataPath..imagePath.."/"..(selectAssetProfile and selectAssetProfile("") or "1024x768")
	if not checkDirectory(path) then path = dataPath..imagePath.."/1024x768_pc" end
	if not checkDirectory(path) then path = "/" end
	
	if (love.keyboard.isDown and love.keyboard.isDown("lctrl")) or not checkDirectory("spriteinfo.lua") or force then
		--load all the spritesheets

	    print("remaking spritesheets..")
		-- love.graphics.print("Remaking spritesheet and composprite list..", screenWidth/16, screenHeight/16)
		-- love.graphics.present()
		cachedimgs = {csprites = {}}
		local its = #love.filesystem.getDirectoryItems(path)
		for i,sprite in pairs(love.filesystem.getDirectoryItems(path)) do
			if endswith(sprite,".dat") then
				local data = love.filesystem.read(path.."/"..sprite)
				local info = getDatInfo(data,sprite,"SPRT")
				if info.compos then
					for i,v in pairs(info.compos)do
						cachedimgs.csprites[i] = v
					end
				elseif info.sprites and info.filename then
					local filename = info.filename
					local extension = ".png"
					if endswith(filename,".pvr") then extension = ".pvr.png" filename=filename..".png" end
					if endswith(filename,".webp") then extension = ".webp.png" filename=filename..".png" end
					-- print(sprite)
					local spritesheet = love.graphics.newImage(path.."/"..filename)
					for i,spr in pairs(info.sprites) do
						-- if i:sub(1,21)=="THEME_GROUND_TEXTURE_"then print(filename:sub(1,-5))end
						cachedimgs[i] = {q=love.graphics.newQuad(spr.x, spr.y, spr.width, spr.height,spritesheet:getWidth(),spritesheet:getHeight()),
							spsh=spritesheet,px=spr.pivotX,py=spr.pivotY,src=path.."/"..sprite:sub(1,-5)..extension}--imagePath.."/img/"..sprite:sub(1,-5)..".png"}
					end
				end
				love.graphics.clear()
				love.graphics.print("Building sprite list..\n"..
									"This may take a while.\n\n"..
									"Current file: "..sprite, screenWidth/16, screenHeight/16)
				love.graphics.print(math.floor(i/its*100).."%\n", (screenWidth-20)*(i/its)*.5, screenHeight-48)
				love.graphics.rectangle("line", 10, screenHeight-20, (screenWidth-20)*(i/its), 10, rx, ry, segments)
				love.graphics.present()
				love.event.pump()
				if love.keyboard.isDown("escape") then print("abort") error()return end
			end
		end
		
		for i,v in pairs(cachedimgs.csprites)do
			local x0,x1,y0,y1 = 0,0,0,0
			
			for ii,vv in pairs(v)do
				local sprite = cachedimgs[vv.n]
				if sprite then
					local _,_,w,h = sprite.q:getViewport()
					x0,x1 = math.min(x0,vv.x - w),math.max(x1,vv.x + w)
					y0,y1 = math.min(y0,vv.y - h),math.max(y1,vv.y + h)
				end
			end
			v.bounds = {x=x1,x0=x0,y=y1,y0=y0}
			cachedimgs.csprites[i] = v
		end
		
		saveLuaFileLocal("spriteinfo.lua",cachedimgs,"cachedimgs2",true,"local q = love.graphics.newQuad\nsi_version = 1\n")
		for i,image in pairs(cachedimgs) do
			if image.q then
				local _,_,w,h = image.q:getViewport()
				cachedimgs[i].w,cachedimgs[i].h = w,h
			end
		end
		cachedimgs2 = cachedimgs
	else
		runLuaFile("spriteinfo.lua")

		if si_version ~= 1 then
			cachedimgs2 = nil
			showPopup("Warning",
						"The spriteinfo.lua version is too old. ("..tostring(si_version)..")\nIt might be a result of updating the game.\nThe file will now be remade.",
						{
							{sprite = "TUTORIAL_OK", callback = function()
								love.graphics.setBlendMode("alpha")
								makeImages(true)
								return true
							end},
						}
					) currentPopup.important = true
		end
		-- local cursors = love.filesystem.read(imagePath.."/img/".."CURSORS_SHEET_1.dat")
		-- getDatInfo(cursors)
	end
	love.graphics.setBlendMode("alpha","premultiplied")
end