local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local state = ReplicatedStorage:WaitForChild("HomeInvasionRoundState")

local gui = player:WaitForChild("PlayerGui"):WaitForChild("HomeInvasionRoundHUD")
local label = gui:WaitForChild("RoundStatus")

local function refresh()
    local phase = state:GetAttribute("Phase") or "Waiting"
    local message = state:GetAttribute("Message") or "Waiting for players"
    local seconds = state:GetAttribute("SecondsRemaining") or 0
    local role = player:GetAttribute("RoundRole") or "Lobby"
    if phase == "Preparation" then
        if role == "Protectors" then
            message = "Preparation: find weapons and barricade"
        elseif role == "Invaders" then
            message = "Wait outside. Invasion starts in"
        else
            message = "Round preparation in progress"
        end
    end
    if phase == "Active" then
        if role == "Protectors" then
            message = "Survive until time runs out, or eliminate the invaders"
        elseif role == "Invaders" then
            message = "Eliminate every protector before time runs out"
        end
    end
    if (phase == "Preparation" or phase == "Active") and role == "Lobby" then
        if player:GetAttribute("EliminatedRoundId") == state:GetAttribute("RoundId") then
            message = "You were eliminated. Spectate the remaining players or wait in the lobby"
        else
            message = "Round in progress. You will join the next round"
        end
    end
    if phase == "Waiting" then
        message ..= string.format(" (%d/%d)", state:GetAttribute("PlayerCount") or 0,
            state:GetAttribute("MinimumPlayers") or 11)
    elseif seconds > 0 then
        message ..= string.format(" | %d:%02d", math.floor(seconds / 60), seconds % 60)
    end
    if state:GetAttribute("StudioSoloRound") then
        message = "[STUDIO SOLO] " .. message
    end
    label.Text = message .. "\n" .. role
    if phase == "Active" or phase == "Preparation" then
        label.Text ..= string.format(" | Invaders: %d | Protectors: %d",
            state:GetAttribute("InvadersAlive") or 0, state:GetAttribute("ProtectorsAlive") or 0)
    elseif phase == "Results" and state:GetAttribute("ResultRoundId") then
        label.Text ..= string.format(" | Final survivors: %d invaders, %d protectors",
            state:GetAttribute("FinalInvadersAlive") or 0,
            state:GetAttribute("FinalProtectorsAlive") or 0)
    end
end

state.AttributeChanged:Connect(refresh)
player:GetAttributeChangedSignal("RoundRole"):Connect(refresh)
player:GetAttributeChangedSignal("EliminatedRoundId"):Connect(refresh)
refresh()
