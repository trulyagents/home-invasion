local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")
local RunService = game:GetService("RunService")

local Config = require(script.Parent.Config)
local RoundRules = require(script.Parent.RoundRules)
local RoundShared = require(script.Parent.RoundShared)
local arena = workspace:WaitForChild("HomeInvasionPrototype")
local state = ReplicatedStorage:WaitForChild("HomeInvasionRoundState")
local lobbySpawn = arena.Lobby.Spawn
local random = Random.new()

local roster = {}
local playerConnections = {}
local spawnJobs = {}
local roundId = 0
local phase = "Waiting"
local livePlayerCount = Config.MinimumPlayers
local participantCount = 0
local soloRound = false

-- only ever works in studio, even if the config gets published with it on
local studioSoloEnabled = RunService:IsStudio() and Config.StudioSoloEnabled

local function getRequiredPlayerCount()
    if studioSoloEnabled and #Players:GetPlayers() == 1 then
        return 1
    end
    return livePlayerCount
end

local minimumPlayers = getRequiredPlayerCount()

Players.CharacterAutoLoads = false

-- Tells individual players about secret roles. Never broadcast.
local secretRoleRemote = state:FindFirstChild("SecretRole") or Instance.new("RemoteEvent")
secretRoleRemote.Name = "SecretRole"
secretRoleRemote.Parent = state

local function updateState(nextPhase, seconds, message)
    phase = nextPhase
    state:SetAttribute("Phase", nextPhase)
    state:SetAttribute("SecondsRemaining", seconds)
    state:SetAttribute("Message", message)
    state:SetAttribute("RoundId", roundId)
    state:SetAttribute("MinimumPlayers", minimumPlayers)
    state:SetAttribute("StudioSoloRound", soloRound)
    state:SetAttribute("PlayerCount", #Players:GetPlayers())
end

local function releaseInvader(player, entry)
    if entry and entry.heldRoot then
        if entry.heldRoot.Parent then
            entry.heldRoot.Anchored = entry.previousRootAnchored
        end
        entry.heldRoot = nil
        entry.previousRootAnchored = nil
    end
    player:SetAttribute("InvaderPreparationLocked", false)
end

local function holdInvader(player, entry, character)
    if entry.role ~= "Invaders" then
        return
    end
    local root = character:FindFirstChild("HumanoidRootPart")
    if root and not entry.heldRoot then
        -- anchor on the server, a client side movement lock is easy to get around
        entry.previousRootAnchored = root.Anchored
        entry.heldRoot = root
        root.Anchored = true
        player:SetAttribute("InvaderPreparationLocked", true)
    end
end

-- a newer spawn request replaces a pending one. one load at a time per player
local function requestSpawn(player)
    local job = spawnJobs[player]
    if not job then
        return
    end
    job.revision += 1
    if job.running then
        return
    end
    job.running = true

    task.spawn(function()
        local failures
        while player.Parent == Players do
            local revision = job.revision
            local entry = roster[player]
            player.Team = entry and Teams[entry.role] or Teams.Lobby
            player.Neutral = false
            player.RespawnLocation = entry and entry.spawn or lobbySpawn
            player:SetAttribute("RoundRole", entry and entry.role or "Lobby")
            player:SetAttribute("InRound", entry ~= nil)

            local success, failure = pcall(function()
                player:LoadCharacterAsync()
            end)
            if success and revision == job.revision then
                local character = player.Character
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                if entry and roster[player] == entry then
                    local root = character and character:FindFirstChild("HumanoidRootPart")
                    entry.ready = humanoid ~= nil and humanoid.Health > 0 and root ~= nil
                    if entry.ready then
                        holdInvader(player, entry, character)
                    end
                end
            elseif not success then
                warn("Character load failed for " .. player.Name .. ": " .. tostring(failure))
                -- Retry instead of leaving the player unready until the spawn timeout.
                failures = (failures or 0) + 1
                if failures < 3 and revision == job.revision then
                    task.wait(1)
                    continue
                end
            end

            if revision == job.revision then
                break
            end
        end
        job.running = false
    end)
end

local function sendToLobby(player)
    releaseInvader(player, roster[player])
    roster[player] = nil
    player.Team = Teams.Lobby
    player.Neutral = false
    player.RespawnLocation = lobbySpawn
    player:SetAttribute("InRound", false)
    player:SetAttribute("ParticipantRoundId", nil)
    player:SetAttribute("RoundRole", "Lobby")
    player:SetAttribute("Survivor", nil)
    player:SetAttribute("Mask", nil)
end

local function setupPlayer(player)
    if playerConnections[player] then
        return
    end
    spawnJobs[player] = { revision = 0, running = false }
    local connections = {}
    playerConnections[player] = connections
    sendToLobby(player)

    connections.character = player.CharacterAdded:Connect(function(character)
        if connections.death then
            connections.death:Disconnect()
            connections.death = nil
        end
        local humanoid = character:WaitForChild("Humanoid", 10)
        if not humanoid or player.Character ~= character or player.Parent ~= Players then
            return
        end
        connections.death = humanoid.Died:Connect(function()
            if player.Character ~= character then
                return
            end
            local entry = roster[player]
            if entry then
                player:SetAttribute("EliminatedRoundId", roundId)
                player:SetAttribute("LastRoundRole", entry.role)
            end
            sendToLobby(player)
            local job = spawnJobs[player]
            local revision = job and job.revision
            task.delay(Config.RespawnSeconds, function()
                if player.Parent == Players and spawnJobs[player] == job
                    and job.revision == revision and player.Character == character then
                    requestSpawn(player)
                end
            end)
        end)
    end)
    requestSpawn(player)
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(player)
    releaseInvader(player, roster[player])
    roster[player] = nil
    spawnJobs[player] = nil
    local connections = playerConnections[player]
    if connections then
        for _, connection in pairs(connections) do
            connection:Disconnect()
        end
    end
    playerConnections[player] = nil
end)
for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end

