# bugs

furniture dropping instantly
- grabbing unequips your weapon and roblox sends a Cancel for the mouse. client treated it as letting go
- ALSO the place still had old copies of every script next to the rojo ones (same names) so 2 furniture clients were running. deleted the old ones
- check for duplicate scripts after moving stuff into rojo. and check rojo is actually connected

masks falling off - avatar loading swaps the head after the mask is welded. wait for HasAppearanceLoaded

lights out did nothing in the house - it only turned off lights in HomeInvasionPrototype, the mansion lamps are outside it

fp weapons huge - ScaleTo is absolute, not relative. model:ScaleTo(0.72) on something already scaled to 0.375 made it bigger. use model:ScaleTo(model:GetScale() * x)

crowbar did nothing in a test - melee checks the character's facing and in first person the character turns to the camera. aim the camera, not the root

fuse box on top of a hammer - objectives and weapons used the same spawn markers. box blocked line of sight so the hammer couldn't be picked up. objectives now skip taken markers

fuse box model invisible on a wall - the mesh draws about a stud off its part's centre so it was inside the wall. the stored model has an offset + 90° turn baked in now

oct fixes
- round stalled if someone failed to spawn (retries now)
- player counted alive after character replaced
- invisible triggers blocked bullets
- furniture clipped walls (collision check started from wrong point)
- hitmarker errored on decimal damage

not actually bugs
- "no hitmarkers" - DemoPresentationClient has them
- "invaders lose loadout on death" - dying takes you out anyway
- "no range check on door damage" - only the weapon server calls it
