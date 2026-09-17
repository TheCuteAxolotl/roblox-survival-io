local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local InventoryService = require(script.Parent.InventoryService)
local PlayerService = require(script.Parent.PlayerService)

local world = Workspace:WaitForChild("SurvivalArena", 20)
local remotes = ReplicatedStorage:WaitForChild("SurvivalRemotes", 20)
if not world or not remotes then return end

local feedback = remotes:FindFirstChild("WorldNPCFeedback") or Instance.new("RemoteEvent")
feedback.Name = "WorldNPCFeedback"
feedback.Parent = remotes

local old = world:FindFirstChild("RebornNPCWorld")
if old then old:Destroy() end
local root = Instance.new("Model")
root.Name = "RebornNPCWorld"
root.Parent = world

local cooldowns = {}

local function tell(player, message)
	if player and player.Parent then feedback:FireClient(player, message) end
end

local function ready(player, key, seconds)
	cooldowns[player] = cooldowns[player] or {}
	local now = os.clock()
	local nextTime = cooldowns[player][key] or 0
	if now < nextTime then
		return false, math.ceil(nextTime - now)
	end
	cooldowns[player][key] = now + seconds
	return true, 0
end

local function part(parent,name,size,cf,color,material,collide)
	local p=Instance.new("Part")
	p.Name=name p.Size=size p.CFrame=cf p.Color=color p.Material=material or Enum.Material.SmoothPlastic
	p.Anchored=true p.CanCollide=collide~=false p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Parent=parent
	return p
end

local function nameplate(head, name, role, color)
	local gui=Instance.new("BillboardGui")
	gui.Size=UDim2.fromOffset(180,44) gui.StudsOffsetWorldSpace=Vector3.new(0,2.4,0) gui.AlwaysOnTop=true gui.MaxDistance=90 gui.Parent=head
	local label=Instance.new("TextLabel")
	label.Size=UDim2.fromScale(1,1) label.BackgroundTransparency=1
	label.Text=name.."\n"..role label.TextColor3=color label.TextStrokeTransparency=0.35
	label.Font=Enum.Font.GothamBold label.TextScaled=true label.Parent=gui
end

local function makeNPC(parent, data)
	local m=Instance.new("Model")
	m.Name=data.Name:gsub(" ","")
	m:SetAttribute("WorldNPC",true)
	m:SetAttribute("NPCRole",data.Role)
	m.Parent=parent
	local pos=data.Position
	local skin=data.Skin or Color3.fromRGB(196,151,115)
	local outfit=data.Outfit or Color3.fromRGB(67,78,91)
	local accent=data.Accent or Color3.fromRGB(210,175,96)

	local torso=part(m,"Torso",Vector3.new(2.4,3.2,1.4),CFrame.new(pos+Vector3.new(0,3.6,0)),outfit,Enum.Material.Fabric)
	part(m,"Belt",Vector3.new(2.5,0.35,1.5),torso.CFrame*CFrame.new(0,-1.15,0),accent,Enum.Material.Leather)
	local head=part(m,"Head",Vector3.new(2.0,2.0,2.0),CFrame.new(pos+Vector3.new(0,6.2,0)),skin,Enum.Material.SmoothPlastic)
	head.Shape=Enum.PartType.Ball
	part(m,"Hair",Vector3.new(2.05,0.65,2.05),head.CFrame*CFrame.new(0,0.65,0),data.Hair or Color3.fromRGB(58,43,37),Enum.Material.SmoothPlastic,false)
	for _,side in{-1,1} do
		part(m,"Arm",Vector3.new(0.7,3.0,0.7),CFrame.new(pos+Vector3.new(side*1.6,3.7,0)),skin,Enum.Material.SmoothPlastic)
		part(m,"Boot",Vector3.new(0.9,2.6,1.0),CFrame.new(pos+Vector3.new(side*0.65,1.45,0)),Color3.fromRGB(52,48,45),Enum.Material.Leather)
	end
	if data.Backpack then
		part(m,"Backpack",Vector3.new(2.0,2.4,0.8),torso.CFrame*CFrame.new(0,0,1.05),Color3.fromRGB(87,63,45),Enum.Material.Fabric,false)
	end
	if data.Hat then
		local hat=part(m,"Hat",Vector3.new(2.6,0.45,2.6),head.CFrame*CFrame.new(0,1.15,0),accent,Enum.Material.Fabric,false)
		hat.Shape=Enum.PartType.Cylinder
	end
	m.PrimaryPart=torso
	nameplate(head,data.Name,data.Role,accent)

	local prompt=Instance.new("ProximityPrompt")
	prompt.ActionText=data.ActionText or "Talk"
	prompt.ObjectText=data.Name.." • "..data.Role
	prompt.MaxActivationDistance=12
	prompt.HoldDuration=0.25
	prompt.RequiresLineOfSight=false
	prompt.Parent=torso
	prompt.Triggered:Connect(function(player)
		data.Action(player)
	end)
	return m
end

