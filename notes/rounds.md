# rounds

server runs everything. clients just read attributes on ReplicatedStorage.HomeInvasionRoundState

waiting > intermission > starting > preparation > active > results

- needs 4 players. in studio solo works and flips your team every round
- prep: protectors loot/barricade, invaders frozen
- active: invaders let in, power cuts
- protectors win = escape with keys or kill all invaders
- invaders win = kill every loyal protector, or timer runs out (TimeoutWinner)
- die = out for the round, respawn in lobby
- if someone can't spawn after a few tries, everyone goes back to lobby

files
- RoundServer - main loop, teams, spawning, freezing invaders
- RoundRules - who won
- Config - timers + team sizes (prep 45s, round 300s, intermission 15s)
- RoundShared - secret info (traitor etc) shared between server scripts
- MaskServer, ObjectiveServer - see roles-objectives
- AnimationService - plays anims from server
- client: HomeInvasionRoundHUD (H = help), HomeInvasionHotbarClient (1/2/3), SpectatorClient, DemoPresentationClient (aim, crosshair, hitmarkers)

todo / known
- anim tracks might pile up if old characters don't get destroyed
- always spawn in first person, can mess up camera after aiming/spectating
- spectator ui rechecks 4x a second on purpose (fixes camera after respawn). hotbar only redraws on tool/round changes now
