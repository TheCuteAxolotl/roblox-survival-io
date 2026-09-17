local Players = game:GetService("Players")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui"):WaitForChild("SurvivalSystemsHUD", 12)
if not gui then return end

local function clean(object)
	if not (object:IsA("TextLabel") or object:IsA("TextButton")) then return end
	local busy = false
	local function apply()
		if busy then return end
		local text = object.Text
		if string.find(text, "$", 1, true) then
			busy = true
			object.Text = string.gsub(text, "%$", "")
			busy = false
		end
	end
	apply()
	object:GetPropertyChangedSignal("Text"):Connect(apply)
end

for _, descendant in gui:GetDescendants() do clean(descendant) end
gui.DescendantAdded:Connect(function(descendant)
	task.defer(clean, descendant)
end)
