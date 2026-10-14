-- The Survivor (one random Protector) can put down nail-board traps.
-- Traps only hurt Invaders, and each one goes off once.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local Config = require(script.Parent.Config)
local RoundShared = require(game.ServerScriptService:WaitForChild("HomeInvasionRoundSystem"):WaitForChild("RoundShared"))
local roundState = ReplicatedStorage:WaitForChild("HomeInvasionRoundState")
local arena = workspace:WaitForChild("HomeInvasionPrototype")

local folder = ReplicatedStorage:FindFirstChild("HomeInvasionTraps") or Instance.new("Folder")
folder.Name = "HomeInvasionTraps"
folder.Parent = ReplicatedStorage
local remote = folder:FindFirstChild("Interaction") or Instance.new("RemoteEvent")
remote.Name = "Interaction"
remote.Parent = folder

local trapFolder = Instance.new("Folder")
trapFolder.Name = "Traps"
trapFolder.Parent = arena

local placed = {} -- [player] = number placed this round
local lastPlaced = {}
local slowed = {}

local function notify(player, message)
    remote:FireClient(player, "Notice", message)
end

local function clearTraps()
    trapFolder:ClearAllChildren()
    table.clear(placed)
    for _, player in ipairs(Players:GetPlayers()) do
        player:SetAttribute("TrapsLeft", nil)
    end
end

local function slow(humanoid)
    if slowed[humanoid] then
        return
    end
    slowed[humanoid] = humanoid.WalkSpeed
    humanoid.WalkSpeed = Config.SlowWalkSpeed
    task.delay(Config.SlowSeconds, function()
        if humanoid.Parent then
            humanoid.WalkSpeed = slowed[humanoid]
        end
        slowed[humanoid] = nil
    end)
end

local function buildTrap(position)
    local board = Instance.new("Part")
    board.Name = "NailBoard"
    board.Size = Vector3.new(2.4, 0.15, 2.4)
    board.Color = Color3.fromRGB(95, 70, 45)
    board.Material = Enum.Material.Wood
    board.Anchored = true
    board.CanCollide = false
    board.CFrame = CFrame.new(position + Vector3.new(0, 0.08, 0))
    for i = 1, 9 do
        local nail = Instance.new("Part")
        nail.Name = "Nail"
        nail.Size = Vector3.new(0.06, 0.35, 0.06)
        nail.Color = Color3.fromRGB(150, 150, 155)
        nail.Material = Enum.Material.Metal
        nail.Anchored = true
        nail.CanCollide = false
        nail.CanTouch = false
        nail.CanQuery = false
        local x = ((i - 1) % 3 - 1) * 0.7
        local z = (math.floor((i - 1) / 3) - 1) * 0.7
        nail.CFrame = board.CFrame * CFrame.new(x, 0.2, z)
        nail.Parent = board
    end
    return board
end

local function placeTrap(player)
    local phase = roundState:GetAttribute("Phase")
    if RoundShared.survivor ~= player or not (phase == "Preparation" or phase == "Active") then
        return
    end
    local now = os.clock()
    if now - (lastPlaced[player] or 0) < Config.PlaceCooldown then
        return
    end
    local count = placed[player] or 0
    if count >= Config.MaxTraps then
        notify(player, "You're out of traps.")
        return
    end
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not root then
        return
    end

    -- Put the trap on the floor right in front of the player, using the server's position.
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { character, trapFolder }
    local origin = root.Position + root.CFrame.LookVector * 2.5
    local floor = workspace:Raycast(origin, Vector3.new(0, -8, 0), params)
    if not floor or floor.Normal.Y < 0.8 then
        notify(player, "You can't put a trap there.")
        return
    end

    lastPlaced[player] = now
    placed[player] = count + 1
    player:SetAttribute("TrapsLeft", Config.MaxTraps - placed[player])
    local trap = buildTrap(floor.Position)
    trap:SetAttribute("RoundId", RoundShared.roundId)
    trap.Parent = trapFolder

    local armedAt = os.clock() + Config.ArmDelay
    local connection
    connection = trap.Touched:Connect(function(part)
        if os.clock() < armedAt then
            return
        end
        local victim = Players:GetPlayerFromCharacter(part.Parent)
        local victimHumanoid = part.Parent and part.Parent:FindFirstChildOfClass("Humanoid")
        if not victim or victim.Team ~= Teams.Invaders or not victimHumanoid or victimHumanoid.Health <= 0 then
            return
        end
        connection:Disconnect()
        victimHumanoid:TakeDamage(Config.Damage)
        slow(victimHumanoid)
        notify(victim, "You stepped on a nail board.")
        trap:Destroy()
    end)
end

remote.OnServerEvent:Connect(function(player, action)
    if action == "Place" then
        placeTrap(player)
    end
end)

roundState:GetAttributeChangedSignal("Phase"):Connect(function()
    local phase = roundState:GetAttribute("Phase")
    if phase == "Preparation" then
        clearTraps()
        local survivor = RoundShared.survivor
        if survivor then
            survivor:SetAttribute("TrapsLeft", Config.MaxTraps)
        end
    elseif phase ~= "Active" then
        clearTraps()
    end
end)

Players.PlayerRemoving:Connect(function(player)
    placed[player] = nil
    lastPlaced[player] = nil
end)
