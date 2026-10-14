# bugs

furniture dropping instantly
- grabbing unequips your weapon and roblox sends a Cancel for the mouse. client treated it as letting go
- ALSO the place still had old copies of every script next to the rojo ones (same names) so 2 furniture clients were running. deleted the old ones
- check for duplicate scripts after moving stuff into rojo. and check rojo is actually connected

masks falling off - avatar loading swaps the head after the mask is welded. wait for HasAppearanceLoaded

lights out did nothing in the house - it only turned off lights in HomeInvasionPrototype, the mansion lamps are outside it

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
