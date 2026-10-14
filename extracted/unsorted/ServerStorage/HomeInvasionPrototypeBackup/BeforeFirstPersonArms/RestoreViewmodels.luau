return function()
    local RunService = game:GetService("RunService")
    assert(RunService:IsStudio() and not RunService:IsRunning(), "Stop the playtest before restoring.")
    local backup = script.Parent
    local weapons = game.ServerScriptService.HomeInvasionWeaponSystem
    weapons.WeaponServer.Source = backup.HomeInvasionWeaponSystem.WeaponServer.Source
    local client = game.StarterPlayer.StarterPlayerScripts:FindFirstChild("FirstPersonViewmodelClient")
    if client then client:Destroy() end
    local assets = game.ReplicatedStorage:FindFirstChild("HomeInvasionFirstPersonAssets")
    if assets then assets:Destroy() end
    return "Camera arms and weapon animations removed; previous server source restored."
end
