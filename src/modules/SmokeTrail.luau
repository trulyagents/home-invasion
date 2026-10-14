local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local Thread = require(game.ReplicatedStorage.Modules.Thread)

local SmokeTrail = {}

local Emitting = false
local ForceStop = false

function SmokeTrail:EmitSmokeTrail(Trail, VMTrail, MaxEmitTime)
	local StartTime = tick()
	while true do
		local DeltaTime = tick() - StartTime
		Emitting = true
		if ForceStop or DeltaTime >= MaxEmitTime then
			Emitting = false
			ForceStop = false
			break
		end
		if (Camera.Focus.p-Camera.CoordinateFrame.p).magnitude <= 1 then
			Trail.Enabled = false
			VMTrail.Enabled = true
		else
			Trail.Enabled = true
			VMTrail.Enabled = false
		end
		Thread:Wait()
	end
	Emitting = false
	Trail.Enabled = false
	VMTrail.Enabled = false
end

function SmokeTrail:StopEmission()
	if Emitting == true then
		ForceStop = true
	end
end

return SmokeTrail