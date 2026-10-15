local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("HomeInvasionFurniture"):WaitForChild("Interaction")
local state = ReplicatedStorage:WaitForChild("HomeInvasionRoundState")
local folder = workspace:WaitForChild("HomeInvasionPrototype"):WaitForChild("Furniture")
local gui = player:WaitForChild("PlayerGui"):WaitForChild("FurnitureDraggingHUD")
local panel = gui.Controls
local highlight = gui.HeldFurniture
local hint = player.PlayerGui:WaitForChild("ContextInteractionHUD").Furniture
local help = player.PlayerGui:WaitForChild("HomeInvasionRoundHUD"):WaitForChild("Help")
local heldModel, sessionId
local pointerHeld = false
local dragDepth = 8
local pending = false
local pendingSequence = 0
local feedbackUntil = 0

local function allowed()
    local phase = state:GetAttribute("Phase")
    return not help.Visible
        and player:GetAttribute("InRound") == true
        and player:GetAttribute("RoundRole") == "Protectors"
        and (phase == "Preparation" or phase == "Active")
end
local function cursorRay()
    local position = UserInputService:GetMouseLocation()
    return workspace.CurrentCamera:ViewportPointToRay(position.X, position.Y)
end
local function pointedFurniture()
    local ray = cursorRay()
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { player.Character, workspace.CurrentCamera }
    local hit = workspace:Raycast(ray.Origin, ray.Direction * 30, params)
    local model = hit and hit.Instance:FindFirstAncestorOfClass("Model")
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if
        model
        and model.Parent == folder
        and model:GetAttribute("DraggableFurniture")
        and not model:GetAttribute("BarricadeBroken")
        and root
        and (root.Position - model:GetPivot().Position).Magnitude <= 9
    then
        return model, hit.Position, hit.Distance
    end
end
-- Grabbing unequips your weapon, and Roblox can send a Cancel for the mouse button when
-- that happens. Only treat it as a release if the button really is up.
local function pointerDown()
    return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
        or UserInputService.TouchEnabled and pointerHeld
end
local function drop()
    pointerHeld = false
    if sessionId then
        remote:FireServer("Drop", sessionId)
    end
end
local function rotate(direction)
    if sessionId then
        remote:FireServer("Rotate", sessionId, direction)
    end
end
panel.RotateLeft.Activated:Connect(function()
    rotate(-1)
end)
panel.RotateRight.Activated:Connect(function()
    rotate(1)
end)
panel.Drop.Activated:Connect(drop)
ContextActionService:BindActionAtPriority("HomeInvasionFurnitureHold", function(_, inputState)
    if inputState == Enum.UserInputState.Begin then
        if heldModel or pending then
            return Enum.ContextActionResult.Sink
        end
        if not allowed() or UserInputService:GetFocusedTextBox() then
            return Enum.ContextActionResult.Pass
        end
        local model, point, distance = pointedFurniture()
        if not model then
            return Enum.ContextActionResult.Pass
        end
        pointerHeld = true
        pending = true
        dragDepth = distance
        player:SetAttribute("FurnitureGrabPending", true)
        remote:FireServer("Grab", model, point)
        pendingSequence += 1
        local requestSequence = pendingSequence
        task.delay(2, function()
            if pending and pendingSequence == requestSequence then
                pending = false
                pointerHeld = false
                player:SetAttribute("FurnitureGrabPending", nil)
                panel.Status.Text = "Could not grab furniture. Try again."
                panel.Visible = true
                feedbackUntil = os.clock() + 1.5
            end
        end)
        return Enum.ContextActionResult.Sink
    elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
        if inputState == Enum.UserInputState.Cancel and pointerDown() then
            return Enum.ContextActionResult.Pass
        end
        if pointerHeld or heldModel or pending then
            drop()
            return Enum.ContextActionResult.Sink
        end
    end
    return Enum.ContextActionResult.Pass
end, false, 3000, Enum.UserInputType.MouseButton1)
UserInputService.InputBegan:Connect(function(input, processed)
    if not heldModel or processed or UserInputService:GetFocusedTextBox() then
        return
    end
    if input.KeyCode == Enum.KeyCode.Q then
        rotate(-1)
    elseif input.KeyCode == Enum.KeyCode.R then
        rotate(1)
    elseif input.KeyCode == Enum.KeyCode.E then
        drop()
    end
end)
UserInputService.WindowFocusReleased:Connect(drop)
player.CharacterRemoving:Connect(drop)
remote.OnClientEvent:Connect(function(action, modelOrMessage, id)
    if action == "Grabbed" then
        pending = false
        player:SetAttribute("FurnitureGrabPending", nil)
        heldModel, sessionId = modelOrMessage, id
        if not pointerHeld and not pointerDown() then
            drop()
            return
        end
        pointerHeld = true
        highlight.Adornee = heldModel
        highlight.Enabled = true
        panel.Status.Text = "Hold left click: carry / drag • Q / R: rotate • release: drop"
        panel.Visible = true
        feedbackUntil = 0
    elseif action == "Blocked" then
        if heldModel then
            panel.Status.Text = modelOrMessage or "Hold left click: carry / drag • Q / R: rotate • release: drop"
        end
    elseif action == "Dropped" or action == "Rejected" then
        heldModel, sessionId = nil, nil
        pending, pointerHeld = false, false
        player:SetAttribute("FurnitureGrabPending", nil)
        highlight.Enabled = false
        highlight.Adornee = nil
        panel.Status.Text = modelOrMessage or "Dropped"
        panel.Visible = true
        feedbackUntil = os.clock() + 1.5
    end
end)
local elapsed = 0
RunService.RenderStepped:Connect(function(deltaTime)
    elapsed += deltaTime
    if elapsed < 0.1 then
        return
    end
    elapsed = 0
    hint.Visible = false
    if heldModel and sessionId then
        -- Catches a release that never sent an End event.
        if not allowed() or not heldModel:IsDescendantOf(workspace) or not UserInputService.TouchEnabled and not pointerDown() then
            drop()
            return
        end
        local ray = cursorRay()
        remote:FireServer("Move", sessionId, ray.Origin + ray.Direction * dragDepth)
    elseif not pending and allowed() then
        local model = pointedFurniture()
        if model then
            hint.Visible = true
            hint.Text = model.Name .. "  •  hold left click to drag"
        end
    end
    if not heldModel and feedbackUntil > 0 and os.clock() >= feedbackUntil then
        panel.Visible = false
        feedbackUntil = 0
    end
end)
