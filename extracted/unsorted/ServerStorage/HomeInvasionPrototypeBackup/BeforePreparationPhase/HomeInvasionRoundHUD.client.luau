-- NOTE: was Disabled in Studio
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
    if phase == "Active" then
        label.Text ..= string.format(" | Invaders: %d | Protectors: %d",
            state:GetAttribute("InvadersAlive") or 0, state:GetAttribute("ProtectorsAlive") or 0)
    end
end

state.AttributeChanged:Connect(refresh)
player:GetAttributeChangedSignal("RoundRole"):Connect(refresh)
refresh()
