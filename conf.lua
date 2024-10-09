function love.conf(love)
    love.modules.joystick = false
    love.window.width = 1024--864
    love.window.height = 640--480
    love.window.minwidth = 512--864
    love.window.minheight = 320--480
    love.window.resizable = true

    love.window.usedpiscale = false
    -- love.window.fullscreen = true
    -- love.window.msaa = 8
end