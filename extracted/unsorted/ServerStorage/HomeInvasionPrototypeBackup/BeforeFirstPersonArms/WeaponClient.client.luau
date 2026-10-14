local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("HomeInvasionWeapons"):WaitForChild("Interaction")
local state = ReplicatedStorage:WaitForChild("HomeInvasionRoundState")
local drops = workspace:WaitForChild("HomeInvasionPrototype"):WaitForChild("WeaponPickups")
local gui = player:WaitForChild("PlayerGui"):WaitForChild("WeaponHUD")
local status = gui:WaitForChild("Status")
local notice = gui:WaitForChild("Notice")
local help = player.PlayerGui:WaitForChild("HomeInvasionRoundHUD"):WaitForChild("Help")
local toolConnections = {}
local characterConnections = {}
local backpackConnection = nil
local noticeSequence = 0
local lastAttackRequest = {}
local attackFeedbackUntil = 0

local function equippedWeapon()
    local character = player.Character
    if character then
        for _, child in ipairs(character:GetChildren()) do
            if child:IsA("Tool") and child:GetAttribute("HomeInvasionWeapon") then
                return child
            end
        end
    end
    return nil
end

local function refreshHUD()
    local tool = equippedWeapon()
    local phase = state:GetAttribute("Phase")
    gui.Enabled = phase == "Active" or phase == "Preparation"
    gui.Reload.Visible = phase == "Active" and tool ~= nil and tool:GetAttribute("AttackKind") == "Ranged"
    if tool then
        if phase == "Preparation" then
            status.Text = tool.Name .. " | ready for invasion; combat starts after preparation"
        elseif tool:GetAttribute("AttackKind") == "Ranged" then
            status.Text = string.format(
                "%s | %d / %d | %s",
                tool.Name,
                tool:GetAttribute("Ammo") or 0,
                tool:GetAttribute("ReserveAmmo") or 0,
                tool:GetAttribute("Reloading") and "Reloading..." or "R: reload"
            )
        else
            status.Text = tool.Name .. " | click / tap to swing"
        end
    elseif player:GetAttribute("RoundRole") == "Protectors" then
        status.Text = string.format(
            "Search the house | %d weapons left | hold F to pick up",
            state:GetAttribute("WeaponsRemaining") or 0
        )
    elseif player:GetAttribute("RoundRole") == "Invaders" and player:GetAttribute("InRound") then
        status.Text = "Invader loadout ready | select crossbow, machete, or crowbar"
    else
        gui.Enabled = false
    end
end

local function refreshPrompt(model)
    local handle = model:FindFirstChild("Handle")
    local prompt = handle and handle:FindFirstChild("WeaponPickupPrompt")
    if not prompt then
        return
    end
    local phase = state:GetAttribute("Phase")
    prompt.Enabled = player:GetAttribute("RoundRole") == "Protectors"
        and player:GetAttribute("InRound") == true
        and not player:GetAttribute("DraggingFurniture")
        and (phase == "Active" or phase == "Preparation")
end

local function refreshPrompts()
    for _, model in ipairs(drops:GetChildren()) do
        refreshPrompt(model)
    end
end

