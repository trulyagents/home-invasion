-- Pulls every script out of a place file into src/.
-- Usage: lune run tools/extract.luau <place.rbxl|rbxlx>
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local placePath = process.args[1]
assert(placePath, "usage: lune run tools/extract.luau <place file>")
local game = roblox.deserializePlace(fs.readFile(placePath))

-- Where each service's scripts go. Anything else lands in src/unsorted (not synced).
local roots = {
	ServerScriptService = "src/server",
	ReplicatedStorage = "src/shared",
	ReplicatedFirst = "src/unsorted/ReplicatedFirst",
	ServerStorage = "src/unsorted/ServerStorage",
	Workspace = "src/unsorted/Workspace",
	StarterGui = "src/unsorted/StarterGui",
	StarterPack = "src/unsorted/StarterPack",
}

local suffix = { Script = ".server.luau", LocalScript = ".client.luau", ModuleScript = ".luau" }
local count = 0

local function hasScripts(inst)
	for _, d in inst:GetDescendants() do
		if suffix[d.ClassName] then
			return true
		end
	end
	return false
end

local function clean(name)
	return (string.gsub(name, '[<>:"/\\|%?%*]', "_"))
end

local function write(inst, dir)
	local kind = suffix[inst.ClassName]
	local name = clean(inst.Name)
	if kind then
		-- Disabled scripts and RunContext are not preserved; flag them in the source.
		local src = inst.Source
		if inst.ClassName ~= "ModuleScript" and inst.Disabled then
			src = "-- NOTE: was Disabled in Studio\n" .. src
		end
		if hasScripts(inst) then
			fs.writeDir(dir .. "/" .. name)
			fs.writeFile(dir .. "/" .. name .. "/init" .. kind, src)
			for _, c in inst:GetChildren() do
				write(c, dir .. "/" .. name)
			end
		else
			fs.writeFile(dir .. "/" .. name .. kind, src)
		end
		count += 1
		print(dir .. "/" .. name .. kind)
	elseif hasScripts(inst) then
		fs.writeDir(dir .. "/" .. name)
		for _, c in inst:GetChildren() do
			write(c, dir .. "/" .. name)
		end
	end
end

local function dump(container, dir)
	for _, c in container:GetChildren() do
		write(c, dir)
	end
end

for service, dir in roots do
	local s = game:FindFirstChildOfClass(service)
	if s then
		fs.writeDir(dir)
		dump(s, dir)
	end
end

local sp = game:FindFirstChildOfClass("StarterPlayer")
if sp then
	local ps = sp:FindFirstChild("StarterPlayerScripts")
	local cs = sp:FindFirstChild("StarterCharacterScripts")
	if ps then
		dump(ps, "src/client")
	end
	if cs then
		fs.writeDir("src/unsorted/StarterCharacterScripts")
		dump(cs, "src/unsorted/StarterCharacterScripts")
	end
end

print(`\nExtracted {count} scripts`)
