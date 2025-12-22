function love.conf(t)
    t.modules.math = false
    t.modules.thread = false
    t.modules.video = false
	t.modules.joystick = true

    t.window.title = "Loading..."

    t.window.width = 1024--864
    t.window.height = 600--480
    t.window.minwidth = 480--864
    t.window.minheight = 320--480
    t.window.resizable = true

    t.window.usedpiscale = true
    t.accelerometerjoystick = false
    -- love.window.fullscreen = true
    t.window.msaa = 8
    
--     t.version = "11.5" 11.5 and 12.0 are supported
end
