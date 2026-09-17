local ClanService = {}

local clans = {}
local playerClan = {}

local function cleanName(name)
	name = tostring(name or ""):gsub("[^%w%s%-_]", ""):sub(1, 20)
	name = name:gsub("^%s+", ""):gsub("%s+$", "")
	return name
end

local function newCode()
	local chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	for _ = 1, 50 do
		local code = ""
		for _ = 1, 5 do
			local i = math.random(1, #chars)
			code ..= chars:sub(i, i)
		end
		if not clans[code] then return code end
	end
	return tostring(math.random(10000, 99999))
end

function ClanService.GetCode(player)
	return playerClan[player]
end

function ClanService.GetClan(player)
	local code = playerClan[player]
	return code and clans[code] or nil
end

function ClanService.GetPublic(player)
	local code = playerClan[player]
	local clan = code and clans[code]
	if not clan then return { InClan = false } end
	local count = 0
	for _ in clan.Members do count += 1 end
	return {
		InClan = true,
		Code = code,
		Name = clan.Name,
		OwnerUserId = clan.OwnerUserId,
		MemberCount = count,
	}
end

function ClanService.SameClan(a, b)
	local ca = playerClan[a]
	return ca ~= nil and ca == playerClan[b]
end

function ClanService.CanAccessOwnerOrClan(actor, ownerUserId, mode)
	if actor.UserId == ownerUserId then return true end
	if mode == "Public" then return true end
	if mode ~= "Clan" then return false end
	local owner
	for player, _ in playerClan do
		if player.UserId == ownerUserId then owner = player break end
	end
	return owner ~= nil and ClanService.SameClan(actor, owner)
end

function ClanService.Create(player, rawName)
	if playerClan[player] then return false, "Leave your current clan first." end
	local name = cleanName(rawName)
	if #name < 2 then return false, "Clan name must be at least 2 characters." end
	local code = newCode()
	clans[code] = {
		Name = name,
		OwnerUserId = player.UserId,
		Members = { [player] = true },
	}
	playerClan[player] = code
	return true, `Created {name}. Join code: {code}`
end

function ClanService.Join(player, rawCode)
	if playerClan[player] then return false, "Leave your current clan first." end
	local code = tostring(rawCode or ""):upper():gsub("%s", "")
	local clan = clans[code]
	if not clan then return false, "Clan code not found." end
	clan.Members[player] = true
	playerClan[player] = code
	return true, `Joined {clan.Name}.`
end

function ClanService.Leave(player)
	local code = playerClan[player]
	local clan = code and clans[code]
	if not clan then return false, "You are not in a clan." end
	clan.Members[player] = nil
	playerClan[player] = nil
	if clan.OwnerUserId == player.UserId then
		local newOwner
		for member in clan.Members do newOwner = member break end
		if newOwner then clan.OwnerUserId = newOwner.UserId else clans[code] = nil end
	end
	return true, "Left clan."
end

function ClanService.RemovePlayer(player)
	ClanService.Leave(player)
end

return ClanService
