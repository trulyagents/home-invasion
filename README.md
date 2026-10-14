# Home Invasion

A Roblox horror game inspired by *You're Next*. Masked Invaders break into a house, and the people inside have to fight back or get out.

Protectors get a prep phase to grab whatever they can find (knives, a poker, a meat tenderizer), lock doors and barricade with furniture. Then the power cuts out and the Invaders come in wearing animal masks, armed with crossbows, machetes and crowbars.

- **Escape:** find the car keys and get to the road.
- **The traitor:** one Protector secretly hired the Invaders.
- **The Survivor:** one Protector can set nail traps.
- **Lights out:** fix the fuse box to get the lights back on.

Protectors win by escaping or taking out the Invaders. Invaders win if nobody gets out before dawn.

## Running it

You need [Rokit](https://github.com/rojo-rbx/rokit) and Roblox Studio.

```
rokit install
rojo serve
```

Then open the place in Studio and connect with the Rojo plugin.

## Layout

```
src/
  server/    ServerScriptService
  client/    StarterPlayerScripts
notes/       my notes on how stuff works
tools/       helper scripts (run with Lune)
extracted/   copies of scripts that live inside models and UI (not synced)
```

The map, models, UI and weapon tools live in the place file, not in this repo.

Code from other creators is listed in [CREDITS.md](CREDITS.md).

More details are in [notes/](notes/README.md).