local function requestAttack(tool, screenPoint)
    if
        help.Visible
        or tool ~= equippedWeapon()
        or player:GetAttribute("DraggingFurniture")
        or player:GetAttribute("FurnitureGrabPending")
    then
        return
    end
    if state:GetAttribute("Phase") ~= "Active" then
        if os.clock() >= attackFeedbackUntil then
            attackFeedbackUntil = os.clock() + 1
            notice.Text = "Combat opens when preparation ends."
            notice.Visible = true
            local sequence = noticeSequence + 1
            noticeSequence = sequence
            task.delay(2, function()
                if noticeSequence == sequence then
                    notice.Visible = false
                end
            end)
        end
        return
    end
    if os.clock() < (lastAttackRequest[tool] or 0) then
        return
    end
    lastAttackRequest[tool] = os.clock() + (tool:GetAttribute("AttackCooldown") or 0.3)
    local character = player.Character
    local head = character and character:FindFirstChild("Head")
    if not head then
        return
    end
    local camera = workspace.CurrentCamera
    local cursor = screenPoint or UserInputService:GetMouseLocation()
    local ray = camera:ViewportPointToRay(cursor.X, cursor.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { character, drops, camera }
    local hit = workspace:Raycast(ray.Origin, ray.Direction * 500, params)
    local point = hit and hit.Position or ray.Origin + ray.Direction * 500
    local offset = point - head.Position
    if offset.Magnitude > 0.01 then
        remote:FireServer("Attack", tool, offset.Unit)
    end
end

local function watchTool(tool)
    if not tool:IsA("Tool") or not tool:GetAttribute("HomeInvasionWeapon") or toolConnections[tool] then
        return
    end
    local connections = {}
    toolConnections[tool] = connections
    connections.activated = tool.Activated:Connect(function()
        requestAttack(tool)
    end)
    connections.attributes = tool.AttributeChanged:Connect(refreshHUD)
    connections.ancestry = tool.AncestryChanged:Connect(function()
        if tool.Parent == nil then
            for _, connection in pairs(connections) do
                connection:Disconnect()
            end
            toolConnections[tool] = nil
            lastAttackRequest[tool] = nil
        end
        refreshHUD()
    end)
end

local function watchCharacter(character)
    for _, connection in ipairs(characterConnections) do
        connection:Disconnect()
    end
    table.clear(characterConnections)
    for _, child in ipairs(character:GetChildren()) do
        watchTool(child)
    end
    table.insert(
        characterConnections,
        character.ChildAdded:Connect(function(child)
            watchTool(child)
            refreshHUD()
        end)
    )
    table.insert(characterConnections, character.ChildRemoved:Connect(refreshHUD))
    refreshHUD()
end

local function watchBackpack(backpack)
    if backpackConnection then
        backpackConnection:Disconnect()
    end
    backpackConnection = backpack.ChildAdded:Connect(watchTool)
    for _, child in ipairs(backpack:GetChildren()) do
        watchTool(child)
    end
end
watchBackpack(player:WaitForChild("Backpack"))
player.ChildAdded:Connect(function(child)
    if child:IsA("Backpack") then
        watchBackpack(child)
    end
end)
player.CharacterAdded:Connect(watchCharacter)
if player.Character then
    watchCharacter(player.Character)
end

ProximityPromptService.PromptTriggered:Connect(function(prompt)
    if prompt.Name == "WeaponPickupPrompt" and prompt.Parent then
        remote:FireServer("Pickup", prompt.Parent.Parent)
    end
end)
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end
    if help.Visible or UserInputService:GetFocusedTextBox() or player:GetAttribute("DraggingFurniture") then
        return
    end
    local tool = equippedWeapon()
    if
        tool
        and (
            input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
            or input.KeyCode == Enum.KeyCode.ButtonR2
        )
    then
        local point = input.UserInputType == Enum.UserInputType.Touch
                and Vector2.new(input.Position.X, input.Position.Y)
            or nil
        requestAttack(tool, point)
    end
    if tool and (input.KeyCode == Enum.KeyCode.R or input.KeyCode == Enum.KeyCode.ButtonX) then
        remote:FireServer("Reload", tool)
    end
end)
gui.Reload.Activated:Connect(function()
    local tool = equippedWeapon()
    if tool then
        remote:FireServer("Reload", tool)
    end
end)

remote.OnClientEvent:Connect(function(action, first, second, weaponId)
    if action == "Shot" then
        local length = (second - first).Magnitude
        if length > 0.01 then
            local tracer = Instance.new("Part")
            tracer.Name = "WeaponTracer"
            tracer.Anchored = true
            tracer.CanCollide = false
            tracer.CanTouch = false
            tracer.CanQuery = false
            tracer.Size = Vector3.new(0.04, 0.04, length)
            tracer.CFrame = CFrame.lookAt((first + second) / 2, second)
            tracer.Material = Enum.Material.Neon
            tracer.Color = weaponId == "Crossbow" and Color3.fromRGB(190, 220, 235)
                or Color3.fromRGB(255, 220, 130)
            tracer.Parent = workspace
            Debris:AddItem(tracer, 0.08)
        end
    elseif action == "BreachImpact" then
        for index = 1, second and 8 or 3 do
            local chip = Instance.new("Part")
            chip.Name = "BreachChip"
            chip.Size = Vector3.new(0.12, 0.12, 0.3)
            chip.CFrame = CFrame.new(first + Vector3.new(0, 0.2, 0))
            chip.Material = Enum.Material.Wood
            chip.Color = Color3.fromRGB(121, 88, 60)
            chip.CanCollide = false
            chip.CanQuery = false
            chip.CanTouch = false
            chip.AssemblyLinearVelocity =
                Vector3.new(math.random(-7, 7), math.random(3, 9), math.random(-7, 7))
            chip.Parent = workspace
            Debris:AddItem(chip, 0.65)
        end
    elseif action == "Notice" then
        gui:SetAttribute("LastNotice", first)
        noticeSequence += 1
        local sequence = noticeSequence
        notice.Text = first
        notice.Visible = true
        task.delay(3, function()
            if sequence == noticeSequence then
                notice.Visible = false
            end
        end)
    end
end)

drops.ChildAdded:Connect(function(model)
    local handle = model:WaitForChild("Handle", 5)
    if handle then
        local prompt = handle:WaitForChild("WeaponPickupPrompt", 5)
        if prompt then
            refreshPrompt(model)
        end
    end
end)
state.AttributeChanged:Connect(refreshHUD)
state:GetAttributeChangedSignal("Phase"):Connect(refreshPrompts)
player:GetAttributeChangedSignal("RoundRole"):Connect(function()
    refreshHUD()
    refreshPrompts()
end)
player:GetAttributeChangedSignal("InRound"):Connect(refreshPrompts)
player:GetAttributeChangedSignal("DraggingFurniture"):Connect(function()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if player:GetAttribute("DraggingFurniture") and humanoid then
        humanoid:UnequipTools()
    end
    refreshPrompts()
end)
refreshPrompts()
refreshHUD()
