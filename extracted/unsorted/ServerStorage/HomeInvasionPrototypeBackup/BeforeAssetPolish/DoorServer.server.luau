local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local Config = require(script.Parent.Config)
local state = ReplicatedStorage:WaitForChild("HomeInvasionRoundState")
local doorsFolder = workspace.HomeInvasionPrototype:WaitForChild("Doors")
local weaponRemote = ReplicatedStorage.HomeInvasionWeapons:WaitForChild("Interaction")
local records = {}
local lastInteraction = {}

local probe = Instance.new("Part")
probe.Name = "DoorCloseProbe"
probe.Anchored = true
probe.Transparency = 1
probe.CanCollide = false
probe.CanTouch = false
probe.CanQuery = false
probe.Parent = doorsFolder

local function notify(player, message)
    if player.Parent == Players then
        weaponRemote:FireClient(player, "Notice", message)
    end
end

local function validPlayer(player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local phase = state:GetAttribute("Phase")
    if player.Parent ~= Players or player:GetAttribute("InRound") ~= true
        or (player.Team ~= Teams.Protectors and player.Team ~= Teams.Invaders)
        or (phase ~= "Active" and phase ~= "Preparation")
        or (player.Team == Teams.Invaders and phase ~= "Active")
        or not humanoid or humanoid.Health <= 0 or not root
        or player:GetAttribute("DraggingFurniture") then
        return nil
    end
    return root
end

local function publish(record)
    local model = record.model
    model:SetAttribute("DoorLocked", record.locked)
    model:SetAttribute("DoorOpen", record.open)
    model:SetAttribute("DoorBroken", record.broken)
    model:SetAttribute("DoorHealth", record.health)
    record.openPrompt.ActionText = record.open and "Close door" or "Open door"
    record.openPrompt.ObjectText = record.locked and "Locked door" or "House door"
    record.lockPrompt.ActionText = record.locked and "Unlock door" or "Lock door"
    record.lockPrompt.ObjectText = string.format("Door: %d / %d", record.health, Config.DoorHealth)
    record.openPrompt.Enabled = not record.broken
    record.lockPrompt.Enabled = not record.broken
end

local function moveLeaf(record, open)
    local pivot = open and record.openPivot or record.closedPivot
    if record.leaf:IsA("Model") then
        record.leaf:PivotTo(pivot)
    else
        record.leaf.CFrame = pivot
    end
    record.collider.CFrame = open and record.openCollider or record.closedCollider
    record.open = open
end

local function canClose(record)
    probe.Size = record.collider.Size - Vector3.one * Config.CollisionInset
    probe.CFrame = record.closedCollider
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { record.model, record.leaf, probe }
    params.RespectCanCollide = true
    params.MaxParts = 1
    return #workspace:GetPartsInPart(probe, params) == 0
end

local function interact(player, record, action)
    local root = validPlayer(player)
    if not root or record.broken then
        return
    end
    local now = os.clock()
    if now - (lastInteraction[player] or 0) < Config.InteractionCooldown then
        return
    end
    lastInteraction[player] = now
    if (root.Position - record.collider.Position).Magnitude > Config.InteractionDistance then
        return
    end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { player.Character, record.model, record.leaf }
    params.RespectCanCollide = true
    if workspace:Raycast(root.Position, record.collider.Position - root.Position, params) then
        return
    end

    if action == "Lock" then
        if player.Team ~= Teams.Protectors then
            return
        end
        if record.open then
            notify(player, "Close the door before locking it.")
            return
        end
        record.locked = not record.locked
    else
        if record.locked then
            notify(player, "Door locked. Protectors can unlock it; invaders must breach it.")
            return
        end
        if record.open and not canClose(record) then
            notify(player, "The doorway is blocked. Move the furniture or step aside.")
            return
        end
        moveLeaf(record, not record.open)
    end
    publish(record)
end

for _, model in ipairs(doorsFolder:GetChildren()) do
    if model:IsA("Model") then
        local leaf = model.OriginalLeaf.Value
        local collider = model.DoorCollider
        local record = {
            model = model,
            leaf = leaf,
            collider = collider,
            closedPivot = model:GetAttribute("ClosedPivot"),
            openPivot = model:GetAttribute("OpenPivot"),
            closedCollider = collider.CFrame,
            openCollider = model:GetAttribute("OpenCollider"),
            openPrompt = collider.DoorOpenPrompt,
            lockPrompt = collider.DoorLockPrompt,
            parts = {},
            locked = false,
            open = false,
            broken = false,
            health = Config.DoorHealth,
        }
        local parts = leaf:IsA("BasePart") and { leaf } or leaf:GetDescendants()
        for _, part in ipairs(parts) do
            if part:IsA("BasePart") then
                record.parts[part] = part.Transparency
            end
        end
        records[model] = record
        model:SetAttribute("DoorMaxHealth", Config.DoorHealth)
        publish(record)
        record.openPrompt.Triggered:Connect(function(player)
            interact(player, record, "Open")
        end)
        record.lockPrompt.Triggered:Connect(function(player)
            interact(player, record, "Lock")
        end)
    end
end

local damageDoor = Instance.new("BindableFunction")
damageDoor.Name = "DamageDoor"
damageDoor.OnInvoke = function(player, model, damage)
    local record = records[model]
    if not record or record.broken or record.open or not validPlayer(player)
        or player.Team ~= Teams.Invaders or state:GetAttribute("Phase") ~= "Active"
        or typeof(damage) ~= "number" or damage ~= damage or math.abs(damage) == math.huge
        or damage <= 0 then
        return nil
    end
    -- WeaponServer validates the registered crowbar, reach, facing and cooldown.
    record.health = math.max(0, record.health - damage)
    if record.health == 0 then
        record.broken = true
        record.locked = false
        record.collider.CanCollide = false
        record.collider.CanQuery = false
        for part in pairs(record.parts) do
            if part.Parent then part.Transparency = 1 end
        end
    end
    publish(record)
    return record.health
end
damageDoor.Parent = script.Parent

local function resetDoors()
    for _, record in pairs(records) do
        record.locked = false
        record.broken = false
        record.health = Config.DoorHealth
        moveLeaf(record, false)
        record.collider.CanCollide = true
        record.collider.CanQuery = true
        for part, transparency in pairs(record.parts) do
            if part.Parent then part.Transparency = transparency end
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
