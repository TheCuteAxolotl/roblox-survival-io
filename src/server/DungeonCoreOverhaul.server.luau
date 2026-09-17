local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local InventoryService = require(script.Parent.InventoryService)
local PlayerService = require(script.Parent.PlayerService)

local world = Workspace:WaitForChild("SurvivalArena", 20)
if not world then return end

local RESPAWN_SECONDS = 210
local records = {}

local definitions = {
	EmberWyrm = {
		Label = "EMBER WYRM",
		Style = "Dragon",
		Health = 2100,
		Damage = 38,
		Speed = 12,
		AttackRange = 11,
		Aggro = 115,
		Cooldown = 1.25,
		Scale = 0.82,
		Color = Color3.fromRGB(166, 69, 35),
		Glow = Color3.fromRGB(255, 143, 52),
		Gold = 320,
		XP = 210,
		Drops = { { "DragonScale", 2, 3 }, { "ObsidianShard", 1, 3 } },
	},
	AncientDragon = {
		Label = "ANCIENT DRAGON",
		Style = "Dragon",
		Health = 4800,
		Damage = 58,
		Speed = 10.5,
		AttackRange = 13,
		Aggro = 135,
		Cooldown = 1.45,
		Scale = 1.28,
		Color = Color3.fromRGB(94, 38, 34),
		Glow = Color3.fromRGB(255, 202, 72),
		Gold = 900,
		XP = 520,
		Drops = { { "DragonScale", 5, 8 }, { "ObsidianShard", 3, 6 } },
		Rare = { { "EclipseCloak", 0.16 }, { "AncientRelic", 0.045 } },
	},
	DreadKnight = {
		Label = "DREAD KNIGHT",
		Style = "Knight",
		Health = 2400,
		Damage = 44,
		Speed = 12.5,
		AttackRange = 9,
		Aggro = 110,
		Cooldown = 1.05,
		Scale = 1.0,
		Color = Color3.fromRGB(54, 46, 61),
		Glow = Color3.fromRGB(181, 77, 209),
		Gold = 350,
		XP = 230,
		Drops = { { "DemonCore", 2, 3 }, { "ObsidianShard", 2, 4 } },
	},
	BoneColossus = {
		Label = "BONE COLOSSUS",
		Style = "Colossus",
		Health = 3300,
		Damage = 52,
		Speed = 8.5,
		AttackRange = 12,
		Aggro = 118,
		Cooldown = 1.55,
		Scale = 1.22,
		Color = Color3.fromRGB(176, 168, 143),
		Glow = Color3.fromRGB(231, 219, 167),
		Gold = 500,
		XP = 310,
		Drops = { { "DemonCore", 2, 4 }, { "ObsidianShard", 3, 6 } },
	},
	AbyssKing = {
		Label = "ABYSS KING",
		Style = "Demon",
		Health = 4300,
		Damage = 56,
		Speed = 11,
		AttackRange = 11,
		Aggro = 135,
		Cooldown = 1.3,
		Scale = 1.3,
		Color = Color3.fromRGB(87, 34, 89),
		Glow = Color3.fromRGB(255, 68, 190),
		Gold = 800,
		XP = 470,
		Drops = { { "DemonCore", 5, 7 }, { "ObsidianShard", 4, 7 } },
		Rare = { { "EclipseCloak", 0.12 }, { "AncientRelic", 0.035 } },
	},
}

local dungeonSetups = {
	DragonDungeon = {
		Center = Vector3.new(-480, 0, 475),
		Bosses = {
			{ Key = "EmberWyrm", Offset = Vector3.new(-34, 0, 18) },
			{ Key = "AncientDragon", Offset = Vector3.new(28, 0, 32) },
		},
	},
	DemonDungeon = {
		Center = Vector3.new(480, 0, 475),
		Bosses = {
			{ Key = "DreadKnight", Offset = Vector3.new(-42, 0, 5) },
			{ Key = "BoneColossus", Offset = Vector3.new(38, 0, 8) },
			{ Key = "AbyssKing", Offset = Vector3.new(0, 0, 42) },
		},
	},
}

