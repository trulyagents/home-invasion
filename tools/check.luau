-- Syntax-checks every .luau file under src/. Usage: lune run tools/check.luau
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local bad = 0
local function walk(dir)
    for _, name in fs.readDir(dir) do
        local path = dir .. "/" .. name
        if fs.isDir(path) then
            walk(path)
        elseif string.sub(name, -5) == ".luau" then
            local ok, err = pcall(luau.compile, fs.readFile(path))
            if not ok then
                bad += 1
                print(path, err)
            end
        end
    end
end
walk("src")
print(bad == 0 and "All scripts compile" or `{bad} file(s) failed`)
