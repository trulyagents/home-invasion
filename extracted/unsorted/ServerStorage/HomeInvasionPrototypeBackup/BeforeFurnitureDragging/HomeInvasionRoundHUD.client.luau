-- NOTE: was Disabled in Studio
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local state = ReplicatedStorage:WaitForChild("HomeInvasionRoundState")

local gui = Instance.new("ScreenGui")
gui.Name = "HomeInvasionRoundHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Name = "RoundStatus"
label.AnchorPoint = Vector2.new(0.5, 0)
label.Position = UDim2.new(0.5, 0, 0, 16)
label.Size = UDim2.new(0.8, 0, 0, 85)
label.BackgroundColor3 = Color3.fromRGB(20, 24, 30)
label.BackgroundTransparency = 0.15
label.TextColor3 = Color3.fromRGB(245, 245, 245)
label.TextSize = 18
label.Font = Enum.Font.GothamMedium
label.TextWrapped = true
label.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = label

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
