-- power goes out when invaders show up, protectors fix it at the fuse box, then car keys
-- spawn and whoever gets them to the escape point wins
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Teams = game:GetService("Teams")

local RoundShared = require(script.Parent.RoundShared)
local SpotPicker = require(script.Parent.SpotPicker)
local roundState = ReplicatedStorage:WaitForChild("HomeInvasionRoundState")
local arena = workspace:WaitForChild("HomeInvasionPrototype")

local ESCAPE_RADIUS = 8
local OPEN_SECONDS = 0.3 -- the repair minigame is the real work
local MIN_REPAIR_SECONDS = 3.5 -- quicker than this and the client skipped the minigame
local REPAIR_RANGE = 10
local CUT_SECONDS = 2.5
local CUT_COOLDOWN = 30
local KEYS_MIN_DISTANCE = 45 -- keys never appear this close to anyone

local ServerStorage = game:GetService("ServerStorage")
local objectiveModels = ServerStorage:FindFirstChild("HomeInvasionObjectiveModels")

local remoteFolder = ReplicatedStorage:FindFirstChild("HomeInvasionObjectives") or Instance.new("Folder")
remoteFolder.Name = "HomeInvasionObjectives"
remoteFolder.Parent = ReplicatedStorage
local remote = remoteFolder:FindFirstChild("Interaction") or Instance.new("RemoteEvent")
remote.Name = "Interaction"
remote.Parent = remoteFolder

local objectiveFolder = Instance.new("Folder")
objectiveFolder.Name = "Objectives"
objectiveFolder.Parent = arena

-- puts a nicer model on top of a plain objective part if one is stored in
-- ServerStorage.HomeInvasionObjectiveModels. The model's pivot lines up with the part
local function dress(part, modelName)
    local template = objectiveModels and objectiveModels:FindFirstChild(modelName)
    if not template then
        return
    end
    local model = template:Clone()
    model.Name = "Visual"
    model:PivotTo(part.CFrame)
    for _, child in model:GetDescendants() do
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
-- can't be pressed from automated tests. Never created in a live game
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

-- power

local spawnKeys -- set further down, called when the power first comes back

local savedLights = {}
local savedLighting = nil
local powerOn = true
local lastCut = 0
local fusePrompt
local repairs = {} -- [player] = { started, roundId }

local function endRepair(player, message)
    if repairs[player] then
        repairs[player] = nil
        if player.Parent == Players then
            remote:FireClient(player, "FuseEnd", message)
        end
    end
end

local function endAllRepairs(message)
    for player in repairs do
        endRepair(player, message)
    end
end

local function holdingScrewdriver(player)
    local character = player.Character
    local tool = character and character:FindFirstChildOfClass("Tool")
    return tool ~= nil and tool:GetAttribute("WeaponId") == "Screwdriver"
end

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
        -- dark but you can still find the fuse box
        Lighting.Brightness = math.min(Lighting.Brightness, 0.6)
        Lighting.Ambient = Color3.fromRGB(26, 28, 38)
        Lighting.OutdoorAmbient = Color3.fromRGB(40, 44, 60)
        -- whole map, the house lamps aren't inside the arena
        for _, light in workspace:GetDescendants() do
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
            for property, value in savedLighting do
                Lighting[property] = value
            end
            savedLighting = nil
        end
        for light in savedLights do
            if light.Parent then
                light.Enabled = true
            end
        end
        table.clear(savedLights)
    end
    if fusePrompt then
        fusePrompt.ActionText = on and "Cut power" or "Restore power"
        fusePrompt.HoldDuration = on and CUT_SECONDS or OPEN_SECONDS
    end
    if on then
        endAllRepairs(nil)
        if roundState:GetAttribute("Phase") == "Active" then
            spawnKeys()
        end
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
            if not holdingScrewdriver(player) then
                remote:FireClient(player, "Notice", "You need a screwdriver to fix the fuse box")
            elseif not repairs[player] then
                repairs[player] = { started = os.clock(), roundId = roundState:GetAttribute("RoundId") }
                remote:FireClient(player, "FuseStart", fusePrompt.Parent)
            end
        end
    end
    prompt.Triggered:Connect(onTriggered)
    studioTriggers.FuseBox = onTriggered
    return prompt
