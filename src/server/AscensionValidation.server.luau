local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local RiftData = require(ReplicatedStorage.Shared.RiftRunData)

local errors = {}
local function expect(condition, message)
	if not condition then table.insert(errors, message) end
end

expect(RiftData.MaxStages == 10, "Ascension should have 10 stages.")
expect(type(RiftData.ExtractStages) == "table" and RiftData.ExtractStages[3] and RiftData.ExtractStages[6] and RiftData.ExtractStages[9], "Cash-out stages 3/6/9 are missing.")
expect(#RiftData.ModifierOrder >= 7, "Not enough run modifiers.")
expect(#RiftData.UpgradeOrder >= 12, "Not enough run powers.")
expect(RiftData.Stages[10] and RiftData.Stages[10].Kind == "Boss", "Final Sovereign stage is missing.")
expect(RiftData.Enemies.AbyssalSovereign and RiftData.Enemies.SolarDevourer and RiftData.Enemies.GraveTitan, "Final boss pool is incomplete.")

task.wait(2)
local arena = Workspace:FindFirstChild("SurvivalArena")
local sanctuary = arena and arena:FindFirstChild("AscensionSanctuary")
local gate = Workspace:FindFirstChild("RiftExpeditionGate")
expect(sanctuary ~= nil, "Ascension Sanctuary did not generate.")
expect(gate ~= nil, "Ascension Gate did not generate.")

if #errors > 0 then
	for _, message in errors do warn("[AscensionValidation] " .. message) end
	error("[AscensionValidation] Failed with " .. #errors .. " issue(s).")
end

print("[AscensionValidation] Passed: Sanctuary + Gate + 10 stages + 7 modifiers + 12 powers + 3 Sovereign bosses.")
