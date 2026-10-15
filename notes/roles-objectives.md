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
- keys spawn on a random weapon spot that no weapon took (fuse box too). waits up to 3s for weapons to spawn first. bring them to the ESCAPE pad = protectors win
- holder dies = keys drop
- pad goes at invader spawn unless there's an EscapePoint part in HomeInvasionPrototype

lights out
- power cuts when invaders come in, every light on the map off
- dim not black + local glow around you (AtmosphereClient)
- fixing it needs the screwdriver in hand. G at the fuse box opens a repair minigame (FuseMinigameClient): hold on 4 screws, then drag 3 wires to matching colours. ~6-8s
- no screwdriver = "You need a screwdriver to fix the fuse box"
- getting hit, walking 10+ studs away, putting the screwdriver away, X or Esc cancels it
- server re-checks everything when the client says done: still a protector, alive, in range, holding the screwdriver, and at least 3.5s since it started (stops instant "done" cheats)
- remote: ReplicatedStorage.HomeInvasionObjectives.Interaction (FuseStart / FuseEnd / Notice to client, FuseDone / FuseCancel to server)
- only 1 screwdriver spawns, so it's a key item. bump SpawnCount in weapon Config if that's too harsh
- invaders still cut it with a 2.5s hold, 30s cooldown
- fuse box random unless there's a FuseBox part in HomeInvasionPrototype (there is now, on the ground floor wall near Door08). it gets the model too. part has to be anchored and its front (-Z) facing out from the wall

models
- fuse box, car keys, escape car live in ServerStorage.HomeInvasionObjectiveModels (FuseBox, CarKeys, EscapeCar). pivot = center of the part (car: bottom center). missing one = plain block
- car parks next to the escape pad
- prompts can't be pressed in automated tests, so in studio there's ServerStorage.StudioObjectiveTest (BindableFunction): Invoke("FuseBox", player) / Invoke("FuseDone", player) / Invoke("CarKeys", player). only exists in studio
