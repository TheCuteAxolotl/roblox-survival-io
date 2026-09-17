# Wildforge Survival

A simple-graphics Roblox survival/PvP game with persistent progression, session bases, crafting, farming, exploration, creatures, and fast `.io`-style combat.

## Current survival loop
- gather wood, stone, berries, herbs, wheat, and cactus fiber
- maintain hunger and thirst
- drink from the river and refill crafted flasks
- fight wolves, spiders, boars, snow wolves, snow bears, and desert scorpions
- hunt passive deer
- collect mob loot including meat, hide, bone, fur, web, and venom
- carry a persistent 6-slot survival inventory
- drop items for other players to pick up
- death drops carried inventory and supplies, but permanent gold is safe
- bases are session-only and disappear when their owner leaves
- place workbenches, chests, farm plots, campfires, torches, and traps
- grow and harvest wheat
- craft 28 recipes with Common / Uncommon / Rare / Epic rarities
- use healing, speed, fortify, antidote, cold-resistance, and hunger/thirst-suppression consumables
- buy survival kits and ability hats with earned gold
- snow slows players unless they have cold protection or the Frost Hood
- desert survival can be improved with the Desert Veil

## Existing combat/progression systems
- primary and secondary weapon branches
- melee, shields, bows, firearms, knockback, and ranged combat
- walls, spikes, windmills, defenses, age progression, XP, and gold
- windmills generate both gold and XP

## Persistence rules
- Gold persists and is not lost on death.
- Survival inventory persists between sessions while the player is alive.
- Dying clears the survival inventory and drops it into the world.
- Player bases and chest contents are not persisted between server sessions.

## Development setup
1. Install Rokit and Rojo.
2. Run `rokit install`.
3. Run `rojo plugin install`.
4. Run `rojo serve`.
5. Open Roblox Studio and connect the Rojo plugin.

Monetization product IDs remain placeholders until the Roblox experience and products are created.
