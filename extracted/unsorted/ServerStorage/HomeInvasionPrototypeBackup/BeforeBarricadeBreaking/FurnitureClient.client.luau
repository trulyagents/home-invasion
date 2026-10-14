-- NOTE: was Disabled in Studio
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer
local network = ReplicatedStorage:WaitForChild("HomeInvasionFurniture")
local remote = network:WaitForChild("Interaction")
local sendSeconds = network:GetAttribute("ClientSendSeconds") or 0.1
local heldModel = nil
local sessionId = nil
local feedbackUntil = 0
local roundState = ReplicatedStorage:WaitForChild("HomeInvasionRoundState")
local furnitureFolder = workspace:WaitForChild("HomeInvasionPrototype"):WaitForChild("Furniture")

local gui = player:WaitForChild("PlayerGui"):WaitForChild("FurnitureDraggingHUD")
local panel = gui:WaitForChild("Controls")
local label = panel:WaitForChild("Status")
local highlight = gui:WaitForChild("HeldFurniture")

local function drop()
    if sessionId then
        remote:FireServer("Drop", sessionId)
    end
end

local function rotate(direction)
    if sessionId then
        remote:FireServer("Rotate", sessionId, direction)
    end
end

panel.RotateLeft.Activated:Connect(function() rotate(-1) end)
panel.Drop.Activated:Connect(drop)
panel.RotateRight.Activated:Connect(function() rotate(1) end)

UserInputService.InputBegan:Connect(function(input)
    if not heldModel or UserInputService:GetFocusedTextBox() then
        return
    end
    local keyCode = input.KeyCode
    if keyCode == Enum.KeyCode.E or keyCode == Enum.KeyCode.ButtonB then
        drop()
    elseif keyCode == Enum.KeyCode.Q or keyCode == Enum.KeyCode.ButtonL1 then
        rotate(-1)
    elseif keyCode == Enum.KeyCode.R or keyCode == Enum.KeyCode.ButtonR1 then
        rotate(1)
    end
end)

local function refreshPrompt(model)
    local collider = model:FindFirstChild("DragCollider")
    local prompt = collider and collider:FindFirstChild("FurnitureDragPrompt")
    if not prompt then
        return
    end
    local phase = roundState:GetAttribute("Phase")
    prompt.Enabled = player:GetAttribute("RoundRole") == "Protectors"
        and player:GetAttribute("InRound") == true
        and (phase == "Active" or phase == "Preparation")
        and model:GetAttribute("DraggedByUserId") == 0
end

local function refreshPrompts()
    for _, model in ipairs(furnitureFolder:GetChildren()) do
        refreshPrompt(model)
    end
end

for _, model in ipairs(furnitureFolder:GetChildren()) do
    model:GetAttributeChangedSignal("DraggedByUserId"):Connect(function()
        refreshPrompt(model)
    end)
end
player:GetAttributeChangedSignal("RoundRole"):Connect(refreshPrompts)
player:GetAttributeChangedSignal("InRound"):Connect(refreshPrompts)
roundState:GetAttributeChangedSignal("Phase"):Connect(refreshPrompts)
refreshPrompts()

ProximityPromptService.PromptTriggered:Connect(function(prompt)
    if prompt.Name ~= "FurnitureDragPrompt" or heldModel then
        return
    end
    local model = prompt.Parent and prompt.Parent.Parent
    if model and model:IsA("Model") and model:GetAttribute("DraggableFurniture") then
        remote:FireServer("Grab", model)
    end
end)

remote.OnClientEvent:Connect(function(action, modelOrMessage, id)
    if action == "Grabbed" then
        heldModel = modelOrMessage
        sessionId = id
        highlight.Adornee = heldModel
        highlight.Enabled = true
        label.Text = "Dragging " .. heldModel.Name .. ": walk and turn the camera to move it."
        panel.Visible = true
        feedbackUntil = 0
    elseif action == "Dropped" then
        heldModel = nil
        sessionId = nil
        highlight.Adornee = nil
        highlight.Enabled = false
        label.Text = modelOrMessage
        feedbackUntil = os.clock() + 2
    elseif action == "Rejected" then
        label.Text = modelOrMessage
        panel.Visible = true
        feedbackUntil = os.clock() + 3
    end
end)

local accumulatedSeconds = 0
RunService.RenderStepped:Connect(function(deltaTime)
    if not heldModel then
        if feedbackUntil > 0 and os.clock() >= feedbackUntil then
            panel.Visible = false
            feedbackUntil = 0
        end
        return
    end
    accumulatedSeconds += deltaTime
    if accumulatedSeconds < sendSeconds then
        return
    end
    accumulatedSeconds = 0
    local camera = workspace.CurrentCamera
    if not camera or not heldModel:IsDescendantOf(workspace) then
        drop()
        return
    end
    local look = camera.CFrame.LookVector
    local direction = Vector3.new(look.X, 0, look.Z)
    if direction.Magnitude > 0.01 then
        remote:FireServer("Aim", sessionId, direction.Unit)
    end
end)