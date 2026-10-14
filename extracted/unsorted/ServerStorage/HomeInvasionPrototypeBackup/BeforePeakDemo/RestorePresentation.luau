-- Invoke only in Edit mode to revert this presentation pass.
return function()
    assert(not game:GetService("RunService"):IsRunning(), "Stop Play before restoring.")
    local backup = script.Parent
    local function resolve(path)
        local current = game
        for name in path:gmatch("[^.]+") do
            current = current:FindFirstChild(name)
            if not current then return nil end
        end
        return current
    end
    for _, saved in backup.Scripts:GetChildren() do
        local target = resolve(saved.Name)
        if target and target:IsA("LuaSourceContainer") then target.Source = saved.Source end
    end
    for _, reference in backup.PropertyStates:GetChildren() do
        local target = reference.Value
        if target then
            for property, value in reference:GetAttributes() do
                target[property] = value
            end
        end
    end
    for property, value in backup.Settings:GetAttributes() do game.Lighting[property] = value end
    for _, name in {"DemoColorGrade", "DemoAtmosphere"} do
        local effect = game.Lighting:FindFirstChild(name)
        if effect then effect:Destroy() end
    end
    local arena = workspace.HomeInvasionPrototype
    local oldLobby = arena:FindFirstChild("Lobby")
    if oldLobby then oldLobby:Destroy() end
    backup.Lobby:Clone().Parent = arena
    local presentation = arena:FindFirstChild("Presentation")
    if presentation then presentation:Destroy() end
    for _, reference in backup.MovedHouseSigns:GetChildren() do
        if reference.Value and reference.OriginalParent.Value then reference.Value.Parent = reference.OriginalParent.Value end
    end
    for _, root in backup.ArchivedWorkspace:GetChildren() do
        root.Parent = root.Name == "Casa" and workspace.Bosque or workspace
    end
    for _, saved in backup.Gui:GetChildren() do
        local current = game.StarterGui:FindFirstChild(saved.Name)
        if current then current:Destroy() end
        saved:Clone().Parent = game.StarterGui
    end
    for _, name in {"DemoFeedbackHUD"} do
        local current = game.StarterGui:FindFirstChild(name)
        if current then current:Destroy() end
    end
    local client = game.StarterPlayer.StarterPlayerScripts:FindFirstChild("DemoPresentationClient")
    if client then client:Destroy() end
    local audio = game.SoundService:FindFirstChild("HomeInvasionPresentation")
    if audio then audio:Destroy() end
    for _, model in arena.Doors:GetChildren() do
        if model:IsA("Model") then
            for _, name in {"DoorMove", "DoorLock", "BreachSound"} do
                local sound = model.DoorCollider:FindFirstChild(name)
                if sound then sound:Destroy() end
            end
        end
    end
    for _, name in {"Crossbow", "Rifle"} do
        game.ServerStorage.HomeInvasionWeaponTemplates[name]:Destroy()
        backup[name]:Clone().Parent = game.ServerStorage.HomeInvasionWeaponTemplates
    end
    for _, name in {"FootstepSounds", "KillNotification"} do
        game.StarterPlayer.StarterCharacterScripts[name]:Destroy()
        backup[name]:Clone().Parent = game.StarterPlayer.StarterCharacterScripts
    end
    return "Presentation pass restored."
end
