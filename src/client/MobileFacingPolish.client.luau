local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

if not UserInputService.TouchEnabled then return end

local player = Players.LocalPlayer

-- GameController faces desktop players toward the mouse every frame. On touch
-- devices there is no useful mouse target, so make facing follow movement instead.
RunService:BindToRenderStep("MobileTopDownFacing", Enum.RenderPriority.Camera.Value + 20, function()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then return end

	humanoid.AutoRotate = true
	local direction = Vector3.new(humanoid.MoveDirection.X, 0, humanoid.MoveDirection.Z)
	if direction.Magnitude > 0.08 then
		root.CFrame = CFrame.lookAt(root.Position, root.Position + direction.Unit)
	end
end)
