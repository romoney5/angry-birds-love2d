--load components
if not jit then
	print("LuaJIT not found; disabling libcrypto")
end

--just load all the base files without dealing with dec/ caching etc.
local function runLua(path)
	print(("Loading Lua \"%s\"..."):format(path))
	return love.filesystem.load(path)()
end

--first load filesystem functions
runLua(compsPath.."/filesystem.lua")					--filesystem functions

--extra libraries
pcall(require, "table.clear")                               --clear key tables instead of remaking them
pcall(require, "table.new")                                 --allocate a table
has_ffi, ffi = pcall(require, "ffi")                        --luajit ffi
has_utf8, utf8 = pcall(require, "utf8")						--utf8 library, now required for utf8 text

table.clear = table.clear or function(t)
	for i, v in pairs(t) do
		t[i] = nil
	end
end

table.unpack = unpack

bit = bit or	runLua(compsPath.."/libs/numberlua.lua")   --bit library since https://github.com/davidm/lua-bit-numberlua/blob/master/lmod/bit/numberlua.lua
luna_loadbytecode = runLua(compsPath.."/libs/luna.lua") --run lua 5.1 bytecode in a custom vm because normally it's not usable in luajit
json			= runLua(compsPath.."/libs/json.lua")	--json support for modern seasons versions
AES				= runLua(compsPath.."/libs/aes.lua")	--aes-256-cbc decryption powered by none other than luajit ffi
has_pvr, pvr	= pcall(runLua, compsPath.."/libs/pvrtc.lua")	--pvrtc format
fetch			= _G.require("components.libs.fetch")

--debugging features
runLua(compsPath.."/debugging/console.lua")				--debug console
runLua(compsPath.."/debugging/collisions.lua")			--debug collision log
runLua(compsPath.."/debugging/speed_up.lua")			--debug speed-up with shift+a

--readers for proprietary data formats
runLua(compsPath.."/data/formats/pvr.lua")				--pvr image format

runLua(compsPath.."/data/formats/ka3d_sprt.lua")		--spritesheet format
runLua(compsPath.."/data/formats/ka3d_font.lua")		--font format
runLua(compsPath.."/data/formats/ka3d_comp.lua")		--composprites format
runLua(compsPath.."/data/formats/ka3d_text.lua")		--localization format
runLua(compsPath.."/data/data_readers.lua")				--functions for reading dat formats
runLua(compsPath.."/data/read.lua")						--general reader for dat files

--_G.res library and related frontend (graphics, audio, etc.) functions
runLua(compsPath.."/resources/res.lua")					--initialize res. (resources) library
runLua(compsPath.."/resources/graphics.lua")			--graphics functions
runLua(compsPath.."/resources/audio.lua")				--audio functions
runLua(compsPath.."/resources/localization.lua")		--localization/text group functions
runLua(compsPath.."/resources/font.lua")				--font/text functions

--everything related to physics and levels
runLua(compsPath.."/physics/create_objects.lua")		--create box, circle, polygon, etc. box2d objects
runLua(compsPath.."/physics/level.lua")					--level saving/loading, world functions, trajectory
runLua(compsPath.."/physics/objects_collisions.lua")	--object functions, damage system
runLua(compsPath.."/physics/update.lua")				--physics update functions

runLua(compsPath.."/game_arguments.lua")				--handles arguments passed in to love
runLua(compsPath.."/options.lua")						--extra options, like devicemodel or gravity
runLua(compsPath.."/ui.lua")							--ui components used in debug menus
runLua(compsPath.."/input.lua")							--input receivers, for keys, touch/mouse, and scrolling
runLua(compsPath.."/draw_layers.lua")					--draw bg, fg, and game
runLua(compsPath.."/particles.lua")						--update/draw/create particles
runLua(compsPath.."/level_particles.lua")				--update/draw/create level particles
runLua(compsPath.."/something.lua")						--something (file manager)
runLua(compsPath.."/iap.lua")							--iap (in app purchase) functions
runLua(compsPath.."/game_loop.lua")						--main game loop, calls update function
runLua(compsPath.."/gamepad.lua")						--controller-related functions

--functions and global libraries introduced in later game versions
runLua(compsPath.."/versionspecific/classic_old.lua")	--functions for classic versions below 3.x
runLua(compsPath.."/versionspecific/classic.lua")		--functions for 3.0.1 and later
runLua(compsPath.."/versionspecific/seasons.lua")		--functions for modern seasons
runLua(compsPath.."/versionspecific/rio.lua")			--functions for rio 1.4.0
runLua(compsPath.."/versionspecific/friends.lua")		--functions for friends mobile
runLua(compsPath.."/versionspecific/stella.lua")		--functions for ab stella

runLua(compsPath.."/debugging/error.lua")				--run the error handler after everything is loaded
