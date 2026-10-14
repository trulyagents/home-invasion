# setup

rokit installs rojo + lune (versions in rokit.toml)

- `rojo serve` then Plugins > Rojo > Connect in studio
- edit stuff in src/, it syncs straight in
- rojo only does the scripts in src/. map, models, ui, weapons, serverstorage = place file, edit in studio
- `lune run tools/check.luau` = does everything compile
- `lune run tools/extract.luau <file.rbxl>` = pull scripts out of a place file

gotchas
- don't sync folders that have non-script stuff in them, rojo will wipe it
- every script needs a .meta.json with ignoreUnknownInstances or rojo deletes its children / re-enables disabled scripts
