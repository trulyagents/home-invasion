local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local state = ReplicatedStorage:WaitForChild("HomeInvasionRoundState")
local gui = player:WaitForChild("PlayerGui"):WaitForChild("HomeInvasionRoundHUD")
local helpRequested = false

local function refresh()
    local phase = state:GetAttribute("Phase") or "Waiting"
    local seconds = state:GetAttribute("SecondsRemaining") or 0
    local role = player:GetAttribute("RoundRole") or "Lobby"
    local phaseNames = {Waiting="LOBBY", Intermission="GET READY", Starting="JOINING THE HOUSE", Preparation="PREPARATION", Active="INVASION", Results="ROUND COMPLETE"}
    gui.Header.Phase.Text = phaseNames[phase] or phase:upper()
    gui.Header.Timer.Text = seconds > 0 and string.format("%d:%02d", math.floor(seconds / 60), seconds % 60) or "--:--"
    gui.Header.Timer.TextColor3 = phase == "Active" and seconds <= 30
        and Color3.fromRGB(237,108,88) or Color3.fromRGB(206,131,79)
    local message = state:GetAttribute("Message") or "Waiting for players"
    if phase == "Waiting" then
        message = string.format("Waiting for players: %d / %d", state:GetAttribute("PlayerCount") or 0, state:GetAttribute("MinimumPlayers") or 11)
    elseif phase == "Preparation" then
        message = role == "Protectors" and "Find weapons. Lock doors. Barricade the house."
            or role == "Invaders" and "Check your loadout. The house opens when preparation ends."
            or "The teams are preparing. You will join the next round."
    elseif phase == "Active" then
        message = role == "Protectors" and "Survive the timer or eliminate the invaders."
            or role == "Invaders" and "Breach the house and eliminate every protector."
            or player:GetAttribute("EliminatedRoundId") == state:GetAttribute("RoundId")
                and "You were eliminated. Spectate the remaining players or wait in the lobby."
            or "Round in progress. You will join the next round."
    end
    gui.RoundStatus.Text = message .. "\n" .. role .. "  •  H: controls"
    gui.Header.Alive.Text = (phase == "Preparation" or phase == "Active")
        and string.format("%d INVADERS  /  %d PROTECTORS", state:GetAttribute("InvadersAlive") or 0, state:GetAttribute("ProtectorsAlive") or 0)
        or state:GetAttribute("StudioSoloRound") and "STUDIO SOLO PREVIEW"
        or "3 INVADERS  /  8 PROTECTORS"
    local results = gui.Results
    results.Visible = phase == "Results"
    local winner = state:GetAttribute("WinnerTeam")
    results.Heading.Text = winner == "Invaders" and "THE HOUSE FELL"
        or winner == "Protectors" and "THE HOUSE SURVIVED"
        or winner == "StudioSolo" and "PREVIEW COMPLETE" or "ROUND OVER"
    results.Reason.Text = state:GetAttribute("ResultReason") == "TimeExpired"
        and "Time ran out. The protectors held the house."
        or state:GetAttribute("Message") or "Round complete."
    results.Survivors.Text = string.format("Survivors: %d invaders  •  %d protectors",
        state:GetAttribute("FinalInvadersAlive") or 0, state:GetAttribute("FinalProtectorsAlive") or 0)
    results.NextRound.Text = string.format("Next lobby countdown in %d seconds", seconds)
    gui.Help.Visible = phase ~= "Results" and helpRequested
    gui.Help.Body.Text = role == "Invaders"
        and "1 / 2 / 3: equip weapons\nClick: attack • R: reload\nRight mouse: aim\nCrowbar: breach doors and furniture\nE: open unlocked doors"
        or "F: collect a house weapon\nE: drag furniture or use a door\nQ / R: rotate held furniture\nE: drop • L: lock / unlock a door\n1 / 2 / 3: equip • click: attack\nR: reload • right mouse: aim"
end
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and not UserInputService:GetFocusedTextBox() and input.KeyCode == Enum.KeyCode.H then
        helpRequested = not helpRequested
        refresh()
    end
end)
state.AttributeChanged:Connect(refresh)
player.AttributeChanged:Connect(refresh)
refresh()
