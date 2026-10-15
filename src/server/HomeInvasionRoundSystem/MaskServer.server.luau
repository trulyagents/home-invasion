-- puts an animal mask on every Invader, like the killers in You're Next.
-- Uses the models in ServerStorage.HomeInvasionMasks (<Lamb|Fox|Tiger>, pivot at the centre of the head),
-- and falls back to a simple block mask if one is missing
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local looks = {
    Lamb = { face = Color3.fromRGB(235, 230, 220), ear = Color3.fromRGB(225, 215, 200), earShape = "Floppy" },
    Fox = { face = Color3.fromRGB(205, 110, 50), ear = Color3.fromRGB(190, 95, 40), earShape = "Pointed" },
    Tiger = { face = Color3.fromRGB(225, 140, 45), ear = Color3.fromRGB(40, 30, 25), earShape = "Round" },
}

local function weldTo(head, part, offset)
    part.Anchored = false
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.Massless = true
    part.CFrame = head.CFrame * offset
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = head
    weld.Part1 = part
    weld.Parent = part
end

local function newPart(model, name, size, color, shape)
    local part = Instance.new(shape or "Part")
    part.Name = name
    part.Size = size
    part.Color = color
    part.Material = Enum.Material.SmoothPlastic
    part.Parent = model
    return part
end

local function buildPlaceholder(maskName, head)
    local look = looks[maskName]
    local model = Instance.new("Model")
    model.Name = "AnimalMask"
    local z = -head.Size.Z / 2 - 0.08

    local face = newPart(model, "Face", Vector3.new(head.Size.X * 1.05, head.Size.Y * 1.1, 0.18), look.face)
    weldTo(head, face, CFrame.new(0, 0.05, z))
    for _, x in { -0.22, 0.22 } do
        local eye = newPart(model, "EyeHole", Vector3.new(0.2, 0.12, 0.05), Color3.new(0, 0, 0))
        weldTo(head, eye, CFrame.new(x, 0.15, z - 0.1))
    end
    local snout = newPart(model, "Snout", Vector3.new(0.35, 0.25, 0.2), look.ear)
    weldTo(head, snout, CFrame.new(0, -0.2, z - 0.15))

    for _, side in { -1, 1 } do
        local ear
        if look.earShape == "Pointed" then
            ear = newPart(model, "Ear", Vector3.new(0.12, 0.45, 0.3), look.ear, "WedgePart")
            weldTo(head, ear, CFrame.new(side * 0.4, head.Size.Y / 2 + 0.2, z + 0.15))
        elseif look.earShape == "Floppy" then
            ear = newPart(model, "Ear", Vector3.new(0.45, 0.15, 0.25), look.ear)
            weldTo(head, ear, CFrame.new(side * 0.75, 0.2, z + 0.1) * CFrame.Angles(0, 0, side * math.rad(-25)))
        else
            ear = newPart(model, "Ear", Vector3.new(0.3, 0.3, 0.1), look.ear, "Part")
            ear.Shape = Enum.PartType.Cylinder
            ear.Size = Vector3.new(0.1, 0.3, 0.3)
            weldTo(head, ear, CFrame.new(side * 0.42, head.Size.Y / 2 + 0.05, z + 0.1) * CFrame.Angles(0, math.rad(90), 0))
        end
    end
    return model
end

local function wearMask(player, character)
    local maskName = player:GetAttribute("Mask")
    if player:GetAttribute("RoundRole") ~= "Invaders" or not looks[maskName] then
        return
    end
    -- loading the avatar swaps out the head, which would break the mask's welds
    local deadline = os.clock() + 10
    while not player:HasAppearanceLoaded() and os.clock() < deadline and player.Character == character do
        task.wait(0.1)
    end
    local head = character:WaitForChild("Head", 10)
    if not head or player.Character ~= character or character:FindFirstChild("AnimalMask") then
        return
    end
    local custom = ServerStorage:FindFirstChild("HomeInvasionMasks")
    custom = custom and custom:FindFirstChild(maskName)
    local mask
    if custom and custom:IsA("Model") then
        mask = custom:Clone()
        mask.Name = "AnimalMask"
        -- the mask model's pivot has to be the middle of the head
        mask:PivotTo(head.CFrame)
        for _, part in mask:GetDescendants() do
            if part:IsA("BasePart") then
                weldTo(head, part, head.CFrame:ToObjectSpace(part.CFrame))
            end
        end
    else
        mask = buildPlaceholder(maskName, head)
    end
    mask.Parent = character
end

local function setup(player)
    player.CharacterAdded:Connect(function(character)
        wearMask(player, character)
    end)
    if player.Character then
        task.spawn(wearMask, player, player.Character)
    end
end

Players.PlayerAdded:Connect(setup)
for _, player in Players:GetPlayers() do
    setup(player)
end
