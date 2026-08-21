--file and folder-related functions

--cache decrypted files in the save directory to speed up loading dramatically
local ALLOW_LUA_CACHE = true

--replace a missing filename due to case sensitivity
function findCaseInsensitive(dir)
	local dir, paths = resolvePath(dir)

	if checkDirectory(dir) then
		--it's there already
		return dir, paths
	elseif dir and dir ~= "" then
		if #paths == 0 then return "" end

		local name = paths[#paths] --get the filename now

		for lookfor_i = 1, #paths - 1 do
			local lookfor = table.concat(paths, "/", 1, lookfor_i)
			for _, f in ipairs(love.filesystem.getDirectoryItems(lookfor)) do
				if lookfor_i == #paths - 1 then
					if f:lower() == name:lower() then
						local output = lookfor.."/"..f
						local _, paths = resolvePath(output)
						return output, paths --return that and do ANOTHER resolvepath
					end
				else
					if f:lower() == paths[lookfor_i + 1]:lower() then
						paths[lookfor_i + 1] = f
						break
					end
				end
			end
		end
	end

	-- print("findCaseInsensitive: could not find "..dir)
	return nil, nil
end

--look recursively for any file and return its path
local function findAnything(dir)
	for i, file in ipairs(love.filesystem.getDirectoryItems(dir)) do
		local path = dir.."/"..file
		local info = love.filesystem.getInfo(path)

		if info.type == "file" then --ding ding ding!!!
			return path
		elseif info.type == "directory" then --look inside it then
			local result = findAnything(path)

			if result then return result end --ding ding ding 2!!
		end
	end
end

function identifySrc(src)
	--lzma support?
	if src:sub(1, 6) == "7z\xbc\xaf\x27\x1c" then return "7z" end
	if src:sub(2, 5) == "LZMA" then return "lzma" end
	if src:sub(1, 4) == "\27Lua" then return "lua" end
	if src:sub(1, 64):find("[\128-\255]") then return "binary" end
	return "plain" --what we want
end

--load either plain text lua, a precompiled chunk with fione,
--a 7-zipped file, an aes-256 encrypted file, or all of the above
function decryptSrc(filename, src)
	--use already-decrypted assets if available, moved here for json support
	local decinfo = ALLOW_LUA_CACHE and love.filesystem.getInfo("/dec/"..filename)
	local info = decinfo and love.filesystem.getInfo(filename)
	
	if decinfo and decinfo.modtime and info and info.modtime and decinfo.modtime >= info.modtime then
		src = love.filesystem.read("/dec/"..filename)
		return src
	end

	src = src or love.filesystem.read(filename)

	if not src then return end

	--temporary file for use in 7-zip
	local function temp_file()
		local dec_filename = "/dec/"..filename
		love.filesystem.createDirectory(dec_filename:match(".*/") or "")
		
		local success, message = love.filesystem.write(dec_filename, src)
		if not success then
			print("decryptSrc: writing to temporary file failed ("..tostring(message)..")")
			return
		end
		
		return dec_filename
	end
	
	local kind = identifySrc(src)
	
	if kind == "binary" then --it's probably encrypted..
		--let's use libcrypto as a dll/so
		if AES then
			local iv = nil --iv is always nil
			local key = AES.FindKey(src, AES.Keys.Assets, iv)

			if key then
				src = AES.Decrypt(src, key, iv)
				--equivalent to openssl enc -aes-256-cbc -d -K <key> -iv 0 -in <file>

				--make sure it worked..
				assert(src, "decryptSrc: libcrypto failure")
			else
				print("decryptSrc: could not find valid key, skipping")
			end
			
			--reidentify it
			kind = identifySrc(src)
		else
			print("decryptSrc: Could not run libcrypto for "..tostring(filename))
			return --just don't bother trying to run an encrypted file
		end
	end
	
	if kind == "lzma" then --new versions use lzma rather than 7z
		src = src:sub(1 + 9)
		local dec_filename = temp_file()
		
		--now use lzma with stdin and open it in binary mode on windows
		local mode = love._os == "Windows" and "rb" or "r"
		--xz utils' lzma works differently
		local cmd = love._os == "Windows" and "lzma d -so" or "lzma -d -c"
		local file = io.popen(cmd.." \""..love.filesystem.getSaveDirectory()..dec_filename.."\"", mode)
		if file then
			src = file:read("*a")
			file:close()
			
			--did it do anything?
			assert(src and src:len() > 0, "decryptSrc: LZMA returned nothing")
			
			--reidentify it
			kind = identifySrc(src)
		else
			print("decryptSrc: Could not run LZMA")
		end
	end
	
	if kind == "7z" then --looks like it's 7-zipped too
		--use 7-zip using love2d itself, many times faster than using 7-zip from the command line
		local temp = "temp_file"
		local filedata = love.filesystem.newFileData(src, temp)
		local success = love.filesystem.mount(filedata, temp)
		
		if success then
			--look everywhere for any sort of file
			local path = findAnything(temp)

			if path then
				src = love.filesystem.read(path)
			end

			love.filesystem.unmount(temp)
		else
			print("decryptSrc: Could not mount file")
		end
		
		--reidentify it
		kind = identifySrc(src)
	end
	
	if ALLOW_LUA_CACHE then
		temp_file()
	end
	
	--now it shouldn't be binary
	--assert(kind ~= "binary", "decryptSrc: file is binary")

	return src
end

function makeChunk(filename, env)
	--we need runnable lua code
	src = decryptSrc(filename)

	if not src then
		return nil, nil, "No source"
	end

	local kind = identifySrc(src)
	
	if kind == "lua" then --it's bytecode!
		print("Loading compiled Lua \""..filename.."\"...")
		local err, lua = pcall(loadbytecode, src, env, filename)
		return true, lua, not err
	elseif kind == "plain" then --that's just plain old lua.. boring..
		print("Loading Lua \""..filename.."\"...")
		
		--shorten the filename because lua's traceback truncates filenames.. at the end
		local shortname = filename
		local datapath = "/"..datapath
		if shortname:sub(1, datapath:len()) == datapath then
			shortname = "dp"..shortname:sub(datapath:len() + 1, -1)
		end
		local lua, err = loadstring(src, shortname)
		return false, lua, err
	end
end

--very important in later codebases
function loadLuaFileToObject(filename, ctx, key, lenient)
	local newname, paths = findCaseInsensitive(datapath.."/"..filename)
	filename = newname or filename

	ctx = ctx or _G

	local env
	if type(key) == "table" then
		env = key
	elseif type(key) == "string" and key ~= "" then
		--make a new table in ctx with the name of key (this, "ui")
		ctx[key] = ctx[key] or {}
		if type(ctx[key]) ~= "table" then ctx[key] = {} end
		env = ctx[key]
	else
		--use ctx table (this.ui, "")
		env = ctx
	end

	local compiled, lua, err = makeChunk(filename, env)

	if lua and not err then
		--fione needs the env on script loading so this should only work on plaintext luas
		if not compiled then
			setfenv(lua, env)
		end

		
		--emulate scope behavior
		if not getmetatable(env) then
			setmetatable(env, {
				__index = function(self, k)
					if k == "_G" or k == "gamelua" then
						return _G
					elseif k == "this" then
						return self
					--hack for libao
					elseif k == "loadAssets" then
						return loadAssets
					end
				end,
				__newindex = function(self, k, v)
					if k ~= "filename" then
						rawset(self, k, v)
					end
				end
			})
		end

		lua()
		
		if filename == "/"..datapath.."/"..scriptPath.."/options.lua" and queueCheatsEnabled then
			cheatsEnabled = true
			releaseBuild = false
		end
	elseif not lenient then
		if checkDirectory(filename) then
			--error("Could not load Lua file: "..filename.."\n"..tostring(err))
			print("Could not load Lua file: "..filename.."\n"..tostring(lua))
		else
			print("Could not load Lua file: "..filename.."\n"..tostring(err))
			if enableDebug then
				openPopup("Warning",
						"Could not load Lua file: "..filename.."\n"..tostring(err),
						{
							{sprite = "TUTORIAL_OK", callback = function()
								return true
							end},
						}
					, true)
			end
		end
	else
		return tostring(lua)
	end
end

--also used in some versions
--absw: blocks makes the file load into .blocks, unpack unpacks all tables inside
function loadLuaFile(filename, envKey, blocks, unpack, lenient)
	local newname, paths = findCaseInsensitive(datapath.."/"..filename)
	filename = newname or filename

	local compiled, lua, err = makeChunk(filename, env)
	local env = _G[envKey] or _G
	local og_env = env

	if lua and not err then
		if not compiled and not blocks then
			setfenv(lua, env)
		end

		if blocks and not unpack then
			blockTable[envKey] = blockTable[envKey] or {}
			env = blockTable[envKey]
		elseif blocks and unpack then
			env.blocks = env.blocks or {}
			env = env.blocks
		end

		if blocks then
			og_env = {}

			if not compiled then
				setfenv(lua, og_env)
			end

			local _mt = {
				__newindex = function(self, k, v)
					if type(v) == "table" then
						if unpack then
							for kk, vv in pairs(v) do
								if type(vv) == "table" then
									kk = vv.definition or kk
									rawset(env, kk, vv)
								end
							end
						else
							rawset(env, k, v)
						end
					else
						rawset(self, k, v)
					end
				end
			}

			setmetatable(og_env, _mt)
		end
		
		return lua()
	elseif not lenient then
		-- error("Could not load Lua file: "..filename)
		if not checkDirectory(filename) then
			err = "File does not exist."
		end
		print("Could not load Lua file: "..filename.."\n"..tostring(err))
	end

	return false
end

function runLuaFile(filename, lenient)
	local newname, paths = findCaseInsensitive(datapath.."/"..filename)
	filename = newname or filename

	local compiled, lua, err = makeChunk(filename)

	if lua and not err then
		return lua()
	elseif not lenient then
		-- error("Could not load Lua file: "..filename)
		if not checkDirectory(filename) then
			err = "File does not exist."
		end
		error("Could not load Lua file: "..filename.."\n"..tostring(err))
	end
end

--also used in some versions
local alreadyloaded = {}
function requireFile(filename)
	if alreadyloaded[filename] then return end

	if loadLuaFile(scriptPath.."/"..filename, nil, nil, nil, true) == false and loadLuaFile(commonScriptPath.."/"..filename) == false then
		print("Could not load Lua file: "..filename)
		return
	end

	alreadyloaded[filename] = true
end

--strips .. and separates directories into a table
function resolvePath(path)
	local resolved = {}
	for part in path:gmatch("[^/]+") do
		if part == ".." then
			table.remove(resolved)
		elseif part ~= "." and part ~= "" then
			table.insert(resolved, part)
		end
	end
	return "/"..table.concat(resolved, "/"), resolved
end

local req = require
function require(filename)
	if filename:sub(1, 4) == "data" then
		local newname, paths = resolvePath("/"..(filename:gsub("\\", "/")))
		newname = table.concat(paths, "/", 2, #paths)
		return req(datapath.."/"..newname)
	end

	return req(filename)
end

--debugging function to decrypt and save a lua file into the save directory
function exportLua(filename)
	local newname, paths = findCaseInsensitive(datapath.."/"..filename)
	filename = newname or filename

	local src = decryptSrc(filename)
	if src then
		--findCaseInsensitive
		-- paths = resolvePath(newname)
		local exportname = paths[#paths]..".dec"
		love.filesystem.write(exportname, src)

		print("Decrypted file \""..filename.."\" into \""..exportname.."\"")
	else
		print("Could not decrypt file \""..filename.."\"")
	end
end

--decrypt all json and lua files in the data folder
function exportAllScripts(path)
	local files = native.FileSystem.enumerate(path or "", nil, nil, true)
	local files2 = {}

	for i, v in pairs(files) do
		if endsWith(i, ".lua") or endsWith(i, ".json") then
			table.insert(files2, i)
		end
	end
	

	for i, v in pairs(files2) do
		decryptSrc(datapath.."/"..v)
		print(math.floor(i / #files2 * 100).."% ("..i.."/"..#files2..") ("..v..")")
	end
	
	print("Exported all encrypted files (look for the dec folder in the save directory)")
end

function checkDirectory(directory)
	return love.filesystem.exists(directory)
end

function createDirectory(directory)
	love.filesystem.createDirectory(directory)
end
