-- NOTE: was Disabled in Studio
wait (.1)

local m = script.Parent.Parent.Parent.P1.SS.Motor
local n = script.Parent.Parent.Parent.P2.SS.Motor

script.Parent.MouseClick:connect(function()
	if m.DesiredAngle == 0 then
		m.DesiredAngle = 1.5
		n.DesiredAngle = -3
		script.Parent.Parent.Parent.Inferface.SurfaceGui.Frame.TextLabel.Text = "Garage Door: Open"
	elseif m.DesiredAngle == 1.5 then
		m.DesiredAngle = 0
		n.DesiredAngle = 0
		script.Parent.Parent.Parent.Inferface.SurfaceGui.Frame.TextLabel.Text = "Garage Door: Closed"
		end
end)