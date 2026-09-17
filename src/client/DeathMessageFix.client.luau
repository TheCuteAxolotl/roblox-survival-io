local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local stateChanged = ReplicatedStorage:WaitForChild("SurvivalRemotes"):WaitForChild("StateChanged")

stateChanged.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" or type(payload.FX) ~= "table" or payload.FX.Kind ~= "Death" then return end
	task.defer(function()
		local hud = player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("SurvivalHUD")
		if not hud then return end
		for _, descendant in hud:GetDescendants() do
			if descendant:IsA("TextLabel") and string.find(descendant.Text, "35%", 1, true) then
				descendant.Text = "You dropped all carried supplies and inventory. Your gold is safe."
			end
		end
	end)
end)
