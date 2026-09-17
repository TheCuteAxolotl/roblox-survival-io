local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local arena = Workspace:WaitForChild("SurvivalArena", 20)
if not arena then return end

-- The prototype created spawn pads in all three biomes. V2 starts every fresh
-- run in the readable central Grasslands; beds can later override respawn.
for _, child in arena:GetChildren() do
	if child:IsA("SpawnLocation") then
		if math.abs(child.Position.X) >= Config.BiomeSplit then
			child:Destroy()
		else
			child.Duration = 8
			child.Neutral = true
		end
	end
end

-- V3 spawn court sits directly outside Hunter Haven.
for index, position in {
	Vector3.new(-28, 1, -232),
	Vector3.new(28, 1, -232),
	Vector3.new(-48, 1, -218),
	Vector3.new(48, 1, -218),
} do
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "HunterHavenSpawn" .. index
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = position
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 8
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Parent = arena
end

print("[SpawnSafety] Fresh runs now begin at Hunter Haven beside the Rift hub.")
