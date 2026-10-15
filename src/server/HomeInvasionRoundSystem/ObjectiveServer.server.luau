-- Gives the Protectors something to do besides hide:
--   * The power goes out when the Invaders arrive. Protectors can fix it at the fuse box,
--     and Invaders can cut it again.
--   * Car keys are hidden somewhere in the house. A Protector who reaches the escape
--     point with them wins the round for their team.
--
-- To place things yourself, add parts named "FuseBox" and "EscapePoint" to
-- workspace.HomeInvasionPrototype. Otherwise they get placed automatically.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Teams = game:GetService("Teams")

local RoundShared = require(script.Parent.RoundShared)
local roundState = ReplicatedStorage:WaitForChild("HomeInvasionRoundState")
local arena = workspace:WaitForChild("HomeInvasionPrototype")
local markers = arena:WaitForChild("WeaponSpawns")
local random = Random.new()

local ESCAPE_RADIUS = 8
local RESTORE_SECONDS = 4
local CUT_SECONDS = 2.5
local CUT_COOLDOWN = 30

local ServerStorage = game:GetService("ServerStorage")
local objectiveModels = ServerStorage:FindFirstChild("HomeInvasionObjectiveModels")

local objectiveFolder = Instance.new("Folder")
objectiveFolder.Name = "Objectives"
objectiveFolder.Parent = arena

-- Puts a nicer model on top of a plain objective part if one is stored in
-- ServerStorage.HomeInvasionObjectiveModels. The model's pivot lines up with the part.
local function dress(part, modelName)
    local template = objectiveModels and objectiveModels:FindFirstChild(modelName)
    if not template then
        return
    end
    local model = template:Clone()
    model.Name = "Visual"
    model:PivotTo(part.CFrame)
    for _, child in ipairs(model:GetDescendants()) do
        if child:IsA("BasePart") then
            child:SetAttribute("BaseTransparency", child.Transparency)
            child.Anchored = true
            child.CanCollide = false
            child.CanQuery = false
            child.CanTouch = false
        end
    end
    model.Parent = part
    part.Transparency = 1
end

-- Studio only: lets play tests run the same code as pressing a prompt, since prompts
-- can't be pressed from automated tests. Never created in a live game.
local studioTriggers = {}
if RunService:IsStudio() then
    local hook = Instance.new("BindableFunction")
    hook.Name = "StudioObjectiveTest"
    hook.OnInvoke = function(name, player)
        local handler = studioTriggers[name]
        if handler then
            handler(player)
            return true
        end
        return false
    end
    hook.Parent = ServerStorage
end

-- Power ----------------------------------------------------------------------

local savedLights = {}
local savedLighting = nil
local powerOn = true
local lastCut = 0
local fusePrompt

local function setPower(on)
    if powerOn == on then
        return
    end
    powerOn = on
    roundState:SetAttribute("PowerOn", on)
    if not on then
        savedLighting = {
            Brightness = Lighting.Brightness,
            Ambient = Lighting.Ambient,
            OutdoorAmbient = Lighting.OutdoorAmbient,
        }
        -- Dark enough to be scary, light enough to still find the fuse box.
        Lighting.Brightness = math.min(Lighting.Brightness, 0.6)
        Lighting.Ambient = Color3.fromRGB(26, 28, 38)
        Lighting.OutdoorAmbient = Color3.fromRGB(40, 44, 60)
        -- The whole map, not just the arena: the house's own lamps live outside it.
        for _, light in ipairs(workspace:GetDescendants()) do
            if
                light:IsA("Light")
                and light.Enabled
                and not light:IsDescendantOf(objectiveFolder)
                and not light:FindFirstAncestorOfClass("Tool")
                and not (light:FindFirstAncestorOfClass("Model") and light:FindFirstAncestorOfClass("Model"):FindFirstChildOfClass("Humanoid"))
            then
                savedLights[light] = true
                light.Enabled = false
            end
        end
    else
        if savedLighting then
            for property, value in pairs(savedLighting) do
                Lighting[property] = value
            end
            savedLighting = nil
        end
        for light in pairs(savedLights) do
            if light.Parent then
                light.Enabled = true
            end
        end
        table.clear(savedLights)
    end
    if fusePrompt then
        fusePrompt.ActionText = on and "Cut power" or "Restore power"
        fusePrompt.HoldDuration = on and CUT_SECONDS or RESTORE_SECONDS
    end
end

