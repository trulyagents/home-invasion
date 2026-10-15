# weapons

protectors: knives, meat tenderizer, screwdriver, poker, crowbars (no guns in the house)
invaders: crossbow, machete, crowbar
only works in active phase. traitor can hit protectors, invaders can't hit traitor

server does damage/ammo/cooldown/range/LOS. client just sends aim direction
- crossbow = server raycasts from head
- melee = server hits closest enemy in front, ignores aim. invader crowbar also breaks doors/barricades

files
- WeaponServer - pickups, attacks, reload, damage
- Config - stats per weapon, HouseWeapons = what spawns, Placeholder = block fallback if the template is missing. pickup 9 studs, max 2 weapons
- WeaponClient - input, ammo, prompts, tracers
- FirstPersonViewmodelClient - fp arms + weapon. rig arms colored to skin (avatar arms broke w/ layered clothing). slimmer than normal or they cover the screen. hidden when unarmed
- GameFeelClient - camera kick on swing/hit, red edges + shake when hurt

house weapon models (free models, see CREDITS, plus ai-generated ones)
- world tool: ServerStorage.HomeInvasionWeaponTemplates.<id>. invisible Handle along Y (tip up), visuals welded on, Tool.Grip = where the hand goes
- fp copy: ReplicatedStorage.HomeInvasionFirstPersonAssets.Weapons.<id> = same thing at 0.72 scale with RightGrip/LeftGrip on the Handle
- each needs a pose in MotionProfiles or it falls back to unarmed
- each Handle has AttackSound (swing) and HitSound (plays when a melee swing lands). ProSoundEffects library sounds
- meat tenderizer is built from parts (wood grip, steel head, spikes) welded to the Handle, in both copies. old hammer mesh backed up in ServerStorage.HammerBackup. blender version in models/
- knife is an ai mesh. screwdriver is an ai mesh handle + part shaft and tip. old ones in ServerStorage.OldModelsBackup
- crowbar is built from parts (ai kept making candy canes). poker is an ai mesh. machete and crossbow are still the free models, ai crossbow came out like a rifle
- fp copies have no welds, so every part in them has to be Anchored or it falls out of the world when cloned

old gun kit is gone. tools/cleanup-place.luau removes leftovers

known
- aimbot works within range (normal for roblox, detect it later)
- exploiter could push head into thin wall and shoot from inside
