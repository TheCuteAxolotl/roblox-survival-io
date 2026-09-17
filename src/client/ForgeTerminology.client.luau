local Players = game:GetService("Players")

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local hud = playerGui:WaitForChild("SurvivalHUD", 15)
if not hud then return end

local watched = {}

local function normalize(label)
	if not label:IsA("TextLabel") or watched[label] then return end
	watched[label] = true

	local busy = false
	local function apply()
		if busy or not label.Parent then return end
		local text = label.Text
		local nextText = text
		nextText = string.gsub(nextText, "AGE UP", "FORGE LEVEL UP")
		nextText = string.gsub(nextText, "AGE (%d+)", "FORGE %1")
		if nextText ~= text then
			busy = true
			label.Text = nextText
			busy = false
		end
	end

	label:GetPropertyChangedSignal("Text"):Connect(apply)
	apply()
end

for _, descendant in hud:GetDescendants() do normalize(descendant) end
hud.DescendantAdded:Connect(function(descendant)
	task.defer(normalize, descendant)
end)
