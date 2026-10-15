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
local armNames ={ "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand" }
local function preparePart(part)
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.LocalTransparencyModifier = 0
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
local function addFollower(followers, model, target, size, offset, color, shape, material)
    local part = Instance.new("Part")
    part.Name = "ArmVisual"
    part.Shape = shape or Enum.PartType.Block
    part.Size = size
    part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    preparePart(part)
    part.Parent = model
    table.insert(followers, { part = part, target = target, offset = offset })
end
-- the rig's blocky arm meshes stay invisible and only drive the pose. What you see is
-- a slim sleeve and a fist built from parts that follow them every frame
local function replaceArms(model, character)
    local colors = character:FindFirstChildOfClass("BodyColors")
    local skin = colors and colors.RightArmColor3 or Color3.fromRGB(234, 184, 146)
    local sleeve = Color3.fromRGB(38, 38, 44)
    local cuff = Color3.fromRGB(28, 28, 32)
    local followers = {}
    local cylinder = CFrame.Angles(0, 0, math.pi / 2)
    for _, name in armNames do
        local template = model[name]
        preparePart(template)
        template.Transparency = 1
        if name:find("UpperArm") then
            addFollower(followers, model, template, Vector3.new(template.Size.Y, 0.5, 0.5), cylinder, sleeve, Enum.PartType.Cylinder, Enum.Material.Fabric)
        elseif name:find("LowerArm") then
            local length = template.Size.Y
            addFollower(followers, model, template, Vector3.new(length, 0.42, 0.42), cylinder, sleeve, Enum.PartType.Cylinder, Enum.Material.Fabric)
            addFollower(followers, model, template, Vector3.new(0.14, 0.46, 0.46), CFrame.new(0, -length / 2 + 0.07, 0) * cylinder, cuff, Enum.PartType.Cylinder, Enum.Material.Fabric)
        else
            -- fist wraps the handle, which runs along the hand's look axis
            addFollower(followers, model, template, Vector3.new(0.26, 0.3, 0.34), CFrame.new(0, 0.05, 0), skin)
            addFollower(followers, model, template, Vector3.new(0.3, 0.12, 0.3), CFrame.new(0, 0.2, 0.01), skin)
            for i = 0, 3 do
                local z = -0.12 + i * 0.08
                addFollower(followers, model, template, Vector3.new(0.09, 0.09, 0.09), CFrame.new(0.12, -0.06, z), skin, Enum.PartType.Ball)
                addFollower(followers, model, template, Vector3.new(0.09, 0.09, 0.09), CFrame.new(-0.12, -0.06, z), skin, Enum.PartType.Ball)
            end
            addFollower(followers, model, template, Vector3.new(0.22, 0.09, 0.09), CFrame.new(0, -0.1, -0.17), skin, Enum.PartType.Cylinder)
        end
    end
    return followers
end
local function build(character, camera, tool)
    local model = assets.Rig:Clone()
    model.Name = "HomeInvasionFirstPerson"
    model.Humanoid.EvaluateStateMachine = false
    model.Humanoid.RequiresNeck = false
    local followers = replaceArms(model, character)
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
        followers = followers,
    }
    current.weaponId = tool and tool:GetAttribute("WeaponId") or "Unarmed"
    -- weapons without their own first-person model borrow the crowbar's until one is made
    local viewId = current.weaponId
    if tool and not assets.Weapons:FindFirstChild(viewId) then
        viewId = "Crowbar"
    end
    current.profile = animations.Profiles[viewId] or animations.Profiles.Unarmed
    model:SetAttribute("WeaponId", current.weaponId)
    model:SetAttribute("Action", "Idle")
    for name, count in counts do
        model:SetAttribute(name .. "Count", count)
    end
    if tool then
        local weapon = assets.Weapons[viewId]:Clone()
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
    -- bare block fists floating in view looked worse than nothing, so arms only show with a weapon
    if not tool then
        cleanup()
        return
    end
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
        -- one-handed weapons keep the free hand down out of view
        leftHand = profile.FreeLeft and CFrame.new(-0.9, -2.3, -1) * CFrame.Angles(-0.4, 0, 0)
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
    for _, follower in current.followers do
        follower.part.CFrame = follower.target.CFrame * follower.offset
    end
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
