local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local state = ReplicatedStorage:WaitForChild("HomeInvasionRoundState")
local doors = workspace:WaitForChild("HomeInvasionPrototype"):WaitForChild("Doors")
local remote = ReplicatedStorage:WaitForChild("HomeInvasionDoors"):WaitForChild("Interaction")
local panel = player:WaitForChild("PlayerGui"):WaitForChild("ContextInteractionHUD").Door
local selected
local help = player.PlayerGui:WaitForChild("HomeInvasionRoundHUD"):WaitForChild("Help")
-- Keep an open door selectable through its original doorway, without adding
-- invisible query parts that would block weapon or furniture raycasts.
local function doorwayDistance(model, ray)
    local closedCollider = model:GetAttribute("DoorClosedCollider") or model:GetAttribute("ClosedPivot")
    local origin = closedCollider:PointToObjectSpace(ray.Origin)
    local direction = closedCollider:VectorToObjectSpace(ray.Direction)
    local halfSize = model.DoorCollider.Size / 2
    local nearest, farthest = 0, 40
    for _, axis in { "X", "Y", "Z" } do
        if math.abs(direction[axis]) < 0.00001 then
            if math.abs(origin[axis]) > halfSize[axis] then
                return nil
            end
        else
            local first = (-halfSize[axis] - origin[axis]) / direction[axis]
            local second = (halfSize[axis] - origin[axis]) / direction[axis]
            nearest = math.max(nearest, math.min(first, second))
            farthest = math.min(farthest, math.max(first, second))
            if nearest > farthest then
                return nil
            end
        end
    end
    return nearest
end

local function focusedDoor()
    local phase = state:GetAttribute("Phase")
    local role = player:GetAttribute("RoundRole")
    if
        help.Visible
        or not player:GetAttribute("InRound")
        or player:GetAttribute("DraggingFurniture")
        or player:GetAttribute("FurnitureGrabPending")
        or (phase ~= "Active" and not (phase == "Preparation" and role == "Protectors"))
    then
        return nil
    end
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return nil
    end
    local cursor = UserInputService:GetMouseLocation()
    local camera = workspace.CurrentCamera
    local ray = camera:ViewportPointToRay(cursor.X, cursor.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { character, camera }
    local hit = workspace:Raycast(ray.Origin, ray.Direction * 40, params)
    local model = hit and hit.Instance:FindFirstAncestorOfClass("Model")
    if
        model
        and model.Parent == doors
        and not model:GetAttribute("DoorBroken")
        and (root.Position - model.DoorCollider.Position).Magnitude <= 9
    then
        return model
    end
    if model and model.Parent == workspace.HomeInvasionPrototype.Furniture then
        return nil
    end
    local closest, closestDistance
    for _, door in doors:GetChildren() do
        if
            door:IsA("Model")
            and not door:GetAttribute("DoorBroken")
            and (door:GetAttribute("DoorOpen") or door:GetAttribute("DoorMoving"))
        then
            local frame = door:GetAttribute("DoorClosedCollider") or door:GetAttribute("ClosedPivot")
            if (root.Position - frame.Position).Magnitude <= 9 then
                local distance = doorwayDistance(door, ray)
                if
                    distance
                    and (not hit or hit.Distance >= distance - 0.15)
                    and (not closestDistance or distance < closestDistance)
                then
                    closest, closestDistance = door, distance
                end
            end
        end
    end
    return closest
end
UserInputService.InputBegan:Connect(function(input, processed)
    if processed or UserInputService:GetFocusedTextBox() then
        return
    end
    local door = focusedDoor()
    if not door or door:GetAttribute("DoorMoving") then
        return
    end
    if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonA then
        remote:FireServer("Open", door)
    elseif input.KeyCode == Enum.KeyCode.L or input.KeyCode == Enum.KeyCode.ButtonY then
        local invader = player:GetAttribute("RoundRole") == "Invaders"
        remote:FireServer(invader and door:GetAttribute("DoorLocked") and "Pick" or "Lock", door)
    end
end)
local elapsed = 0
RunService.RenderStepped:Connect(function(deltaTime)
    elapsed += deltaTime
    if elapsed < 0.08 then
        return
    end
    elapsed = 0
    selected = focusedDoor()
    panel.Visible = selected ~= nil
    panel:SetAttribute("FocusedDoor", selected and selected.Name or nil)
    if not selected then
        return
    end
    local locked = selected:GetAttribute("DoorLocked")
    local open = selected:GetAttribute("DoorOpen")
    local moving = selected:GetAttribute("DoorMoving")
    panel.DoorName.Text = locked and "LOCKED DOOR" or "HOUSE DOOR"
    panel.Actions.Text = moving and "Door moving..."
        or locked and player:GetAttribute("RoundRole") == "Invaders" and "[L] Pick the lock (quiet)    CROWBAR: break it"
        or "[E] "
            .. (open and "Close" or "Open")
            .. "    "
            .. (
                player:GetAttribute("RoundRole") == "Protectors"
                    and "[L] " .. (locked and "Unlock" or "Lock")
                or ""
            )
    panel.Health.Text = string.format(
        "Door health: %d / %d",
        selected:GetAttribute("DoorHealth") or 100,
        selected:GetAttribute("DoorMaxHealth") or 100
    )
end)