local function countSurvivors()
    local invaders, protectors, loyal = 0, 0, 0
    for player, entry in pairs(roster) do
        -- Still spawning counts as alive; once ready, require a living humanoid.
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        local alive = not entry.ready or (humanoid ~= nil and humanoid.Health > 0)
        if player.Parent == Players and alive then
            if entry.role == "Invaders" then
                invaders += 1
            else
                -- The public count includes the traitor so nobody can work out who it is.
                protectors += 1
                if not RoundShared.isTraitor(player) then
                    loyal += 1
                end
            end
        end
    end
    state:SetAttribute("InvadersAlive", invaders)
    state:SetAttribute("ProtectorsAlive", protectors)
    return invaders, protectors, loyal
end

local function eliminationResult()
    local invaders, _, loyal = countSurvivors()
    return RoundRules.eliminationResult(invaders, loyal, soloRound)
end

local function recordResult(result)
    -- Capture the final roster before lobby cleanup clears it.
    local invaders, protectors = countSurvivors()
    state:SetAttribute("WinnerTeam", result.winner)
    state:SetAttribute("ResultReason", result.reason)
    state:SetAttribute("ResultRoundId", roundId)
    state:SetAttribute("FinalInvadersAlive", invaders)
    state:SetAttribute("FinalProtectorsAlive", protectors)
    state:SetAttribute("TraitorName", RoundShared.traitor and RoundShared.traitor.DisplayName or nil)
end

local function returnEveryoneToLobby()
    for _, player in ipairs(Players:GetPlayers()) do
        sendToLobby(player)
        requestSpawn(player)
    end
    countSurvivors()
end