local function makeFuseBox(cframe)
    local box = arena:FindFirstChild("FuseBox")
    if not box then
        box = Instance.new("Part")
        box.Name = "FuseBox"
        box.Size = Vector3.new(1.6, 2.2, 0.6)
        box.Color = Color3.fromRGB(90, 95, 100)
        box.Material = Enum.Material.DiamondPlate
        box.Anchored = true
        box.CFrame = cframe + Vector3.new(0, 1.6, 0)
        box.Parent = objectiveFolder
    end
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "FusePrompt"
    prompt.ObjectText = "Fuse box"
    prompt.ActionText = "Cut power"
    prompt.HoldDuration = CUT_SECONDS
    prompt.KeyboardKeyCode = Enum.KeyCode.G
    prompt.MaxActivationDistance = 8
    prompt.RequiresLineOfSight = true
    prompt.Parent = box
    if not box:FindFirstChild("Visual") then
        dress(box, "FuseBox")
    end
    local function onTriggered(player)
        if roundState:GetAttribute("Phase") ~= "Active" then
            return
        end
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 or player:GetAttribute("InRound") ~= true then
            return
        end
        if powerOn and player.Team == Teams.Invaders then
            if os.clock() - lastCut < CUT_COOLDOWN then
                return
            end
            lastCut = os.clock()
            setPower(false)
        elseif not powerOn and player.Team == Teams.Protectors then
            setPower(true)
        end
    end
    prompt.Triggered:Connect(onTriggered)
    studioTriggers.FuseBox = onTriggered
    return prompt
end

-- Keys and escape --------------------------------------------------------------

local keys, keysPrompt, keyHolder, escapePart
local heartbeat

local function setHolder(player)
    if keyHolder then
        keyHolder:SetAttribute("HasKeys", nil)
    end
    keyHolder = player
    if player then
        player:SetAttribute("HasKeys", true)
    end
    roundState:SetAttribute("KeysHolder", player and player.DisplayName or nil)
end

local function setKeysVisible(part, visible)
    local visual = part:FindFirstChild("Visual")
    if visual then
        for _, child in ipairs(visual:GetDescendants()) do
            if child:IsA("BasePart") then
                child.Transparency = visible and child:GetAttribute("BaseTransparency") or 1
            end
        end
    else
        part.Transparency = visible and 0 or 1
    end
end

local function dropKeys(position)
    setHolder(nil)
    keys.CFrame = CFrame.new(position)
    local visual = keys:FindFirstChild("Visual")
    if visual then
        visual:PivotTo(keys.CFrame)
    end
    setKeysVisible(keys, true)
    keysPrompt.Enabled = true
end

local function makeKeys(cframe)
    local part = Instance.new("Part")
    part.Name = "CarKeys"
    part.Size = Vector3.new(0.6, 0.15, 0.4)
    part.Color = Color3.fromRGB(200, 170, 60)
    part.Material = Enum.Material.Metal
    part.Anchored = true
    part.CanCollide = false
    part.CFrame = cframe + Vector3.new(0, 0.2, 0)
    part.Parent = objectiveFolder
    local prompt = Instance.new("ProximityPrompt")
    prompt.ObjectText = "Car keys"
    prompt.ActionText = "Take"
    prompt.KeyboardKeyCode = Enum.KeyCode.F
    prompt.HoldDuration = 0.4
    prompt.MaxActivationDistance = 8
    prompt.RequiresLineOfSight = true
    prompt.Parent = part
    dress(part, "CarKeys")
    local function onTriggered(player)
        local phase = roundState:GetAttribute("Phase")
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if
            keyHolder
            or not (phase == "Preparation" or phase == "Active")
            or player.Team ~= Teams.Protectors
            or player:GetAttribute("InRound") ~= true
            or not humanoid
            or humanoid.Health <= 0
            or not root
            or (root.Position - part.Position).Magnitude > 10
        then
            return
        end
        setHolder(player)
        setKeysVisible(part, false)
        prompt.Enabled = false
        humanoid.Died:Once(function()
            if keyHolder == player and keys == part then
                dropKeys(root.Position - Vector3.new(0, 2.5, 0))
            end
        end)
    end
    prompt.Triggered:Connect(onTriggered)
    studioTriggers.CarKeys = onTriggered
    return part, prompt
end

-- Parks the getaway car (ServerStorage.HomeInvasionObjectiveModels.EscapeCar) beside the pad.
-- The car's pivot should be at the bottom centre of the car.
local function parkCar(pad)
    local template = objectiveModels and objectiveModels:FindFirstChild("EscapeCar")
    if not template then
        return
    end
    local car = template:Clone()
    local beside = pad.CFrame * CFrame.new(0, 0, ESCAPE_RADIUS / 2 + 4.5)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { objectiveFolder, pad }
    local ground = workspace:Raycast(beside.Position + Vector3.new(0, 10, 0), Vector3.new(0, -40, 0), params)
    local height = ground and ground.Position.Y or pad.Position.Y
    car:PivotTo(CFrame.new(beside.X, height, beside.Z) * pad.CFrame.Rotation)
    car.Parent = objectiveFolder