local function camp(parent,name,center,accent)
	local m=Instance.new("Model")
	m.Name=name
	m:SetAttribute("VillageBiome",name)
	m:SetAttribute("GeneratedLandmark",true)
	m.Parent=parent
	part(m,"CampGround",Vector3.new(68,0.6,54),CFrame.new(center+Vector3.new(0,0.3,0)),Color3.fromRGB(73,68,61),Enum.Material.Ground)
	local fireBase=part(m,"FirePit",Vector3.new(7,0.6,7),CFrame.new(center+Vector3.new(0,0.6,2)),Color3.fromRGB(68,61,55),Enum.Material.Slate)
	fireBase.Shape=Enum.PartType.Cylinder
	local flame=part(m,"CampFlame",Vector3.new(2.4,2.8,2.4),CFrame.new(center+Vector3.new(0,2.2,2)),accent,Enum.Material.Neon,false)
	flame.Shape=Enum.PartType.Ball
	local light=Instance.new("PointLight") light.Color=accent light.Range=28 light.Brightness=2.5 light.Shadows=true light.Parent=flame
	for _,x in{-24,24} do
		local post=part(m,"AwningPost",Vector3.new(0.7,6,0.7),CFrame.new(center+Vector3.new(x,3,-13)),Color3.fromRGB(88,60,44),Enum.Material.Wood)
		part(m,"Awning",Vector3.new(18,0.7,14),post.CFrame*CFrame.new(0,3.2,5),accent:Lerp(Color3.new(0,0,0),0.35),Enum.Material.Fabric,false)
	end
	for _,z in{-22,22} do
		part(m,"Crate",Vector3.new(4,3,4),CFrame.new(center+Vector3.new(28,1.5,z/2)),Color3.fromRGB(112,78,50),Enum.Material.WoodPlanks)
	end
	return m
end

local function healAction(key)
	return function(player)
		local ok,remaining=ready(player,key,70)
		if not ok then tell(player, "Healer is resting • "..remaining.."s") return end
		local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum.Health=hum.MaxHealth end
		tell(player,"Restored to full health.")
	end
end

local function suppliesAction(key)
	return function(player)
		local ok,remaining=ready(player,key,180)
		if not ok then tell(player,"Supplies restock in "..remaining.."s") return end
		PlayerService.Add(player,{Wood=28,Stone=14,Food=8})
		tell(player,"Quartermaster issued 28 Wood • 14 Stone • 8 Food.")
	end
end

local function hideTrade(player)
	if InventoryService.CountItem(player,"Hide") < 3 then tell(player,"Bring me 3 Animal Hide and I'll pay 24 Gold.") return end
	InventoryService.RemoveItem(player,"Hide",3)
	PlayerService.Add(player,{Gold=24})
	tell(player,"Sold 3 Animal Hide • +24 Gold.")
end

local function furTrade(player)
	if InventoryService.CountItem(player,"Fur") < 3 then tell(player,"Bring me 3 Thick Fur and I'll pay 30 Gold.") return end
	InventoryService.RemoveItem(player,"Fur",3)
	PlayerService.Add(player,{Gold=30})
	tell(player,"Sold 3 Thick Fur • +30 Gold.")
end

local function venomTrade(player)
	if InventoryService.CountItem(player,"Venom") < 2 or InventoryService.CountItem(player,"Herb") < 2 then
		tell(player,"I can brew a Health Potion for 2 Venom + 2 Herbs.") return
	end
	if not InventoryService.CanAdd(player,"HealthPotion",1) then tell(player,"Your inventory is full.") return end
	InventoryService.RemoveItem(player,"Venom",2,true)
	InventoryService.RemoveItem(player,"Herb",2,true)
	InventoryService.AddItem(player,"HealthPotion",1)
	tell(player,"Brewed 1 Health Potion.")
end

local function materialTrade(player)
	if not PlayerService.CanAfford(player,{Gold=22}) then tell(player,"22 Gold buys a builder bundle.") return end
	PlayerService.Spend(player,{Gold=22})
	PlayerService.Add(player,{Wood=45,Stone=28})
	tell(player,"Builder bundle • +45 Wood • +28 Stone.")
end

local function scoutAction(regionKey, regionName)
	return function(player)
		player:SetAttribute("Discovered_"..regionKey,true)
		PlayerService.Add(player,{XP=12})
		tell(player,regionName.." marked as discovered • +12 XP.")
	end
end

local CAMPS={
	{Key="Sanctuary",Center=Vector3.new(0,0,-315),Accent=Color3.fromRGB(161,108,232)},
	{Key="Highlands",Center=Vector3.new(-720,0,570),Accent=Color3.fromRGB(118,194,255)},
	{Key="Dunes",Center=Vector3.new(720,0,570),Accent=Color3.fromRGB(95,228,255)},
	{Key="Marsh",Center=Vector3.new(-720,0,-570),Accent=Color3.fromRGB(114,222,142)},
	{Key="Grove",Center=Vector3.new(720,0,-570),Accent=Color3.fromRGB(255,126,70)},
}

