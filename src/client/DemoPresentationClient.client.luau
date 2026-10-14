local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local state = ReplicatedStorage:WaitForChild("HomeInvasionRoundState")
local remote = ReplicatedStorage:WaitForChild("HomeInvasionWeapons"):WaitForChild("Interaction")
local gui = player:WaitForChild("PlayerGui"):WaitForChild("DemoFeedbackHUD")
local sounds = game:GetService("SoundService"):WaitForChild("HomeInvasionPresentation")
local help = player.PlayerGui:WaitForChild("HomeInvasionRoundHUD"):WaitForChild("Help")
local aiming = false
local savedCameraMode, savedFov
local aimCamera
local fovTween
local feedbackSequence = 0
local phaseSequence = 0
local previousPhase = state:GetAttribute("Phase")

local function rangedTool()
    local character = player.Character
    local tool = character and character:FindFirstChildOfClass("Tool")
    return tool
            and tool:GetAttribute("HomeInvasionWeapon")
            and tool:GetAttribute("AttackKind") == "Ranged"
            and tool
        or nil
end
local function setAim(value)
    local tool = rangedTool()
    value = value
        and tool ~= nil
        and state:GetAttribute("Phase") == "Active"
        and player:GetAttribute("InRound") == true
        and not help.Visible
        and not player:GetAttribute("DraggingFurniture")
    if aiming == value then
        return
    end
    aiming = value
    if fovTween then
        fovTween:Cancel()
    end
    if value then
        aimCamera = workspace.CurrentCamera
        savedFov = aimCamera.FieldOfView
        savedCameraMode = player.CameraMode
        player.CameraMode = Enum.CameraMode.LockFirstPerson
        fovTween = TweenService:Create(aimCamera, TweenInfo.new(0.15), { FieldOfView = 54 })
        fovTween:Play()
    else
        if savedCameraMode then
            player.CameraMode = savedCameraMode
        end
        if aimCamera and savedFov then
            fovTween = TweenService:Create(aimCamera, TweenInfo.new(0.15), { FieldOfView = savedFov })
            fovTween:Play()
        end
        savedCameraMode, savedFov, aimCamera = nil, nil, nil
    end
    gui.Aim.Text = aiming and "STOP AIM" or "AIM"
end
UserInputService.InputBegan:Connect(function(input, processed)
    if
        not processed
        and not UserInputService:GetFocusedTextBox()
        and input.UserInputType == Enum.UserInputType.MouseButton2
    then
        setAim(true)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        setAim(false)
    end
end)
gui.Aim.Activated:Connect(function()
    setAim(not aiming)
end)
help:GetPropertyChangedSignal("Visible"):Connect(function()
    if help.Visible then
        setAim(false)
    end
end)
player.CharacterRemoving:Connect(function()
    setAim(false)
end)
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    setAim(false)
end)
local elapsed = 0
RunService.RenderStepped:Connect(function(deltaTime)
    elapsed += deltaTime
    if elapsed < 0.05 then
        return
    end
    elapsed = 0
    local tool = rangedTool()
    local enabled = state:GetAttribute("Phase") == "Active"
        and player:GetAttribute("InRound") == true
        and tool ~= nil
        and not help.Visible
    gui.Reticle.Visible = enabled
    gui.Aim.Visible = enabled and UserInputService.TouchEnabled
    if aiming and not enabled then
        setAim(false)
    end
    local cursor = UserInputService:GetMouseLocation()
    gui.Reticle.Position = aiming and UDim2.fromScale(0.5, 0.5) or UDim2.fromOffset(cursor.X, cursor.Y)
end)
remote.OnClientEvent:Connect(function(action, first, second)
    if action ~= "Hit" then
        return
    end
    feedbackSequence += 1
    local sequence = feedbackSequence
    gui.HitMarker.Visible = true
    gui.HitText.Visible = true
    gui.HitText.Text = second and "ELIMINATED" or string.format("%d DAMAGE", math.floor(tonumber(first) or 0))
    sounds.HitCue:Play()
    task.delay(0.55, function()
        if sequence == feedbackSequence then
            gui.HitMarker.Visible = false
            gui.HitText.Visible = false
        end
    end)
end)
state:GetAttributeChangedSignal("Phase"):Connect(function()
    local phase = state:GetAttribute("Phase")
    phaseSequence += 1
    local sequence = phaseSequence
    gui.PhaseAnnouncement.Visible = false
    if phase ~= "Active" then
        setAim(false)
    end
    if phase == "Active" and previousPhase == "Preparation" then
        gui.PhaseAnnouncement.Text = "INVASION BEGINS"
        gui.PhaseAnnouncement.Visible = true
        sounds.InvasionCue:Play()
        task.delay(2.5, function()
            if phaseSequence == sequence then
                gui.PhaseAnnouncement.Visible = false
            end
        end)
    end
    previousPhase = phase
end)
sounds.NightAmbience:Play()

local function frameSpawn(character)
    task.spawn(function()
        local humanoid = character:WaitForChild("Humanoid", 10)
        local root = character:WaitForChild("HumanoidRootPart", 10)
        task.wait(0.3)
        if not humanoid or not root or player.Character ~= character then
            return
        end
        local phase = state:GetAttribute("Phase")
        if
            not player:GetAttribute("InRound")
            and (phase == "Active" or phase == "Preparation")
            and player:GetAttribute("EliminatedRoundId") == state:GetAttribute("RoundId")
        then
            return
        end
        local camera = workspace.CurrentCamera
        player.CameraMode = Enum.CameraMode.LockFirstPerson
        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = humanoid
        local head = character:FindFirstChild("Head")
        local eyePosition = head and head.Position or root.Position + Vector3.new(0, 1.5, 0)
        camera.CFrame = CFrame.lookAt(eyePosition, eyePosition + root.CFrame.LookVector)
    end)
end
player.CharacterAdded:Connect(frameSpawn)
if player.Character then
    frameSpawn(player.Character)
end
