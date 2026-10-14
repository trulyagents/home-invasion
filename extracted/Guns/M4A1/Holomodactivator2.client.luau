local Tool = script.Parent





Tool.Equipped:connect(function(TempMouse)
	game.Players.LocalPlayer.PlayerScripts.Holomod2.Disabled = false
end)

Tool.Unequipped:connect(function()
	game.Players.LocalPlayer.PlayerScripts.Holomod2.Disabled = true
end)