end

-- the client says the minigame is done. Check everything again before believing it
local function finishRepair(player)
    local repair = repairs[player]
    local box = fusePrompt and fusePrompt.Parent
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if
        not repair
        or powerOn
        or not box
        or roundState:GetAttribute("Phase") ~= "Active"
        or roundState:GetAttribute("RoundId") ~= repair.roundId
        or os.clock() - repair.started < MIN_REPAIR_SECONDS
        or player.Team ~= Teams.Protectors
        or not humanoid
        or humanoid.Health <= 0
        or not root
        or (root.Position - box.Position).Magnitude > REPAIR_RANGE
        or not holdingScrewdriver(player)
    then
        endRepair(player, "Repair failed")
        return
    end
    repairs[player] = nil
    setPower(true)
    remote:FireClient(player, "FuseEnd", "Power restored")
end
studioTriggers.FuseDone = finishRepair

remote.OnServerEvent:Connect(function(player, action)
    if action == "FuseDone" then
        finishRepair(player)
    elseif action == "FuseCancel" then
        repairs[player] = nil
    end
end)

-- keys and escape

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
        for _, child in visual:GetDescendants() do
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
            or player:GetAttribute("HasFuel")
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

-- parks the getaway car (ServerStorage.HomeInvasionObjectiveModels.EscapeCar) beside the pad.
-- The car's pivot should be at the bottom centre of the car
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
    -- no escape point placed yet, so use the road where the Invaders start
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

-- keys go on a free spot far from every player in the round, so nobody gets them for free
spawnKeys = function()
    if keys or not escapePart then
        return
    end
    local spot = SpotPicker.take(KEYS_MIN_DISTANCE)
    if not spot then
        warn("No free spot left for the car keys")
        return
    end
    keys, keysPrompt = makeKeys(spot.CFrame)
    roundState:SetAttribute("KeysOut", true)
    for _, player in Players:GetPlayers() do
        if player.Team == Teams.Protectors and player:GetAttribute("InRound") then
            remote:FireClient(player, "Notice", "Power's back. The car keys are somewhere in the house")
        end
    end
end

-- round lifecycle

local function cleanup()
    endAllRepairs(nil)
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
    roundState:SetAttribute("KeysOut", nil)
end

local function setupRound()
    cleanup()
    local fuseSpot = not arena:FindFirstChild("FuseBox") and SpotPicker.take()
    if roundState:GetAttribute("Phase") ~= "Preparation" then
        return
    end
    fusePrompt = makeFuseBox(fuseSpot and fuseSpot.CFrame or CFrame.new())
    escapePart = makeEscapePoint()
    roundState:SetAttribute("PowerOn", true)

    local roundId = RoundShared.roundId
    local lastEmptyWarning = 0
    heartbeat = RunService.Heartbeat:Connect(function()
        local holder = keyHolder
        local character = holder and holder.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if root and roundState:GetAttribute("Phase") == "Active" then
            local offset = root.Position - escapePart.Position
            if Vector3.new(offset.X, 0, offset.Z).Magnitude <= ESCAPE_RADIUS and math.abs(offset.Y) < 10 then
                if roundState:GetAttribute("CarFueled") then
                    RoundShared.escapedRoundId = roundId
                    RoundShared.escapedBy = holder
                elseif os.clock() - lastEmptyWarning > 5 then
                    lastEmptyWarning = os.clock()
                    remote:FireClient(holder, "Notice", "The car's out of gas. Find the gas can")
                end
            end
        end
    end)
end

roundState:GetAttributeChangedSignal("Phase"):Connect(function()
    local phase = roundState:GetAttribute("Phase")
    if phase == "Preparation" then
        setupRound()
    elseif phase == "Active" then
        -- the Invaders cut the power as they arrive
        lastCut = os.clock()
        setPower(false)
    else
        cleanup()
    end
end)

Players.PlayerRemoving:Connect(function(player)
    repairs[player] = nil
    if player == keyHolder and keys then
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        dropKeys(root and root.Position - Vector3.new(0, 2.5, 0) or keys.Position)
    end
end)
