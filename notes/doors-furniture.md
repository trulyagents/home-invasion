# doors + furniture

doors (DoorServer, DoorClient)
- E open/close, L lock (protectors, closed door only)
- invaders can't open til active
- swings away from you, tries other way if blocked. sliding doors slide
- invader crowbar breaks them. reset every round
- server checks 9 studs, LOS, team, spam
- each door needs OriginalLeaf + DoorCollider + open/closed attributes

furniture (FurnitureServer, FurnitureClient)
- protectors hold left click to drag, Q/R rotate. barricade doors with it
- server moves it so nobody can fling it
- max 40 studs from start, same floor, no walls. you walk slower
- invader crowbar breaks barricades. resets every round
- needs a DragCollider. numbers in Config

known
- dragging onto another floor height just stops w/ no message
- nothing checks parts are anchored
- doors choppy when laggy
- 9 studs is hardcoded in the clients
- broken doors/furniture records never cleaned up (small leak)
