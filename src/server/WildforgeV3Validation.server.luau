local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local RiftData = require(ReplicatedStorage.Shared.RiftRunData)

local errors = {}

local function check(condition, message)
	if not condition then table.insert(errors, message) end
end

check(type(RiftData.Stages) == "table", "Rift stages table missing.")
check(RiftData.MaxStages == 6, "Rift should currently have six stages.")
for i = 1, RiftData.MaxStages do
	check(RiftData.Stages[i] ~= nil, "Missing Rift stage " .. i)
end

check(RiftData.Stages[4] and RiftData.Stages[4].Kind == "Survival", "Stage 4 Corruption Storm is not configured as timed survival.")
check(RiftData.Stages[6] and type(RiftData.Stages[6].BossPool) == "table" and #RiftData.Stages[6].BossPool >= 3, "Final boss pool should contain at least three overlords.")

for _, bossId in RiftData.Stages[6].BossPool or {} do
	local boss = RiftData.Enemies[bossId]
	check(boss ~= nil and boss.Boss == true, "Final boss is missing or not marked Boss: " .. tostring(bossId))
end

check(#RiftData.UpgradeOrder >= 8, "Rift needs a meaningful random power pool.")
for _, id in RiftData.UpgradeOrder do
	check(RiftData.Upgrades[id] ~= nil, "Missing Rift power: " .. tostring(id))
end

check(#RiftData.ModifierOrder >= 5, "Rift mutations are missing.")
for _, id in RiftData.ModifierOrder do
	check(RiftData.Modifiers[id] ~= nil, "Missing Rift modifier: " .. tostring(id))
end

if #errors > 0 then
	for _, message in errors do warn("[WildforgeV3Validation] " .. message) end
	error("[WildforgeV3Validation] Configuration failed with " .. #errors .. " issue(s).")
end

print(string.format(
	"[WildforgeV3Validation] Config passed: %d stages • %d powers • %d run mutations • %d final bosses.",
	RiftData.MaxStages,
	#RiftData.UpgradeOrder,
	#RiftData.ModifierOrder,
	#RiftData.Stages[6].BossPool
))

task.delay(8, function()
	local gate = Workspace:FindFirstChild("RiftExpeditionGate")
	local arena = Workspace:FindFirstChild("RiftExpeditionArena")
	if not gate then warn("[WildforgeV3Validation] Runtime missing RiftExpeditionGate.") end
	if not arena then warn("[WildforgeV3Validation] Runtime missing RiftExpeditionArena.") end

	local portal = gate and gate:FindFirstChild("RiftPortal", true)
	local prompt = portal and portal:FindFirstChildOfClass("ProximityPrompt")
	local floor = arena and arena:FindFirstChild("RiftFloor", true)
	if gate and arena and portal and prompt and floor then
		print("[WildforgeV3Validation] Runtime passed: central Rift gate and expedition arena are online.")
	else
		warn("[WildforgeV3Validation] Runtime incomplete: gate/portal/prompt/arena/floor did not all initialize.")
	end
end)
