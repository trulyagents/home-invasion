# weapons

protectors: knives, meat tenderizer, screwdriver, poker, crowbars (no guns in the house)
invaders: crossbow, machete, crowbar
only works in active phase. traitor can hit protectors, invaders can't hit traitor

server does damage/ammo/cooldown/range/LOS. client just sends aim direction
- crossbow = server raycasts from head
- melee = server hits closest enemy in front, ignores aim. invader crowbar also breaks doors/barricades

files
- WeaponServer - pickups, attacks, reload, damage
- Config - stats per weapon, HouseWeapons = what spawns, Placeholder = block model until a real one exists. pickup 9 studs, max 2 weapons
- WeaponClient - input, ammo, prompts, tracers
- FirstPersonViewmodelClient - fp arms + weapon. rig arms colored to skin (avatar arms broke w/ layered clothing). slimmer than normal or they cover the screen. hidden when unarmed
- GameFeelClient - camera kick on swing/hit, red edges + shake when hurt

old gun kit is gone. tools/cleanup-place.luau removes leftovers

known
- aimbot works within range (normal for roblox, detect it later)
- exploiter could push head into thin wall and shoot from inside