local function beginRound()
    local candidates = {}
    for _, player in ipairs(Players:GetPlayers()) do
        local job = spawnJobs[player]
        if job and not job.running then
            table.insert(candidates, player)
        end
    end
    soloRound = studioSoloEnabled and #Players:GetPlayers() == 1
    minimumPlayers = soloRound and 1 or livePlayerCount
    if #candidates < minimumPlayers then
        return false
    end
    participantCount = math.min(#candidates, Config.MaxInvaders + Config.MaxProtectors)
    local invaderCount = math.clamp(
        math.floor(participantCount / Config.PlayersPerInvader),
        1,
        Config.MaxInvaders
    )
    participantCount = math.min(participantCount, invaderCount + Config.MaxProtectors)

    for index = #candidates, 2, -1 do
        local swapIndex = random:NextInteger(1, index)
        candidates[index], candidates[swapIndex] = candidates[swapIndex], candidates[index]
    end
    roundId += 1
    state:SetAttribute("WinnerTeam", nil)
    state:SetAttribute("ResultReason", nil)
    state:SetAttribute("ResultRoundId", nil)
    state:SetAttribute("FinalInvadersAlive", nil)
    state:SetAttribute("FinalProtectorsAlive", nil)
    state:SetAttribute("TraitorName", nil)
    RoundShared.reset(roundId)
    local protectorList = {}
    for index = 1, participantCount do
        local player = candidates[index]
        local isInvader = index <= invaderCount
        local role = isInvader and "Invaders" or "Protectors"
        local spawnIndex = isInvader and index or index - invaderCount
        if soloRound then
            -- Alternate roles so repeated solo rounds exercise both sets of spawns.
            role = roundId % 2 == 1 and "Protectors" or "Invaders"
            spawnIndex = 1
        end
        player:SetAttribute("ParticipantRoundId", roundId)
        player:SetAttribute("EliminatedRoundId", nil)
        player:SetAttribute("LastRoundRole", role)
        if role == "Invaders" then
            player:SetAttribute("Mask", Config.Masks[(spawnIndex - 1) % #Config.Masks + 1])
        else
            table.insert(protectorList, player)
        end
        roster[player] = {
            role = role,
            spawn = arena.Spawns[role][tostring(spawnIndex)],
            ready = false,
        }
        requestSpawn(player)
    end

    -- Secret roles. Candidates are already shuffled, so the list order is random.
    if not soloRound and #protectorList >= Config.TraitorMinimumProtectors then
        RoundShared.traitor = table.remove(protectorList, 1)
    end
    RoundShared.survivor = protectorList[1]
    if RoundShared.survivor then
        RoundShared.survivor:SetAttribute("Survivor", true)
    end

    updateState("Starting", 0, "Spawning teams...")
    local deadline = os.clock() + Config.SpawnTimeoutSeconds
    repeat
        local readyCount = 0
        for _, entry in pairs(roster) do
            if entry.ready then
                readyCount += 1
            end
        end
        if readyCount == participantCount then
            local traitor = RoundShared.traitor
            if traitor then
                secretRoleRemote:FireClient(traitor, "Traitor")
                for player, entry in pairs(roster) do
                    if entry.role == "Invaders" then
                        secretRoleRemote:FireClient(player, "TraitorIs", traitor.DisplayName)
                    end
                end
            end
            return true
        end
        local invaders, protectors = countSurvivors()
        if invaders + protectors < participantCount then
            break
        end
        task.wait(0.2)
    until os.clock() >= deadline
    returnEveryoneToLobby()
    return false
end

local function runPreparation()
    local deadline = os.clock() + Config.PreparationSeconds
    while true do
        local result = eliminationResult()
        if result then
            return result
        end
        local seconds = math.max(0, math.ceil(deadline - os.clock()))
        if seconds == 0 then
            return nil
        end
        updateState("Preparation", seconds, "Protectors are preparing")
        task.wait(0.25)
    end
end

updateState("Waiting", 0, "Waiting for players")
countSurvivors()

while true do
    soloRound = false
    minimumPlayers = getRequiredPlayerCount()
    while #Players:GetPlayers() < minimumPlayers do
        updateState("Waiting", 0, "Waiting for players")
        task.wait(1)
        minimumPlayers = getRequiredPlayerCount()
    end

    -- Everyone should be standing in the lobby before the countdown starts.
    local loadDeadline = os.clock() + Config.SpawnTimeoutSeconds
    while os.clock() < loadDeadline do
        local loading = false
        for player, job in pairs(spawnJobs) do
            if job.running or not player.Character then
                loading = true
                break
            end
        end
        if not loading then
            break
        end
        updateState("Waiting", 0, "Loading players")
        task.wait(0.5)
    end

    local countdownComplete = true
    local intermissionSeconds = minimumPlayers == 1
        and Config.StudioSoloIntermissionSeconds or Config.IntermissionSeconds
    for seconds = intermissionSeconds, 1, -1 do
        if #Players:GetPlayers() < minimumPlayers or getRequiredPlayerCount() ~= minimumPlayers then
            countdownComplete = false
            break
        end
        updateState("Intermission", seconds, "Round starts soon")
        task.wait(1)
    end

    if countdownComplete and beginRound() then
        local result = runPreparation()
        if not result then
            result = RoundRules.timeExpiredResult(soloRound, Config.TimeoutWinner)
            local roundSeconds = soloRound and Config.StudioSoloRoundSeconds or Config.RoundSeconds
            local deadline = os.clock() + roundSeconds
            updateState("Active", roundSeconds, soloRound and "Studio solo test" or "Invasion in progress")
            for player, entry in pairs(roster) do
                releaseInvader(player, entry)
            end

            while true do
                if RoundShared.escapedRoundId == roundId and RoundShared.escapedBy then
                    result = RoundRules.escapeResult(RoundShared.escapedBy)
                    break
                end
                if RoundShared.helpArrivedRoundId == roundId then
                    result = RoundRules.helpArrivedResult()
                    break
                end
                local elimination = eliminationResult()
                if elimination then
                    result = elimination
                    break
                end
                local seconds = math.max(0, math.ceil(deadline - os.clock()))
                if seconds == 0 then
                    break
                end
                updateState("Active", seconds, soloRound and "Studio solo test" or "Invasion in progress")
                task.wait(0.25)
            end
        end
        recordResult(result)
        updateState("Results", Config.ResultsSeconds, result.message)
        returnEveryoneToLobby()
        for seconds = Config.ResultsSeconds, 1, -1 do
            updateState("Results", seconds, result.message)
            task.wait(1)
        end
    else
        updateState("Waiting", 0, "Waiting for all players to be ready")
        task.wait(1)
    end
end
