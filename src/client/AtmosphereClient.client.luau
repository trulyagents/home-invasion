--!strict
-- Horror sound cues: a heartbeat for Protectors that gets louder as an Invader gets close,
-- a power-down sound when the lights go out, and a faint glow around you in the dark
-- (only you can see it) so a blackout is scary rather than unplayable.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")

local player = Players.LocalPlayer
local state = ReplicatedStorage:WaitForChild("HomeInvasionRoundState")
local sounds = game:GetService("SoundService"):WaitForChild("HomeInvasionPresentation")
local heartbeat = sounds:WaitForChild("Heartbeat") :: Sound
local powerCut = sounds:WaitForChild("PowerCut") :: Sound

local HEARING_RANGE = 40
local MAX_VOLUME = 0.9

local function nearestInvaderDistance(position: Vector3): number
    local nearest = math.huge
    local invaders = Teams:FindFirstChild("Invaders")
    if not invaders then
        return nearest
    end
    for _, other in ipairs((invaders :: Team):GetPlayers()) do
        local character = other.Character
        local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if root and humanoid and humanoid.Health > 0 then
            nearest = math.min(nearest, (root.Position - position).Magnitude)
        end
    end
    return nearest
end

local volume = 0
local elapsed = 0
RunService.Heartbeat:Connect(function(deltaTime)
    elapsed += deltaTime
    if elapsed < 0.2 then
        return
    end
    local step = elapsed
    elapsed = 0

    local target = 0
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
    if root and player:GetAttribute("RoundRole") == "Protectors" and state:GetAttribute("Phase") == "Active" then
        local distance = nearestInvaderDistance(root.Position)
        target = math.clamp(1 - distance / HEARING_RANGE, 0, 1)
    end
    volume += (target - volume) * math.min(1, step * 3)
    heartbeat.Volume = volume * MAX_VOLUME
    heartbeat.PlaybackSpeed = 1 + volume * 0.35
    if volume > 0.02 and not heartbeat.IsPlaying then
        heartbeat:Play()
    elseif volume <= 0.02 and heartbeat.IsPlaying then
        heartbeat:Stop()
    end
end)

local function updateGlow()
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return
    end
    local glow = root:FindFirstChild("DarkVision") :: PointLight?
    if not glow then
        local light = Instance.new("PointLight")
        light.Name = "DarkVision"
        light.Color = Color3.fromRGB(170, 180, 220)
        light.Brightness = 1
        light.Range = 20
        light.Shadows = false
        light.Parent = root
        glow = light
    end
    (glow :: PointLight).Enabled = state:GetAttribute("PowerOn") == false
end

state:GetAttributeChangedSignal("PowerOn"):Connect(function()
    if state:GetAttribute("PowerOn") == false then
        powerCut:Play()
    end
    updateGlow()
end)
player.CharacterAdded:Connect(function(character)
    character:WaitForChild("HumanoidRootPart", 10)
    updateGlow()
end)
updateGlow()
