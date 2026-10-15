-- Random scares during the invasion: the phone rings, a dog barks outside, thunder,
-- or the lights briefly flicker out.
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

local Config = require(script.Parent.Config)
local TaskKit = require(script.Parent.TaskKit)

local roundState = TaskKit.roundState
local random = Random.new()
local ringPhone = script.Parent:WaitForChild("PhoneServer"):WaitForChild("RingPhone")

local function houseCenter()
    local spawns = TaskKit.arena:FindFirstChild("WeaponSpawns")
    local sum, count = Vector3.zero, 0
    for _, marker in (spawns and spawns:GetChildren() or {}) do
        if marker:IsA("BasePart") then
            sum += marker.Position
            count += 1
        end
    end
    return count > 0 and sum / count or Vector3.zero
end

local function soundAt(position, id, volume)
    local holder = Instance.new("Part")
    holder.Anchored = true
    holder.CanCollide = false
    holder.CanQuery = false
    holder.CanTouch = false
    holder.Transparency = 1
    holder.Size = Vector3.one
    holder.Position = position
    holder.Parent = TaskKit.folder
    local sound = TaskKit.sound(holder, id, volume, 250)
    sound:Play()
    task.delay(15, function()
        holder:Destroy()
    end)
end

local function everyone(name, duration)
    for _, player in Players:GetPlayers() do
        TaskKit.remote:FireClient(player, "Event", name, duration)
    end
end

local events = {
    function()
        ringPhone:Fire()
    end,
    function()
        local angle = random:NextNumber(0, math.pi * 2)
        local offset = Vector3.new(math.cos(angle), 0, math.sin(angle)) * random:NextNumber(70, 110)
        soundAt(houseCenter() + offset, Config.Sounds.DogBark, 1)
    end,
    function()
        local thunder = Instance.new("Sound")
        thunder.SoundId = Config.Sounds.Thunder
        thunder.Volume = 0.9
        thunder.Parent = SoundService
        thunder:Play()
        task.delay(15, function()
            thunder:Destroy()
        end)
        everyone("Thunder", 0.4)
    end,
    function()
        if roundState:GetAttribute("PowerOn") then
            everyone("Blackout", Config.BlackoutSeconds)
        else
            ringPhone:Fire()
        end
    end,
}

local loopRound = nil
local function runEvents()
    local roundId = roundState:GetAttribute("RoundId")
    loopRound = roundId
    while loopRound == roundId do
        task.wait(random:NextNumber(Config.EventMinGap, Config.EventMaxGap))
        if loopRound ~= roundId or TaskKit.phase() ~= "Active" then
            return
        end
        events[random:NextInteger(1, #events)]()
    end
end

TaskKit.onRound(nil, runEvents, function()
    loopRound = nil
end)
