# Home Invasion

A Roblox game where 3 Invaders try to break into a house defended by 8 Protectors.

Protectors get a prep phase to search the house for weapons, lock doors and barricade with furniture. Then the Invaders come in with crossbows, machetes and crowbars. Last team standing wins. If time runs out, the Protectors win.

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
  modules/   ReplicatedStorage.Modules
tools/       helper scripts (run with Lune)
extracted/   copies of scripts that live inside models and UI (not synced)
```

The map, models, UI and weapon tools live in the place file, not in this repo.

Code from other creators is listed in [CREDITS.md](CREDITS.md).

