script.Parent = game.StarterGui
H = script.Parent.Parent.Character.Humanoid

while true do
	if H.Health == 0 then
		script.DeathEffect.Disabled = false
		script.RestoreEffects.Disabled = false
		wait()
	end
	wait()
end
--HIGHLY RECOMMENDED THAT YOU PUT THIS IN STARTERGUI
