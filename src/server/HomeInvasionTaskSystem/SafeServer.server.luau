-- The car keys turn up locked in a safe. The 3-digit code is split across notes hidden
-- around the house. Reading a note tells every protector that digit.
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(script.Parent.Config)
local TaskKit = require(script.Parent.TaskKit)
local SpotPicker = require(ServerScriptService.HomeInvasionRoundSystem.SpotPicker)

local roundState = TaskKit.roundState
local remote = TaskKit.remote
local random = Random.new()
local ORDINALS = { "1st", "2nd", "3rd" }

local code = ""
local clues = {}
local notes = {}
local safe, keysPart
local lastGuess = {}

local function publishClues()
    local shown = {}
    for index = 1, #code do
        shown[index] = clues[index] or "_"
    end
    roundState:SetAttribute("SafeClues", table.concat(shown, " "))
end

local function cleanup()
    for _, note in notes do
        note.part:Destroy()
        SpotPicker.release(note.spot)
    end
    table.clear(notes)
    table.clear(clues)
    if safe then
        safe:Destroy()
    end
    safe, keysPart = nil, nil
    code = ""
    roundState:SetAttribute("SafeClues", nil)
    roundState:SetAttribute("SafeOpen", nil)
end

local function makeNote(index)
    local spot = SpotPicker.take()
    if not spot then
        return
    end
    local part = TaskKit.place("Note", spot.CFrame * CFrame.new(0, 0.1, 0) * CFrame.Angles(0, random:NextNumber(0, math.pi * 2), 0),
        Vector3.new(0.8, 0.05, 1), Color3.fromRGB(235, 225, 195))
    part.Material = Enum.Material.SmoothPlastic
    local prompt = TaskKit.prompt(part, "Note", "Read", 0.3, "Protectors")
    TaskKit.connect(prompt, function(player)
        if not TaskKit.validPlayer(player, "Protectors") or not TaskKit.inRange(player, part, 10) then
            return
        end
        clues[index] = code:sub(index, index)
        publishClues()
        TaskKit.notifyTeam("Protectors", string.format("Note found: the %s number of the safe code is %s", ORDINALS[index], clues[index]))
        part:Destroy()
    end)
    table.insert(notes, { part = part, spot = spot })
end

local function setup()
    cleanup()
    code = string.format("%03d", random:NextInteger(0, 999))
    for index = 1, Config.NoteCount do
        makeNote(index)
    end
    publishClues()
end

-- Wraps the car keys in a safe as soon as they appear.
local function lockKeys()
    local keys = TaskKit.arena:FindFirstChild("Objectives") and TaskKit.arena.Objectives:FindFirstChild("CarKeys")
    if not keys or safe or code == "" then
        return
    end
    keysPart = keys
    local keysPrompt = keys:FindFirstChildOfClass("ProximityPrompt")
    if keysPrompt then
        keysPrompt.Enabled = false
    end
    TaskKit.setVisible(keys, false)
    safe = TaskKit.place("Safe", CFrame.new(keys.Position + Vector3.new(0, 0.9, 0)), Vector3.new(2, 2.2, 2), Color3.fromRGB(40, 60, 45))
    safe.CanCollide = true
    local prompt = TaskKit.prompt(safe, "Safe", "Enter code", 0.2, "Protectors")
    TaskKit.connect(prompt, function(player)
        if TaskKit.validPlayer(player, "Protectors") and TaskKit.inRange(player, safe, 10) then
            remote:FireClient(player, "SafeOpen", roundState:GetAttribute("SafeClues"))
        end
    end)
    TaskKit.notifyTeam("Protectors", "The car keys are locked in a safe. Find the notes with the code")
end

local function tryCode(player, guess)
    if typeof(guess) ~= "string" or #guess ~= #code or not guess:match("^%d+$") then
        return
    end
    local now = os.clock()
    if now - (lastGuess[player] or 0) < Config.SafeGuessCooldown then
        return
    end
    lastGuess[player] = now
    if not safe or TaskKit.phase() ~= "Active" or not TaskKit.validPlayer(player, "Protectors")
        or not TaskKit.inRange(player, safe, 10) then
        return
    end
    if guess ~= code then
        remote:FireClient(player, "SafeWrong")
        return
    end
    safe:Destroy()
    safe = nil
    roundState:SetAttribute("SafeOpen", true)
    remote:FireClient(player, "SafeClose")
    if keysPart and keysPart.Parent then
        TaskKit.setVisible(keysPart, true)
        local keysPrompt = keysPart:FindFirstChildOfClass("ProximityPrompt")
        if keysPrompt then
            keysPrompt.Enabled = true
        end
    end
    TaskKit.notifyTeam("Protectors", player.DisplayName .. " opened the safe. Grab the keys")
end

remote.OnServerEvent:Connect(function(player, action, value)
    if action == "SafeGuess" then
        tryCode(player, value)
    end
end)

roundState:GetAttributeChangedSignal("KeysOut"):Connect(function()
    if roundState:GetAttribute("KeysOut") then
        lockKeys()
    end
end)

TaskKit.onRound(setup, nil, cleanup)

Players.PlayerRemoving:Connect(function(player)
    lastGuess[player] = nil
end)
