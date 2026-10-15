-- Landline phone. A protector can call the police, and if the house holds out until
-- they arrive, protectors win. Invaders can cut the line, which kills the phone for the round.
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(script.Parent.Config)
local TaskKit = require(script.Parent.TaskKit)
local RoundShared = require(ServerScriptService.HomeInvasionRoundSystem.RoundShared)
local SpotPicker = require(ServerScriptService.HomeInvasionRoundSystem.SpotPicker)

local roundState = TaskKit.roundState
local noise = game:GetService("ServerStorage"):WaitForChild("HomeInvasionNoise")
local phone, callPrompt, cutPrompt, ring
local helpAt = nil
local dead = false

local function cleanup()
    if phone then
        phone:Destroy()
    end
    phone, callPrompt, cutPrompt, ring, helpAt = nil, nil, nil, nil, nil
    dead = false
    roundState:SetAttribute("HelpArrivesIn", nil)
    roundState:SetAttribute("PhoneDead", nil)
end

local function killLine(message)
    dead = true
    helpAt = nil
    roundState:SetAttribute("HelpArrivesIn", nil)
    roundState:SetAttribute("PhoneDead", true)
    if callPrompt then
        callPrompt.Enabled = false
    end
    if cutPrompt then
        cutPrompt.Enabled = false
    end
    TaskKit.notifyTeam(nil, message)
end

local function setup()
    cleanup()
    local spot = SpotPicker.take()
    if not spot or TaskKit.phase() ~= "Preparation" then
        return
    end
    phone = TaskKit.place("Phone", spot.CFrame * CFrame.new(0, 1.4, 0), Vector3.new(1.6, 2.8, 1.6), Color3.fromRGB(200, 190, 160))
    ring = TaskKit.sound(phone, Config.Sounds.PhoneRing, 0.8, 90)
    phone:SetAttribute("TaskItem", "Phone")

    callPrompt = TaskKit.prompt(phone, "Phone", "Call the police", Config.CallSeconds, "Protectors")
    TaskKit.connect(callPrompt, function(player)
        if dead or helpAt or TaskKit.phase() ~= "Active" or not TaskKit.inRange(player, phone, 10)
            or not TaskKit.validPlayer(player, "Protectors") then
            return
        end
        helpAt = os.clock() + Config.HelpSeconds
        noise:Fire(phone.Position, "phone")
        callPrompt.Enabled = false
        TaskKit.notifyTeam("Protectors", "You called the police. Hold out until they arrive")
        TaskKit.notifyTeam("Invaders", "Someone called the police. Cut the phone line!")
    end)

    cutPrompt = TaskKit.prompt(phone, "Phone line", "Cut the line", Config.CutLineSeconds, "Invaders")
    TaskKit.connect(cutPrompt, function(player)
        if dead or TaskKit.phase() ~= "Active" or not TaskKit.inRange(player, phone, 10)
            or not TaskKit.validPlayer(player, "Invaders") then
            return
        end
        killLine(helpAt and "The phone line was cut. The police aren't coming" or "The phone line was cut")
    end)
end

RunService.Heartbeat:Connect(function()
    if not helpAt then
        return
    end
    if TaskKit.phase() ~= "Active" then
        helpAt = nil
        return
    end
    local left = math.max(0, math.ceil(helpAt - os.clock()))
    if roundState:GetAttribute("HelpArrivesIn") ~= left then
        roundState:SetAttribute("HelpArrivesIn", left)
    end
    if left == 0 then
        helpAt = nil
        RoundShared.helpArrivedRoundId = RoundShared.roundId
        if phone then
            local siren = TaskKit.sound(phone, Config.Sounds.Siren, 1, 400)
            siren:Play()
        end
    end
end)

-- lets the random event script ring the phone as a decoy
local ringEvent = Instance.new("BindableEvent")
ringEvent.Name = "RingPhone"
ringEvent.Event:Connect(function()
    if ring and not dead then
        ring:Play()
    end
end)
ringEvent.Parent = script

TaskKit.onRound(setup, nil, cleanup)