end

local function makeEscapePoint()
    local existing = arena:FindFirstChild("EscapePoint")
    if existing then
        parkCar(existing)
        return existing
    end
    -- No escape point placed yet, so use the road where the Invaders start.
    local invaderSpawn = arena.Spawns.Invaders:FindFirstChild("1")
    local part = Instance.new("Part")
    part.Name = "EscapePoint"
    part.Size = Vector3.new(ESCAPE_RADIUS, 0.2, ESCAPE_RADIUS)
    part.Color = Color3.fromRGB(70, 150, 95)
    part.Material = Enum.Material.Neon
    part.Transparency = 0.8
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CFrame = invaderSpawn.CFrame
    part.Parent = objectiveFolder
    local gui = Instance.new("BillboardGui")
    gui.Size = UDim2.fromOffset(160, 40)
    gui.StudsOffset = Vector3.new(0, 5, 0)
    gui.AlwaysOnTop = true
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = "ESCAPE"
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = Color3.fromRGB(120, 230, 150)
    label.Parent = gui
    gui.Parent = part
    parkCar(part)
    return part
end

-- Round lifecycle --------------------------------------------------------------

local function cleanup()
    if heartbeat then
        heartbeat:Disconnect()
        heartbeat = nil
    end
    setHolder(nil)
    setPower(true)
    if fusePrompt then
        fusePrompt:Destroy()
    end
    objectiveFolder:ClearAllChildren()
    keys, keysPrompt, escapePart, fusePrompt = nil, nil, nil, nil
    roundState:SetAttribute("PowerOn", nil)
end

-- Weapons spawn on the same markers, so wait for them and only use the empty ones.
-- Otherwise the fuse box can land on a weapon and block anyone from picking it up.
local function freeSpots()
    local pickups = arena:FindFirstChild("WeaponPickups")
    local roundId = roundState:GetAttribute("RoundId")
    local deadline = os.clock() + 3
    while pickups and os.clock() < deadline do
        local spawned = false
        for _, pickup in ipairs(pickups:GetChildren()) do
            if pickup:GetAttribute("RoundId") == roundId then
                spawned = true
                break
            end
        end
        if spawned then
            break
        end
        task.wait(0.1)
    end
    local taken = {}
    for _, pickup in ipairs(pickups and pickups:GetChildren() or {}) do
        local marker = pickup:GetAttribute("SpawnMarker")
        if marker then
            taken[marker] = true
        end
    end
    local spots = {}
    for _, marker in ipairs(markers:GetChildren()) do
        if not taken[marker.Name] then
            table.insert(spots, marker)
        end
    end
    -- Not enough empty spots: fall back to any marker rather than skipping objectives.
    if #spots < 2 then
        spots = markers:GetChildren()
    end
    return spots
end

local function setupRound()
    cleanup()
    local spots = freeSpots()
    if roundState:GetAttribute("Phase") ~= "Preparation" then
        return
    end
    if #spots < 2 then
        warn("Objectives need at least 2 WeaponSpawns markers")
        return
    end
    local keySpot = table.remove(spots, random:NextInteger(1, #spots))
    local fuseSpot = spots[random:NextInteger(1, #spots)]
    keys, keysPrompt = makeKeys(keySpot.CFrame)
    fusePrompt = makeFuseBox(fuseSpot.CFrame)
    escapePart = makeEscapePoint()
    roundState:SetAttribute("PowerOn", true)

    local roundId = RoundShared.roundId
    heartbeat = RunService.Heartbeat:Connect(function()
        local holder = keyHolder
        local character = holder and holder.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if root and roundState:GetAttribute("Phase") == "Active" then
            local offset = root.Position - escapePart.Position
            if Vector3.new(offset.X, 0, offset.Z).Magnitude <= ESCAPE_RADIUS and math.abs(offset.Y) < 10 then
                RoundShared.escapedRoundId = roundId
                RoundShared.escapedBy = holder
            end
        end
    end)
end

roundState:GetAttributeChangedSignal("Phase"):Connect(function()
    local phase = roundState:GetAttribute("Phase")
    if phase == "Preparation" then
        setupRound()
    elseif phase == "Active" then
        -- The Invaders cut the power as they arrive.
        lastCut = os.clock()
        setPower(false)
    else
        cleanup()
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if player == keyHolder and keys then
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        dropKeys(root and root.Position - Vector3.new(0, 2.5, 0) or keys.Position)
    end
end)
