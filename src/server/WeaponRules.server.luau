local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemData = require(ReplicatedStorage.Shared.ItemData)

-- These are authoritative server-only role rules. Keeping Stick attackable on the
-- client would make the client consume gathering clicks, so the server rejects
-- its combat actions while still allowing Gather requests against resources.
local stick = ItemData.Items.Stick
if stick then
	stick.CanAttack = false
	stick.BuildDamage = 0
end

-- Secondary utility weapons are not gathering tools.
local greatHammer = ItemData.Items.GreatHammer
if greatHammer then greatHammer.CanGather = false end

local grabby = ItemData.Items.McGrabby
if grabby then grabby.CanGather = false end
