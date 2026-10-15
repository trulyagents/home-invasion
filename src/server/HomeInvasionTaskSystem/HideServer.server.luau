-- Wardrobes protectors can hide in. One person per wardrobe. Invaders can search them,
-- which drags out whoever is inside.
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(script.Parent.Config)
local TaskKit = require(script.Parent.TaskKit)
local SpotPicker = require(ServerScriptService.HomeInvasionRoundSystem.SpotPicker)

local noise = game:GetService("ServerStorage"):WaitForChild("HomeInvasionNoise")
local random = Random.new()
local wardrobes = {} -- [part] = { spot, occupant, saved, creak }
local hiding = {} -- [player] = wardrobe part

local function leave(player, pushedOut)
    local wardrobe = hiding[player]
    if not wardrobe then
        return
    end
    hiding[player] = nil
    local entry = wardrobes[wardrobe]
    if entry then
        entry.occupant = nil
        entry.creak:Play()
    end
    player:SetAttribute("Hidden", nil)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if entry and entry.saved then
        for part, transparency in entry.saved do
            if part.Parent then
                part.Transparency = transparency
            end
        end
        entry.saved = nil
    end
    if root then
        root.Anchored = false
        if wardrobe.Parent then
            root.CFrame = wardrobe.CFrame * CFrame.new(0, -wardrobe.Size.Y / 2 + 3, -(wardrobe.Size.Z / 2 + 2.5)) * CFrame.Angles(0, math.pi, 0)
        end
    end
    if pushedOut then
        TaskKit.notify(player, "You've been found!")
    end
end

local function hide(player, wardrobe)
    local entry = wardrobes[wardrobe]
    local root = TaskKit.validPlayer(player, "Protectors")
    if not entry or not root or (root.Position - wardrobe.Position).Magnitude > 10 then
        return
    end
    if entry.occupant then
        TaskKit.notify(player, "Someone's already in there")
        return
    end
    if player:GetAttribute("HasKeys") or player:GetAttribute("HasFuel") then
        TaskKit.notify(player, "You can't fit in there carrying that")
        return
    end
    local character = player.Character
    character:FindFirstChildOfClass("Humanoid"):UnequipTools()
    entry.occupant = player
    hiding[player] = wardrobe
    player:SetAttribute("Hidden", true)
    entry.saved = {}
    for _, part in character:GetDescendants() do
        if part:IsA("BasePart") or part:IsA("Decal") then
            entry.saved[part] = part.Transparency
            part.Transparency = 1
        end
    end
    root.CFrame = CFrame.new(wardrobe.Position) * wardrobe.CFrame.Rotation
    root.Anchored = true
    entry.creak:Play()
    noise:Fire(wardrobe.Position, "creak")
end

local function makeWardrobe()
    local spot = SpotPicker.take()
    if not spot then
        return
    end
    local size = Vector3.new(4, 7, 2.4)
    local cframe = CFrame.new(spot.Position + Vector3.new(0, size.Y / 2, 0)) * CFrame.Angles(0, random:NextInteger(0, 3) * math.pi / 2, 0)
    local part = TaskKit.place("Wardrobe", cframe, size, Color3.fromRGB(70, 45, 30))
    part.CanCollide = true
    part.Material = Enum.Material.Wood
    local entry = { spot = spot, creak = TaskKit.sound(part, Config.Sounds.Creak, 0.6, 50) }
    wardrobes[part] = entry
    local hidePrompt = TaskKit.prompt(part, "Wardrobe", "Hide / leave", 0.5, "Protectors", Enum.KeyCode.E)
    TaskKit.connect(hidePrompt, function(player)
        if hiding[player] == part then
            leave(player)
        elseif not hiding[player] and (TaskKit.phase() == "Preparation" or TaskKit.phase() == "Active") then
            hide(player, part)
        end
    end)
    local searchPrompt = TaskKit.prompt(part, "Wardrobe", "Search", Config.SearchSeconds, "Invaders", Enum.KeyCode.E)
    TaskKit.connect(searchPrompt, function(player)
        if TaskKit.phase() ~= "Active" or not TaskKit.validPlayer(player, "Invaders") or not TaskKit.inRange(player, part, 10) then
            return
        end
        if entry.occupant then
            local found = entry.occupant
            leave(found, true)
            TaskKit.notify(player, "Found " .. found.DisplayName .. "!")
        else
            entry.creak:Play()
            TaskKit.notify(player, "Empty")
        end
    end)
end

local function cleanup()
    for player in hiding do
        leave(player)
    end
    for part, entry in wardrobes do
        SpotPicker.release(entry.spot)
        part:Destroy()
    end
    table.clear(wardrobes)
end

local function setup()
    cleanup()
    for _ = 1, Config.WardrobeCount do
        makeWardrobe()
    end
end

TaskKit.onRound(setup, nil, cleanup)

-- the player leaves the wardrobe if they die or respawn
local function watch(player)
    player.CharacterAdded:Connect(function()
        if hiding[player] then
            local entry = wardrobes[hiding[player]]
            if entry then
                entry.occupant = nil
                entry.saved = nil
            end
            hiding[player] = nil
            player:SetAttribute("Hidden", nil)
        end
    end)
end
Players.PlayerAdded:Connect(watch)
for _, player in Players:GetPlayers() do
    watch(player)
end
Players.PlayerRemoving:Connect(function(player)
    local wardrobe = hiding[player]
    if wardrobe and wardrobes[wardrobe] then
        wardrobes[wardrobe].occupant = nil
    end
    hiding[player] = nil
end)
