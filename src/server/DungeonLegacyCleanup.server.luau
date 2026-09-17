local Workspace = game:GetService("Workspace")

local world = Workspace:WaitForChild("SurvivalArena", 20)
if not world then return end

local function cleanDungeon(name)
	local dungeon = world:FindFirstChild(name)
	if not dungeon then return 0 end
	local removed = 0
	for _, descendant in dungeon:GetDescendants() do
		if descendant:IsA("Model")
			and descendant:GetAttribute("DungeonMob") == true
			and descendant:GetAttribute("DungeonBoss") ~= true
			and descendant:GetAttribute("BossKey") == nil then
			descendant:Destroy()
			removed += 1
		end
	end
	return removed
end

task.spawn(function()
	task.wait(3)
	while true do
		local removed = cleanDungeon("DragonDungeon") + cleanDungeon("DemonDungeon")
		if removed > 0 then print(`[DungeonLegacyCleanup] Removed {removed} legacy dungeon mob(s).`) end
		task.wait(8)
	end
end)
