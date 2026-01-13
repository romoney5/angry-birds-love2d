--load components

--extra libraries

pcall(require, "table.clear")                               --clear key* tables instead of remaking them
_, ffi = pcall(require, "ffi")                              --luajit ffi
_, utf8 = pcall(require, "utf8")							--utf8 library, now required for utf8 text

loadbytecode = runLuaFile(compsPath.."/libs/fione.lua")     --run lua 5.1 bytecode because loadstring
runLuaFile(compsPath.."/libs/aes.lua")                      --aes-256-cbc decryption powered by none other than luajit ffi
haswebp, webp = pcall(runLuaFile,compsPath.."/libs/love-webp.lua")--read webp images
_ = nil

--debug
runLuaFile(compsPath.."/debugging/console.lua")				--debug console
runLuaFile(compsPath.."/debugging/fps.lua")					--debug fps
runLuaFile(compsPath.."/debugging/collisions.lua")			--debug collisions
runLuaFile(compsPath.."/debugging/options.lua")				--debug options
runLuaFile(compsPath.."/debugging/speed_up.lua")			--debug speed-up with shift+a

--readers for proprietary formats
runLuaFile(compsPath.."/data/formats/pvr.lua")				--pvr image format

runLuaFile(compsPath.."/data/formats/ka3d_sprt.lua")		--spritesheet format
runLuaFile(compsPath.."/data/formats/ka3d_font.lua")		--font format
runLuaFile(compsPath.."/data/formats/ka3d_comp.lua")		--composprites format
runLuaFile(compsPath.."/data/formats/ka3d_text.lua")		--localization format
runLuaFile(compsPath.."/data/data_readers.lua")				--functions for reading
runLuaFile(compsPath.."/data/read.lua")						--read dat

--_G.res
runLuaFile(compsPath.."/resources/res.lua")					--misc resources
runLuaFile(compsPath.."/resources/graphics.lua")			--graphics functions
runLuaFile(compsPath.."/resources/draw_box.lua")			--drawboxnative
runLuaFile(compsPath.."/resources/audio.lua")				--audio functions
runLuaFile(compsPath.."/resources/localization.lua")		--localization functions
runLuaFile(compsPath.."/resources/font.lua")				--font functions

--physics
runLuaFile(compsPath.."/physics/create_objects.lua")		--create box, circle, polygon, etc
runLuaFile(compsPath.."/physics/level.lua")					--level saving/loading, world functions, trajectory
runLuaFile(compsPath.."/physics/objects_collisions.lua")	--object params functions, damage system
runLuaFile(compsPath.."/physics/update.lua")				--physics update function

--dummy functions
runLuaFile(compsPath.."/blanks/classic.lua")				--blank functions for 1.6.3.1
runLuaFile(compsPath.."/blanks/3.0.1.lua")					--blank functions for 3.0.1
runLuaFile(compsPath.."/blanks/rio.lua")					--blank functions for rio 1.4.0
runLuaFile(compsPath.."/blanks/friends.lua")				--blank functions for friends mobile

runLuaFile(compsPath.."/game_arguments.lua")				--handles arguments passed on to love
runLuaFile(compsPath.."/options.lua")						--extra options, like devicemodel or gravity
runLuaFile(compsPath.."/ui.lua")							--ui components used in debug menus
runLuaFile(compsPath.."/input.lua")							--input receivers, for keys, touch/mouse, and scrolling
runLuaFile(compsPath.."/draw_layers.lua")					--draw bg, fg, and game
runLuaFile(compsPath.."/particles.lua")						--particles update/draw/create
runLuaFile(compsPath.."/something.lua")						--something
runLuaFile(compsPath.."/iap.lua")							--in app purchases functions
runLuaFile(compsPath.."/game_loop.lua")						--main game loop, calls update
runLuaFile(compsPath.."/gamepad.lua")						--controller related functions

runLuaFile(compsPath.."/debugging/error.lua")				--run the error handler after everything is loaded