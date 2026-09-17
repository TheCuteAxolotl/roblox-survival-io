local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ClanService = {}

local initialized = false
local persistent = false
local clanStore = nil
local playerStore = nil
local clanCache = {}
local playerClan = {}

local function trim(value)
	return (tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function cleanName(raw)
	if type(raw) ~= "string" then return nil end
	local value = trim(raw)
	if #value < 3 or #value > 18 then return nil end
	if not value:match("^[%w _%-]+$") then return nil end
	return value
end

local function clanKey(raw)
	local value = trim(raw):lower()
	value = value:gsub("%s+", " ")
	return value
end

local function makeTag(name)
	local compact = name:upper():gsub("[^A-Z0-9]", "")
	if #compact < 2 then compact = "CLAN" end
	return string.sub(compact, 1, math.min(4, #compact))
end

local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, inner in value do result[copy(key)] = copy(inner) end
	return result
end

local function memberKey(userId)
	return tostring(userId)
end

local function savePlayerClan(userId, key)
	if not persistent or not playerStore then return true end
	local ok, err = pcall(function()
		if key then playerStore:SetAsync(`p_{userId}`, key) else playerStore:RemoveAsync(`p_{userId}`) end
	end)
	if not ok then warn("[ClanService] player clan save failed:", err) end
	return ok
end

local function loadClan(key)
	if clanCache[key] then return clanCache[key] end
	if not persistent or not clanStore then return nil end
	local ok, record = pcall(function() return clanStore:GetAsync(`c_{key}`) end)
	if not ok then warn("[ClanService] clan load failed:", record) return nil end
	if type(record) == "table" then clanCache[key] = record return record end
	return nil
end

local function saveClan(key, record)
	clanCache[key] = record
	if not persistent or not clanStore then return true end
	local ok, err = pcall(function() clanStore:SetAsync(`c_{key}`, record) end)
	if not ok then warn("[ClanService] clan save failed:", err) end
	return ok
end

local function loadPlayer(player)
	local key = nil
	if persistent and playerStore then
		local ok, value = pcall(function() return playerStore:GetAsync(`p_{player.UserId}`) end)
		if ok and type(value) == "string" then key = value elseif not ok then warn("[ClanService] membership load failed:", value) end
	end
	if key then
		local record = loadClan(key)
		if record and record.Retired ~= true and record.Members and record.Members[memberKey(player.UserId)] == true then
			playerClan[player.UserId] = key
			return
		end
		savePlayerClan(player.UserId, nil)
	end
	playerClan[player.UserId] = nil
end

function ClanService.Init()
	if initialized then return end
	initialized = true
	if not (RunService:IsStudio() and game.GameId == 0) then
		local ok1, cs = pcall(function() return DataStoreService:GetDataStore("Wildforge_Clans_v1") end)
		local ok2, ps = pcall(function() return DataStoreService:GetDataStore("Wildforge_PlayerClan_v1") end)
		if ok1 and ok2 then clanStore, playerStore, persistent = cs, ps, true else warn("[ClanService] DataStores unavailable; clans are session-only.") end
	else
		warn("[ClanService] Unpublished Studio place: clans are temporary this session.")
	end
	Players.PlayerAdded:Connect(loadPlayer)
	for _, player in Players:GetPlayers() do task.spawn(loadPlayer, player) end
	Players.PlayerRemoving:Connect(function(player) playerClan[player.UserId] = nil end)
end

function ClanService.GetClanKey(playerOrUserId)
	local id = typeof(playerOrUserId) == "Instance" and playerOrUserId.UserId or tonumber(playerOrUserId)
	return id and playerClan[id] or nil
end

function ClanService.GetRecord(playerOrUserId)
	local key = ClanService.GetClanKey(playerOrUserId)
	return key and loadClan(key) or nil
end

function ClanService.GetTag(playerOrUserId)
	local record = ClanService.GetRecord(playerOrUserId)
	return record and record.Tag or nil
end

function ClanService.IsOwner(player)
	local record = ClanService.GetRecord(player)
	return record ~= nil and record.OwnerUserId == player.UserId
end

function ClanService.GetMemberCount(playerOrUserId)
	local record = ClanService.GetRecord(playerOrUserId)
	if not record or type(record.Members) ~= "table" then return 0 end
	local count = 0
	for _, active in record.Members do if active == true then count += 1 end end
	return count
end

function ClanService.SameClan(a, b)
	local aId = typeof(a) == "Instance" and a.UserId or tonumber(a)
	local bId = typeof(b) == "Instance" and b.UserId or tonumber(b)
	if not aId or not bId then return false end
	local aKey, bKey = playerClan[aId], playerClan[bId]
	return aKey ~= nil and aKey == bKey
end

function ClanService.Create(player, rawName)
	if playerClan[player.UserId] then return false, "Leave your current clan first." end
	local name = cleanName(rawName)
	if not name then return false, "Clan name must be 3–18 letters/numbers/spaces." end
	local key = clanKey(name)
	local record = {
		Name = name,
		Tag = makeTag(name),
		OwnerUserId = player.UserId,
		Members = { [memberKey(player.UserId)] = true },
		Retired = false,
		CreatedAt = os.time(),
	}

	if persistent and clanStore then
		local created = false
		local ok, result = pcall(function()
			return clanStore:UpdateAsync(`c_{key}`, function(existing)
				if existing ~= nil then return existing end
				created = true
				return record
			end)
		end)
		if not ok then return false, "Clan service is temporarily unavailable." end
		if not created then
			if type(result) == "table" then clanCache[key] = result end
			return false, "That clan name is permanently reserved."
		end
	else
		if clanCache[key] then return false, "That clan name is permanently reserved." end
		clanCache[key] = record
	end

	playerClan[player.UserId] = key
	savePlayerClan(player.UserId, key)
	clanCache[key] = record
	return true, `Created clan [{record.Tag}].`
end

function ClanService.Join(player, rawName)
	if playerClan[player.UserId] then return false, "Leave your current clan first." end
	local key = clanKey(rawName)
	local record = loadClan(key)
	if not record or record.Retired == true then return false, "That clan is not active." end

	if persistent and clanStore then
		local ok, updated = pcall(function()
			return clanStore:UpdateAsync(`c_{key}`, function(current)
				if type(current) ~= "table" or current.Retired == true then return current end
				current.Members = current.Members or {}
				current.Members[memberKey(player.UserId)] = true
				return current
			end)
		end)
		if not ok or type(updated) ~= "table" or updated.Retired == true then return false, "Could not join that clan." end
		record = updated
	else
		record.Members = record.Members or {}
		record.Members[memberKey(player.UserId)] = true
	end
	clanCache[key] = record
	playerClan[player.UserId] = key
	savePlayerClan(player.UserId, key)
	return true, `Joined [{record.Tag}].`
end

function ClanService.TransferOwnership(player, rawUsername)
	local key = playerClan[player.UserId]
	local record = key and loadClan(key)
	if not record then return false, "You are not in a clan." end
	if record.OwnerUserId ~= player.UserId then return false, "Only the clan owner can transfer ownership." end
	local username = trim(rawUsername)
	if username == "" then return false, "Enter the Roblox username of a clan member." end

	local okId, targetUserId = pcall(function() return Players:GetUserIdFromNameAsync(username) end)
	if not okId or not targetUserId then return false, "Roblox username not found." end
	if targetUserId == player.UserId then return false, "You already own this clan." end
	if not record.Members or record.Members[memberKey(targetUserId)] ~= true then return false, "That player must already be a member of your clan." end

	if persistent and clanStore then
		local transferred = false
		local ok, updated = pcall(function()
			return clanStore:UpdateAsync(`c_{key}`, function(current)
				if type(current) ~= "table" or current.Retired == true then return current end
				if current.OwnerUserId ~= player.UserId then return current end
				if not current.Members or current.Members[memberKey(targetUserId)] ~= true then return current end
				current.OwnerUserId = targetUserId
				current.LastOwnershipTransferAt = os.time()
				transferred = true
				return current
			end)
		end)
		if not ok or not transferred or type(updated) ~= "table" then return false, "Ownership transfer failed. Try again." end
		record = updated
	else
		record.OwnerUserId = targetUserId
		record.LastOwnershipTransferAt = os.time()
		saveClan(key, record)
	end

	clanCache[key] = record
	savePlayerClan(targetUserId, key)
	return true, `Ownership transferred to {username}. You can now leave the clan.`
end

function ClanService.Leave(player)
	local key = playerClan[player.UserId]
	local record = key and loadClan(key)
	if not record then return false, "You are not in a clan." end
	if record.OwnerUserId == player.UserId then
		return false, "Clan owners cannot leave. Transfer ownership to a member first, or disband the clan."
	end
	local uid = memberKey(player.UserId)

	if persistent and clanStore then
		local removed = false
		local ok, updated = pcall(function()
			return clanStore:UpdateAsync(`c_{key}`, function(current)
				if type(current) ~= "table" or current.Retired == true then return current end
				if current.OwnerUserId == player.UserId then return current end
				current.Members = current.Members or {}
				current.Members[uid] = nil
				removed = true
				return current
			end)
		end)
		if not ok or not removed or type(updated) ~= "table" then return false, "Could not leave the clan. Try again." end
		record = updated
	else
		record.Members = record.Members or {}
		record.Members[uid] = nil
		saveClan(key, record)
	end

	clanCache[key] = record
	playerClan[player.UserId] = nil
	savePlayerClan(player.UserId, nil)
	return true, "Left clan."
end

function ClanService.Disband(player)
	local key = playerClan[player.UserId]
	local record = key and loadClan(key)
	if not record then return false, "You are not in a clan." end
	if record.OwnerUserId ~= player.UserId then return false, "Only the clan owner can disband the clan." end

	if persistent and clanStore then
		local disbanded = false
		local ok, updated = pcall(function()
			return clanStore:UpdateAsync(`c_{key}`, function(current)
				if type(current) ~= "table" then return current end
				if current.Retired == true or current.OwnerUserId ~= player.UserId then return current end
				current.Retired = true
				current.DisbandedAt = os.time()
				current.DisbandedByUserId = player.UserId
				disbanded = true
				return current
			end)
		end)
		if not ok or not disbanded or type(updated) ~= "table" then return false, "Could not disband the clan. Try again." end
		record = updated
	else
		record.Retired = true
		record.DisbandedAt = os.time()
		record.DisbandedByUserId = player.UserId
		saveClan(key, record)
	end

	clanCache[key] = record
	for memberId, active in record.Members or {} do
		if active == true then
			local numericId = tonumber(memberId)
			if numericId then
				playerClan[numericId] = nil
				savePlayerClan(numericId, nil)
			end
		end
	end
	return true, `Clan [{record.Tag}] disbanded. Its name is permanently reserved.`
end

return ClanService
