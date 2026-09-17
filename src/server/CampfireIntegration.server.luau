local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes", 20)
local survivalState = remotes and remotes:WaitForChild("SurvivalState", 10)
local arena = Workspace:WaitForChild("SurvivalArena", 20)
if not arena or not survivalState then return end

local function attach(model)
	if not model:IsA("Model") or model:GetAttribute("BuildType") ~= "Campfire" or not model.PrimaryPart then return end
	-- SurvivalService uses this attribute to validate Campfire recipes nearby.
	model:SetAttribute("SurvivalStructure", "SurvivalCampfire")
	if model.PrimaryPart:FindFirstChild("WildforgeCookPrompt") then return end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "WildforgeCookPrompt"
	prompt.ActionText = "Cook"
	prompt.ObjectText = "Campfire"
	prompt.MaxActivationDistance = 12
	prompt.HoldDuration = 0.12
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		if model.Parent then
			survivalState:FireClient(player, { OpenCrafting = "Campfire" })
		end
	end)
end

task.spawn(function()
	while arena.Parent do
		for _, child in arena:GetChildren() do attach(child) end
		task.wait(0.5)
	end
end)
