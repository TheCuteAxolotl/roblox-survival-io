local Lighting = game:GetService("Lighting")

Lighting.Brightness = 2
Lighting.EnvironmentDiffuseScale = 0.55
Lighting.EnvironmentSpecularScale = 0.35

local CYCLE_SECONDS = 600
local start = os.clock()

task.spawn(function()
	while true do
		task.wait(0.25)
		local progress = ((os.clock() - start) % CYCLE_SECONDS) / CYCLE_SECONDS
		local hour = (7 + progress * 24) % 24
		Lighting.ClockTime = hour
		local night = hour >= 19 or hour < 6
		Lighting.Brightness = night and 1.25 or 2.1
		Lighting.OutdoorAmbient = night and Color3.fromRGB(72, 82, 108) or Color3.fromRGB(135, 135, 135)
		Lighting.Ambient = night and Color3.fromRGB(55, 62, 82) or Color3.fromRGB(110, 110, 110)
	end
end)
