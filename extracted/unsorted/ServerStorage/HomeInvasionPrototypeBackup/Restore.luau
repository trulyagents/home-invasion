-- Run manually from the Edit-mode Command Bar only when you want to remove this prototype:
-- require(game.ServerStorage.HomeInvasionPrototypeBackup.Restore)()
return function()
    assert(not game:GetService("RunService"):IsRunning(), "Stop the playtest first")
    local backup = script.Parent
    local doorCheckpoint = backup:FindFirstChild("BeforeDoorsAndWeapons")
    if doorCheckpoint then
        require(doorCheckpoint.RestoreDoorAssets)()
    end
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
    local weaponCheckpoint = backup:FindFirstChild("BeforeWeaponPickups")
    if weaponCheckpoint then
        for _, reference in ipairs(weaponCheckpoint:GetChildren()) do
            if reference:IsA("ObjectValue") and reference.Value then
                local originalDisabled = reference:GetAttribute("OriginalDisabled")
                if originalDisabled ~= nil then
                    reference.Value.Disabled = originalDisabled
                end
                local originalPivot = reference:GetAttribute("OriginalPivot")
                if originalPivot then
                    reference.Value:PivotTo(originalPivot)
                end
            end
        end
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
