-- Run manually from the Edit-mode Command Bar only when you want to remove this prototype:
-- require(game.ServerStorage.HomeInvasionPrototypeBackup.Restore)()
return function()
    assert(not game:GetService("RunService"):IsRunning(), "Stop the playtest first")
    local backup = script.Parent
    local lightingBackup = backup:FindFirstChild("Lighting")
    assert(lightingBackup, "Lighting backup missing")
    for key, value in pairs(lightingBackup:GetAttributes()) do
        game.Lighting[key] = value
    end
    for _, item in ipairs(lightingBackup:GetChildren()) do
        item.Parent = game.Lighting
    end
    local dynamic = game.ServerScriptService:FindFirstChild("Dynamic Lighting")
    if dynamic then
        dynamic.Disabled = backup:GetAttribute("DynamicLightingDisabled")
    end
    for _, tool in ipairs(backup.StarterPack:GetChildren()) do
        tool.Parent = game.StarterPack
    end
    local originalSpawn = backup.OriginalSpawn.Value
    if originalSpawn then
        originalSpawn.Enabled = backup:GetAttribute("OriginalSpawnEnabled")
    end
    for _, reference in ipairs(backup.CreatedInstances:GetChildren()) do
        if reference.Value then
            reference.Value:Destroy()
        end
    end
    print("Prototype removed; original lighting, starter tools, and spawn setting restored.")
end
