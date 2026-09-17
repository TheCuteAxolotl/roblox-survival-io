local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes", 15)
if not remotes then return end

local remote = remotes:FindFirstChild("Dodge")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "Dodge"
	remote.Parent = remotes
end

local BASE_COOLDOWN = 2.15
local BASE_SPEED = 58
local cooldowns = {}

local function horizontalUnit(direction)
	if typeof(direction) ~= "Vector3" then return nil end
	local flat = Vector3.new(direction.X, 0, direction.Z)
	if flat.Magnitude < 0.15 then return nil end
	return flat.Unit
end

local function dodgeStats(player)
	local agility = math.max(1, math.floor(player:GetAttribute("HunterAgilityLevel") or 1))
	local cooldown = math.max(1.35, BASE_COOLDOWN - (agility - 1) * 0.04)
	local speed = BASE_SPEED + math.min(10, (agility - 1) * 0.55)
	return cooldown, speed
end

remote.OnServerEvent:Connect(function(player, requestedDirection)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 or humanoid.Sit then return end

	local now = workspace:GetServerTimeNow()
	if now < (cooldowns[player] or 0) then return end

	local direction = horizontalUnit(requestedDirection)
	if not direction then direction = horizontalUnit(root.CFrame.LookVector) end
	if not direction then return end

	local cooldown, speed = dodgeStats(player)
	cooldowns[player] = now + cooldown
	player:SetAttribute("WildforgeDodgeReadyAt", now + cooldown)
	player:SetAttribute("WildforgeDodgeUntil", now + 0.18)

	local oldVelocity = root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity = Vector3.new(direction.X * speed, math.max(oldVelocity.Y, 1.5), direction.Z * speed)
	remote:FireClient(player, cooldown)
end)

Players.PlayerRemoving:Connect(function(player)
	cooldowns[player] = nil
end)
