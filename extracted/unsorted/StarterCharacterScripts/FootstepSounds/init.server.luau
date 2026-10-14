local humanoid = script.Parent:WaitForChild("Humanoid")
local root = script.Parent:WaitForChild("HumanoidRootPart")
local definitions = require(script:FindFirstChildWhichIsA("ModuleScript"))
local sound = Instance.new("Sound")
sound.Name = "CurrentSound"
sound.Looped = true
sound.RollOffMinDistance = 5
sound.RollOffMaxDistance = 45
sound.Parent = root

-- Footsteps are cosmetic. No client request can change the server's WalkSpeed.
humanoid.Running:Connect(function(speed)
    local definition = definitions[humanoid.FloorMaterial.Name] or definitions.Concrete
    sound.SoundId = definition.id
    sound.Volume = definition.volume * .55
    sound.PlaybackSpeed = math.clamp(speed / 16, .5, 1.4) * definition.speed
    if speed > .5 and humanoid.Health > 0 and humanoid.FloorMaterial ~= Enum.Material.Air then
        if not sound.Playing then sound:Play() end
    else
        sound:Stop()
    end
end)
humanoid.Died:Connect(function() sound:Stop() end)
