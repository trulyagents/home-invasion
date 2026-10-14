local prompt = script.Parent
local chair = prompt.Parent

prompt.Triggered:Connect(function(plr)
	chair:Sit(plr.Character.Humanoid)
end)

chair.Changed:Connect(function(change)
	if chair.Occupant then
		prompt.Enabled = false
	else
		prompt.Enabled = true
	end
end)