for _,info in CAMPS do
	local c=camp(root,info.Key.."Outpost",info.Center,info.Accent)
	local base=info.Center
	if info.Key=="Sanctuary" then
		makeNPC(c,{Name="Elowen",Role="Field Healer",Position=base+Vector3.new(-19,0,-8),Accent=info.Accent,Outfit=Color3.fromRGB(75,88,83),ActionText="Rest",Action=healAction("sanctuary_heal")})
		makeNPC(c,{Name="Mira",Role="Quartermaster",Position=base+Vector3.new(19,0,-8),Accent=Color3.fromRGB(232,191,104),Outfit=Color3.fromRGB(75,68,61),ActionText="Supplies",Action=suppliesAction("sanctuary_supply"),Backpack=true})
		makeNPC(c,{Name="Torren",Role="Master Builder",Position=base+Vector3.new(-19,0,15),Accent=Color3.fromRGB(205,142,89),Outfit=Color3.fromRGB(73,76,82),ActionText="Buy Bundle",Action=materialTrade})
		makeNPC(c,{Name="Kael",Role="Hide Buyer",Position=base+Vector3.new(19,0,15),Accent=Color3.fromRGB(154,204,119),Outfit=Color3.fromRGB(58,76,60),ActionText="Trade Hide",Action=hideTrade,Backpack=true})
	elseif info.Key=="Highlands" then
		makeNPC(c,{Name="Sera",Role="Frost Scout",Position=base+Vector3.new(-18,0,-10),Accent=info.Accent,Outfit=Color3.fromRGB(86,103,116),ActionText="Mark Region",Action=scoutAction("Highlands","Frostspire Highlands"),Backpack=true})
		makeNPC(c,{Name="Bram",Role="Fur Trader",Position=base+Vector3.new(18,0,-10),Accent=Color3.fromRGB(222,214,191),Outfit=Color3.fromRGB(91,78,69),ActionText="Trade Fur",Action=furTrade,Hat=true})
		makeNPC(c,{Name="Ilya",Role="Mountain Medic",Position=base+Vector3.new(0,0,16),Accent=Color3.fromRGB(150,213,237),Outfit=Color3.fromRGB(70,85,92),ActionText="Rest",Action=healAction("highland_heal")})
	elseif info.Key=="Dunes" then
		makeNPC(c,{Name="Nyra",Role="Glass Scout",Position=base+Vector3.new(-18,0,-10),Accent=info.Accent,Outfit=Color3.fromRGB(111,82,58),ActionText="Mark Region",Action=scoutAction("Dunes","Glass Dunes"),Backpack=true})
		makeNPC(c,{Name="Qadir",Role="Dune Quartermaster",Position=base+Vector3.new(18,0,-10),Accent=Color3.fromRGB(236,184,93),Outfit=Color3.fromRGB(102,71,47),ActionText="Supplies",Action=suppliesAction("dunes_supply"),Hat=true})
		makeNPC(c,{Name="Vexa",Role="Venom Alchemist",Position=base+Vector3.new(0,0,16),Accent=Color3.fromRGB(118,231,205),Outfit=Color3.fromRGB(64,75,70),ActionText="Brew Potion",Action=venomTrade})
	elseif info.Key=="Marsh" then
		makeNPC(c,{Name="Moss",Role="Fen Guide",Position=base+Vector3.new(-18,0,-10),Accent=info.Accent,Outfit=Color3.fromRGB(64,83,64),ActionText="Mark Region",Action=scoutAction("Marsh","Mire Fen"),Backpack=true})
		makeNPC(c,{Name="Talla",Role="Bog Alchemist",Position=base+Vector3.new(18,0,-10),Accent=Color3.fromRGB(151,230,154),Outfit=Color3.fromRGB(65,76,62),ActionText="Brew Potion",Action=venomTrade,Hat=true})
		makeNPC(c,{Name="Orin",Role="Fen Healer",Position=base+Vector3.new(0,0,16),Accent=Color3.fromRGB(131,218,171),Outfit=Color3.fromRGB(70,82,68),ActionText="Rest",Action=healAction("marsh_heal")})
	elseif info.Key=="Grove" then
		makeNPC(c,{Name="Rook",Role="Ember Ranger",Position=base+Vector3.new(-18,0,-10),Accent=info.Accent,Outfit=Color3.fromRGB(95,59,47),ActionText="Mark Region",Action=scoutAction("Grove","Emberwood Grove"),Backpack=true})
		makeNPC(c,{Name="Aya",Role="Hide Buyer",Position=base+Vector3.new(18,0,-10),Accent=Color3.fromRGB(239,154,95),Outfit=Color3.fromRGB(84,65,51),ActionText="Trade Hide",Action=hideTrade})
		makeNPC(c,{Name="Fenric",Role="Grove Healer",Position=base+Vector3.new(0,0,16),Accent=Color3.fromRGB(214,143,95),Outfit=Color3.fromRGB(70,72,57),ActionText="Rest",Action=healAction("grove_heal"),Hat=true})
	end
end

Players.PlayerRemoving:Connect(function(player) cooldowns[player]=nil end)

print("[RebornNPCs] Five inhabited outposts and sixteen functional NPCs are online.")
