-- NOTE: was Disabled in Studio
local car = script.Parent.Parent.Parent.Car.Value
local mouse = game.Players.LocalPlayer:GetMouse()
script.Parent:WaitForChild("Reverse")
if not car.DriveSeat:FindFirstChild("Reverse") then
script.Parent.Reverse:Clone().Parent = car.DriveSeat
end
car.DriveSeat:WaitForChild("Reverse")
---
if 	script.Parent.Parent.Parent.IsOn.Value then
	script.Parent.Parent:TweenPosition(UDim2.new(0, 0, 0, 0),Enum.EasingDirection.InOut,Enum.EasingStyle.Quad,1,true)
end
	script.Parent.MouseButton1Click:connect(function()
		if car.Body.Lights.L.L.L.Enabled == false and car.Body.Lights.H.L.L.Enabled == false then
			script.Parent.BackgroundColor3 = Color3.new(0,255/255,0)
			script.Parent.TextStrokeColor3 = Color3.new(0,255/255,0)
			car.Body.Lights.L.L.L.Enabled = true
			car.Body.Lights.R.L.L.Enabled = true
			car.Body.Lights.H.L.L.Enabled = false
			for index, child in pairs(car.Body.Lights.L:GetChildren()) do
			child.Material = Enum.Material.Neon
			car.Body.Lights.light1.light1.light.Enabled = true
			car.Body.Lights.light2.light1.light.Enabled = true
			end
			for index, child in pairs(car.Body.Lights.R:GetChildren()) do
			child.Material = Enum.Material.Neon
			end
			for index, child in pairs(car.Body.Lights.H:GetChildren()) do
			child.Material = Enum.Material.SmoothPlastic
			end
		elseif car.Body.Lights.L.L.L.Enabled == true and car.Body.Lights.H.L.L.Enabled == false then
			script.Parent.BackgroundColor3 = Color3.new(0,0,255/255)
			script.Parent.TextStrokeColor3 = Color3.new(0,0,255/255)
			car.Body.Lights.L.L.L.Enabled = true
			car.Body.Lights.R.L.L.Enabled = true
			car.Body.Lights.H.L.L.Enabled = true
			for index, child in pairs(car.Body.Lights.L:GetChildren()) do
			child.Material = Enum.Material.Neon
			car.Body.Lights.light1.light1.light.Enabled = true
			car.Body.Lights.light2.light1.light.Enabled = true
			end
			for index, child in pairs(car.Body.Lights.R:GetChildren()) do
			child.Material = Enum.Material.Neon
			end
			for index, child in pairs(car.Body.Lights.H:GetChildren()) do
			child.Material = Enum.Material.Neon
			end
		elseif car.Body.Lights.L.L.L.Enabled == true and car.Body.Lights.H.L.L.Enabled == true then
			script.Parent.BackgroundColor3 = Color3.new(0,0,0)
			script.Parent.TextStrokeColor3 = Color3.new(0,0,0)
			car.Body.Lights.L.L.L.Enabled = false
			car.Body.Lights.R.L.L.Enabled = false
			car.Body.Lights.H.L.L.Enabled = false
			for index, child in pairs(car.Body.Lights.L:GetChildren()) do
			child.Material = Enum.Material.SmoothPlastic
			car.Body.Lights.light1.light1.light.Enabled = false
			car.Body.Lights.light2.light1.light.Enabled = false
			end
			for index, child in pairs(car.Body.Lights.R:GetChildren()) do
			child.Material = Enum.Material.SmoothPlastic
			end
			for index, child in pairs(car.Body.Lights.H:GetChildren()) do
			child.Material = Enum.Material.SmoothPlastic
			end
		end
	end)
	
	script.Parent.Parent.Parent.Values.Brake.Changed:connect(function()
		if script.Parent.Parent.Parent.Values.Brake.Value ~= 1 and script.Parent.Parent.Parent.IsOn.Value then
			for index, child in pairs(car.Body.Lights.B:GetChildren()) do
			child.Material = Enum.Material.SmoothPlastic
			end
			car.Body.Lights.B.L.L.Enabled = false
		else
			for index, child in pairs(car.Body.Lights.B:GetChildren()) do
			child.Material = Enum.Material.Neon
			end
			car.Body.Lights.B.L.L.Enabled = true
		end
	end)
	
	script.Parent.Parent.Parent.Values.Brake.Changed:connect(function()
		if script.Parent.Parent.Parent.Values.Brake.Value ~= 1 then
			for index, child in pairs(car.Body.Lights.B:GetChildren()) do
			child.Material = Enum.Material.SmoothPlastic
			end
			car.Body.Lights.B.L.L.Enabled = false
		else
			for index, child in pairs(car.Body.Lights.B:GetChildren()) do
			child.Material = Enum.Material.Neon
			end
			car.Body.Lights.B.L.L.Enabled = true
		end
	end)
	
	script.Parent.Parent.Parent.Values.Gear.Changed:connect(function()
		if script.Parent.Parent.Parent.Values.Gear.Value == -1 then
			for index, child in pairs(car.Body.Lights.Rev:GetChildren()) do
			child.Material = Enum.Material.Neon
			car.DriveSeat.Reverse:Play()
			end
		else
			for index, child in pairs(car.Body.Lights.Rev:GetChildren()) do
			child.Material = Enum.Material.SmoothPlastic
			car.DriveSeat.Reverse:Stop()
			end
		end
	end)
	
	while wait() do
		if (car.DriveSeat.Velocity.magnitude/40)+0.300 < 1.3 then
		car.DriveSeat.Reverse.Pitch = (car.DriveSeat.Velocity.magnitude/40)+0.300
		car.DriveSeat.Reverse.Volume = (car.DriveSeat.Velocity.magnitude/150)	
		else
		car.DriveSeat.Reverse.Pitch = 1.3
		car.DriveSeat.Reverse.Volume = .2
		end
	end