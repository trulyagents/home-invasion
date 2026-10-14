-- Edit-mode rollback for this interaction repair only.
return function()
    local RunService = game:GetService("RunService")
    assert(RunService:IsStudio() and not RunService:IsRunning(), "Stop the playtest before restoring.")
    local backup = script.Parent
    local function restoreFolder(parent, name)
        local current = parent:FindFirstChild(name)
        if current then current:Destroy() end
        backup[name]:Clone().Parent = parent
    end
    for _, name in {"HomeInvasionWeaponSystem", "HomeInvasionFurnitureSystem", "HomeInvasionDoorSystem"} do
        restoreFolder(game.ServerScriptService, name)
    end
    for _, saved in backup.Scripts:GetChildren() do
        local current = game.StarterPlayer.StarterPlayerScripts:FindFirstChild(saved.Name)
        assert(current, "Missing original script: " .. saved.Name)
        current.Source = saved.Source
        current.Enabled = saved.Enabled
    end
    restoreFolder(game.ServerStorage, "HomeInvasionWeaponTemplates")
    restoreFolder(game.StarterGui, "FurnitureDraggingHUD")
    restoreFolder(game.StarterGui, "WeaponHUD")
    game.StarterGui.HomeInvasionRoundHUD.Help.Body.Text = backup.OriginalHelpText.Value
    for _, target in {
        game.ServerScriptService:FindFirstChild("HomeInvasionAnimationSystem"),
        game.ReplicatedStorage:FindFirstChild("HomeInvasionAnimations"),
        game.ReplicatedStorage:FindFirstChild("HomeInvasionDoors"),
        game.StarterGui:FindFirstChild("ContextInteractionHUD"),
    } do
        if target then target:Destroy() end
    end
    for _, reference in backup.LegacyPrompts:GetChildren() do
        if reference.Value then reference.Value.Enabled = true end
    end
    if backup:FindFirstChild("OriginalEntranceGeometry") and backup.EntranceCollisionPart.Value then
        backup.EntranceCollisionPart.Value:SubstituteGeometry(backup.OriginalEntranceGeometry)
    end
    return "Interaction systems restored to the before-repair snapshots."
end