local function makePart(parent, name, size, cf, color, material, transparency)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.Slate
	p.Transparency = transparency or 0
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function addBossBar(model, root, definition)
	local gui = Instance.new("BillboardGui")
	gui.Name = "BossHUD"
	gui.Size = UDim2.fromOffset(280, 58)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 11 * definition.Scale, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 180
	gui.Parent = root

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1,0,0,28)
	title.BackgroundTransparency = 1
	title.Text = definition.Label
	title.TextColor3 = definition.Glow
	title.TextStrokeTransparency = 0.25
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 17
	title.Parent = gui

	local back = Instance.new("Frame")
	back.Position = UDim2.fromOffset(10,34)
	back.Size = UDim2.new(1,-20,0,13)
	back.BackgroundColor3 = Color3.fromRGB(35,35,41)
	back.BorderSizePixel = 0
	back.Parent = gui
	Instance.new("UICorner",back).CornerRadius = UDim.new(1,0)
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1,1)
	fill.BackgroundColor3 = definition.Glow
	fill.BorderSizePixel = 0
	fill.Parent = back
	Instance.new("UICorner",fill).CornerRadius = UDim.new(1,0)
	return fill
end

local function dragonVisual(model, root, d)
	local s = d.Scale
	makePart(model,"Body",Vector3.new(11,6,18)*s,root.CFrame*CFrame.new(0,2.8*s,0),d.Color,Enum.Material.Slate)
	makePart(model,"Chest",Vector3.new(9,7,9)*s,root.CFrame*CFrame.new(0,3.5*s,-4*s),d.Color:Lerp(Color3.new(1,1,1),0.08),Enum.Material.Slate)
	makePart(model,"Head",Vector3.new(7,5.5,7)*s,root.CFrame*CFrame.new(0,6*s,-11*s),d.Color,Enum.Material.Slate)
	makePart(model,"Snout",Vector3.new(5.4,2.6,5.5)*s,root.CFrame*CFrame.new(0,5*s,-15.5*s),d.Color:Lerp(Color3.new(1,1,1),0.09),Enum.Material.Slate)
	for _, side in { -1,1 } do
		makePart(model,"Eye",Vector3.new(0.7,0.7,0.4)*s,root.CFrame*CFrame.new(side*2.0*s,6.6*s,-14.2*s),d.Glow,Enum.Material.Neon)
		makePart(model,"Horn",Vector3.new(0.8,4,0.8)*s,root.CFrame*CFrame.new(side*2.4*s,9.2*s,-11*s)*CFrame.Angles(math.rad(-28),0,math.rad(side*17)),Color3.fromRGB(221,203,155),Enum.Material.Slate)
		makePart(model,"Wing",Vector3.new(13,0.65,12)*s,root.CFrame*CFrame.new(side*10.5*s,6*s,1.5*s)*CFrame.Angles(0,0,math.rad(side*15)),d.Color:Lerp(Color3.new(0,0,0),0.28),Enum.Material.Fabric)
		for _, z in { -4,5 } do
			makePart(model,"Leg",Vector3.new(1.8,5.5,1.8)*s,root.CFrame*CFrame.new(side*4.0*s,-0.3*s,z*s),d.Color,Enum.Material.Slate)
			makePart(model,"Claw",Vector3.new(2.7,1,3.5)*s,root.CFrame*CFrame.new(side*4.0*s,-3*s,(z-0.7)*s),d.Glow:Lerp(Color3.new(0,0,0),0.35),Enum.Material.Slate)
		end
	end
	for i=1,5 do makePart(model,"Tail",Vector3.new(math.max(1.2,4-i*0.5),math.max(1.2,4-i*0.5),5)*s,root.CFrame*CFrame.new(0,2*s-i*0.25,(10+i*4)*s),d.Color,Enum.Material.Slate) end
end

