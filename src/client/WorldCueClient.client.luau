-- noise markers for invaders, plus the thunder flash and short blackouts from random events
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("HomeInvasionTasks"):WaitForChild("Interaction")

local function noiseMarker(position)
    local anchor = Instance.new("Part")
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.CanQuery = false
    anchor.CanTouch = false
    anchor.Transparency = 1
    anchor.Size = Vector3.one
    anchor.Position = position + Vector3.new(0, 3, 0)
    anchor.Parent = workspace.CurrentCamera
    local billboard = Instance.new("BillboardGui")
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.fromOffset(46, 46)
    billboard.Parent = anchor
    local ring = Instance.new("Frame")
    ring.AnchorPoint = Vector2.new(0.5, 0.5)
    ring.Position = UDim2.fromScale(0.5, 0.5)
    ring.Size = UDim2.fromScale(0.4, 0.4)
    ring.BackgroundTransparency = 1
    ring.Parent = billboard
    Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
    local stroke = Instance.new("UIStroke", ring)
    stroke.Color = Color3.fromRGB(230, 60, 50)
    stroke.Thickness = 3
    TweenService:Create(ring, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 1), { Size = UDim2.fromScale(1, 1) }):Play()
    TweenService:Create(stroke, TweenInfo.new(2.4), { Transparency = 1 }):Play()
    task.delay(2.5, function()
        anchor:Destroy()
    end)
end

local flash = Instance.new("ColorCorrectionEffect")
flash.Name = "ThunderFlash"
flash.Parent = Lighting

local function thunder()
    flash.Brightness = 0.6
    TweenService:Create(flash, TweenInfo.new(0.5), { Brightness = 0 }):Play()
    task.delay(0.25, function()
        flash.Brightness = 0.4
        TweenService:Create(flash, TweenInfo.new(0.6), { Brightness = 0 }):Play()
    end)
end

local blackoutToken = 0
local function blackout(seconds)
    blackoutToken += 1
    local token = blackoutToken
    -- only on this client, the real power state stays on the server
    local turnedOff = {}
    for _, light in workspace:GetDescendants() do
        if light:IsA("Light") and light.Enabled and not light:FindFirstAncestorOfClass("Tool")
            and not (player.Character and light:IsDescendantOf(player.Character)) then
            light.Enabled = false
            table.insert(turnedOff, light)
        end
    end
    local brightness = Lighting.Brightness
    Lighting.Brightness = math.min(brightness, 0.6)
    task.delay(seconds, function()
        -- if the invaders cut the power meanwhile, leave it dark
        if token ~= blackoutToken or ReplicatedStorage.HomeInvasionRoundState:GetAttribute("PowerOn") == false then
            return
        end
        for _, light in turnedOff do
            if light.Parent then
                light.Enabled = true
            end
        end
        Lighting.Brightness = brightness
    end)
end

remote.OnClientEvent:Connect(function(action, first, second)
    if action == "Noise" and typeof(first) == "Vector3" then
        noiseMarker(first)
    elseif action == "Event" and first == "Thunder" then
        thunder()
    elseif action == "Event" and first == "Blackout" and typeof(second) == "number" then
        blackout(second)
    end
end)
