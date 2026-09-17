local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local cycleConfig = Config.WorldCycle or {
	DawnSeconds = 45,
	DaySeconds = 210,
	DuskSeconds = 45,
	NightSeconds = 120,
	MaxThreat = 6,
}

local phases = {
	{ Name = "Dawn", Duration = cycleConfig.DawnSeconds, StartHour = 5.7, EndHour = 8.5 },
	{ Name = "Day", Duration = cycleConfig.DaySeconds, StartHour = 8.5, EndHour = 17.0 },
	{ Name = "Dusk", Duration = cycleConfig.DuskSeconds, StartHour = 17.0, EndHour = 20.0 },
	{ Name = "Night", Duration = cycleConfig.NightSeconds, StartHour = 20.0, EndHour = 29.7 },
}

local cycleSeconds = 0
for _, phase in phases do cycleSeconds += phase.Duration end

local atmosphere = Lighting:FindFirstChild("WildforgeAtmosphere")
if not atmosphere then
	atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "WildforgeAtmosphere"
	atmosphere.Density = 0.24
	atmosphere.Offset = 0.1
	atmosphere.Glare = 0.08
	atmosphere.Haze = 1.1
	atmosphere.Parent = Lighting
end

local color = Lighting:FindFirstChild("WildforgeColor")
if not color then
	color = Instance.new("ColorCorrectionEffect")
	color.Name = "WildforgeColor"
	color.Parent = Lighting
end

local bloom = Lighting:FindFirstChild("WildforgeBloom")
if not bloom then
	bloom = Instance.new("BloomEffect")
	bloom.Name = "WildforgeBloom"
	bloom.Intensity = 0.16
	bloom.Size = 24
	bloom.Threshold = 1.4
	bloom.Parent = Lighting
end

Lighting.EnvironmentDiffuseScale = 0.55
Lighting.EnvironmentSpecularScale = 0.35
Lighting.GlobalShadows = true

local startClock = os.clock()
local lastPhase = nil
local lastDay = nil

local function phaseAt(cycleTime)
	local cursor = 0
	for index, phase in phases do
		local finish = cursor + phase.Duration
		if cycleTime < finish or index == #phases then
			local elapsed = math.clamp(cycleTime - cursor, 0, phase.Duration)
			return phase, elapsed / math.max(phase.Duration, 0.001), phase.Duration - elapsed
		end
		cursor = finish
	end
	return phases[1], 0, phases[1].Duration
end

local function worldEvent(day, phaseName)
	if phaseName ~= "Night" then return "" end
	if day % 5 == 0 then return "BLOOD MOON" end
	if day % 3 == 0 then return "PREDATOR HUNT" end
	return "NIGHTFALL"
end

local function publish(day, phase, progress, remaining)
	local threat = math.clamp(day, 1, cycleConfig.MaxThreat or 6)
	local event = worldEvent(day, phase.Name)
	ReplicatedStorage:SetAttribute("WildforgeDay", day)
	ReplicatedStorage:SetAttribute("WildforgePhase", phase.Name)
	ReplicatedStorage:SetAttribute("WildforgePhaseProgress", progress)
	ReplicatedStorage:SetAttribute("WildforgeThreat", threat)
	ReplicatedStorage:SetAttribute("WildforgeEvent", event)
	ReplicatedStorage:SetAttribute("WildforgePhaseEndsAt", workspace:GetServerTimeNow() + remaining)
	ReplicatedStorage:SetAttribute("WildforgeIsNight", phase.Name == "Night")
end

local function applyLighting(day, phase, progress)
	local rawHour = phase.StartHour + (phase.EndHour - phase.StartHour) * progress
	Lighting.ClockTime = rawHour % 24

	if phase.Name == "Dawn" then
		Lighting.Brightness = 1.8 + progress * 0.45
		Lighting.Ambient = Color3.fromRGB(112, 99, 104):Lerp(Color3.fromRGB(115, 115, 112), progress)
		Lighting.OutdoorAmbient = Color3.fromRGB(143, 126, 122):Lerp(Color3.fromRGB(151, 151, 145), progress)
		color.TintColor = Color3.fromRGB(255, 223, 195):Lerp(Color3.fromRGB(255, 249, 232), progress)
		color.Contrast = 0.02
		color.Saturation = 0.04
		atmosphere.Color = Color3.fromRGB(205, 194, 187)
		atmosphere.Decay = Color3.fromRGB(114, 129, 154)
	elseif phase.Name == "Day" then
		Lighting.Brightness = 2.25
		Lighting.Ambient = Color3.fromRGB(116, 116, 112)
		Lighting.OutdoorAmbient = Color3.fromRGB(154, 154, 146)
		color.TintColor = Color3.fromRGB(255, 252, 238)
		color.Contrast = 0.025
		color.Saturation = 0.06
		atmosphere.Color = Color3.fromRGB(202, 213, 218)
		atmosphere.Decay = Color3.fromRGB(105, 122, 145)
	elseif phase.Name == "Dusk" then
		Lighting.Brightness = 2.0 - progress * 0.65
		Lighting.Ambient = Color3.fromRGB(116, 101, 100):Lerp(Color3.fromRGB(66, 70, 91), progress)
		Lighting.OutdoorAmbient = Color3.fromRGB(158, 126, 112):Lerp(Color3.fromRGB(78, 86, 112), progress)
		color.TintColor = Color3.fromRGB(255, 198, 161):Lerp(Color3.fromRGB(180, 193, 230), progress)
		color.Contrast = 0.045
		color.Saturation = 0.03
		atmosphere.Color = Color3.fromRGB(191, 163, 164)
		atmosphere.Decay = Color3.fromRGB(82, 77, 108)
	else
		local bloodMoon = day % 5 == 0
		Lighting.Brightness = bloodMoon and 1.05 or 1.12
		Lighting.Ambient = bloodMoon and Color3.fromRGB(78, 47, 55) or Color3.fromRGB(49, 57, 82)
		Lighting.OutdoorAmbient = bloodMoon and Color3.fromRGB(105, 58, 64) or Color3.fromRGB(68, 78, 108)
		color.TintColor = bloodMoon and Color3.fromRGB(235, 153, 150) or Color3.fromRGB(174, 193, 235)
		color.Contrast = bloodMoon and 0.1 or 0.07
		color.Saturation = bloodMoon and -0.08 or -0.14
		atmosphere.Color = bloodMoon and Color3.fromRGB(128, 78, 80) or Color3.fromRGB(101, 113, 148)
		atmosphere.Decay = Color3.fromRGB(42, 46, 72)
	end
end

task.spawn(function()
	while true do
		local elapsed = os.clock() - startClock
		local cycleIndex = math.floor(elapsed / cycleSeconds)
		local day = cycleIndex + 1
		local cycleTime = elapsed % cycleSeconds
		local phase, progress, remaining = phaseAt(cycleTime)

		publish(day, phase, progress, remaining)
		applyLighting(day, phase, progress)

		if phase.Name ~= lastPhase or day ~= lastDay then
			lastPhase = phase.Name
			lastDay = day
			local event = worldEvent(day, phase.Name)
			if event ~= "" then
				print(`[WildforgeWorld] Day {day} • {phase.Name} • {event} • Threat {math.clamp(day, 1, cycleConfig.MaxThreat or 6)}`)
			else
				print(`[WildforgeWorld] Day {day} • {phase.Name}`)
			end
		end

		task.wait(0.35)
	end
end)
