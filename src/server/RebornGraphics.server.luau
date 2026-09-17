local Lighting = game:GetService("Lighting")
local Terrain = workspace:FindFirstChildOfClass("Terrain")

pcall(function()
	Lighting.Technology = Enum.Technology.Future
end)

Lighting.GlobalShadows = true
Lighting.ShadowSoftness = 0.22
Lighting.EnvironmentDiffuseScale = 0.68
Lighting.EnvironmentSpecularScale = 0.52
Lighting.ExposureCompensation = 0.05

local sun = Lighting:FindFirstChild("RebornSunRays") or Instance.new("SunRaysEffect")
sun.Name = "RebornSunRays"
sun.Intensity = 0.055
sun.Spread = 0.84
sun.Parent = Lighting

local depth = Lighting:FindFirstChild("RebornDepth") or Instance.new("DepthOfFieldEffect")
depth.Name = "RebornDepth"
depth.FocusDistance = 58
depth.InFocusRadius = 95
depth.NearIntensity = 0
depth.FarIntensity = 0.075
depth.Parent = Lighting

local tone = Lighting:FindFirstChild("RebornTone") or Instance.new("ColorCorrectionEffect")
tone.Name = "RebornTone"
tone.Brightness = 0.01
tone.Contrast = 0.035
tone.Saturation = 0.08
tone.TintColor = Color3.fromRGB(255, 249, 238)
tone.Parent = Lighting

local bloom = Lighting:FindFirstChild("WildforgeBloom")
if bloom and bloom:IsA("BloomEffect") then
	bloom.Intensity = 0.22
	bloom.Size = 30
	bloom.Threshold = 1.2
end

if Terrain then
	local clouds = Terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
	clouds.Name = "WildforgeClouds"
	clouds.Cover = 0.34
	clouds.Density = 0.58
	clouds.Color = Color3.fromRGB(232, 235, 239)
	clouds.Parent = Terrain
end

print("[RebornGraphics] Future lighting, clouds, sun rays, depth and richer material lighting enabled.")
