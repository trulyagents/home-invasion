-- One-time cleanup of the old gun kit. Paste into Studio's Command Bar (View → Command Bar)
-- and press Enter, then save the place. Ctrl+Z undoes it if something goes wrong.
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local recording = ChangeHistoryService:TryBeginRecording("Remove old gun kit")

local targets = {
	{ "ReplicatedStorage", "Guns" },
	{ "ReplicatedStorage", "Miscs" },
	{ "ReplicatedStorage", "Remotes" },
	{ "ReplicatedStorage", "Events" },
	{ "ReplicatedStorage", "Modules" },
	{ "ReplicatedStorage", "Shared" },
	{ "ReplicatedStorage", "HomeInvasionFirstPersonAssets", "Weapons", "Rifle" },
	{ "ServerStorage", "HomeInvasionPrototypeBackup" },
	{ "ServerStorage", "HomeInvasionWeaponTemplates", "Rifle" },
	{ "ServerScriptService", "Server" },
	{ "StarterGui", "Realistic Head Movement" },
	{ "StarterGui", "Death" },
	{ "StarterGui", "NeoHotbar" },
	{ "StarterGui", "ViewmodelScript" },
	{ "StarterGui", "HotbarGUI" },
	{ "StarterPlayer", "StarterCharacterScripts", "KillNotification" },
	{ "StarterPlayer", "StarterPlayerScripts", "Client" },
}

local removed = 0
for _, path in ipairs(targets) do
	local instance = game:GetService(path[1])
	for i = 2, #path do
		instance = instance and instance:FindFirstChild(path[i])
	end
	if instance then
		instance:Destroy()
		removed += 1
		print("Removed " .. table.concat(path, "."))
	end
end
for _, tool in ipairs(game:GetService("StarterPack"):GetChildren()) do
	tool:Destroy()
	removed += 1
	print("Removed StarterPack." .. tool.Name)
end

if recording then
	ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
end
print(("Cleanup done: removed %d things. Save the place now."):format(removed))
