local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HatData = require(ReplicatedStorage.Shared.HatData)

local HatService = {}

local function clearVisual(character)
	local old = character:FindFirstChild("SurvivalHat")
	if old then old:Destroy() end
end

local function weldPart(model, head, name, size, offset, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.CFrame = head.CFrame * offset
	part.Parent = model

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = head
	weld.Part1 = part
	weld.Parent = part
	return part
end

local function buildVisual(character, hatName)
	clearVisual(character)
	local data = HatData.Hats[hatName]
	if not data then return end
	local head = character:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then return end

	local model = Instance.new("Model")
	model.Name = "SurvivalHat"
	model.Parent = character

	if data.Style == "Cap" then
		weldPart(model, head, "CapTop", Vector3.new(2.25, 0.65, 2.25), CFrame.new(0, 0.68, 0), data.Color)
		weldPart(model, head, "Brim", Vector3.new(2.5, 0.18, 1.1), CFrame.new(0, 0.42, -0.85), data.Accent)
	elseif data.Style == "Miner" then
		local dome = weldPart(model, head, "Helmet", Vector3.new(2.35, 1.15, 2.35), CFrame.new(0, 0.72, 0), data.Color)
		dome.Shape = Enum.PartType.Ball
		weldPart(model, head, "Lamp", Vector3.new(0.62, 0.62, 0.48), CFrame.new(0, 0.78, -1.18), data.Accent, Enum.Material.Neon)
	elseif data.Style == "Helm" then
		weldPart(model, head, "Helm", Vector3.new(2.35, 1.25, 2.3), CFrame.new(0, 0.58, 0), data.Color, Enum.Material.Metal)
		weldPart(model, head, "Crest", Vector3.new(0.35, 1.35, 1.65), CFrame.new(0, 1.45, 0.1), data.Accent, Enum.Material.Metal)
	elseif data.Style == "Hood" then
		local hood = weldPart(model, head, "Hood", Vector3.new(2.55, 2.35, 2.45), CFrame.new(0, 0.25, 0.15), data.Color, Enum.Material.Fabric)
		hood.Transparency = 0.18
	elseif data.Style == "Crown" then
		weldPart(model, head, "Band", Vector3.new(2.25, 0.35, 2.25), CFrame.new(0, 0.62, 0), data.Color, Enum.Material.Metal)
		for i, x in { -0.75, -0.25, 0.25, 0.75 } do
			local spike = weldPart(model, head, `Spike{i}`, Vector3.new(0.28, 1.15, 0.28), CFrame.new(x, 1.28, -0.65), data.Accent, Enum.Material.Metal)
			spike.Orientation = Vector3.new(0, 0, x * 12)
		end
	end
end

function HatService.Apply(player, hatName)
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local data = HatData.Hats[hatName]
	local effects = data and data.Effects or {}
	local oldMax = humanoid.MaxHealth > 0 and humanoid.MaxHealth or 100
	local ratio = math.clamp(humanoid.Health / oldMax, 0, 1)

	humanoid.UseJumpPower = true
	humanoid.JumpPower = 42
	humanoid.WalkSpeed = 16 + (effects.WalkSpeedBonus or 0)
	humanoid.MaxHealth = 100 + (effects.MaxHealthBonus or 0)
	humanoid.Health = math.max(1, humanoid.MaxHealth * ratio)

	buildVisual(character, hatName)
end

function HatService.Clear(player)
	local character = player.Character
	if not character then return end
	clearVisual(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.UseJumpPower = true
		humanoid.JumpPower = 42
		humanoid.WalkSpeed = 16
		humanoid.MaxHealth = 100
		humanoid.Health = math.min(humanoid.Health, 100)
	end
end

return HatService
