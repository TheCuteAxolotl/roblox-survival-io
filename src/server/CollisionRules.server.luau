local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local PLAYER_GROUP = "SurvivalPlayers"
local MOB_GROUP = "SurvivalMobs"

local function ensureGroup(name)
	pcall(function() PhysicsService:RegisterCollisionGroup(name) end)
end

ensureGroup(PLAYER_GROUP)
ensureGroup(MOB_GROUP)
pcall(function() PhysicsService:CollisionGroupSetCollidable(PLAYER_GROUP, MOB_GROUP, false) end)

local function setGroup(part, group)
	if not part:IsA("BasePart") then return end
	pcall(function() part.CollisionGroup = group end)
end

local function setupCharacter(character)
	for _, d in character:GetDescendants() do if d:IsA("BasePart") then setGroup(d, PLAYER_GROUP) end end
	character.DescendantAdded:Connect(function(d)
		if d:IsA("BasePart") then setGroup(d, PLAYER_GROUP) end
	end)
end

local function maybeMobPart(instance)
	if not instance:IsA("BasePart") then return end
	local model = instance:FindFirstAncestorOfClass("Model")
	if model and model:GetAttribute("SurvivalMob") == true then setGroup(instance, MOB_GROUP) end
end

local function setupPlayer(player)
	player.CharacterAdded:Connect(setupCharacter)
	if player.Character then setupCharacter(player.Character) end
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in Players:GetPlayers() do setupPlayer(player) end

for _, d in Workspace:GetDescendants() do maybeMobPart(d) end
Workspace.DescendantAdded:Connect(function(d)
	if d:IsA("BasePart") then
		task.defer(function()
			if d.Parent then maybeMobPart(d) end
		end)
	end
end)

task.spawn(function()
	-- Catch mob models whose SurvivalMob attribute is assigned immediately before
	-- their parts are constructed/parented.
	while true do
		task.wait(2)
		local arena = Workspace:FindFirstChild("SurvivalArena")
		if arena then
			for _, model in arena:GetDescendants() do
				if model:IsA("Model") and model:GetAttribute("SurvivalMob") == true then
					for _, d in model:GetDescendants() do if d:IsA("BasePart") then setGroup(d, MOB_GROUP) end end
				end
			end
		end
	end
end)
