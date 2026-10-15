local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")

local player = Players.LocalPlayer
local state = ReplicatedStorage:WaitForChild("HomeInvasionRoundState")
local gui = player:WaitForChild("PlayerGui"):WaitForChild("SpectatorHUD")
local panel = gui:WaitForChild("Controls")
local targetLabel = panel:WaitForChild("Target")
local previousButton = panel:WaitForChild("Previous")
local nextButton = panel:WaitForChild("Next")
local toggleButton = panel:WaitForChild("Toggle")

local watching = false
local wasEligible = false
local targetPlayer = nil
local selectedIndex = 1
local savedCameraSettings = nil

local function canSpectate()
    local phase = state:GetAttribute("Phase")
    return (phase == "Active" or phase == "Preparation")
        and player:GetAttribute("InRound") == false
        and player:GetAttribute("EliminatedRoundId") == state:GetAttribute("RoundId")
        and player.Team == Teams.Lobby
end

local function livingTargets()
    local targets = {}
    for _, candidate in ipairs(Players:GetPlayers()) do
        local character = candidate.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if candidate ~= player and candidate.Parent == Players
            and candidate:GetAttribute("InRound") == true
            and candidate:GetAttribute("ParticipantRoundId") == state:GetAttribute("RoundId")
            and (candidate.Team == Teams.Invaders or candidate.Team == Teams.Protectors)
            and humanoid and humanoid.Health > 0
            and character:FindFirstChild("HumanoidRootPart") then
            table.insert(targets, {
                player = candidate,
                humanoid = humanoid,
                label = candidate.DisplayName .. " (" .. candidate.Team.Name .. ")",
            })
        end
    end
    table.sort(targets, function(left, right)
        return left.player.UserId < right.player.UserId
    end)
    return targets
end

local function restoreCamera()
    local camera = workspace.CurrentCamera
    if savedCameraSettings then
        player.CameraMode = savedCameraSettings.mode
        player.CameraMinZoomDistance = savedCameraSettings.minimumZoom
        player.CameraMaxZoomDistance = savedCameraSettings.maximumZoom
        savedCameraSettings = nil
    end
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if camera then
        camera.CameraType = Enum.CameraType.Custom
        if humanoid then
            camera.CameraSubject = humanoid
        end
    end
    targetPlayer = nil
    gui:SetAttribute("WatchingTargetUserId", nil)
end

local function followTarget(target)
    local camera = workspace.CurrentCamera
    if not camera then return end
    if not savedCameraSettings then
        savedCameraSettings = {
            mode = player.CameraMode,
            minimumZoom = player.CameraMinZoomDistance,
            maximumZoom = player.CameraMaxZoomDistance,
        }
        player.CameraMode = Enum.CameraMode.Classic
        player.CameraMaxZoomDistance = math.max(player.CameraMaxZoomDistance, 18)
        player.CameraMinZoomDistance = 6
    end
    camera.CameraType = Enum.CameraType.Custom
    camera.CameraSubject = target.humanoid
    targetPlayer = target.player
    gui:SetAttribute("WatchingTargetUserId", target.player.UserId)
end

local function refresh(direction)
    local eligible = canSpectate()
    if eligible and not wasEligible then
        watching = true
        selectedIndex = 1
    end
    wasEligible = eligible
    gui.Enabled = eligible
    if not eligible then
        watching = false
        if savedCameraSettings then restoreCamera() end
        targetPlayer = nil
        return
    end

    local targets = livingTargets()
    local currentIndex = nil
    for index, target in ipairs(targets) do
        if target.player == targetPlayer then currentIndex = index; break end
    end
    selectedIndex = currentIndex or math.clamp(selectedIndex, 1, math.max(1, #targets))
    if direction and #targets > 0 then
        selectedIndex = (selectedIndex - 1 + direction) % #targets + 1
        watching = true
    end

    previousButton.Active = #targets > 1
    nextButton.Active = #targets > 1
    previousButton.AutoButtonColor = #targets > 1
    nextButton.AutoButtonColor = #targets > 1
    toggleButton.Text = watching and "Return to lobby view" or "Watch round"
    if not watching then
        if savedCameraSettings then restoreCamera() end
        targetLabel.Text = "Lobby view | " .. #targets .. " players to watch"
        return
    end

    local target = targets[selectedIndex]
    if not target then
        if savedCameraSettings then restoreCamera() end
        targetLabel.Text = "No living players available"
        return
    end
    followTarget(target)
    targetLabel.Text = string.format("%s | %d / %d", target.label, selectedIndex, #targets)
end

previousButton.Activated:Connect(function() refresh(-1) end)
nextButton.Activated:Connect(function() refresh(1) end)
toggleButton.Activated:Connect(function()
    watching = not watching
    refresh()
end)

-- recheck who's watchable after deaths, leaves and respawns. running it 4x a second
-- also fixes the camera when roblox resets it after a lobby respawn
local accumulatedSeconds = 0
RunService.Heartbeat:Connect(function(deltaTime)
    accumulatedSeconds += deltaTime
    if accumulatedSeconds >= 0.25 then
        accumulatedSeconds = 0
        refresh()
    end
end)
state:GetAttributeChangedSignal("Phase"):Connect(function() refresh() end)
state:GetAttributeChangedSignal("RoundId"):Connect(function() refresh() end)
player:GetAttributeChangedSignal("InRound"):Connect(function() refresh() end)
player:GetAttributeChangedSignal("EliminatedRoundId"):Connect(function() refresh() end)
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() refresh() end)
refresh()
