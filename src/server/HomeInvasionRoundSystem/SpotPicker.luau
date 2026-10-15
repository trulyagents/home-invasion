--!strict
-- Hands out the WeaponSpawns markers so weapons, objectives and task items never share
-- a spot. Weapons spawn first; everything else takes what's left.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local roundState = ReplicatedStorage:WaitForChild("HomeInvasionRoundState")
local arena = workspace:WaitForChild("HomeInvasionPrototype")
local markers = arena:WaitForChild("WeaponSpawns")
local random = Random.new()

local SpotPicker = {}

local claimed: { [string]: boolean } = {}
local claimedRound: any = nil

local function syncRound()
    local roundId = roundState:GetAttribute("RoundId")
    if roundId ~= claimedRound then
        claimedRound = roundId
        table.clear(claimed)
    end
end

-- Weapons go down at the start of preparation. Give them up to 3s so we don't steal a weapon spot.
local function waitForWeapons()
    local pickups = arena:FindFirstChild("WeaponPickups")
    local roundId = roundState:GetAttribute("RoundId")
    local deadline = os.clock() + 3
    while pickups and os.clock() < deadline do
        for _, pickup in pickups:GetChildren() do
            if pickup:GetAttribute("RoundId") == roundId then
                return
            end
        end
        task.wait(0.1)
    end
end

local function freeMarkers(): { BasePart }
    syncRound()
    local taken = {}
    local pickups = arena:FindFirstChild("WeaponPickups")
    for _, pickup in (pickups and pickups:GetChildren() or {}) do
        local marker = pickup:GetAttribute("SpawnMarker")
        if marker then
            taken[marker] = true
        end
    end
    local spots = {}
    for _, marker in markers:GetChildren() do
        if marker:IsA("BasePart") and not taken[marker.Name] and not claimed[marker.Name] then
            table.insert(spots, marker)
        end
    end
    return spots
end

local function playerPositions(): { Vector3 }
    local positions = {}
    for _, player in Players:GetPlayers() do
        local character = player.Character
        local root = player:GetAttribute("InRound") and character and character:FindFirstChild("HumanoidRootPart")
        if root and root:IsA("BasePart") then
            table.insert(positions, root.Position)
        end
    end
    return positions
end

-- Claims a free spot. With minDistance, prefers spots at least that far from every player
-- in the round, falling back to the farthest one. Returns nil when the house is full.
function SpotPicker.take(minDistance: number?): BasePart?
    waitForWeapons()
    local spots = freeMarkers()
    if #spots == 0 then
        return nil
    end
    local choice: BasePart
    if minDistance then
        local positions = playerPositions()
        local far, best, bestDistance = {}, spots[1], -1
        for _, spot in spots do
            local nearest = math.huge
            for _, position in positions do
                nearest = math.min(nearest, (spot.Position - position).Magnitude)
            end
            if nearest >= minDistance then
                table.insert(far, spot)
            end
            if nearest > bestDistance then
                best, bestDistance = spot, nearest
            end
        end
        choice = #far > 0 and far[random:NextInteger(1, #far)] or best
    else
        choice = spots[random:NextInteger(1, #spots)]
    end
    claimed[choice.Name] = true
    return choice
end

function SpotPicker.release(spot: BasePart?)
    if spot then
        claimed[spot.Name] = nil
    end
end

return SpotPicker
