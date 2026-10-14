--Original sciprt was made by LAZY_DAISY001 (Maybe)
--Edied by me using ACS

local camera = game.Workspace.CurrentCamera

local runservice = game:GetService("RunService")


runservice.Stepped:connect(function()
	for index, Part in pairs(workspace.Camera.Arms:GetDescendants()) do
		if Part:IsA("BasePart") and Part.Name == "ProjectorSight" then	
			local dist_scale = Part.CFrame:pointToObjectSpace(camera.CFrame.Position)/Part.Size

			local reticle = Part.SurfaceGui.ClippingFrame.Reticle	
			reticle.Position=UDim2.new(.5+dist_scale.x,0,.50-dist_scale.y,0)	
		end
	end
end)