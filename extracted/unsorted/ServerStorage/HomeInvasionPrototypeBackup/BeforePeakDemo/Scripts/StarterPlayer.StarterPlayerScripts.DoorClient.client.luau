local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local state = ReplicatedStorage:WaitForChild("HomeInvasionRoundState")
local doors = workspace:WaitForChild("HomeInvasionPrototype"):WaitForChild("Doors")

local function refresh(model)
    local collider = model:FindFirstChild("DoorCollider")
    if not collider then return end
    local phase = state:GetAttribute("Phase")
    local protector = player:GetAttribute("RoundRole") == "Protectors"
    local invader = player:GetAttribute("RoundRole") == "Invaders"
    local allowed = player:GetAttribute("InRound") == true
        and not player:GetAttribute("DraggingFurniture")
        and not model:GetAttribute("DoorBroken")
        and ((protector and (phase == "Preparation" or phase == "Active"))
            or (invader and phase == "Active"))
    collider.DoorOpenPrompt.Enabled = allowed and not model:GetAttribute("DoorLocked")
    collider.DoorLockPrompt.Enabled = allowed and protector
end

local function refreshAll()
    for _, model in ipairs(doors:GetChildren()) do
        if model:IsA("Model") then refresh(model) end
    end
end

for _, model in ipairs(doors:GetChildren()) do
    if model:IsA("Model") then
        model.AttributeChanged:Connect(function() refresh(model) end)
    end
end
state:GetAttributeChangedSignal("Phase"):Connect(refreshAll)
player:GetAttributeChangedSignal("RoundRole"):Connect(refreshAll)
player:GetAttributeChangedSignal("InRound"):Connect(refreshAll)
player:GetAttributeChangedSignal("DraggingFurniture"):Connect(refreshAll)
refreshAll()
