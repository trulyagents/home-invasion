# tasks (stuff to do besides fight)

all in src/server/HomeInvasionTaskSystem, one script per task, timings in Config. TaskKit = shared prompt/notice/model helpers

spots
- items use WeaponSpawns markers. SpotPicker (in RoundSystem) hands them out so nothing stacks. weapons go first
- added Extra1-18 markers in studio (some removed) so there's room for everything. 24 total

protector chain
- fix power (screwdriver + fuse box) > keys show up locked in a safe > code is split across 3 notes hidden in the house (any protector reading one tells the whole team) > safe keypad (F at the safe) > keys
- car starts empty. gas can somewhere in the house, carry it to the escape pad and fill the tank. can't carry keys and gas at once
- escape only works with keys AND a fueled car
- or: call the police from the landline (hold F 4s). survive 90s = protectors win (HelpArrived)
- wardrobes (4): E to hide, E again to leave. invisible + anchored inside. can't hide holding keys or gas. can't attack while hidden

invader side
- cut the phone line (kills the phone for the round, cancels a call)
- drain the car (hold 4s, 45s cooldown). gas can goes back somewhere far
- search wardrobes (hold 1.5s), pulls out whoever's inside
- L on a locked door = quiet lock pick, 5s, has to stay close. in DoorServer, PickSeconds in door Config
- noise: protector swings, door locks, wardrobe creaks, phone calls, filling the car flash a red ring for invaders (rough spot, not exact). fire ServerStorage.HomeInvasionNoise(position, label) to add more

random events (every 40-70s in active)
- phone rings (decoy), dog barks outside, thunder + flash, short blackout (client side only, skipped if the power is already out)

client
- TaskPromptClient hides prompts with ForTeam for the other team (sets range 0 locally, server still checks)
- SafeKeypadClient = keypad ui. WorldCueClient = noise rings, thunder flash, blackout
- RoleClient info lines: gas can, safe code clues, police timer, hiding

models
- ServerStorage.HomeInvasionTaskModels: Wardrobe, Safe, GasCan (ai meshes), Phone (built from parts, ai phone kept failing), Note (paper part)
- sounds are ProSoundEffects except the dog bark

testing
- studio only: ServerStorage.StudioTaskTest:Invoke(prompt, player) runs a task prompt like pressing it
