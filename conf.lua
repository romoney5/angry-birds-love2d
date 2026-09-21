function love.conf(t)
	t.modules.math = false
	t.modules.video = false
	t.modules.joystick = true
	
	t.accelerometerjoystick = false

	t.window.title = "Loading..."

	t.window.width = 1024--864
	t.window.height = 600--480
	t.window.minwidth = 2
	t.window.minheight = 2
	-- t.window.minwidth = 480--864
	-- t.window.minheight = 320--480

	t.window.usedpiscale = true
	t.window.msaa = 8
	
	local system = love.system.getOS()
	
	if system == "Android" then
		t.window.fullscreen = true
	else
		t.window.resizable = true
	end

	--love2d with vulkan on most platforms doesn't support many image formats such as etc1
	if t.graphics then
		t.graphics.excluderenderers = {"vulkan"}
		-- t.graphics.lowpower = true
	end
	
	--t.version = "11.5" --11.5 and 12.0 are supported --TODO: remove this when love 12 releases
end
