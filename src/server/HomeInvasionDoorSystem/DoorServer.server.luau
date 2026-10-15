local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")
local Config = require(script.Parent.Config)
local AnimationService = require(game.ServerScriptService.HomeInvasionAnimationSystem.AnimationService)
local state = ReplicatedStorage:WaitForChild("HomeInvasionRoundState")
local doorsFolder = workspace.HomeInvasionPrototype:WaitForChild("Doors")
local remote = ReplicatedStorage.HomeInvasionDoors:WaitForChild("Interaction")
local notices = ReplicatedStorage.HomeInvasionWeapons:WaitForChild("Interaction")
local records = {}
local lastInteraction = {}
local MOVE_SECONDS = 0.4
local PATH_STEPS = 18
local FRAME_EDGE_CLEARANCE = 0.25
local SLIDING_TRACK_CLEARANCE = 0.8
local SLIDING_LEAD_FRACTION = 0.15

local probe = Instance.new("Part")
probe.Name = "DoorMovementProbe"
probe.Anchored = true
probe.Transparency = 1
probe.CanCollide = false
probe.CanQuery = false
probe.CanTouch = false
probe.Parent = doorsFolder

local function notify(player, message)
    if player.Parent == Players then
        notices:FireClient(player, "Notice", message)
    end
end
local function validPlayer(player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local phase = state:GetAttribute("Phase")
    if
        player.Parent ~= Players
        or not player:GetAttribute("InRound")
        or not humanoid
        or humanoid.Health <= 0
        or not root
        or player:GetAttribute("DraggingFurniture")
        or (player.Team ~= Teams.Protectors and player.Team ~= Teams.Invaders)
        or (phase ~= "Active" and phase ~= "Preparation")
        or (player.Team == Teams.Invaders and phase ~= "Active")
    then
        return nil
    end
    return root
end
local function publish(record)
    local model = record.model
    model:SetAttribute("DoorClosedCollider", record.closedCollider)
    model:SetAttribute("DoorOpen", record.open)
    model:SetAttribute("DoorLocked", record.locked)
    model:SetAttribute("DoorBroken", record.broken)
    model:SetAttribute("DoorMoving", record.motion ~= nil)
    model:SetAttribute("DoorHealth", record.health)
    -- these old prompts are kept for rollback, never drawn or used for input
    record.collider.DoorOpenPrompt.Enabled = false
    record.collider.DoorLockPrompt.Enabled = false
end
local function transformAt(record, fraction)
    if record.hinge then
        return CFrame.new(record.hinge)
            * CFrame.Angles(0, record.angle * fraction, 0)
            * CFrame.new(-record.hinge)
    end
    local leaveFrame = math.clamp(fraction / SLIDING_LEAD_FRACTION, 0, 1)
    local slideFraction = math.clamp((fraction - SLIDING_LEAD_FRACTION) / (1 - SLIDING_LEAD_FRACTION), 0, 1)
    return CFrame.new(record.trackOffset * leaveFrame + record.slide * slideFraction)
end
local function place(record, fraction)
    local transform = transformAt(record, fraction)
    local pivot = transform * record.closedPivot
    if record.leaf:IsA("Model") then
        record.leaf:PivotTo(pivot)
    else
        record.leaf.CFrame = pivot
    end
    record.collider.CFrame = transform * record.closedCollider
    record.fraction = fraction
end
local function poseClear(record, fraction)
    probe.Size = record.probeSize
    probe.CFrame = transformAt(record, fraction) * record.closedCollider
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { record.model, record.leaf, probe }
    params.RespectCanCollide = true
    params.MaxParts = 1
    if #workspace:GetPartsInPart(probe, params) > 0 then
        return false
    end
    local characters = {}
    for _, player in Players:GetPlayers() do
        local character = player.Character
        if character then
            for _, name in { "HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso", "Head" } do
                local part = character:FindFirstChild(name)
                if part then
                    table.insert(characters, part)
                end
            end
        end
    end
    if #characters > 0 then
        params.FilterType = Enum.RaycastFilterType.Include
        params.FilterDescendantsInstances = characters
        params.RespectCanCollide = false
        if #workspace:GetPartsInPart(probe, params) > 0 then
            return false
        end
    end
    return true
end
local function pathClear(record, target)
    for index = 1, PATH_STEPS do
        local fraction = record.fraction + (target - record.fraction) * index / PATH_STEPS
        if not poseClear(record, fraction) then
            return false
        end
    end
    return true
end
local function interact(player, record, action)
    local root = validPlayer(player)
    if not root or record.broken or record.motion then
        return
    end
    local now = os.clock()
    if now - (lastInteraction[player] or 0) < Config.InteractionCooldown then
        return
    end
    lastInteraction[player] = now
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { player.Character, record.model, record.leaf }
    params.RespectCanCollide = true
    local interactionPositions = { record.collider.Position }
    if record.open then
        table.insert(interactionPositions, record.closedCollider.Position)
    end
    local reachable = false
    for _, position in interactionPositions do
        local offset = position - root.Position
        if
            offset.Magnitude <= Config.InteractionDistance
            and not workspace:Raycast(root.Position, offset, params)
        then
            reachable = true
            break
        end
    end
    if not reachable then
        return
    end
    if action == "Pick" then
        if player.Team ~= Teams.Invaders or not record.locked or record.open or record.picking then
            return
        end
        record.picking = { player = player, started = now }
        notify(player, "Picking the lock... stay close")
        return
    end
    if action == "Lock" then
        if player.Team ~= Teams.Protectors then
            return
        end
        local noise = game:GetService("ServerStorage"):FindFirstChild("HomeInvasionNoise")
        if noise then
            noise:Fire(record.collider.Position, "lock")
        end
        if record.open then
            notify(player, "Close the door before locking it.")
            return
        end
        record.locked = not record.locked
        record.collider.DoorLock:Play()
        AnimationService.play(player.Character, "Interact", false, 2)
        publish(record)
        return
    end
    if record.locked then
        notify(
            player,
            player.Team == Teams.Protectors and "Press L to unlock this door."
                or "Locked. Use your crowbar to breach."
        )
        return
    end
    local target = record.open and 0 or 1
    if target == 1 and record.hinge then
        local oldAngle = record.angle
        record.angle = record.defaultAngle
        local movement = (transformAt(record, 1) * record.closedCollider).Position
            - record.closedCollider.Position
        if movement:Dot(root.Position - record.closedCollider.Position) > 0 then
            record.angle = -record.angle
        end
        if not pathClear(record, 1) then
            record.angle = -record.angle
            if not pathClear(record, 1) then
                record.angle = oldAngle
                notify(player, "Door swing blocked. Move the furniture or step aside.")
                return
            end
        end
    elseif target == 1 then
        local previousOffset = record.trackOffset
        record.trackOffset = record.defaultTrackOffset
        if record.trackOffset:Dot(root.Position - record.closedCollider.Position) > 0 then
            record.trackOffset = -record.trackOffset
        end
        if not pathClear(record, 1) then
            record.trackOffset = -record.trackOffset
            if not pathClear(record, 1) then
                record.trackOffset = previousOffset
                notify(player, "Door track blocked. Move the furniture or step aside.")
                return
            end
        end
    elseif not pathClear(record, target) then
        notify(player, "Doorway blocked. Move the furniture or step aside.")
        return
    end
    record.motion = { started = now, from = record.fraction, to = target, player = player }
    record.collider.DoorMove:Play()
    AnimationService.play(player.Character, "Interact", false, 2)
    publish(record)
end

for _, model in doorsFolder:GetChildren() do
    if model:IsA("Model") and model:FindFirstChild("OriginalLeaf") then
        local leaf = model.OriginalLeaf.Value
        local closedPivot = model:GetAttribute("ClosedPivot")
        local openPivot = model:GetAttribute("OpenPivot")
        local hingePart = model:GetAttribute("DoorKind") == "Hinged"
            and leaf:IsA("Model")
            and leaf:FindFirstChild("SS2", true)
        local relativeRotation = openPivot.Rotation * closedPivot.Rotation:Inverse()
        local _, angle = relativeRotation:ToOrientation()
        local collider = model.DoorCollider
        local size = collider.Size
        -- shrink the check so it doesn't catch the door frame
        local probeSize = Vector3.new(
            math.max(
                0.08,
                size.X > size.Z and size.X - FRAME_EDGE_CLEARANCE * 2
                    or math.min(0.2, size.X - Config.CollisionInset)
            ),
            math.max(0.1, size.Y - FRAME_EDGE_CLEARANCE),
            math.max(
                0.08,
                size.Z > size.X and size.Z - FRAME_EDGE_CLEARANCE * 2
                    or math.min(0.2, size.Z - Config.CollisionInset)
            )
        )
        local normal = size.X < size.Z and collider.CFrame.RightVector or collider.CFrame.LookVector
        local trackOffset = normal * SLIDING_TRACK_CLEARANCE
        local record = {
            model = model,
            leaf = leaf,
            collider = model.DoorCollider,
            closedPivot = closedPivot,
            closedCollider = model.DoorCollider.CFrame,
            hinge = hingePart and hingePart.Position,
            defaultAngle = angle,
            angle = angle,
            slide = model:GetAttribute("OpenCollider").Position - model.DoorCollider.Position,
            probeSize = probeSize,
            defaultTrackOffset = trackOffset,
            trackOffset = trackOffset,
            fraction = 0,
            open = false,
            locked = false,
            broken = false,
            health = Config.DoorHealth,
            parts = {},
        }
        local parts = leaf:IsA("BasePart") and { leaf } or leaf:GetDescendants()
        for _, part in parts do
            if part:IsA("BasePart") then
                record.parts[part] = part.Transparency
            end
        end
        records[model] = record
        model:SetAttribute("DoorMaxHealth", Config.DoorHealth)
        publish(record)
    end
end
remote.OnServerEvent:Connect(function(player, action, model)
    if (action ~= "Open" and action ~= "Lock" and action ~= "Pick") or typeof(model) ~= "Instance" then
        return
    end
    local record = records[model]
    if record and model.Parent == doorsFolder then
        interact(player, record, action)
    end
end)
RunService.Heartbeat:Connect(function()
    local now = os.clock()
    for _, record in records do
        local picking = record.picking
        if picking and now - picking.started >= Config.PickSeconds then
            record.picking = nil
            local root = validPlayer(picking.player)
            if
                root
                and record.locked
                and not record.broken
                and picking.player.Team == Teams.Invaders
                and (root.Position - record.collider.Position).Magnitude <= Config.InteractionDistance + 1
            then
                -- no lock sound, picking is meant to be quiet
                record.locked = false
                publish(record)
                notify(picking.player, "Lock picked")
            else
                notify(picking.player, "Lock pick interrupted")
            end
        end
        local motion = record.motion
        if motion then
            local alpha = math.clamp((now - motion.started) / MOVE_SECONDS, 0, 1)
            local eased = alpha * alpha * (3 - 2 * alpha)
            local fraction = motion.from + (motion.to - motion.from) * eased
            if not poseClear(record, fraction) then
                record.motion = nil
                record.open = record.fraction > 0.01
                notify(motion.player, "Door movement stopped: doorway blocked.")
                publish(record)
            else
                place(record, fraction)
                if alpha == 1 then
                    record.motion = nil
                    record.open = motion.to == 1
                    publish(record)
                end
            end
        end
    end
end)
local damageDoor = Instance.new("BindableFunction")
damageDoor.Name = "DamageDoor"
damageDoor.OnInvoke = function(player, model, damage)
    local record = records[model]
    if
        not record
        or record.broken
        or record.open
        or record.motion
        or not validPlayer(player)
        or player.Team ~= Teams.Invaders
        or state:GetAttribute("Phase") ~= "Active"
        or typeof(damage) ~= "number"
        or damage ~= damage
        or math.abs(damage) == math.huge
        or damage <= 0
    then
        return nil
    end
    record.health = math.max(0, record.health - damage)
    if record.health == 0 then
        record.broken = true
        record.locked = false
        record.collider.CanCollide = false
        record.collider.CanQuery = false
        record.collider.BreachSound:Play()
        for part in record.parts do
            if part.Parent then
                part.Transparency = 1
            end
        end
    end
    publish(record)
    return record.health
end
damageDoor.Parent = script.Parent
local function resetDoors()
    for _, record in records do
        record.motion = nil
        record.picking = nil
        record.locked, record.open, record.broken = false, false, false
        record.health = Config.DoorHealth
        record.angle = record.defaultAngle
        place(record, 0)
        record.collider.CanCollide = true
        record.collider.CanQuery = true
        for part, transparency in record.parts do
            if part.Parent then
                part.Transparency = transparency
            end
        end
        publish(record)
    end
end
state:GetAttributeChangedSignal("Phase"):Connect(function()
    local phase = state:GetAttribute("Phase")
    if phase ~= "Preparation" and phase ~= "Active" then
        resetDoors()
    end
end)
state:GetAttributeChangedSignal("RoundId"):Connect(resetDoors)
Players.PlayerRemoving:Connect(function(player)
    lastInteraction[player] = nil
end)
