local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local assets = ReplicatedStorage:WaitForChild("HomeInvasionFirstPersonAssets")
local animations = require(assets:WaitForChild("MotionProfiles"))
local remote = ReplicatedStorage:WaitForChild("HomeInvasionWeapons"):WaitForChild("Interaction")
local BINDING = "HomeInvasionFirstPersonArms"
local context
local counts = { Equip = 0, Attack = 0, Reload = 0 }
local armNames = { "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand" }
local function preparePart(part)
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.LocalTransparencyModifier = 0
end
local function cleanClone(instance)
    for _, child in instance:GetDescendants() do
        if
            child:IsA("BaseScript")
            or child:IsA("JointInstance")
            or child:IsA("Constraint")
            or child:IsA("WeldConstraint")
        then
            child:Destroy()
        end
    end
end
local function cleanup()
    if not context then
        return
    end
    for _, connection in context.connections do
        connection:Disconnect()
    end
    for part, value in context.worldTransparency do
        if part.Parent then
            part.LocalTransparencyModifier = value
        end
    end
    for beam, enabled in context.worldBeams do
        if beam.Parent then
            beam.Enabled = enabled
        end
    end
    context.model:Destroy()
    context = nil
end
local function equipped(character)
    for _, child in character:GetChildren() do
        if child:IsA("Tool") and child:GetAttribute("HomeInvasionWeapon") then
            return child
        end
    end
end
local function startAction(name, duration)
    if not context then
        return
    end
    if name == "Attack" and context.tool and context.tool:GetAttribute("Reloading") then
        return
    end
    context.action = { name = name, started = os.clock(), duration = duration }
    counts[name] += 1
    context.model:SetAttribute(name .. "Count", counts[name])
    context.model:SetAttribute("Action", name)
end
local function replaceArms(model, character)
    local r6 = character.Humanoid.RigType == Enum.HumanoidRigType.R6
    for _, name in armNames do
        local source = character:FindFirstChild(name)
        local template = model[name]
        if source and source:IsA("BasePart") then
            local clone = source:Clone()
            if clone then
                cleanClone(clone)
                clone.Name = name
                clone.Parent = model
                template:Destroy()
                template = clone
            end
        elseif r6 then
            local sourceArm = character:FindFirstChild(name:sub(1, 4) == "Left" and "Left Arm" or "Right Arm")
            if sourceArm then
                template.Color = sourceArm.Color
            end
        end
        preparePart(template)
        template.Transparency = 0
    end
    for _, name in { "Shirt", "Pants", "Body Colors" } do
        local item = character:FindFirstChild(name)
        if item then
            item:Clone().Parent = model
        end
    end
end
local function build(character, camera, tool)
    local model = assets.Rig:Clone()
    model.Name = "HomeInvasionFirstPerson"
    model.Humanoid.EvaluateStateMachine = false
    model.Humanoid.RequiresNeck = false
    replaceArms(model, character)
    for _, part in model:GetDescendants() do
        if part:IsA("BasePart") then
            preparePart(part)
        end
    end
    model.Parent = camera
    local current = {
        model = model,
        character = character,
        camera = camera,
        tool = tool,
        connections = {},
        worldTransparency = {},
        worldBeams = {},
        aim = 0,
        previousCamera = camera.CFrame,
    }
    current.weaponId = tool and tool:GetAttribute("WeaponId") or "Unarmed"
    current.profile = animations.Profiles[current.weaponId] or animations.Profiles.Unarmed
    model:SetAttribute("WeaponId", current.weaponId)
    model:SetAttribute("Action", "Idle")
    for name, count in counts do
        model:SetAttribute(name .. "Count", count)
    end
    if tool then
        local weapon = assets.Weapons[current.weaponId]:Clone()
        weapon.Parent = model
        current.weapon = weapon
        current.rightGrip = weapon.Handle.RightGrip
        current.leftGrip = weapon.Handle.LeftGrip
        current.magazine = weapon:FindFirstChild("ViewMagazine", true)
        current.arrow = weapon:FindFirstChild("Arrow", true)
        current.bolt = weapon:FindFirstChild("Bolt", true)
        local bow = weapon:FindFirstChild("Crossbow")
        if bow and bow:IsA("BasePart") then
            current.string = bow:FindFirstChild("String1")
            current.stringLoose = bow:FindFirstChild("StringLoose")
            current.stringTight = bow:FindFirstChild("StringTight")
        end
        if current.magazine then
            current.magazineOffset = weapon.Handle.CFrame:ToObjectSpace(current.magazine.CFrame)
        end
        if current.bolt then
            current.boltOffset = weapon.Handle.CFrame:ToObjectSpace(current.bolt.CFrame)
        end
        if current.arrow then
            current.loadingBolt = current.arrow:Clone()
            current.loadingBolt.Name = "LoadingBolt"
            current.loadingBolt.Transparency = 1
            current.loadingBolt.Parent = model
            preparePart(current.loadingBolt)
        end
        for _, part in tool:GetDescendants() do
            if part:IsA("BasePart") then
                current.worldTransparency[part] = part.LocalTransparencyModifier
            elseif part:IsA("Beam") then
                current.worldBeams[part] = part.Enabled
            end
        end
    end
    context = current
    if tool then
        table.insert(
            current.connections,
            tool:GetAttributeChangedSignal("Reloading"):Connect(function()
                if context ~= current then
                    return
                end
                if tool:GetAttribute("Reloading") then
                    startAction("Reload", tool:GetAttribute("ReloadSeconds") or 1.8)
                elseif current.action and current.action.name == "Reload" then
                    current.action = nil
                    model:SetAttribute("Action", "Idle")
                end
            end)
        )
        if tool:GetAttribute("Reloading") then
            startAction("Reload", tool:GetAttribute("ReloadSeconds") or 1.8)
        else
            startAction("Equip", animations.EquipSeconds)
        end
    end
