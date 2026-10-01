function love.conf(t)
	t.accelerometerjoystick = false --TODO: remove this when love 12 releases (?)

	t.window.title = "Loading..."

	t.window.usedpiscale = true
	t.window.msaa = 2

	t.window.width = 1280
	t.window.height = 720
	t.window.minwidth = 2
	t.window.minheight = 2
	
	if love.system then
		local system = love.system.getOS()
		
		if system == "Android" then
			t.window.fullscreen = true
		else
			t.window.resizable = true
		end
	end

	--love on vulkan lacks support for many image formats, such as etc1
	if t.graphics then
		t.graphics.excluderenderers = {"vulkan"}
		-- t.graphics.lowpower = true
	end
	
	--t.version = "11.5" --TODO: remove this when love 12 releases
end