local function humanoidVisual(model, root, d)
	local s = d.Scale
	local dark = d.Color:Lerp(Color3.new(0,0,0),0.3)
	makePart(model,"Torso",Vector3.new(7,9,5.5)*s,root.CFrame*CFrame.new(0,3.2*s,0),d.Color,Enum.Material.Slate)
	makePart(model,"Head",Vector3.new(5,5,5)*s,root.CFrame*CFrame.new(0,10*s,-0.5*s),dark,Enum.Material.Slate)
	for _, side in { -1,1 } do
		makePart(model,"Eye",Vector3.new(0.7,0.7,0.35)*s,root.CFrame*CFrame.new(side*1.2*s,10.5*s,-3*s),d.Glow,Enum.Material.Neon)
		makePart(model,"Arm",Vector3.new(1.7,7,1.7)*s,root.CFrame*CFrame.new(side*4.4*s,3*s,0),d.Color,Enum.Material.Slate)
		makePart(model,"Leg",Vector3.new(2,6,2)*s,root.CFrame*CFrame.new(side*1.8*s,-4*s,0.5*s),dark,Enum.Material.Slate)
	end
	if d.Style == "Demon" then
		for _, side in { -1,1 } do makePart(model,"Horn",Vector3.new(0.8,4.5,0.8)*s,root.CFrame*CFrame.new(side*1.8*s,13*s,0)*CFrame.Angles(0,0,math.rad(side*24)),Color3.fromRGB(55,48,62),Enum.Material.Slate) end
	elseif d.Style == "Knight" then
		makePart(model,"Sword",Vector3.new(1,1,9)*s,root.CFrame*CFrame.new(5*s,1*s,-3*s)*CFrame.Angles(math.rad(-25),0,math.rad(20)),d.Glow,Enum.Material.Metal)
	elseif d.Style == "Colossus" then
		makePart(model,"Shoulders",Vector3.new(13,3,6)*s,root.CFrame*CFrame.new(0,7*s,0),d.Color,Enum.Material.Slate)
	end
end

local function ringFX(position, radius, color)
	local ring = Instance.new("Part")
	ring.Name = "BossShockwave"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.25,radius*2,radius*2)
	ring.CFrame = CFrame.new(position + Vector3.new(0,0.25,0))*CFrame.Angles(0,0,math.rad(90))
	ring.Anchored = true ring.CanCollide = false ring.CanQuery = false ring.Material = Enum.Material.Neon ring.Color = color ring.Transparency = 0.45 ring.Parent = Workspace
	Debris:AddItem(ring,0.35)
end

local function adjustedDamage(player, amount)
	if workspace:GetServerTimeNow() < (player:GetAttribute("WildforgeDodgeUntil") or 0) then return 0 end
	local reduction = math.clamp(player:GetAttribute("ArmorReduction") or 0,0,0.65)
	return math.max(1,math.floor(amount*(1-reduction)+0.5))
end

local function nearestPlayer(position, range)
	local best,bestDistance=nil,range
	for _,player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if root and hum and hum.Health>0 then
			local d=(root.Position-position).Magnitude
			if d<bestDistance then best,bestDistance=player,d end
		end
	end
	return best,bestDistance
end

local function rewardBoss(model,key,d)
	local pos=model.PrimaryPart and model.PrimaryPart.Position or Vector3.zero
	for _,drop in d.Drops or {} do InventoryService.CreateWorldDrop(pos + Vector3.new(math.random(-4,4),1.5,math.random(-4,4)),drop[1],math.random(drop[2],drop[3])) end
	for _,rare in d.Rare or {} do if math.random()<rare[2] then InventoryService.CreateWorldDrop(pos + Vector3.new(math.random(-3,3),1.5,math.random(-3,3)),rare[1],1) end end
	local attackerId=model:GetAttribute("LastAttackerUserId")
	local attacker=attackerId and Players:GetPlayerByUserId(attackerId)
	if attacker then PlayerService.Add(attacker,{Gold=d.Gold or 0,XP=d.XP or 0}) end
end

local function ensureArena(dungeon, center, theme)
	local old = dungeon:FindFirstChild("ExpandedBossArena")
	if old then return old end
	local arena=Instance.new("Model") arena.Name="ExpandedBossArena" arena.Parent=dungeon
	local floorColor = theme=="Dragon" and Color3.fromRGB(74,58,54) or Color3.fromRGB(55,48,61)
	local wallColor = theme=="Dragon" and Color3.fromRGB(92,70,62) or Color3.fromRGB(66,54,74)
	local floor=makePart(arena,"EncounterFloor",Vector3.new(170,1,160),CFrame.new(center+Vector3.new(0,0.4,0)),floorColor,Enum.Material.Slate)
	floor.CanCollide=true
	for _,child in dungeon:GetChildren() do
		if child:IsA("BasePart") and child~=floor and (string.find(child.Name,"Wall") or child.Name=="Roof") then child.CanCollide=false child.Transparency=math.max(child.Transparency,0.55) end
	end
	local walls={
		{Vector3.new(170,24,4),Vector3.new(0,12,78)},
		{Vector3.new(4,24,160),Vector3.new(-83,12,0)},
		{Vector3.new(4,24,160),Vector3.new(83,12,0)},
		{Vector3.new(62,24,4),Vector3.new(-54,12,-78)},
		{Vector3.new(62,24,4),Vector3.new(54,12,-78)},
	}
	for _,info in walls do local wall=makePart(arena,"ArenaWall",info[1],CFrame.new(center+info[2]),wallColor,Enum.Material.Rock) wall.CanCollide=true end
	for i=1,10 do
		local x=((i%5)-2.5)*28
		local z=(i<=5 and -1 or 1)*58
		local flame=makePart(arena,"BossTorch",Vector3.new(1.3,2.2,1.3),CFrame.new(center+Vector3.new(x,4,z)),theme=="Dragon" and Color3.fromRGB(255,117,39) or Color3.fromRGB(206,59,255),Enum.Material.Neon)
		local light=Instance.new("PointLight") light.Range=27 light.Brightness=2.5 light.Color=flame.Color light.Parent=flame
	end
	return arena
