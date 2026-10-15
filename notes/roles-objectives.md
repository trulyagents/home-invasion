# roles + objectives (you're next stuff)

teams: 1 invader per 4 players (1-3), rest protectors (max 8). Config

masks
- lamb / fox / tiger on invaders
- models in ServerStorage.HomeInvasionMasks, pivot = center of head. missing one = block fallback
- has to wait for avatar to load or the head gets swapped and the mask falls off the map

traitor
- 4+ protectors = one is secretly the traitor
- only traitor + invaders know (sent privately)
- can hurt protectors, invaders can't hurt them. wins with invaders
- invaders win when every loyal protector is dead. results screen reveals them

survivor
- T = nail trap, 3 per round. hurts + slows first invader. TrapSystem Config

keys + escape
- keys spawn on a random weapon spot. bring them to the ESCAPE pad = protectors win
- holder dies = keys drop
- pad goes at invader spawn unless there's an EscapePoint part in HomeInvasionPrototype

lights out
- power cuts when invaders come in, every light on the map off
- dim not black + local glow around you (AtmosphereClient)
- protectors hold G at fuse box 4s to fix. invaders cut it 2.5s, 30s cooldown
- fuse box random unless there's a FuseBox part

models
- fuse box, car keys, escape car live in ServerStorage.HomeInvasionObjectiveModels (FuseBox, CarKeys, EscapeCar). pivot = center of the part (car: bottom center). missing one = plain block
- car parks next to the escape pad
- prompts can't be pressed in automated tests, so in studio there's ServerStorage.StudioObjectiveTest (BindableFunction): Invoke("FuseBox", player) / Invoke("CarKeys", player). only exists in studio
