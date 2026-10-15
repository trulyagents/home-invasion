local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui"):WaitForChild("HomeInvasionHotbar")
local slots = {}
local orderedTools = {}
local keys = { [Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3 }
local priorities = {
    Crossbow = 1,
    Machete = 2,
    Crowbar = 3,
    KitchenKnife = 1,
    MeatTenderizer = 1,
    FireplacePoker = 1,
    Screwdriver = 2,
}

local function refresh()
    local backpack = player:FindFirstChildOfClass("Backpack")
    local character = player.Character
    table.clear(orderedTools)
    for _, container in { backpack, character } do
        if container then
            for _, tool in container:GetChildren() do
                if tool:IsA("Tool") and tool:GetAttribute("HomeInvasionWeapon") then
                    table.insert(orderedTools, tool)
                end
            end
        end
    end
    table.sort(orderedTools, function(first, second)
        local firstPriority = priorities[first:GetAttribute("WeaponId")] or 10
        local secondPriority = priorities[second:GetAttribute("WeaponId")] or 10
        if firstPriority == secondPriority then
            return first.Name < second.Name
        end
        return firstPriority < secondPriority
    end)
    gui.Enabled = #orderedTools > 0 and player:GetAttribute("InRound") == true
    for index, button in slots do
        local tool = orderedTools[index]
        button.Visible = tool ~= nil
        button.Text = tostring(index) .. "\n" .. (tool and tool.Name or "")
        button.BackgroundColor3 = tool and tool.Parent == character and Color3.fromRGB(120, 24, 20)
            or Color3.fromRGB(28, 24, 24)
    end
end

local function equipSlot(index)
    refresh()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local backpack = player:FindFirstChildOfClass("Backpack")
    local tool = orderedTools[index]
    if
        not humanoid
        or humanoid.Health <= 0
        or not tool
        or not player:GetAttribute("InRound")
        or player:GetAttribute("DraggingFurniture")
        or player:GetAttribute("FurnitureGrabPending")
    then
        return
    end
    if tool.Parent == character then
        humanoid:UnequipTools()
    elseif tool.Parent == backpack then
        humanoid:EquipTool(tool)
    end
    refresh()
end

for index = 1, 3 do
    local button = gui.Controls:WaitForChild("Slot" .. index)
    slots[index] = button
    button.Activated:Connect(function()
        equipSlot(index)
    end)
end
local function handleInput(input, processed)
    if processed or UserInputService:GetFocusedTextBox() then
        return
    end
    local index = keys[input.KeyCode]
    if index then
        equipSlot(index)
    end
end
UserInputService.InputBegan:Connect(handleInput)

-- Core backpack is disabled once; only this hotbar owns weapon selection.
task.spawn(function()
    for attempt = 1, 10 do
        local success = pcall(function()
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
        end)
        if success then
            return
        end
        task.wait(0.2)
    end
end)
-- Redraw only when tools move between the backpack and the character, or the round changes.
local containerConnections = {}
local function watch(container)
    if not container then
        return
    end
    table.insert(containerConnections, container.ChildAdded:Connect(refresh))
    table.insert(containerConnections, container.ChildRemoved:Connect(refresh))
end
local function rewatch()
    for _, connection in containerConnections do
        connection:Disconnect()
    end
    table.clear(containerConnections)
    watch(player:FindFirstChildOfClass("Backpack"))
    watch(player.Character)
    refresh()
end
player.CharacterAdded:Connect(function()
    player:WaitForChild("Backpack")
    rewatch()
end)
player.ChildAdded:Connect(function(child)
    if child:IsA("Backpack") then
        rewatch()
    end
end)
player:GetAttributeChangedSignal("InRound"):Connect(refresh)
rewatch()