end
local function sample(frames, progress)
    for index = 2, #frames do
        local nextFrame = frames[index]
        if progress <= nextFrame.Time then
            local previous = frames[index - 1]
            local alpha = (progress - previous.Time) / (nextFrame.Time - previous.Time)
            alpha = alpha * alpha * (3 - 2 * alpha)
            return previous.Weapon:Lerp(nextFrame.Weapon, alpha), previous.Left:Lerp(nextFrame.Left, alpha)
        end
    end
    return CFrame.identity, CFrame.identity
end
local function addOffset(base, offset)
    return CFrame.new(base.Position + offset.Position) * offset.Rotation * base.Rotation
end
local function segmentPose(first, second, pole)
    local offset = second - first
    local up = (pole - (first + second) / 2).Unit
    if math.abs(up:Dot(offset.Unit)) > 0.98 then
        up = Vector3.xAxis
    end
    return CFrame.lookAt((first + second) / 2, second, up) * CFrame.Angles(math.pi / 2, 0, 0)
end
local function positionArm(current, side, handPose)
    local model = current.model
    local upper = model[side .. "UpperArm"]
    local lower = model[side .. "LowerArm"]
    local hand = model[side .. "Hand"]
    local sign = side == "Left" and -1 or 1
    local shoulder = Vector3.new(sign * 0.8, -1.05, -0.45)
    local wrist = handPose.Position + handPose.UpVector * hand.Size.Y * 0.35
    local offset = wrist - shoulder
    local distance = math.max(offset.Magnitude, 0.01)
    local direction = offset / distance
    local upperLength = math.max(upper.Size.Y, 1.15)
    local lowerLength = math.max(lower.Size.Y, 1.1)
    local solveDistance =
        math.clamp(distance, math.abs(upperLength - lowerLength) + 0.01, upperLength + lowerLength - 0.01)
    local along = (upperLength ^ 2 - lowerLength ^ 2 + solveDistance ^ 2) / (2 * solveDistance)
    local height = math.sqrt(math.max(0, upperLength ^ 2 - along ^ 2))
    local pole = Vector3.new(sign * 1.8, -1.8, -0.4)
    local bend = pole - shoulder
    bend -= direction * bend:Dot(direction)
    if bend.Magnitude < 0.01 then
        bend = Vector3.yAxis
    end
    local elbow = shoulder + direction * along + bend.Unit * height
    upper.CFrame = current.camera.CFrame * segmentPose(shoulder, elbow, pole)
    lower.CFrame = current.camera.CFrame * segmentPose(elbow, wrist, pole)
    hand.CFrame = current.camera.CFrame * handPose
