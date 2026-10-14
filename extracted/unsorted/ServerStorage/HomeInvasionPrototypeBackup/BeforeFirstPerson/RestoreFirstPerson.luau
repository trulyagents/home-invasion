return function()
    local RunService = game:GetService("RunService")
    assert(RunService:IsStudio() and not RunService:IsRunning(), "Stop the playtest before restoring.")
    local backup = script.Parent
    for _, name in {"DemoPresentationClient", "HomeInvasionRoundHUD", "WeaponClient", "FurnitureClient", "DoorClient"} do
        local current = game.StarterPlayer.StarterPlayerScripts[name]
        current.Source = backup[name].Source
        current.Enabled = backup[name].Enabled
    end
    local weapons = game.ServerScriptService.HomeInvasionWeaponSystem
    weapons.WeaponServer.Source = backup.HomeInvasionWeaponSystem.WeaponServer.Source
    weapons.Config.Source = backup.HomeInvasionWeaponSystem.Config.Source
    local cameraSettings = backup.CameraSettings
    game.StarterPlayer.CameraMode = Enum.CameraMode[cameraSettings:GetAttribute("Mode")]
    game.StarterPlayer.CameraMinZoomDistance = cameraSettings:GetAttribute("MinimumZoom")
    game.StarterPlayer.CameraMaxZoomDistance = cameraSettings:GetAttribute("MaximumZoom")
    game.StarterGui.HomeInvasionRoundHUD.Help:Destroy()
    backup.Help:Clone().Parent = game.StarterGui.HomeInvasionRoundHUD
    game.StarterGui.SpectatorHUD:Destroy()
    backup.SpectatorHUD:Clone().Parent = game.StarterGui
    return "First-person change restored to its previous snapshots."
end
