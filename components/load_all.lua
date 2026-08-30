--load components
if not jit then
	print("LuaJIT not found; disabling libcrypto")
end

--first load filesystem functions
local chunk = love.filesystem.load(compsPath.."/filesystem.lua")		--filesystem functions
--setfenv(chunk, gamelua)
chunk()

--extra libraries
pcall(require, "table.clear")                               --clear key* tables instead of remaking them
pcall(require, "table.new")                                 --allocate a table
_, ffi = pcall(require, "ffi")                              --luajit ffi
_, utf8 = pcall(require, "utf8")							--utf8 library, now required for utf8 text

--local compsPath = compsPath
--setfenv(1, gamelua)
local runLuaFile = gamelua.runLuaFile

bit = bit or	runLuaFile(compsPath.."/libs/numberlua.lua")   --bit library since https://github.com/davidm/lua-bit-numberlua/blob/master/lmod/bit/numberlua.lua
loadbytecode	= runLuaFile(compsPath.."/libs/fione.lua")	--run lua 5.1 bytecode in a custom vm because normally it's not portable
json			= runLuaFile(compsPath.."/libs/json.lua")	--json support for modern seasons versions
AES				= runLuaFile(compsPath.."/libs/aes.lua")	--aes-256-cbc decryption powered by none other than luajit ffi
fetch			= _G.require("components.libs.fetch")
_ = nil --really weird hack

--debug
runLuaFile(compsPath.."/debugging/console.lua")				--debug console
runLuaFile(compsPath.."/debugging/collisions.lua")			--debug collisions
runLuaFile(compsPath.."/debugging/speed_up.lua")			--debug speed-up with shift+a

--readers for proprietary formats
runLuaFile(compsPath.."/data/formats/pvr.lua")				--pvr image format

runLuaFile(compsPath.."/data/formats/ka3d_sprt.lua")		--spritesheet format
runLuaFile(compsPath.."/data/formats/ka3d_font.lua")		--font format
runLuaFile(compsPath.."/data/formats/ka3d_comp.lua")		--composprites format
runLuaFile(compsPath.."/data/formats/ka3d_text.lua")		--localization format
runLuaFile(compsPath.."/data/data_readers.lua")				--functions for reading dat formats
runLuaFile(compsPath.."/data/read.lua")						--general reader for dat files

--_G.res
runLuaFile(compsPath.."/resources/res.lua")					--initialize res. (resources) library
runLuaFile(compsPath.."/resources/graphics.lua")			--graphics functions
runLuaFile(compsPath.."/resources/draw_box.lua")			--just drawboxnative
runLuaFile(compsPath.."/resources/audio.lua")				--audio functions
runLuaFile(compsPath.."/resources/localization.lua")		--localization/text group functions
runLuaFile(compsPath.."/resources/font.lua")				--font/text functions

--physics
runLuaFile(compsPath.."/physics/create_objects.lua")		--create box, circle, polygon, etc. box2d objects
runLuaFile(compsPath.."/physics/level.lua")					--level saving/loading, world functions, trajectory
runLuaFile(compsPath.."/physics/objects_collisions.lua")	--object functions, damage system
runLuaFile(compsPath.."/physics/update.lua")				--physics update functions

runLuaFile(compsPath.."/game_arguments.lua")				--handles arguments passed in to love
runLuaFile(compsPath.."/options.lua")						--extra options, like devicemodel or gravity
runLuaFile(compsPath.."/ui.lua")							--ui components used in debug menus
runLuaFile(compsPath.."/input.lua")							--input receivers, for keys, touch/mouse, and scrolling
runLuaFile(compsPath.."/draw_layers.lua")					--draw bg, fg, and game
runLuaFile(compsPath.."/particles.lua")						--update/draw/create particles
runLuaFile(compsPath.."/level_particles.lua")				--update/draw/create level particles
runLuaFile(compsPath.."/something.lua")						--something (file manager)
runLuaFile(compsPath.."/iap.lua")							--iap (in app purchase) functions
runLuaFile(compsPath.."/game_loop.lua")						--main game loop, calls update function
runLuaFile(compsPath.."/gamepad.lua")						--controller-related functions

--functions and global libraries introduced in later game versions
runLuaFile(compsPath.."/versionspecific/classic_old.lua")	--functions for classic versions below 3.x
runLuaFile(compsPath.."/versionspecific/classic.lua")		--functions for 3.0.1 and later
runLuaFile(compsPath.."/versionspecific/seasons.lua")		--functions for modern seasons
runLuaFile(compsPath.."/versionspecific/rio.lua")			--functions for rio 1.4.0
runLuaFile(compsPath.."/versionspecific/friends.lua")		--functions for friends mobile
runLuaFile(compsPath.."/versionspecific/stella.lua")		--functions for ab stella

runLuaFile(compsPath.."/debugging/error.lua")				--run the error handler after everything is loaded