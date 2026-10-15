# Home Invasion

roblox horror game, kinda based on *You're Next*. people in masks break into a house and everyone inside has to fight back or get out

**protectors** get 45 seconds to prep. grab whatever's lying around (kitchen knife, meat tenderizer, screwdriver, fire poker, crowbar), lock doors, shove furniture in front of them. then the power goes out and the invaders show up in animal masks with crossbows, machetes and crowbars

ways to win as a protector:
- **escape** - fix the fuse box (need the screwdriver), find the notes with the safe code, open the safe for the car keys, get gas in the car, drive off
- **call the cops** - use the landline and survive till they get there
- or just kill all the invaders

other stuff:
- one protector is secretly a **traitor** working with the invaders (4+ players)
- one protector is the **survivor** and can put down nail traps
- you can hide in wardrobes
- invaders can pick locks, cut the phone line, drain the car and search wardrobes. they see a red ring when protectors make noise
- random stuff happens (phone rings, dog barking, thunder, lights flicker out)

invaders win if nobody gets out before dawn

## running it

need [Rokit](https://github.com/rojo-rbx/rokit) and roblox studio

```
rokit install
rojo serve
```

open the place in studio and connect the rojo plugin

## where stuff is

```
src/
  server/    ServerScriptService
  client/    StarterPlayerScripts
notes/       my notes on how everything works
tools/       lune scripts (compile check, extracting scripts from the place)
extracted/   copies of scripts that live inside models/ui (not synced)
models/      blender files
```

the map, models, ui and weapon tools are in the place file, not here

stuff other people made is in [CREDITS.md](CREDITS.md). more details in [notes/](notes/README.md)