end

local function clampToArena(center,position,margin)
	return Vector3.new(math.clamp(position.X,center.X-85+margin,center.X+85-margin),3,math.clamp(position.Z,center.Z-80+margin,center.Z+80-margin))
end

local function spawnBoss(record,key,offset)
	local d=definitions[key]
	if not d or not record.Dungeon.Parent then return end
	local spawnPos=record.Center+offset+Vector3.new(0,3,0)
	local model=Instance.new("Model")
	model.Name=d.Label:gsub(" ","")
	model:SetAttribute("SurvivalMob",true)
	model:SetAttribute("DungeonMob",true)
	model:SetAttribute("DungeonBoss",true)
	model:SetAttribute("BossMob",true)
	model:SetAttribute("BossKey",key)
	model:SetAttribute("MobType",d.Style=="Dragon" and "Dragon" or "Demon")
	model:SetAttribute("ReadableDungeonVisual",true)
	model.Parent=record.Dungeon
	local root=makePart(model,"HumanoidRootPart",Vector3.new(6,6,6)*d.Scale,CFrame.new(spawnPos),Color3.new(1,1,1),Enum.Material.SmoothPlastic,1)
	root.CanQuery=true root.CanCollide=false model.PrimaryPart=root
	if d.Style=="Dragon" then dragonVisual(model,root,d) else humanoidVisual(model,root,d) end
	local hum=Instance.new("Humanoid")
	hum.Name="Humanoid" hum.RequiresNeck=false hum.BreakJointsOnDeath=false hum.MaxHealth=d.Health hum.Health=d.Health hum.WalkSpeed=0 hum.JumpPower=0 hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None hum.Parent=model
	local fill=addBossBar(model,root,d)
	hum.HealthChanged:Connect(function(health) if fill.Parent then fill.Size=UDim2.fromScale(math.clamp(health/hum.MaxHealth,0,1),1) end end)
	record.Live[key]=model
	local lastMelee=0
	local lastSpecial=os.clock()+math.random(3,6)
	local lastPulse=os.clock()+math.random(6,9)

	hum.Died:Connect(function()
		if record.Live[key]~=model then return end
		record.Live[key]=nil
		rewardBoss(model,key,d)
		task.delay(2.5,function() if model.Parent then model:Destroy() end end)
		task.delay(RESPAWN_SECONDS,function() if record.Dungeon.Parent and record.Live[key]==nil then spawnBoss(record,key,offset) end end)
	end)

	task.spawn(function()
		local last=os.clock()
		while model.Parent and hum.Health>0 do
			task.wait(0.12)
			local now=os.clock()
			local dt=math.min(0.25,now-last) last=now
			local target,distance=nearestPlayer(root.Position,d.Aggro)
			if not target then continue end
			local targetRoot=target.Character and target.Character:FindFirstChild("HumanoidRootPart")
			local targetHum=target.Character and target.Character:FindFirstChildOfClass("Humanoid")
			if not targetRoot or not targetHum or targetHum.Health<=0 then continue end
			local enrage=hum.Health/hum.MaxHealth<=0.35
			local flatDelta=Vector3.new(targetRoot.Position.X-root.Position.X,0,targetRoot.Position.Z-root.Position.Z)
			if flatDelta.Magnitude>d.AttackRange and flatDelta.Magnitude>0.1 then
				local speed=d.Speed*(enrage and 1.28 or 1)
				local nextPos=clampToArena(record.Center,root.Position+flatDelta.Unit*speed*dt,10*d.Scale)
				model:PivotTo(CFrame.lookAt(nextPos,Vector3.new(targetRoot.Position.X,nextPos.Y,targetRoot.Position.Z)))
			end
			if distance<=d.AttackRange and now-lastMelee>=d.Cooldown*(enrage and 0.75 or 1) then
				lastMelee=now
				local damage=adjustedDamage(target,d.Damage*(enrage and 1.18 or 1))
				if damage>0 then targetHum:TakeDamage(damage) end
			end
			if now>=lastSpecial then
				lastSpecial=now+(d.Style=="Dragon" and 7 or 8)
				if d.Style=="Dragon" then
					local forward=Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z)
					if forward.Magnitude>0.1 then
						for _,other in Players:GetPlayers() do
							local otherRoot=other.Character and other.Character:FindFirstChild("HumanoidRootPart")
							local otherHum=other.Character and other.Character:FindFirstChildOfClass("Humanoid")
							if otherRoot and otherHum and otherHum.Health>0 then
								local delta=Vector3.new(otherRoot.Position.X-root.Position.X,0,otherRoot.Position.Z-root.Position.Z)
								if delta.Magnitude<=65 and delta.Magnitude>0.1 and forward.Unit:Dot(delta.Unit)>=math.cos(math.rad(38)) then
									local damage=adjustedDamage(other,d.Damage*0.82)
									if damage>0 then otherHum:TakeDamage(damage) end
								end
							end
						end
					end
				else
					ringFX(root.Position,22*d.Scale,d.Glow)
					for _,other in Players:GetPlayers() do
						local otherRoot=other.Character and other.Character:FindFirstChild("HumanoidRootPart")
						local otherHum=other.Character and other.Character:FindFirstChildOfClass("Humanoid")
						if otherRoot and otherHum and otherHum.Health>0 and (otherRoot.Position-root.Position).Magnitude<=22*d.Scale then
							local damage=adjustedDamage(other,d.Damage*0.72)
							if damage>0 then otherHum:TakeDamage(damage) end
						end
					end
				end
			end
			if now>=lastPulse then
				lastPulse=now+10
				ringFX(root.Position,30*d.Scale,d.Glow:Lerp(Color3.new(1,1,1),0.22))
				for _,other in Players:GetPlayers() do
					local otherRoot=other.Character and other.Character:FindFirstChild("HumanoidRootPart")
					local otherHum=other.Character and other.Character:FindFirstChildOfClass("Humanoid")
					if otherRoot and otherHum and otherHum.Health>0 and (otherRoot.Position-root.Position).Magnitude<=30*d.Scale then
						local damage=adjustedDamage(other,d.Damage*0.48)
						if damage>0 then otherHum:TakeDamage(damage) end
					end
				end
			end
		end
	end)
