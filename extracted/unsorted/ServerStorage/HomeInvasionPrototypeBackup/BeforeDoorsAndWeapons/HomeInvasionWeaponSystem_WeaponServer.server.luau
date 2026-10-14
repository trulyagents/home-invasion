-- NOTE: was Disabled in Studio
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Teams = game:GetService("Teams")

local Config = require(script.Parent.Config)
local roundState = ReplicatedStorage:WaitForChild("HomeInvasionRoundState")
local remote = ReplicatedStorage.HomeInvasionWeapons:WaitForChild("Interaction")
local arena = workspace:WaitForChild("HomeInvasionPrototype")
local markers = arena:WaitForChild("WeaponSpawns")
local dropsFolder = arena:WaitForChild("WeaponPickups")
local templates = ServerStorage:WaitForChild("HomeInvasionWeaponTemplates")
local random = Random.new()
local furnitureFolder = arena:WaitForChild("Furniture")
local damageBarricade = game.ServerScriptService.HomeInvasionFurnitureSystem
    :WaitForChild("DamageBarricade")

local drops = {}
local weaponRecords = {}
local playerConnections = {}
local requestBudgets = {}
local spawnedRoundId = nil
local invaderLoadoutRounds = {}

local function livingCharacter(player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if player.Parent ~= Players or not humanoid or humanoid.Health <= 0 or not root then
        return nil, nil, nil
    end
    return character, humanoid, root
end

local function isParticipant(player)
    return player:GetAttribute("InRound") == true
        and (player.Team == Teams.Protectors or player.Team == Teams.Invaders)
end

local function notify(player, message)
    if player.Parent == Players then
        remote:FireClient(player, "Notice", message)
    end
end

local function updateDropCount()
    local count = 0
    for _ in pairs(drops) do
        count += 1
    end
    roundState:SetAttribute("WeaponsRemaining", count)
end

local function consumeRequest(player)
    local now = os.clock()
    local budget = requestBudgets[player]
    if not budget then
        budget = { tokens = Config.RequestBurst, time = now }
        requestBudgets[player] = budget
    end
    budget.tokens = math.min(Config.RequestBurst,
        budget.tokens + (now - budget.time) * Config.RequestsPerSecond)
    budget.time = now
    if budget.tokens < 1 then
        return false
    end
    budget.tokens -= 1
    return true
end

local function removeWeapon(tool)
    local record = weaponRecords[tool]
    if not record then
        return
    end
    weaponRecords[tool] = nil
    record.reloadToken += 1
    record.ancestryConnection:Disconnect()
    tool:Destroy()
end

local function clearPlayerWeapons(player)
    local owned = {}
    for tool, record in pairs(weaponRecords) do
        if record.owner == player then
            table.insert(owned, tool)
        end
    end
    for _, tool in ipairs(owned) do
        removeWeapon(tool)
    end
end

local function clearRoundWeapons()
    for model in pairs(drops) do
        drops[model] = nil
        model:Destroy()
    end
    local tools = {}
    for tool in pairs(weaponRecords) do
        table.insert(tools, tool)
    end
    for _, tool in ipairs(tools) do
        removeWeapon(tool)
    end
    updateDropCount()
end

local function spawnRoundWeapons()
    local roundId = roundState:GetAttribute("RoundId")
    if not roundId or roundId <= 0 or spawnedRoundId == roundId then
        return
    end
    clearRoundWeapons()
    local availableMarkers = markers:GetChildren()
    table.sort(availableMarkers, function(left, right) return left.Name < right.Name end)
    for index = #availableMarkers, 2, -1 do
        local swapIndex = random:NextInteger(1, index)
        availableMarkers[index], availableMarkers[swapIndex] =
            availableMarkers[swapIndex], availableMarkers[index]
    end
    local markerIndex = 0
    for _, weaponId in ipairs({ "Rifle", "Crowbar" }) do
        local definition = Config.Weapons[weaponId]
        for _ = 1, definition.SpawnCount do
            markerIndex += 1
            local marker = availableMarkers[markerIndex]
            assert(marker, "Not enough house weapon spawn markers")
            local model = Instance.new("Model")
            model.Name = definition.DisplayName .. " Pickup"
            for _, child in ipairs(templates[weaponId]:GetChildren()) do
                child:Clone().Parent = model
            end
            model.PrimaryPart = model.Handle
            for _, item in ipairs(model:GetDescendants()) do
                if item:IsA("BasePart") then
                    item.Anchored = true
                    item.CanCollide = false
                    item.CanTouch = false
                end
            end
            model:PivotTo(marker.CFrame * CFrame.Angles(math.rad(90), 0, 0))
            local boxCFrame, boxSize = model:GetBoundingBox()
            local verticalHalfExtent = (
                math.abs(boxCFrame.RightVector.Y) * boxSize.X
                + math.abs(boxCFrame.UpVector.Y) * boxSize.Y
                + math.abs(boxCFrame.LookVector.Y) * boxSize.Z
            ) / 2
            local verticalOffset = marker.Position.Y + 0.08
                - (boxCFrame.Position.Y - verticalHalfExtent)
            model:PivotTo(model:GetPivot() + Vector3.new(0, verticalOffset, 0))
            model:SetAttribute("WeaponPickup", true)
            model:SetAttribute("WeaponId", weaponId)
            model:SetAttribute("SpawnMarker", marker.Name)
            model:SetAttribute("RoundId", roundId)
            local prompt = Instance.new("ProximityPrompt")
            prompt.Name = "WeaponPickupPrompt"
            prompt.ObjectText = definition.DisplayName
            prompt.ActionText = "Pick up"
            prompt.KeyboardKeyCode = Enum.KeyCode.F
            prompt.GamepadKeyCode = Enum.KeyCode.ButtonY
            prompt.HoldDuration = 0.2
            prompt.MaxActivationDistance = Config.PickupDistance
            prompt.RequiresLineOfSight = true
            prompt.Parent = model.Handle
            drops[model] = { weaponId = weaponId, roundId = roundId }
            model.Parent = dropsFolder
        end
    end
    spawnedRoundId = roundId
    updateDropCount()
end

local function grantWeapon(player, weaponId, roundId, displayName)
    local character = livingCharacter(player)
    local backpack = player:FindFirstChildOfClass("Backpack")
    if not character or not backpack then
        return nil
    end
    local tool = templates[weaponId]:Clone()
    local definition = Config.Weapons[weaponId]
    tool.Name = displayName or definition.DisplayName
    local record = {
        owner = player,
        character = character,
        weaponId = weaponId,
        roundId = roundId,
        ammo = definition.MagazineSize or 0,
        reserve = definition.ReserveAmmo or 0,
        nextAttack = 0,
        reloading = false,
        reloadToken = 0,
        originalGrip = tool.Grip,
    }
    weaponRecords[tool] = record
    tool:SetAttribute("RoundId", record.roundId)
    tool:SetAttribute("Ammo", record.ammo)
    tool:SetAttribute("ReserveAmmo", record.reserve)
    tool:SetAttribute("Reloading", false)
    record.ancestryConnection = tool.AncestryChanged:Connect(function()
        if tool.Parent ~= player.Character and record.reloading then
            record.reloadToken += 1
            record.reloading = false
            tool:SetAttribute("Reloading", false)
        end
        local currentBackpack = player:FindFirstChildOfClass("Backpack")
        if tool.Parent ~= currentBackpack and tool.Parent ~= player.Character then
            removeWeapon(tool)
        end
    end)
    tool.Parent = backpack
    return tool
end

local function grantInvaderLoadouts()
    local roundId = roundState:GetAttribute("RoundId")
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Team == Teams.Invaders and isParticipant(player)
            and livingCharacter(player) and invaderLoadoutRounds[player] ~= roundId then
            -- Grant once per admitted player, never on respawn or Active transitions.
            invaderLoadoutRounds[player] = roundId
            for _, item in ipairs(Config.InvaderLoadout) do
                grantWeapon(player, item.WeaponId, roundId, item.DisplayName)
            end
        end
    end
end

local function pickUp(player, model)
    if typeof(model) ~= "Instance" then
        return
    end
    local drop = drops[model]
    local phase = roundState:GetAttribute("Phase")
    local character, _, root = livingCharacter(player)
    if not drop or model.Parent ~= dropsFolder
        or drop.roundId ~= roundState:GetAttribute("RoundId") then
        return
    end
    if not character or not isParticipant(player) or player.Team ~= Teams.Protectors
        or (phase ~= "Active" and phase ~= "Preparation") then
        notify(player, "Only living protectors can collect house weapons during a round.")
        return
    end
    if player:GetAttribute("DraggingFurniture") then
        notify(player, "Drop the furniture before picking up a weapon.")
        return
    end
    if (root.Position - model.Handle.Position).Magnitude > Config.PickupDistance then
        notify(player, "Move closer to the weapon.")
        return
    end
    local sightParams = RaycastParams.new()
    sightParams.FilterType = Enum.RaycastFilterType.Exclude
    sightParams.FilterDescendantsInstances = { character, model }
    sightParams.RespectCanCollide = true
    if workspace:Raycast(root.Position, model.Handle.Position - root.Position, sightParams) then
        notify(player, "You cannot pick up a weapon through an obstacle.")
        return
    end
    local ownedCount = 0
    for _, record in pairs(weaponRecords) do
        if record.owner == player then
            ownedCount += 1
            if record.weaponId == drop.weaponId then
                notify(player, "You already have this weapon type.")
                return
            end
        end
    end
    if ownedCount >= Config.MaximumWeapons then
        notify(player, "Your weapon inventory is full.")
        return
    end
    local backpack = player:FindFirstChildOfClass("Backpack")
    if not backpack then
        return
    end
    -- Claim and grant without yielding so two requests cannot collect one pickup.
    local tool = grantWeapon(player, drop.weaponId, drop.roundId)
    if not tool then
        return
    end
    drops[model] = nil
    model.Handle.WeaponPickupPrompt.Enabled = false
    model:Destroy()
    updateDropCount()
    notify(player, "Picked up " .. tool.Name)
end

local function canUseWeapon(player, tool)
    if typeof(tool) ~= "Instance" then
        return nil, nil, nil
    end
    local record = weaponRecords[tool]
    local character, _, root = livingCharacter(player)
    if not record or record.owner ~= player or record.character ~= character
        or tool.Parent ~= character or not isParticipant(player)
        or roundState:GetAttribute("Phase") ~= "Active"
        or record.roundId ~= roundState:GetAttribute("RoundId")
        or player:GetAttribute("DraggingFurniture") then
        return nil, nil, nil
    end
    return record, character, root
end

local function enemyHumanoid(attacker, model)
    if not model or model == attacker.Character then
        return nil
    end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return nil
    end
    local targetPlayer = Players:GetPlayerFromCharacter(model)
    if targetPlayer then
        if not isParticipant(targetPlayer) or targetPlayer.Team == attacker.Team then
            return nil
        end
    elseif not (RunService:IsStudio() and model:GetAttribute("StudioWeaponTestTarget") == true
        and model:GetAttribute("TestTeam") ~= attacker.Team.Name) then
        return nil
    end
    return humanoid
end

local function findCharacter(part)
    local ancestor = part
    while ancestor and ancestor ~= workspace do
        if ancestor:IsA("Model") and ancestor:FindFirstChildOfClass("Humanoid") then
            return ancestor
        end
        ancestor = ancestor.Parent
    end
    return nil
end

local function dealDamage(player, humanoid, damage)
    local previousTag = humanoid:FindFirstChild("creator")
    if previousTag then
        previousTag:Destroy()
    end
    local creator = Instance.new("ObjectValue")
    creator.Name = "creator"
    creator.Value = player
    creator.Parent = humanoid
    Debris:AddItem(creator, 5)
    humanoid:TakeDamage(damage)
end

local function nearestBarricade(player, character, root, definition)
    if player.Team ~= Teams.Invaders then
        return nil, math.huge
    end
    local nearestModel = nil
    local nearestDistance = math.huge
    for _, model in ipairs(furnitureFolder:GetChildren()) do
        local collider = model:FindFirstChild("DragCollider")
        if collider and collider:IsA("BasePart")
            and model:GetAttribute("BarricadeBroken") == false then
            -- Measure reach to the surface, so wide tables can be hit at either end.
            local localPosition = collider.CFrame:PointToObjectSpace(root.Position)
            local halfSize = collider.Size / 2
            local closestLocal = Vector3.new(
                math.clamp(localPosition.X, -halfSize.X, halfSize.X),
                math.clamp(localPosition.Y, -halfSize.Y, halfSize.Y),
                math.clamp(localPosition.Z, -halfSize.Z, halfSize.Z)
            )
            local closestPoint = collider.CFrame:PointToWorldSpace(closestLocal)
            local offset = closestPoint - root.Position
            local distance = offset.Magnitude
            if distance > 0.01 and distance <= definition.Range
                and distance < nearestDistance
                and offset.Unit:Dot(root.CFrame.LookVector) >= definition.MinimumFacingDot then
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                params.FilterDescendantsInstances = { character, model }
                params.RespectCanCollide = true
                if not workspace:Raycast(root.Position, offset, params) then
                    nearestModel = model
                    nearestDistance = distance
                end
            end
        end
    end
    return nearestModel, nearestDistance
end

local function attack(player, tool, direction)
    local record, character, root = canUseWeapon(player, tool)
    if not record or record.reloading or os.clock() < record.nextAttack then
        return
    end
    local definition = Config.Weapons[record.weaponId]
    if record.weaponId == "Rifle" then
        if typeof(direction) ~= "Vector3" or direction.X ~= direction.X
            or direction.Y ~= direction.Y or direction.Z ~= direction.Z
            or direction.Magnitude < 0.9 or direction.Magnitude > 1.1 then
            return
        end
        if record.ammo <= 0 then
            notify(player, "Rifle empty. Press R to reload.")
            return
        end
        record.nextAttack = os.clock() + definition.AttackCooldown
        record.ammo -= 1
        tool:SetAttribute("Ammo", record.ammo)
        local head = character:FindFirstChild("Head")
        local origin = head and head.Position or root.Position
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { character, dropsFolder, markers }
        -- Queryable character parts can be hit even when they do not physically collide.
        params.RespectCanCollide = false
        local result = workspace:Raycast(origin, direction.Unit * definition.Range, params)
        local endpoint = result and result.Position or origin + direction.Unit * definition.Range
        if result then
            local humanoid = enemyHumanoid(player, findCharacter(result.Instance))
            if humanoid then
                dealDamage(player, humanoid, definition.Damage)
            end
        end
        remote:FireAllClients("Shot", origin, endpoint)
    else
        record.nextAttack = os.clock() + definition.AttackCooldown
        local params = OverlapParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { character }
        local checked = {}
        local nearestHumanoid = nil
        local nearestDistance = definition.Range + 1
        for _, part in ipairs(workspace:GetPartBoundsInRadius(root.Position, definition.Range, params)) do
            local model = findCharacter(part)
            if model and not checked[model] then
                checked[model] = true
                local targetRoot = model:FindFirstChild("HumanoidRootPart")
                local humanoid = enemyHumanoid(player, model)
                if targetRoot and humanoid then
                    local offset = targetRoot.Position - root.Position
                    if offset.Magnitude > 0.01 and offset.Magnitude <= definition.Range
                        and offset.Unit:Dot(root.CFrame.LookVector) >= definition.MinimumFacingDot then
                        local sightParams = RaycastParams.new()
                        sightParams.FilterType = Enum.RaycastFilterType.Exclude
                        sightParams.FilterDescendantsInstances = { character, model }
                        sightParams.RespectCanCollide = true
                        if not workspace:Raycast(root.Position, offset, sightParams)
                            and offset.Magnitude < nearestDistance then
                            nearestHumanoid = humanoid
                            nearestDistance = offset.Magnitude
                        end
                    end
                end
            end
        end
        local barricade, barricadeDistance = nearestBarricade(player, character, root, definition)
        -- A swing hits one target. A barricade in front takes priority over a person behind it.
        if barricade and barricadeDistance <= nearestDistance then
            local health = damageBarricade:Invoke(player, barricade, definition.BarricadeDamage)
            if health then
                notify(player, health == 0 and "Barricade broken!"
                    or string.format("%s: %d health left", barricade.Name, health))
            end
        elseif nearestHumanoid then
            dealDamage(player, nearestHumanoid, definition.Damage)
        end
        tool.Grip = record.originalGrip * CFrame.Angles(math.rad(-65), 0, 0)
        task.delay(0.18, function()
            if weaponRecords[tool] == record then
                tool.Grip = record.originalGrip
            end
        end)
    end
end

local function reload(player, tool)
    local record = canUseWeapon(player, tool)
    if not record or record.weaponId ~= "Rifle" or record.reloading then
        return
    end
    local definition = Config.Weapons.Rifle
    if record.ammo >= definition.MagazineSize or record.reserve <= 0 then
        return
    end
    record.reloading = true
    record.reloadToken += 1
    local token = record.reloadToken
    tool:SetAttribute("Reloading", true)
    task.delay(definition.ReloadSeconds, function()
        if weaponRecords[tool] ~= record or record.reloadToken ~= token then
            return
        end
        local currentRecord = canUseWeapon(player, tool)
        record.reloading = false
        tool:SetAttribute("Reloading", false)
        if currentRecord ~= record then
            return
        end
        local transferred = math.min(definition.MagazineSize - record.ammo, record.reserve)
        record.ammo += transferred
        record.reserve -= transferred
        tool:SetAttribute("Ammo", record.ammo)
        tool:SetAttribute("ReserveAmmo", record.reserve)
    end)
end

remote.OnServerEvent:Connect(function(player, action, item, direction)
    if not consumeRequest(player) then
        return
    end
    if action == "Pickup" then
        pickUp(player, item)
    elseif action == "Attack" then
        attack(player, item, direction)
    elseif action == "Reload" then
        reload(player, item)
    end
end)

local function setupPlayer(player)
    if playerConnections[player] then
        return
    end
    local connections = {}
    playerConnections[player] = connections
    local function characterAdded(character)
        clearPlayerWeapons(player)
        if connections.death then
            connections.death:Disconnect()
        end
        local humanoid = character:WaitForChild("Humanoid", 10)
        if humanoid and player.Character == character and player.Parent == Players then
            connections.death = humanoid.Died:Connect(function()
                clearPlayerWeapons(player)
            end)
        end
    end
    connections.character = player.CharacterAdded:Connect(characterAdded)
    if player.Character then
        task.spawn(characterAdded, player.Character)
    end
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(player)
    clearPlayerWeapons(player)
    local connections = playerConnections[player]
    if connections then
        for _, connection in pairs(connections) do
            connection:Disconnect()
        end
    end
    playerConnections[player] = nil
    requestBudgets[player] = nil
    invaderLoadoutRounds[player] = nil
end)
for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end

local function phaseChanged()
    local phase = roundState:GetAttribute("Phase")
    if phase == "Active" or phase == "Preparation" then
        spawnRoundWeapons()
        if phase == "Preparation" then
            grantInvaderLoadouts()
        end
    else
        clearRoundWeapons()
    end
end
roundState:GetAttributeChangedSignal("Phase"):Connect(phaseChanged)
phaseChanged()