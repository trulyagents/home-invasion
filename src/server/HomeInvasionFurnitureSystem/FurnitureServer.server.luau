local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")

local Config = require(script.Parent.Config)
local AnimationService = require(game.ServerScriptService.HomeInvasionAnimationSystem.AnimationService)
local furnitureFolder = workspace.HomeInvasionPrototype:WaitForChild("Furniture")
local roundState = ReplicatedStorage:WaitForChild("HomeInvasionRoundState")
local remote = ReplicatedStorage.HomeInvasionFurniture:WaitForChild("Interaction")

local furnitureRecords = {}
local sessions = {}
local requestBudgets = {}
local sessionSequence = 0

-- one reused probe, bounding boxes are too big for unions
local movementProbe = Instance.new("Part")
movementProbe.Name = "FurnitureMovementProbe"
movementProbe.Anchored = true
movementProbe.Transparency = 1
movementProbe.CanCollide = false
movementProbe.CanQuery = false
movementProbe.CanTouch = false
movementProbe.Parent = furnitureFolder

local function horizontal(vector)
    return Vector3.new(vector.X, 0, vector.Z)
end

local function isFinite(number)
    return number == number and math.abs(number) < math.huge
end

local function canInteract(player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local phase = roundState:GetAttribute("Phase")
    if
        player.Parent ~= Players
        or player.Team ~= Teams.Protectors
        or not player:GetAttribute("InRound")
        or (phase ~= "Active" and phase ~= "Preparation")
        or not humanoid
        or humanoid.Health <= 0
        or humanoid.Sit
        or not root
    then
        return nil, nil
    end
    return root, humanoid
end

local function notify(player, action, ...)
    if player.Parent == Players then
        remote:FireClient(player, action, ...)
    end
end

local function reject(player, reason)
    notify(player, "Rejected", reason)
end

local function settleFurniture(record, character)
    if record.broken or not record.model.Parent then
        return
    end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { record.model, character, movementProbe }
    params.RespectCanCollide = true
    local size = record.collider.Size - Vector3.one * Config.CollisionInset
    local hit = workspace:Blockcast(record.collider.CFrame, size, Vector3.new(0, -6, 0), params)
    if hit and hit.Distance > 0.01 then
        record.model:PivotTo(
            record.model:GetPivot() - Vector3.new(0, math.max(0, hit.Distance - Config.GroundClearance), 0)
        )
    end
end

local function release(player, reason)
    local session = sessions[player]
    if not session then
        return
    end
    sessions[player] = nil
    local record = session.record
    record.holder = nil
    if record.model.Parent == furnitureFolder then
        record.model:SetAttribute("DraggedByUserId", 0)
        record.prompt.Enabled = false
    end
    -- avoid overwriting a speed change made by a different system while dragging
    if session.humanoid.Parent and session.humanoid.WalkSpeed == session.appliedWalkSpeed then
        session.humanoid.WalkSpeed = session.previousWalkSpeed
    end
    settleFurniture(record, session.character)
    AnimationService.stop(session.character, "Carry")
    player:SetAttribute("DraggingFurniture", nil)
    notify(player, "Dropped", reason)
end

local function consumeRequest(player)
    local now = os.clock()
    local budget = requestBudgets[player]
    if not budget then
        budget = { tokens = Config.RequestBurst, time = now }
        requestBudgets[player] = budget
    end
    budget.tokens =
        math.min(Config.RequestBurst, budget.tokens + (now - budget.time) * Config.RequestsPerSecond)
    budget.time = now
    if budget.tokens < 1 then
        return false
    end
    budget.tokens -= 1
    return true
end

local function grab(player, model, hitPosition)
    if typeof(model) ~= "Instance" then
        return
    end
    local record = furnitureRecords[model]
    if not record or record.broken or model.Parent ~= furnitureFolder then
        return
    end
    if
        hitPosition ~= nil
        and (
            typeof(hitPosition) ~= "Vector3"
            or not isFinite(hitPosition.X)
            or not isFinite(hitPosition.Y)
            or not isFinite(hitPosition.Z)
        )
    then
        return
    end
    if hitPosition then
        local localHit = record.collider.CFrame:PointToObjectSpace(hitPosition)
        local halfSize = record.collider.Size / 2 + Vector3.one * 0.5
        if
            math.abs(localHit.X) > halfSize.X
            or math.abs(localHit.Y) > halfSize.Y
            or math.abs(localHit.Z) > halfSize.Z
        then
            return
        end
    end
    local root, humanoid = canInteract(player)
    if not root then
        reject(player, "Only living protectors can drag furniture during a round.")
        return
    end
    if sessions[player] then
        reject(player, "Drop your current furniture first.")
        return
    end
    if record.holder then
        reject(player, "Another protector is dragging this piece.")
        return
    end

    local center = record.collider.Position
    if (root.Position - center).Magnitude > Config.GrabDistance then
        reject(player, "Move closer to the furniture.")
        return
    end
    local sightParams = RaycastParams.new()
    sightParams.FilterType = Enum.RaycastFilterType.Exclude
    sightParams.FilterDescendantsInstances = { model, player.Character }
    sightParams.RespectCanCollide = true
    if workspace:Raycast(root.Position, center - root.Position, sightParams) then
        reject(player, "You cannot grab furniture through a wall.")
        return
    end

    local offset = horizontal(center - root.Position)
    if offset.Magnitude < 0.1 then
        reject(player, "Stand beside the furniture before grabbing it.")
        return
    end
    sessionSequence += 1
    local _, yaw = model:GetPivot():ToOrientation()
    local dragSpeed = record.dragSpeed
    local previousWalkSpeed = humanoid.WalkSpeed
    local appliedWalkSpeed = math.min(previousWalkSpeed, dragSpeed)
    sessions[player] = {
        id = sessionSequence,
        roundId = roundState:GetAttribute("RoundId"),
        character = player.Character,
        humanoid = humanoid,
        previousWalkSpeed = previousWalkSpeed,
        appliedWalkSpeed = appliedWalkSpeed,
        record = record,
        direction = offset.Unit,
        targetPoint = center,
        grabOffset = hitPosition and model:GetPivot():PointToObjectSpace(hitPosition) or Vector3.zero,
        holdDistance = math.clamp(
            offset.Magnitude,
            math.max(
                Config.MinimumHoldDistance,
                horizontal(record.collider.Size).Magnitude / 2 + Config.PlayerClearance
            ),
            Config.MaximumHoldDistance
        ),
        targetYaw = yaw,
        lastInput = os.clock(),
        lastRotation = 0,
    }
    record.holder = player
    record.prompt.Enabled = false
    model:SetAttribute("DraggedByUserId", player.UserId)
    player:SetAttribute("DraggingFurniture", model.Name)
    humanoid.WalkSpeed = appliedWalkSpeed
    humanoid:UnequipTools()
    AnimationService.play(player.Character, "Carry", true)
    notify(player, "Grabbed", model, sessionSequence, sessions[player].grabOffset)
end

remote.OnServerEvent:Connect(function(player, action, sessionIdOrModel, value)
    -- letting go always works, even when rate limited, and an old grab can't drop a new one
    if action == "Drop" then
        local session = sessions[player]
        if session and session.id == sessionIdOrModel then
            release(player, "Dropped")
        end
        return
    end
    if not consumeRequest(player) then
        return
    end
    if action == "Grab" then
        grab(player, sessionIdOrModel, value)
        return
    end

    local session = sessions[player]
    if not session or session.id ~= sessionIdOrModel then
        return
    end
    if action == "Move" then
        if
            typeof(value) ~= "Vector3"
            or not isFinite(value.X)
            or not isFinite(value.Y)
            or not isFinite(value.Z)
        then
            return
        end
        local root = canInteract(player)
        if not root or (value - root.Position).Magnitude > Config.ReleaseDistance + 5 then
            return
        end
        session.targetPoint = value
        session.lastInput = os.clock()
    elseif action == "Aim" then
        if
            typeof(value) ~= "Vector3"
            or not isFinite(value.X)
            or not isFinite(value.Y)
            or not isFinite(value.Z)
            or math.abs(value.Y) > 0.01
        then
            return
        end
        local direction = horizontal(value)
        if direction.Magnitude < 0.9 or direction.Magnitude > 1.1 then
            return
        end
        session.direction = direction.Unit
        session.lastInput = os.clock()
    elseif action == "Rotate" then
        if value ~= -1 and value ~= 1 then
            return
        end
        local now = os.clock()
        if now - session.lastRotation < Config.RotationCooldownSeconds then
            return
        end
        session.lastRotation = now
        session.targetYaw += value * Config.RotationStepRadians
    end
end)

for _, model in furnitureFolder:GetChildren() do
    if model:IsA("Model") and model:FindFirstChild("DragCollider") then
        local collider = model.DragCollider
        local record = {
            model = model,
            collider = collider,
            prompt = collider.FurnitureDragPrompt,
            homePivot = model:GetPivot(),
            homeFloorY = collider.Position.Y - collider.Size.Y / 2 - Config.GroundClearance,
            dragSpeed = model:GetAttribute("FurnitureKind") == "Table" and Config.TableDragSpeed
                or Config.ChairDragSpeed,
            holder = nil,
            broken = false,
            maximumHealth = model:GetAttribute("FurnitureKind") == "Table" and Config.TableHealth
                or Config.ChairHealth,
            parts = {},
        }
        record.health = record.maximumHealth
        record.promptText = record.prompt.ObjectText
        for _, part in model:GetDescendants() do
            if part:IsA("BasePart") then
                record.parts[part] = {
                    transparency = part.Transparency,
                    canCollide = part.CanCollide,
                    canQuery = part.CanQuery,
                    canTouch = part.CanTouch,
                }
            end
        end
        model:SetAttribute("BarricadeHealth", record.health)
        model:SetAttribute("BarricadeMaxHealth", record.maximumHealth)
        model:SetAttribute("BarricadeBroken", false)
        furnitureRecords[model] = record
        model:SetAttribute("DraggedByUserId", 0)
    end
end

-- weaponServer already checked reach, facing and cooldown before calling this
local damageBarricade = Instance.new("BindableFunction")
damageBarricade.Name = "DamageBarricade"
damageBarricade.OnInvoke = function(player, model, damage)
    local record = furnitureRecords[model]
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if
        not record
        or record.broken
        or model.Parent ~= furnitureFolder
        or player.Parent ~= Players
        or player.Team ~= Teams.Invaders
        or player:GetAttribute("InRound") ~= true
        or roundState:GetAttribute("Phase") ~= "Active"
        or not humanoid
        or humanoid.Health <= 0
        or typeof(damage) ~= "number"
        or not isFinite(damage)
        or damage <= 0
    then
        return nil
    end

    record.health = math.max(0, record.health - damage)
    model:SetAttribute("BarricadeHealth", record.health)
    if record.health == 0 then
        record.broken = true
        if record.holder then
            release(record.holder, "Your barricade was broken")
        end
        model:SetAttribute("BarricadeBroken", true)
        record.prompt.Enabled = false
        for part in record.parts do
            if part.Parent then
                part.Transparency = 1
                part.CanCollide = false
                part.CanQuery = false
                part.CanTouch = false
            end
        end
    else
        record.prompt.ObjectText =
            string.format("%s (%d / %d)", record.promptText, record.health, record.maximumHealth)
    end
    return record.health
end
damageBarricade.Parent = script.Parent

local function resetFurniture()
    local holders = {}
    for player in sessions do
        table.insert(holders, player)
    end
    for _, player in holders do
        release(player, "Round ended")
    end
    for model, record in furnitureRecords do
        if model.Parent == furnitureFolder then
            record.broken = false
            record.health = record.maximumHealth
            for part, properties in record.parts do
                if part.Parent then
                    part.Transparency = properties.transparency
                    part.CanCollide = properties.canCollide
                    part.CanQuery = properties.canQuery
                    part.CanTouch = properties.canTouch
                end
            end
            record.prompt.Enabled = false
            record.prompt.ObjectText = record.promptText
            model:SetAttribute("BarricadeHealth", record.health)
            model:SetAttribute("BarricadeBroken", false)
            model:PivotTo(record.homePivot)
            model:SetAttribute("DraggedByUserId", 0)
        end
    end
end

roundState:GetAttributeChangedSignal("Phase"):Connect(function()
    local phase = roundState:GetAttribute("Phase")
    if phase ~= "Active" and phase ~= "Preparation" then
        resetFurniture()
    end
end)
roundState:GetAttributeChangedSignal("RoundId"):Connect(resetFurniture)
Players.PlayerRemoving:Connect(function(player)
    release(player, "Player left")
    requestBudgets[player] = nil
end)

local function movementParams(record, character)
    local castParams = RaycastParams.new()
    castParams.FilterType = Enum.RaycastFilterType.Exclude
    castParams.FilterDescendantsInstances = { record.model, character, movementProbe }
    castParams.RespectCanCollide = true
    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Exclude
    overlapParams.FilterDescendantsInstances = { record.model, character, movementProbe }
    overlapParams.RespectCanCollide = true
    overlapParams.MaxParts = 1
    return castParams, overlapParams
end

local function destinationClear(cframe, size, overlapParams)
    movementProbe.CFrame = cframe
    movementProbe.Size = size
    return #workspace:GetPartsInPart(movementProbe, overlapParams) == 0
end

local function slideMovement(current, size, translation, castParams, overlapParams)
    local candidate = current
    local remaining = translation
    for _ = 1, 2 do
        if remaining.Magnitude < 0.001 then
            break
        end
        local hit = workspace:Blockcast(candidate, size, remaining, castParams)
        if not hit then
            local destination = candidate + remaining
            if destinationClear(destination, size, overlapParams) then
                candidate = destination
            end
            break
        end

        local travel = remaining.Unit * math.max(0, hit.Distance - Config.ObstacleClearance)
        local destination = candidate + travel
        if destinationClear(destination, size, overlapParams) then
            candidate = destination
        end
        remaining -= travel
        -- slide along the wall instead of stopping
        remaining = remaining - hit.Normal * remaining:Dot(hit.Normal)
    end
    return candidate
end

-- furniture remains anchored. The server moves a solid collider after checking the
-- swept path and destination, so a client can't fling or teleport a barricade
local function stepSession(player, session, deltaTime)
    local root = canInteract(player)
    local record = session.record
    if
        not root
        or player.Character ~= session.character
        or record.model.Parent ~= furnitureFolder
        or roundState:GetAttribute("RoundId") ~= session.roundId
        or os.clock() - session.lastInput > Config.InputTimeoutSeconds
    then
        release(player, "Drag interrupted")
        return
    end

    local current = record.model:GetPivot()
    if (root.Position - current.Position).Magnitude > Config.ReleaseDistance then
        release(player, "Furniture is out of reach")
        return
    end
    local rotation = CFrame.Angles(0, session.targetYaw, 0)
    local target = session.targetPoint - rotation:VectorToWorldSpace(session.grabOffset)
    local relative = horizontal(target - root.Position)
    local minimumDistance = horizontal(record.collider.Size).Magnitude / 2 + Config.PlayerClearance
    local direction = relative.Magnitude > 0.01 and relative.Unit or horizontal(root.CFrame.LookVector).Unit
    local distance = math.clamp(relative.Magnitude, minimumDistance, Config.MaximumHoldDistance)
    target = Vector3.new(
        root.Position.X + direction.X * distance,
        target.Y,
        root.Position.Z + direction.Z * distance
    )
    local homeOffset = horizontal(target - record.homePivot.Position)
    if homeOffset.Magnitude > Config.MaximumTravelDistance then
        target = record.homePivot.Position + homeOffset.Unit * Config.MaximumTravelDistance
        target = Vector3.new(target.X, target.Y, target.Z)
    end

    local delta = target - current.Position
    local maximumStep = record.dragSpeed * deltaTime
    if delta.Magnitude > maximumStep then
        delta = delta.Unit * maximumStep
    end
    local nextPosition = current.Position + delta

    local groundExclusions = { furnitureFolder }
    for _, otherPlayer in Players:GetPlayers() do
        if otherPlayer.Character then
            table.insert(groundExclusions, otherPlayer.Character)
        end
    end
    local groundParams = RaycastParams.new()
    groundParams.FilterType = Enum.RaycastFilterType.Exclude
    groundParams.FilterDescendantsInstances = groundExclusions
    groundParams.RespectCanCollide = true
    local groundOrigin = Vector3.new(nextPosition.X, record.homeFloorY + 1.5, nextPosition.Z)
    local ground = workspace:Raycast(groundOrigin, Vector3.new(0, -3, 0), groundParams)
    if
        not ground
        or ground.Normal.Y < 0.9
        or math.abs(ground.Position.Y - record.homeFloorY) > Config.MaximumFloorChange
    then
        -- tell the player once, instead of the furniture just freezing
        if not session.floorBlocked then
            session.floorBlocked = true
            notify(player, "Blocked", "Furniture has to stay on this floor")
        end
        return
    end
    if session.floorBlocked then
        session.floorBlocked = false
        notify(player, "Blocked", nil)
    end
    local minimumY = ground.Position.Y + record.collider.Size.Y / 2 + Config.GroundClearance
    local maximumLift = record.model:GetAttribute("FurnitureKind") == "Table" and Config.MaximumTableLift
        or Config.MaximumChairLift
    nextPosition = Vector3.new(
        nextPosition.X,
        math.clamp(nextPosition.Y, minimumY, minimumY + maximumLift),
        nextPosition.Z
    )

    local colliderSize = record.collider.Size - Vector3.one * Config.CollisionInset
    local castParams, overlapParams = movementParams(record, player.Character)
    -- collision runs on the DragCollider box, which may not sit at the model pivot
    local colliderOffset = current:ToObjectSpace(record.collider.CFrame)
    local candidate = slideMovement(
        current * colliderOffset,
        colliderSize,
        nextPosition - current.Position,
        castParams,
        overlapParams
    ) * colliderOffset:Inverse()

    local _, currentYaw = current:ToOrientation()
    local yawDelta =
        math.atan2(math.sin(session.targetYaw - currentYaw), math.cos(session.targetYaw - currentYaw))
    local yawStep = math.clamp(
        yawDelta,
        -Config.RotationSpeedRadians * deltaTime,
        Config.RotationSpeedRadians * deltaTime
    )
    local rotationSteps = math.max(1, math.ceil(math.abs(yawStep) / Config.RotationCollisionStep))
    for index = 1, rotationSteps do
        local rotated = CFrame.new(candidate.Position)
            * CFrame.Angles(0, currentYaw + yawStep * index / rotationSteps, 0)
        if not destinationClear(rotated * colliderOffset, colliderSize, overlapParams) then
            break
        end
        candidate = rotated
    end
    record.model:PivotTo(candidate)
end

local accumulatedSeconds = 0
RunService.Heartbeat:Connect(function(deltaTime)
    accumulatedSeconds += deltaTime
    if accumulatedSeconds < Config.ServerStepSeconds then
        return
    end
    local stepSeconds = math.min(accumulatedSeconds, 0.05)
    accumulatedSeconds = 0
    for player, session in sessions do
        stepSession(player, session, stepSeconds)
    end
end)
