--!strict
-- Screen feedback that makes fights feel heavier: camera kick when you swing or land a hit,
-- a red edge flash and shake when you get hurt, and a faint red edge while badly hurt.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("HomeInvasionWeapons"):WaitForChild("Interaction") :: RemoteEvent

local BLOOD = Color3.fromRGB(150, 12, 10)
local EDGE_DEPTH = 0.22

local gui = Instance.new("ScreenGui")
gui.Name = "GameFeelHUD"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = -1
gui.Parent = player:WaitForChild("PlayerGui")

-- Four edge strips that fade toward the middle of the screen.
local edges: { Frame } = {}
local function edge(position: UDim2, size: UDim2, rotation: number)
    local frame = Instance.new("Frame")
    frame.BorderSizePixel = 0
    frame.BackgroundColor3 = BLOOD
    frame.Position = position
    frame.Size = size
    frame.BackgroundTransparency = 1
    local gradient = Instance.new("UIGradient")
    gradient.Rotation = rotation
    gradient.Transparency = NumberSequence.new(0, 1)
    gradient.Parent = frame
    frame.Parent = gui
    table.insert(edges, frame)
end
edge(UDim2.fromScale(0, 0), UDim2.fromScale(1, EDGE_DEPTH), 90)
edge(UDim2.fromScale(0, 1 - EDGE_DEPTH), UDim2.fromScale(1, EDGE_DEPTH), -90)
edge(UDim2.fromScale(0, 0), UDim2.fromScale(EDGE_DEPTH, 1), 0)
edge(UDim2.fromScale(1 - EDGE_DEPTH, 0), UDim2.fromScale(EDGE_DEPTH, 1), 180)

local flash = 0 -- 0 to 1, fades out over time
local shake = 0 -- strength of the shake in degrees, fades out over time
local kick = 0 -- upward camera kick in degrees, springs back
local injured = 0 -- 0 to 1 from missing health

local function watchCharacter(character: Model)
    local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
    if not humanoid then
        return
    end
    local last = humanoid.Health
    humanoid.HealthChanged:Connect(function(health)
        local lost = last - health
        last = health
        if lost > 0.5 then
            local share = math.clamp(lost / humanoid.MaxHealth, 0, 1)
            flash = math.min(1, flash + 0.45 + share * 1.5)
            shake = math.max(shake, 1.2 + share * 6)
        end
        injured = math.clamp(1 - health / humanoid.MaxHealth, 0, 1)
    end)
    injured = 0
end
player.CharacterAdded:Connect(watchCharacter)
if player.Character then
    task.spawn(watchCharacter, player.Character)
end

remote.OnClientEvent:Connect(function(action, first, second)
    if action == "Hit" then
        kick = math.max(kick, second and 2.2 or 1.2)
    elseif action == "WeaponAction" and second == "Attack" then
        local character = player.Character
        if typeof(first) == "Instance" and character and first.Parent == character then
            kick = math.max(kick, 0.8)
        end
    end
end)

RunService:BindToRenderStep("HomeInvasionGameFeel", Enum.RenderPriority.Camera.Value + 5, function(deltaTime)
    flash = math.max(0, flash - deltaTime * 1.8)
    shake = math.max(0, shake - deltaTime * 12)
    kick = math.max(0, kick - deltaTime * 9)

    local lowHealth = injured > 0.5 and (injured - 0.5) * 0.9 or 0
    local pulse = lowHealth > 0 and (math.sin(os.clock() * 5) * 0.5 + 0.5) * 0.15 or 0
    local strength = math.clamp(math.max(flash, lowHealth + pulse), 0, 1)
    for _, frame in edges do
        frame.BackgroundTransparency = 1 - strength * 0.75
    end

    local camera = workspace.CurrentCamera
    if camera and (shake > 0 or kick > 0) then
        local x = math.rad(kick + (math.random() - 0.5) * shake)
        local y = math.rad((math.random() - 0.5) * shake)
        camera.CFrame *= CFrame.Angles(x, y, 0)
    end
end)
