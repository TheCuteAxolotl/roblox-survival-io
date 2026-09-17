local MobService = require(script.Parent.MobService)

-- V2 authority boundary:
--   Bootstrap / DirectionalCombat decide when an attack is valid.
--   MobService owns wildlife spawning, AI, health, hit feedback and loot.
-- This file intentionally does not listen to combat remotes anymore; the old
-- prototype listeners could apply a second copy of melee/ranged damage.
MobService.Init()
