--bonus options

local deviceModelMapping = {
	Windows = "windows",
	Linux = "windows",
	["OS X"] = "windows",

	Android = "android",
	iOS = "iphone",

	Web = "android", --web port

	Horizon = "windows", --switch/3ds (lovepotion)
	Cafe = "windows", --wiiu (lovepotion)
}
deviceModel = deviceModelMapping[love.system.getOS()] or "windows"

displayScale = 1
autoScale = 0 --0 to disable, anything else as a target screen height

timeScale = 1
physicsTimeScale = 1

audioSpeed = 1
accurateAudioSpeed = {on = false, _hz = 0}

worldgravity = {x = 0, y = 20}
gravity = setmetatable({}, {__newindex = function(_, i, v)
	if tonumber(v) then
		rawset(worldgravity, i, v)
		if physicsWorld then
			physicsWorld:setGravity(worldgravity.x, worldgravity.y)
		end
	end
end})