end

local function clearLegacyMobs(dungeon)
	for _,descendant in dungeon:GetDescendants() do
		if descendant:IsA("Model") and descendant:GetAttribute("DungeonMob")==true then descendant:Destroy() end
	end
end

local function setupDungeon(name,setup)
	local dungeon=world:WaitForChild(name,20)
	if not dungeon then warn(`[DungeonCore] Missing {name}.`) return end
	clearLegacyMobs(dungeon)
	ensureArena(dungeon,setup.Center,name=="DragonDungeon" and "Dragon" or "Demon")
	local record={Dungeon=dungeon,Center=setup.Center,Live={}}
	records[name]=record
	for _,boss in setup.Bosses do spawnBoss(record,boss.Key,boss.Offset) end
	print(`[DungeonCore] {name} online with {#setup.Bosses} authoritative boss monsters.`)
end

for name,setup in dungeonSetups do task.spawn(setupDungeon,name,setup) end

-- Self-heal the encounter if another script or Studio edit removes a live boss.
task.spawn(function()
	while true do
		task.wait(5)
		for name,setup in dungeonSetups do
			local record=records[name]
			if record and record.Dungeon.Parent then
				for _,boss in setup.Bosses do
					local current=record.Live[boss.Key]
					if not current or not current.Parent then
						record.Live[boss.Key]=nil
						spawnBoss(record,boss.Key,boss.Offset)
					end
				end
			end
		end
	end
end)
