--file and folder-related functions

--cache decrypted files in the save directory to speed up loading dramatically
local ALLOW_LUA_CACHE = true

--load a dll/so library, looks in multiple paths
--returns success, result
function loadLibrary(paths)
	--not even ffi is present?
	if not jit then
		return false, "LuaJIT FFI is not present"
	end
	
	local errors = ""
	
	for i, v in ipairs(paths) do
		local success, result = pcall(ffi.load, v)
		
		if not success then
			errors = errors..result.."\n"
		else
			return success, result
		end
	end
	
	return false, errors
end

--replace a missing filename due to case sensitivity
function findCaseInsensitive(dir)
	local dir, paths = resolvePath(dir)

	if love.filesystem.exists(dir) then
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

function startsWith(str, start)
	return str:sub(1, start:len()) == start
end

--windows has a suspiciously short path name length, so cut out some clutter from the dec path
function trimDataPath(filename)
	if filename:sub(1, 1) == "/" then filename = filename:sub(2) end --cut the starting slash
	return (startsWith(filename, datapath) and filename:sub(datapath:len() + 1) or filename)
end

--load either plain text lua, a precompiled chunk with luna,
--a 7-zipped file, an aes-256 encrypted file, or all of the above
function decryptSrc(filename, src)
	local dec_path = "/dec/"..trimDataPath(filename)

	--use already-decrypted assets if available, moved here for json support
	local decinfo = ALLOW_LUA_CACHE and love.filesystem.getInfo(dec_path)
	local info = decinfo and love.filesystem.getInfo(filename)
	
	if decinfo and decinfo.modtime and info and info.modtime and decinfo.modtime >= info.modtime then
		src = love.filesystem.read(dec_path)
		return src
	end

	src = src or love.filesystem.read(filename)

	if not src then return end

	--temporary file for use in 7-zip
	local function temp_file()
		local dec_filename = dec_path
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
			assert(src and src:len() > 0, "decryptSrc: LZMA could not decompress a file.\n"..
				"Make sure you have lzma.exe; see the \"Dependencies\" section of the README for more information.")
			
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
		local err, lua = pcall(luna_loadbytecode, src, env, filename)
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
function gamelua.loadLuaFileToObject(filename, ctx, key, lenient)
	local newname, paths = findCaseInsensitive(datapath.."/"..filename)
	filename = newname or filename

	ctx = ctx or gamelua

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
		--luna needs the env on script loading so this should only work on plaintext luas
		if not compiled then
			setfenv(lua, env)
		end
		
		--emulate scope behavior
		if not getmetatable(env) then
			setmetatable(env, {
				__index = function(self, k)
					if k == "_G" then
						return _G
					elseif k == "this" then
						return self
					elseif k == "gamelua" then
						return gamelua
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
		
		if queueCheatsEnabled and filename == "/"..datapath.."/"..gamelua.scriptPath.."/options.lua" then
			gamelua.cheatsEnabled = true
			gamelua.releaseBuild = false
		end
		
		return true
	elseif not lenient then
		if love.filesystem.exists(filename) then
			--error("Could not load Lua file: "..filename.."\n"..tostring(err))
			print("Could not load Lua file: "..filename.."\n"..tostring(lua or err))
		else
			print("Could not find Lua file: "..filename.."\n"..tostring(err))
		end
		
		return false
	else
		return tostring(lua)
	end
end

--also used in some versions
--absw: blocks makes the file load into .blocks, unpack unpacks all tables inside
function gamelua.loadLuaFile(filename, envKey, blocks, unpack, lenient)
	local newname, paths = findCaseInsensitive(datapath.."/"..filename)
	filename = newname or filename

	local env = gamelua[envKey] or gamelua
	local og_env = env
	local compiled, lua, err = makeChunk(filename, env)

	if lua and not err then
		if not compiled and not blocks then
			setfenv(lua, env)
		end

		if blocks and not unpack then
			gamelua.blockTable[envKey] = gamelua.blockTable[envKey] or {}
			env = gamelua.blockTable[envKey]
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
		if not love.filesystem.exists(filename) then
			err = "File does not exist."
		end
		print("Failed to load Lua file: "..filename.."\n"..tostring(err))
	end

	return false
end

function gamelua.runLuaFile(filename)
	local newname, paths = findCaseInsensitive(datapath.."/"..filename)
	filename = newname or filename

	local env = _G
	local compiled, lua, err = makeChunk(filename, env)

	if lua and not err then
		if not compiled then
			setfenv(lua, env)
		end
		
		return lua()
	else
		-- error("Could not load Lua file: "..filename)
		if not love.filesystem.exists(filename) then
			err = "File does not exist."
		end
		error("Failed to load Lua file: "..filename.."\n"..tostring(err))
	end
end

--also used in some versions
local alreadyloaded = {}
function gamelua.requireFile(filename)
	if alreadyloaded[filename] then return end

	alreadyloaded[filename] = true
	
	local env = _G --getfenv(2)
	
	local path_scripts = gamelua.scriptPath.."/"..filename
	local path_scriptscommon = gamelua.commonScriptPath.."/"..filename
	
	if findCaseInsensitive(datapath.."/"..path_scripts) then
		gamelua.loadLuaFileToObject(path_scripts, env)
	elseif findCaseInsensitive(datapath.."/"..path_scriptscommon) then
		gamelua.loadLuaFileToObject(path_scriptscommon, env)
	else
		print("Failed to require Lua file: "..filename)
		return
	end
end

requireFile = gamelua.requireFile

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
		print("Failed to decrypt file \""..filename.."\"")
	end
end

function openSaves()
	local dir = love.filesystem.getSaveDirectory()

	if not love.system.openURL("file://"..dir) then
		print("Failed to open folder "..tostring(dir))
	end
end

--decrypt all json and lua files in the data folder to dec
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

function gamelua.checkDirectory(directory)
	return love.filesystem.exists(directory)
end

function gamelua.createDirectory(directory)
	love.filesystem.createDirectory(directory)
end

--serializes a lua table into a loadable string
function serializeTable(t, indent)
	local out = ""
	indent = indent or "\t"

	for i, v in pairs(t) do
		local key
		
		--always use brackets for keys
		if type(i) == "number" then
			key = "["..i.."] = "
		else
			key = "[\""..tostring(i).."\"] = "
		end

		if type(v) == "table" then
			out = out..indent..key.."{\n"..serializeTable(v, indent.."\t", noIndexes)..indent.."}"..(indent == "" and "" or ",").."\n"
		else
			local final_value = tostring(v)
			
			if type(v) == "string" then
				final_value = "\""..final_value.."\""
			end

			if type(v) ~= "userdata" then
				out = out..indent..(tonumber(i) and "" or key)..final_value..""..(indent == "" and "" or ",").."\n"
			--else
				--error("serializeTable(): tried serializing userdata "..tostring(i))
			end
		end
	end

	return out
end

function gamelua.saveLuaFile(fileName, tableName, appData)
	if disableSaving then
		print("saveLuaFile(): Tried saving \""..tableName.."\" but saving is disabled")
		return
	end

	local tableToSave = gamelua[tableName]
	
	if not (tableToSave and type(tableToSave) == "table") then
		print("saveLuaFile(): Table "..tableName.." does not exist in gamelua.")
		
		return
	end

	local s1, m1 = love.filesystem.createDirectory(fileName:match(".*/") or "")
	
	if not s1 then
		print("\""..tableName.."\" failed to save to "..fileName.." ("..(m1 or "Unknown error")..")")
		
		return
	end
	
	local out = serializeTable(tableToSave)
	out = ("%s = {\n%s}"):format(tableName, out)
	
	local success, result = love.filesystem.write(fileName, out)
	
	if success then
		print("\""..tableName.."\" was saved to "..fileName)
	else
		print("\""..tableName.."\" failed to save to "..fileName.." ("..(result or "Unknown error")..")")
	end
end

function gamelua.savePersistentLuaFile(fileName, tableName)
	gamelua.saveLuaFile(fileName, tableName)
end

function gamelua.storePersistentData()
	return
end

function gamelua.checkForLuaFile(filename)
	return love.filesystem.exists(datapath.."/"..filename)
end
