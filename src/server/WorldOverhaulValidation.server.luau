local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local MobData = require(ReplicatedStorage.Shared.MobData)
local AdvancedStructureData = require(ReplicatedStorage.Shared.AdvancedStructureData)

local errors = {}
local function expect(value, message)
	if not value then table.insert(errors, message) end
end

expect(Config.WorldSize == 2600, "WorldSize should be 2600.")
expect((Config.BaseWalkSpeed or 0) >= 24, "Base movement speed should be at least 24.")
expect(#AdvancedStructureData.Order >= 18, "Expanded building catalog should contain at least 18 structures.")

for _, mobName in { "GlacierLeopard", "SandBoar", "MarshBear", "AshHound", "CrystalStag", "Mammoth", "IceGolem", "CrystalGolem" } do
	expect(MobData.Mobs[mobName] ~= nil, "Missing regional mob: " .. mobName)
end

task.wait(4)
local world = Workspace:FindFirstChild("SurvivalArena")
expect(world ~= nil, "SurvivalArena did not generate.")

if world then
	local visuals = world:FindFirstChild("WorldVisualOverhaul")
	local outposts = world:FindFirstChild("WorldNpcOutposts")
	local shrines = world:FindFirstChild("DiscoveryShrines")
	expect(visuals ~= nil, "WorldVisualOverhaul did not generate.")
	expect(outposts ~= nil, "WorldNpcOutposts did not generate.")
	expect(shrines ~= nil, "DiscoveryShrines did not generate.")

	if outposts then
		local npcCount = 0
		for _, descendant in outposts:GetDescendants() do
			if descendant:IsA("Model") and descendant:GetAttribute("WorldNPC") == true then npcCount += 1 end
		end
		expect(npcCount >= 20, "Expected at least 20 functional world NPCs; found " .. npcCount .. ".")
	end

	if shrines then
		local shrineCount = 0
		for _, descendant in shrines:GetChildren() do
			if descendant:IsA("Model") and descendant:GetAttribute("DiscoveryShrine") == true then shrineCount += 1 end
		end
		expect(shrineCount >= 8, "Expected 8 discovery shrines; found " .. shrineCount .. ".")
	end
end

if #errors > 0 then
	for _, message in errors do warn("[WorldOverhaulValidation] " .. message) end
	error("[WorldOverhaulValidation] Failed with " .. #errors .. " issue(s).")
end

print("[WorldOverhaulValidation] Passed: 2600-stud map • 24 speed • 18+ builds • regional mobs • 20 NPCs • 8 shrines • visual overhaul.")
