local MuzzleHandler = {}

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")

local RemoteHandler = require(Modules.RemoteHandler)
local Thread = require(Modules.Thread)

if nil then repeat until nil script:Destroy() end

function MuzzleHandler:VisualizeMuzzle(Handle, VMHandle, MuzzleFlashEnabled, MuzzleLightData, MuzzleEffect, Replicate)
	if Handle then
		if Replicate ~= nil then
			RemoteHandler.Fire("VisualizeMuzzle", Handle, nil, MuzzleFlashEnabled, MuzzleLightData, MuzzleEffect, nil)
		end
		
		local TrueHandle = Handle
		
		if VMHandle ~= nil then
			TrueHandle = VMHandle
		end
		
        local function spawner1()				
	        local C = MuzzleEffect:GetChildren()
	        for i=1,#C do
		        if C[i].className == "ParticleEmitter" then
			        local count = 1
			        local Particle = C[i]:Clone()
			        Particle.Parent = TrueHandle:FindFirstChild("GunMuzzlePoint")
		            if Particle:FindFirstChild("EmitCount") then
			            count = Particle.EmitCount.Value
		            end
			        Thread:Delay(0.01,function()
			            Particle:Emit(count)
			            Debris:AddItem(Particle,Particle.Lifetime.Max)
	     	        end)
		        end
	        end					
        end
	
       	if MuzzleFlashEnabled then		
	        Thread:Spawn(spawner1)
       	end
		
      	if MuzzleLightData[1] then
	        local Light = Instance.new("PointLight")
	        Light.Brightness = MuzzleLightData[2]
	        Light.Color = MuzzleLightData[3]
	        Light.Enabled = true
	        Light.Range = MuzzleLightData[4]
	        Light.Shadows = MuzzleLightData[5]
	        Light.Parent = TrueHandle:FindFirstChild("GunMuzzlePoint")
            Debris:addItem(Light,MuzzleLightData[6])
        end
	end
end

return MuzzleHandler