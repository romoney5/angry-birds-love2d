runLuaFile("settings.lua", true)--, settings)
runLuaFile("highscores.lua", true)--, settings)

--load components

--debug
runLuaFile(compsPath.."/debugging/error.lua")				--error handler
runLuaFile(compsPath.."/debugging/console.lua")				--debug console
runLuaFile(compsPath.."/debugging/fps.lua")					--debug fps
runLuaFile(compsPath.."/debugging/collisions.lua")			--debug collisions
runLuaFile(compsPath.."/debugging/options.lua")				--debug options
runLuaFile(compsPath.."/debugging/speed_up.lua")			--debug speed-up with shift+a

--ka3d dats
runLuaFile(compsPath.."/dat/formats/sprt.lua")				--spritesheet format
runLuaFile(compsPath.."/dat/formats/font.lua")				--font format
runLuaFile(compsPath.."/dat/formats/comp.lua")				--composprites format
runLuaFile(compsPath.."/dat/formats/text.lua")				--localization format
runLuaFile(compsPath.."/dat/data_readers.lua")				--functions for reading
runLuaFile(compsPath.."/dat/read.lua")						--read dat

--_G.res
runLuaFile(compsPath.."/resources/res.lua")					--misc resources
runLuaFile(compsPath.."/resources/build_sprites.lua")		--make images
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