end
local function update(deltaTime)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local camera = workspace.CurrentCamera
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local visible = root
        and humanoid
        and humanoid.Health > 0
        and camera
        and camera.CameraSubject == humanoid
        and player.CameraMode == Enum.CameraMode.LockFirstPerson
        and camera.CameraType == Enum.CameraType.Custom
    if not visible then
        cleanup()
        return
    end
    local tool = equipped(character)
    if not context or context.character ~= character or context.camera ~= camera or context.tool ~= tool then
        cleanup()
        build(character, camera, tool)
    end
    local current = context
    local profile = current.profile
    current.model:PivotTo(camera.CFrame)
    for part in current.worldTransparency do
        if part.Parent then
            part.LocalTransparencyModifier = 1
        end
    end
    for beam in current.worldBeams do
        if beam.Parent then
            beam.Enabled = false
        end
    end
    local aimTarget = profile.Aim and math.clamp((70 - camera.FieldOfView) / 16, 0, 1) or 0
    current.aim += (aimTarget - current.aim) * math.min(1, deltaTime * 18)
    local hold = profile.Aim and profile.Hold:Lerp(profile.Aim, current.aim) or profile.Hold
    local weaponDelta, leftDelta = CFrame.identity, CFrame.identity
    local progress = 0
    local action = current.action
    if action then
        progress = math.clamp((os.clock() - action.started) / action.duration, 0, 1)
        local frames = profile[action.name]
        if frames then
            weaponDelta, leftDelta = sample(frames, progress)
        end
        current.model:SetAttribute("ActionProgress", progress)
        if progress == 1 and action.name ~= "Reload" then
            current.action = nil
            current.model:SetAttribute("Action", "Idle")
        end
    end
    local speed = root.AssemblyLinearVelocity.Magnitude
    local bob = math.sin(os.clock() * 8) * math.min(speed / 16, 1) * 0.018
    local pose = CFrame.new(0, bob, 0) * addOffset(hold, weaponDelta)
    local rightHand, leftHand
    if current.weapon then
        current.weapon:PivotTo(camera.CFrame * pose)
        rightHand = pose * current.rightGrip.CFrame
        leftHand = profile.FreeLeft and CFrame.new(-0.8, -1.12, -1.25) * CFrame.Angles(-0.4, 0, 0)
            or pose * current.leftGrip.CFrame
        leftHand = addOffset(leftHand, leftDelta)
        local reloading = action and action.name == "Reload" and tool:GetAttribute("Reloading")
        if current.string and current.stringLoose and current.stringTight then
            local loaded = (tool:GetAttribute("Ammo") or 0) > 0
            local pull = loaded and 1 or reloading and math.clamp((progress - 0.07) / 0.15, 0, 1) or 0
            current.string.Position = current.stringLoose.Position:Lerp(current.stringTight.Position, pull)
        end
        if current.arrow then
            current.arrow.Transparency = (tool:GetAttribute("Ammo") or 0) > 0 and 0 or 1
            local loading = reloading and progress > 0.25 and (tool:GetAttribute("Ammo") or 0) == 0
            current.loadingBolt.Transparency = loading and 0 or 1
            current.loadingBolt.CFrame = progress > 0.8 and current.arrow.CFrame
                or CFrame.new((camera.CFrame * leftHand).Position) * current.arrow.CFrame.Rotation
        end
        if current.magazine then
            if reloading and progress > 0.18 and progress < 0.78 then
                current.magazine.CFrame = camera.CFrame * leftHand * CFrame.new(0, -0.2, 0)
                current.magazine.Transparency = progress > 0.38 and progress < 0.52 and 1 or 0
            else
                current.magazine.CFrame = current.weapon.Handle.CFrame * current.magazineOffset
                current.magazine.Transparency = 0
            end
        end
        if current.bolt then
            local cock = reloading and progress > 0.8 and progress < 0.94 and 0.16 or 0
            current.bolt.CFrame = current.weapon.Handle.CFrame * current.boltOffset * CFrame.new(0, -cock, 0)
        end
    else
        rightHand = CFrame.new(0.65, -0.65, -1.6) * CFrame.Angles(-0.6, 0, 0)
        leftHand = CFrame.new(-0.65, -0.65, -1.6) * CFrame.Angles(-0.6, 0, 0)
    end
    positionArm(current, "Right", rightHand)
    positionArm(current, "Left", leftHand)
end
remote.OnClientEvent:Connect(function(action, tool, kind)
    if action ~= "WeaponAction" or kind ~= "Attack" or not context or context.tool ~= tool then
        return
    end
    startAction("Attack", context.profile.AttackSeconds)
end)
player.CharacterRemoving:Connect(cleanup)
RunService:BindToRenderStep(BINDING, Enum.RenderPriority.Camera.Value + 10, update)
script.Destroying:Connect(function()
    RunService:UnbindFromRenderStep(BINDING)
    cleanup()
end)
