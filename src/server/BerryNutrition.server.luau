local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes")
local action = remotes:WaitForChild("Action")
local nutritionEvent = script.Parent:WaitForChild("SurvivalNutrition")

local lastBerry = {}

local function validBerryTarget(player, target)
	if typeof(target) ~= "Instance" or not target:IsA("BasePart") then return false end
	if not CollectionService:HasTag(target, "SurvivalResource") then return false end
	local model = target:FindFirstAncestorOfClass("Model")
	if not model or model:GetAttribute("Resource") ~= "Food" or model:GetAttribute("Alive") ~= true then return false end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return false end
	return (root.Position - target.Position).Magnitude <= Config.GatherDistance + 2
end

action.OnServerEvent:Connect(function(player, actionName, target)
	if actionName ~= "Gather" or not validBerryTarget(player, target) then return end
	local now = os.clock()
	if now - (lastBerry[player] or 0) < 0.32 then return end
	lastBerry[player] = now
	nutritionEvent:Fire(player, 6, 0, 2, "Berries: +6 hunger  •  +2 HP")
end)

game:GetService("Players").PlayerRemoving:Connect(function(player)
	lastBerry[player] = nil
end)
