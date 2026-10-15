-- Loud things protectors do (swinging, locking doors, wardrobe creaks, filling the car)
-- flash a rough marker for invaders so hiding and moving quietly matter.
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local Teams = game:GetService("Teams")

local Config = require(script.Parent.Config)
local TaskKit = require(script.Parent.TaskKit)

local noise = ServerStorage:FindFirstChild("HomeInvasionNoise") or Instance.new("BindableEvent")
noise.Name = "HomeInvasionNoise"
noise.Parent = ServerStorage

local random = Random.new()
local recent = {} -- [rounded position key] = time

noise.Event:Connect(function(position, label)
    if typeof(position) ~= "Vector3" or TaskKit.phase() ~= "Active" then
        return
    end
    local key = string.format("%d,%d,%d", position.X // 8, position.Y // 8, position.Z // 8)
    local now = os.clock()
    if now - (recent[key] or 0) < Config.NoiseCooldown then
        return
    end
    recent[key] = now
    -- only a rough area, not an exact spot
    local fuzzy = position + Vector3.new(random:NextNumber(-4, 4), 0, random:NextNumber(-4, 4))
    for _, player in Players:GetPlayers() do
        if player.Team == Teams.Invaders and player:GetAttribute("InRound") then
            TaskKit.remote:FireClient(player, "Noise", fuzzy, typeof(label) == "string" and label or nil)
        end
    end
end)

TaskKit.onRound(nil, nil, function()
    table.clear(recent)
end)
