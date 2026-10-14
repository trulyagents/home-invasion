local ProjectileHandler = {}

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")

local ParticleFramework = require(Modules.ParticleFramework)
local Thread = require(Modules.Thread)
local RemoteHandler = require(Modules.RemoteHandler)
local ScreenCulling = require(Modules.ScreenCulling)

-- Properties
local RenderDistance = 400
local ScreenCullingEnabled = true
local ScreenCullingRadius = 16

if nil then repeat until nil script:Destroy() end

local function numLerp(A, B, Alpha)
	return A + (B - A) * Alpha
end

local function findFirstByClass(dir,class) -- Utility function to find the first child of a given class.
	for _,i in pairs(dir:children()) do
		if (i:IsA(class)) then return i end
	end
	return nil
end

local function vectorRandom(a, b)
	local p = math.acos(1 - 2 * math.random()) / 3
	local z = 1.7320508075688772 * math.sin(p) - math.cos(p)
	local r = ((1 - z * z) * math.random()) ^ 0.5
	local t = 6.28318 * math.random()
	local x = r * math.cos(t)
	local y = r * math.sin(t)
	if b then
		local m = (a + (b - a) * math.random()) / (x * x + y * y + z * z) ^ 0.5
		return Vector3.new(m * x, m * y, m * z)
	elseif a then
		return Vector3.new(a * x, a * y, a * z)
	else
		return Vector3.new(x, y, z)
	end
end

local function MakeImpactFX(Velocity, Hit, Position, Normal, Material, HitEffectData, BulletHoleData)
	if Hit ~= nil and Position ~= nil and Normal ~= nil then
		local surfaceCF = CFrame.new(Position, Position + Normal)
			
   		if HitEffectData[1] then		
			local Attachment = Instance.new("Attachment")
			Attachment.CFrame = surfaceCF
	    	Attachment.Parent = Workspace.Terrain
			local Sound
			
			local function spawner2(material)
				if HitEffectData[6][material.Name]:FindFirstChild("MaterialSounds") then
		            local tracks = HitEffectData[6][material.Name].MaterialSounds:GetChildren()
		            local rn = math.random(1, #tracks)
		            local track = tracks[rn]
		            if track ~= nil then
						Sound = track:Clone()
						if track:FindFirstChild("Pitch") then
							Sound.PlaybackSpeed = Random.new():NextNumber(track.Pitch.Min.Value, track.Pitch.Max.Value)
						else
							Sound.PlaybackSpeed = Random.new():NextNumber(HitEffectData[3], HitEffectData[4])
						end
						if track:FindFirstChild("Volume") then
							Sound.Volume = Random.new():NextNumber(track.Volume.Min.Value, track.Volume.Max.Value)
						else
							Sound.Volume = HitEffectData[5]
						end
						Sound.Parent = Attachment
		            end
				else
					Sound = Instance.new("Sound",Attachment)
					Sound.SoundId = "rbxassetid://"..HitEffectData[2][math.random(1,#HitEffectData[2])]
					Sound.PlaybackSpeed = Random.new():NextNumber(HitEffectData[3], HitEffectData[4])
					Sound.Volume = HitEffectData[5]
				end
	        	local C = HitEffectData[6][material.Name]:GetChildren()
	        	for i=1,#C do
		        	if C[i].className == "ParticleEmitter" then
			        	local count = 1
			        	local Particle = C[i]:Clone()
			        	Particle.Parent = Attachment
		            	if Particle:FindFirstChild("EmitCount") then
			            	count = Particle.EmitCount.Value
		            	end
				    	if Particle.PartColor.Value then
							local hitPartColor = Hit and Hit.Color or Color3.fromRGB(255, 255, 255)
							if Hit and Hit:IsA("Terrain") then
								hitPartColor = Workspace.Terrain:GetMaterialColor(Material or Enum.Material.Sand)
							end
			            	Particle.Color = ColorSequence.new(hitPartColor,hitPartColor)
		            	end
			        	Thread:Delay(0.01,function()
			            	Particle:Emit(count)
			            	Debris:AddItem(Particle, Particle.Lifetime.Max)
		            	end)
		        	end
	        	end
	        	Sound:Play()
				if HitEffectData[6][material.Name]:FindFirstChild("EmitSparks") then
					if HitEffectData[6][material.Name].EmitSparks.Value then
						for i = 1, math.random(0, 2) * 2 + 1 do
							ParticleFramework.new({
								position = Position,
								velocity = (Velocity - 1.2 * Normal:Dot(Velocity) / Normal:Dot(Normal) * Normal) * 0.1 + vectorRandom(50), --Normal * 50 + vectorRandom(20)
								acceleration = Vector3.new(0, -Workspace.Gravity, 0), --Vector3.new(0, -196.2, 0),
								visible = true,
								cancollide = false,
								size = 0.1,
								brightness = 20 * math.random(),
								color = (Hit and HitEffectData[6][material.Name].EmitSparks:FindFirstChild("PartColor")) and Hit.Color or Color3.new(1, 1, 0.8),
								bloom = 0.005 * math.random(),
								life = math.random() * 0.25 --0.1
							})
						end
					end
				end
			    if BulletHoleData[1] then
					local Hole = Instance.new("Part")
					Hole.Name = "BulletHole"
					Hole.Transparency = 1
					Hole.Anchored = true
					Hole.CanCollide = false
					Hole.FormFactor = "Custom"
					Hole.Size = Vector3.new(1, 1, 0.2)
					Hole.TopSurface = 0
					Hole.BottomSurface = 0
					local Mesh = Instance.new("BlockMesh")
					Mesh.Offset = Vector3.new(0, 0, 0)
					if HitEffectData[6][material.Name]:FindFirstChild("MaterialHoleSize") then
						Mesh.Scale = Vector3.new(HitEffectData[6][material.Name].MaterialHoleSize.Value, HitEffectData[6][material.Name].MaterialHoleSize.Value, 0)
					else
						Mesh.Scale = Vector3.new(BulletHoleData[2], BulletHoleData[2], 0)
					end
					Mesh.Parent = Hole
					local Decal
					if HitEffectData[6][material.Name]:FindFirstChild("MaterialDecals") then
			            local decals = HitEffectData[6][material.Name].MaterialDecals:GetChildren()
			            local rn = math.random(1, #decals)
			            local decal = decals[rn]
			            if decal ~= nil then
							Decal = decal:Clone()
							Decal.Face = Enum.NormalId.Front
							if Decal.PartColor.Value then
								local hitPartColor = Hit and Hit.Color or Color3.fromRGB(255, 255, 255)
								if Hit and Hit:IsA("Terrain") then
									hitPartColor = Workspace.Terrain:GetMaterialColor(Material or Enum.Material.Sand)
								end
								Decal.Color3 = hitPartColor
							end
							Decal.Parent = Hole
			            end
					else
						Decal = Instance.new("Decal")
						Decal.Face = Enum.NormalId.Front
						Decal.Texture = "rbxassetid://"..BulletHoleData[3][math.random(1,#BulletHoleData[3])]
					    if BulletHoleData[4] then
							local hitPartColor = Hit and Hit.Color or Color3.fromRGB(255, 255, 255)
							if Hit and Hit:IsA("Terrain") then
								hitPartColor = Workspace.Terrain:GetMaterialColor(Material or Enum.Material.Sand)
							end
							Decal.Color3 = hitPartColor
						end
						Decal.Parent = Hole
					end
					Hole.Parent = Workspace.CurrentCamera
					Hole.CFrame = surfaceCF * CFrame.Angles(0, 0, math.random(0, 360))
					if (not Hit.Anchored) then
						-- Weld hitMark to the hitPart.
						local weld = Instance.new("WeldConstraint")
						weld.Part0 = Hole
						weld.Part1 = Hit
						weld.Parent = Hole
						--[[local Weld = Instance.new("Weld", Hole)
						Weld.Part0 = Hit
						Weld.Part1 = Hole
					    Weld.C0 = Hit.CFrame:toObjectSpace(surfaceCF * CFrame.Angles(0, 0, math.random(0, 360)))]]
						Hole.Anchored = false
				    end
					Thread:Delay(BulletHoleData[5], function()
						if BulletHoleData[5] > 0 then
							local t0 = tick()
							while true do
								local Alpha = math.min((tick() - t0) / BulletHoleData[6], 1)
								if Decal then Decal.Transparency = numLerp(0, 1, Alpha) end
							    if Alpha == 1 then break end
						      	game:GetService("RunService").Heartbeat:Wait()
							end
						    Hole:Destroy()
						else
						    Hole:Destroy()
					    end
					end)
			    end
			end
		
        	if not HitEffectData[7] then
            	if Hit.Material==Enum.Material.Plastic then spawner2(Hit.Material) end
            	if Hit.Material==Enum.Material.Slate then spawner2(Hit.Material) end
	        	if Hit.Material==Enum.Material.Concrete then spawner2(Hit.Material) end
	        	if Hit.Material==Enum.Material.CorrodedMetal then spawner2(Hit.Material) end
		    	if Hit.Material==Enum.Material.DiamondPlate then spawner2(Hit.Material) end
            	if Hit.Material==Enum.Material.Foil then spawner2(Hit.Material) end
            	if Hit.Material==Enum.Material.Marble then spawner2(Hit.Material) end
	        	if Hit.Material==Enum.Material.Granite then	spawner2(Hit.Material) end        
		    	if Hit.Material==Enum.Material.Brick then spawner2(Hit.Material) end          
	        	if Hit.Material==Enum.Material.Pebble then spawner2(Hit.Material) end          
		    	if Hit.Material==Enum.Material.SmoothPlastic then spawner2(Hit.Material) end          
	        	if Hit.Material==Enum.Material.Metal then spawner2(Hit.Material) end         
	        	if Hit.Material==Enum.Material.Cobblestone then spawner2(Hit.Material) end
	        	if Hit.Material==Enum.Material.Neon then spawner2(Hit.Material) end
		    	if Hit.Material==Enum.Material.Wood then spawner2(Hit.Material) end
		    	if Hit.Material==Enum.Material.WoodPlanks then spawner2(Hit.Material) end
	        	if Hit.Material==Enum.Material.Glass then spawner2(Hit.Material) end
		    	if Hit.Material==Enum.Material.Grass then spawner2(Hit.Material) end
		    	if Hit.Material==Enum.Material.Sand then spawner2(Hit.Material) end
		    	if Hit.Material==Enum.Material.Fabric then spawner2(Hit.Material) end
		    	if Hit.Material==Enum.Material.Ice then spawner2(Hit.Material) end
        	else
	        	spawner2(HitEffectData[6].Custom)
        	end

			Debris:AddItem(Attachment, 10)				
		end
	end
end

local function MakeBloodFX(Hit, Position, Normal, Material, BloodEffectData)
	if Hit ~= nil and Position ~= nil and Normal ~= nil then
		local surfaceCF = CFrame.new(Position, Position + Normal)
		
	    if BloodEffectData[1] then
			local Attachment = Instance.new("Attachment")
			Attachment.CFrame = surfaceCF
			Attachment.Parent = Workspace.Terrain
			
			local Sound = Instance.new("Sound",Attachment)
			Sound.SoundId = "rbxassetid://"..BloodEffectData[2][math.random(1,#BloodEffectData[2])]
			Sound.PlaybackSpeed = Random.new():NextNumber(BloodEffectData[3], BloodEffectData[4])
			Sound.Volume = BloodEffectData[5]
		
			local function spawner3()
		        local C = BloodEffectData[6]:GetChildren()
		        for i=1,#C do
			        if C[i].className == "ParticleEmitter" then
				        local count = 1
				        local Particle = C[i]:Clone()
				        Particle.Parent = Attachment
			            if Particle:FindFirstChild("EmitCount") then
				            count = Particle.EmitCount.Value
			            end
				        Thread:Delay(0.01,function()
				            Particle:Emit(count)
				            Debris:AddItem(Particle, Particle.Lifetime.Max)
			            end)
			        end
		        end
		        Sound:Play()
			end
			
		    Thread:Spawn(spawner3)
		    Debris:AddItem(Attachment, 10)
	    end

		if BloodEffectData[7][1] then
			local Hole = Instance.new("Part")
			Hole.Name = "BloodWound"
			Hole.Transparency = 1
			Hole.Anchored = true
			Hole.CanCollide = false
			Hole.FormFactor = "Custom"
			Hole.Size = Vector3.new(1, 1, 0.2)
			Hole.TopSurface = 0
			Hole.BottomSurface = 0
			local Mesh = Instance.new("BlockMesh")
			Mesh.Offset = Vector3.new(0, 0, 0)
			Mesh.Scale = Vector3.new(BloodEffectData[7][2], BloodEffectData[7][2], 0)
			Mesh.Parent = Hole
			local Decal = Instance.new("Decal")
			Decal.Face = Enum.NormalId.Front
			Decal.Texture = "rbxassetid://"..BloodEffectData[7][3][math.random(1,#BloodEffectData[7][3])]
			Decal.Color3 = BloodEffectData[7][4]
			if BloodEffectData[7][7] then
				local hitPartColor = Hit and Hit.Color or Color3.fromRGB(255, 255, 255)
				if Hit and Hit:IsA("Terrain") then
					hitPartColor = Workspace.Terrain:GetMaterialColor(Material or Enum.Material.Sand)
				end
				Decal.Color3 = hitPartColor
			end
			Decal.Parent = Hole
			Hole.Parent = Workspace.CurrentCamera
			Hole.CFrame = surfaceCF * CFrame.Angles(0, 0, math.random(0, 360))
			if (not Hit.Anchored) then
				-- Weld hitMark to the hitPart.
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = Hole
				weld.Part1 = Hit
				weld.Parent = Hole
				--[[local Weld = Instance.new("Weld", Hole)
				Weld.Part0 = Hit
				Weld.Part1 = Hole
			    Weld.C0 = Hit.CFrame:toObjectSpace(surfaceCF * CFrame.Angles(0, 0, math.random(0, 360)))]]
				Hole.Anchored = false
			end
			Thread:Delay(BloodEffectData[7][5], function()
				if BloodEffectData[7][5] > 0 then
					local t0 = tick()
					while true do
						local Alpha = math.min((tick() - t0) / BloodEffectData[7][6], 1)
						Decal.Transparency = numLerp(0, 1, Alpha)
						if Alpha == 1 then break end
						game:GetService("RunService").Heartbeat:Wait()
					end
					Hole:Destroy()
				else
					Hole:Destroy()
				end
			end)
		end
	end	
end

local function OnRayHit(origin, direction, velocity, hitPart, hitPoint, normal, material, hitData)
	local ShowEffects = ScreenCullingEnabled and (ScreenCulling(hitPoint, ScreenCullingRadius) and (hitPoint - Workspace.CurrentCamera.CFrame.p).Magnitude <= RenderDistance) or (hitPoint - Workspace.CurrentCamera.CFrame.p).Magnitude <= RenderDistance
	if not hitData[1][1] then
	    if hitPart ~= nil and hitPart.Parent ~= nil then
			if hitData[6] ~= nil and hitPart.Name == "_glass" then
				RemoteHandler.Fire("ShatterGlass", hitPart, hitPoint, direction)
			else
		   		local Distance = (hitPoint - origin).Magnitude
				local TargetHumanoid = findFirstByClass(hitPart.Parent,"Humanoid")
		   		local TargetTorso = hitPart.Parent:FindFirstChild("HumanoidRootPart") or hitPart.Parent:FindFirstChild("Head")
				local Tagger = game.Players:GetPlayerFromCharacter(hitData[5].Parent)
				if TargetHumanoid and TargetHumanoid.Health > 0 and TargetTorso then
		    		if ShowEffects then MakeBloodFX(hitPart, hitPoint, normal, material, hitData[4]) end
					if hitData[6] ~= nil then
						if TargetHumanoid.Health > 0 then
							Thread:Spawn(function()
			    				RemoteHandler.Invoke("InflictTarget",hitData[7],hitData[5],
			                       	   				Tagger,
			                       	   				TargetHumanoid,
					                   				TargetTorso,
					                   				{hitData[6][1][1],hitData[6][1][2],hitData[6][1][3],Distance,hitData[6][1][4],hitData[6][1][5],hitData[6][1][6]},
					                   				{hitData[6][2][1],hitData[6][2][2],hitData[6][2][3],hitData[6][2][4],hitData[6][2][5],hitData[6][2][6],hitData[6][2][7],hitData[6][2][8]},
					                   				{hitData[6][3][1],hitData[6][3][2],hitData[6][3][3]},
					                   				hitPart,
					                   				{hitData[6][4][1], hitData[6][4][2], hitData[6][4][3], hitData[6][4][4], hitData[6][4][5], hitData[6][4][6], hitData[6][4][7]})
		        	    	end)
							hitData[5].GunScript_Local:FindFirstChild("MarkerEvent"):Fire(hitPart.Name == "Head" and hitData[6][1][3]) 	
						end
					end
		   		else
					if ShowEffects then MakeImpactFX(velocity, hitPart, hitPoint, normal, material, hitData[2], hitData[3]) end
		   		end
			end
		end
    else
	    if hitData[1][3] then
			local Attachment = Instance.new("Attachment")
			Attachment.CFrame = CFrame.new(hitPoint)
			Attachment.Parent = Workspace.Terrain
			local Sound = Instance.new("Sound")
		    Sound.SoundId = "rbxassetid://"..hitData[1][4][math.random(1,#hitData[1][4])]
		    Sound.PlaybackSpeed = Random.new():NextNumber(hitData[1][5], hitData[1][6])
		    Sound.Volume = hitData[1][7]
		    Sound.Parent = Attachment
		    Sound:Play()
			Debris:AddItem(Attachment, 10)		
		end
		
		local Explosion = Instance.new("Explosion")
		Explosion.BlastRadius = hitData[1][2]
		Explosion.BlastPressure = 0
		Explosion.ExplosionType = Enum.ExplosionType.NoCraters
	    Explosion.Position = hitPoint
		Explosion.Parent = Workspace.CurrentCamera
		
		local surfaceCF = CFrame.new(hitPoint, hitPoint + normal)
		
		if ShowEffects and hitPart ~= nil and hitPoint ~= nil and normal ~= nil then 
			if hitData[1][11] and
				hitPart and
				not hitPart.Parent or not findFirstByClass(hitPart.Parent,"Humanoid") then
				local Hole = Instance.new("Part")
				Hole.Name = "ExplosionCrater"
				Hole.Transparency = 1
				Hole.Anchored = true
				Hole.CanCollide = false
				Hole.FormFactor = "Custom"
				Hole.Size = Vector3.new(1, 1, 0.2)
				Hole.TopSurface = 0
				Hole.BottomSurface = 0
				local Mesh = Instance.new("BlockMesh")
				Mesh.Offset = Vector3.new(0, 0, 0)
				Mesh.Scale = Vector3.new(hitData[1][12], hitData[1][12], 0)
				Mesh.Parent = Hole
				local Decal = Instance.new("Decal")
				Decal.Face = Enum.NormalId.Front
				Decal.Texture = "rbxassetid://"..hitData[1][13][math.random(1,#hitData[1][13])]
		    	if hitData[1][14] then
					local hitPartColor = hitPart and hitPart.Color or Color3.fromRGB(255, 255, 255)
					if hitPart and hitPart:IsA("Terrain") then
						hitPartColor = Workspace.Terrain:GetMaterialColor(material or Enum.Material.Sand)
					end
					Decal.Color3 = hitPartColor
				end
				Decal.Parent = Hole
				Hole.Parent = Workspace.CurrentCamera
				Hole.CFrame = surfaceCF * CFrame.Angles(0, 0, math.random(0, 360))
				if (not hitPart.Anchored) then
					-- Weld hitMark to the hitPart
					local weld = Instance.new("WeldConstraint")
					weld.Part0 = Hole
					weld.Part1 = hitPart
					weld.Parent = Hole
					--local Weld = Instance.new("Weld", Hole)
					--Weld.Part0 = HitInfo[1]
					--Weld.Part1 = Hole
			    	--Weld.C0 = HitInfo[1].CFrame:toObjectSpace(surfaceCF * CFrame.Angles(0, 0, math.random(0, 360)))
					Hole.Anchored = false
		    	end
				Thread:Delay(hitData[1][15], function()
					if hitData[1][15] > 0 then
						local t0 = tick()
						while true do
							local Alpha = math.min((tick() - t0) / hitData[1][16], 1)
							Decal.Transparency = numLerp(0, 1, Alpha)
					    	if Alpha == 1 then break end
				      		game:GetService("RunService").Heartbeat:Wait()
						end
				    	Hole:Destroy()
					else
				    	Hole:Destroy()
			    	end
				end)
			end
		end
		
		if hitData[1][8] then
			Explosion.Visible = false
	
			if ShowEffects then
			    local Attachment = Instance.new("Attachment")
			    Attachment.CFrame = surfaceCF
		        Attachment.Parent = Workspace.Terrain
		
			    local function spawner4()
		            local C = hitData[1][9]:GetChildren()
		            for i=1,#C do
			            if C[i].className == "ParticleEmitter" then
				            local count = 1
				            local Particle = C[i]:Clone()
				            Particle.Parent = Attachment
			                if Particle:FindFirstChild("EmitCount") then
				                count = Particle.EmitCount.Value
			                end
				            Thread:Delay(0.01,function()
				                Particle:Emit(count)
				                Debris:AddItem(Particle, Particle.Lifetime.Max)
			                end)
			            end
		            end
			    end
			
		        Thread:Spawn(spawner4)
		        Debris:AddItem(Attachment, 10)
			end
	    end	
		
		Explosion.Hit:connect(function(HitPart, HitDist)
			if HitPart and hitData[6] ~= nil then
				if HitPart.Parent and HitPart.Name == "HumanoidRootPart" or HitPart.Name == "Head" then
					local Distance = (hitPoint - origin).Magnitude
					local TargetHumanoid = findFirstByClass(HitPart.Parent,"Humanoid")
					local TargetTorso = HitPart.Parent:FindFirstChild("HumanoidRootPart") or HitPart.Parent:FindFirstChild("Head")
					local Tagger = game.Players:GetPlayerFromCharacter(hitData[5].Parent)
					if TargetHumanoid then
						if TargetHumanoid.Health > 0 then
							if hitData[1][17] then
								local Multipler = hitData[1][20]
								if TargetHumanoid.Parent.Name == Tagger.Name then Multipler = hitData[1][19] end
								local DistanceFactor = HitDist / hitData[1][2]
								DistanceFactor = 1 - DistanceFactor
								local VelocityMod = (TargetTorso.Position - Explosion.Position).Unit * hitData[1][18] --* DistanceFactor
								local AirVelocity = TargetTorso.Velocity - Vector3.new(0, TargetTorso.Velocity.y, 0) + Vector3.new(VelocityMod.X, 0, VelocityMod.Z)
								local TorsoFly = Instance.new("BodyVelocity")
								TorsoFly.MaxForce = Vector3.new(math.huge,0,math.huge)
								TorsoFly.Velocity = AirVelocity
								TorsoFly.Parent = TargetTorso
								TargetTorso.Velocity = TargetTorso.Velocity + Vector3.new(0, VelocityMod.Y * Multipler, 0)
								Debris:AddItem(TorsoFly, .25)								
							end
							Thread:Spawn(function()
 					    		RemoteHandler.Invoke("InflictTarget",hitData[7],hitData[5],
					            					Tagger,
					           	 					TargetHumanoid,
							    					TargetTorso,
							    					{hitData[6][1][1],hitData[6][1][2],hitData[6][1][3],Distance,hitData[6][1][4],hitData[6][1][5],hitData[6][1][6]},
							    					{hitData[6][2][1],hitData[6][2][2],hitData[6][2][3],hitData[6][2][4],hitData[6][2][5],hitData[6][2][6],hitData[6][2][7],hitData[6][2][8]},
							    					{hitData[6][3][1],hitData[6][3][2],hitData[6][3][3]},
							    					HitPart,
							    					{hitData[6][4][1], hitData[6][4][2], hitData[6][4][3], hitData[6][4][4], hitData[6][4][5], hitData[6][4][6], hitData[6][4][7]},
													{hitData[1][1], hitData[1][2], HitDist, hitData[1][10]})
							end)
			            	hitData[5].GunScript_Local:FindFirstChild("MarkerEvent"):Fire(HitPart.Name == "Head" and hitData[6][1][3])       	
						end
					end
				elseif HitPart.Name == "_glass" then
					RemoteHandler.Fire("ShatterGlass", HitPart, HitPart.Position, direction)
		    	end
			end
	    end)
	end
end

local function OnRayBounced(origin, direction, velocity, hitPart, hitPoint, normal, material, hitData, noExplosion)
	local ShowEffects = ScreenCullingEnabled and (ScreenCulling(hitPoint, ScreenCullingRadius) and (hitPoint - Workspace.CurrentCamera.CFrame.p).Magnitude <= RenderDistance) or (hitPoint - Workspace.CurrentCamera.CFrame.p).Magnitude <= RenderDistance	
	if not hitData[1][1] then
	    if hitPart ~= nil and hitPart.Parent ~= nil then
			if hitData[6] ~= nil and hitPart.Name == "_glass" then
				RemoteHandler.Fire("ShatterGlass", hitPart, hitPoint, direction)
			else
		   		local Distance = (hitPoint - origin).Magnitude
				local TargetHumanoid = findFirstByClass(hitPart.Parent,"Humanoid")
		   		local TargetTorso = hitPart.Parent:FindFirstChild("HumanoidRootPart") or hitPart.Parent:FindFirstChild("Head")
				local Tagger = game.Players:GetPlayerFromCharacter(hitData[5].Parent)
				if TargetHumanoid and TargetHumanoid.Health > 0 and TargetTorso then
		    		if ShowEffects then MakeBloodFX(hitPart, hitPoint, normal, material, hitData[4]) end
					if hitData[6] ~= nil then
						if TargetHumanoid.Health > 0 then
							Thread:Spawn(function()
			    				RemoteHandler.Invoke("InflictTarget",hitData[7],hitData[5],
			                       	   				Tagger,
			                       	   				TargetHumanoid,
					                   				TargetTorso,
					                   				{hitData[6][1][1],hitData[6][1][2],hitData[6][1][3],Distance,hitData[6][1][4],hitData[6][1][5],hitData[6][1][6]},
					                   				{hitData[6][2][1],hitData[6][2][2],hitData[6][2][3],hitData[6][2][4],hitData[6][2][5],hitData[6][2][6],hitData[6][2][7],hitData[6][2][8]},
					                   				{hitData[6][3][1],hitData[6][3][2],hitData[6][3][3]},
					                   				hitPart,
					                   				{hitData[6][4][1], hitData[6][4][2], hitData[6][4][3], hitData[6][4][4], hitData[6][4][5], hitData[6][4][6], hitData[6][4][7]})
		        	    	end)
							hitData[5].GunScript_Local:FindFirstChild("MarkerEvent"):Fire(hitPart.Name == "Head" and hitData[6][1][3]) 	
						end
					end
		   		else
					if ShowEffects then MakeImpactFX(velocity, hitPart, hitPoint, normal, material, hitData[2], hitData[3]) end
		   		end
			end
		end
    else
		if noExplosion then
		    if hitPart ~= nil and hitPart.Parent ~= nil then
				if hitData[6] ~= nil and hitPart.Name == "_glass" then
					RemoteHandler.Fire("ShatterGlass", hitPart, hitPoint, direction)
				else
			   		local Distance = (hitPoint - origin).Magnitude
					local TargetHumanoid = findFirstByClass(hitPart.Parent,"Humanoid")
			   		local TargetTorso = hitPart.Parent:FindFirstChild("HumanoidRootPart") or hitPart.Parent:FindFirstChild("Head")
					local Tagger = game.Players:GetPlayerFromCharacter(hitData[5].Parent)
					if TargetHumanoid and TargetHumanoid.Health > 0 and TargetTorso then
			    		if ShowEffects then MakeBloodFX(hitPart, hitPoint, normal, material, hitData[4]) end
						if hitData[6] ~= nil then
							if TargetHumanoid.Health > 0 then
								Thread:Spawn(function()
				    				RemoteHandler.Invoke("InflictTarget",hitData[7],hitData[5],
				                       	   				Tagger,
				                       	   				TargetHumanoid,
						                   				TargetTorso,
						                   				{hitData[6][1][1],hitData[6][1][2],hitData[6][1][3],Distance,hitData[6][1][4],hitData[6][1][5],hitData[6][1][6]},
						                   				{hitData[6][2][1],hitData[6][2][2],hitData[6][2][3],hitData[6][2][4],hitData[6][2][5],hitData[6][2][6],hitData[6][2][7],hitData[6][2][8]},
						                   				{hitData[6][3][1],hitData[6][3][2],hitData[6][3][3]},
						                   				hitPart,
						                   				{hitData[6][4][1], hitData[6][4][2], hitData[6][4][3], hitData[6][4][4], hitData[6][4][5], hitData[6][4][6], hitData[6][4][7]})
			        	    	end)
								hitData[5].GunScript_Local:FindFirstChild("MarkerEvent"):Fire(hitPart.Name == "Head" and hitData[6][1][3]) 	
							end
						end
			   		else
						if ShowEffects then MakeImpactFX(velocity, hitPart, hitPoint, normal, material, hitData[2], hitData[3]) end
			   		end
				end
			end
		else
		    if hitData[1][3] then
				local Attachment = Instance.new("Attachment")
				Attachment.CFrame = CFrame.new(hitPoint)
				Attachment.Parent = Workspace.Terrain
				local Sound = Instance.new("Sound")
			    Sound.SoundId = "rbxassetid://"..hitData[1][4][math.random(1,#hitData[1][4])]
			    Sound.PlaybackSpeed = Random.new():NextNumber(hitData[1][5], hitData[1][6])
			    Sound.Volume = hitData[1][7]
			    Sound.Parent = Attachment
			    Sound:Play()
				Debris:AddItem(Attachment, 10)		
			end
			
			local Explosion = Instance.new("Explosion")
			Explosion.BlastRadius = hitData[1][2]
			Explosion.BlastPressure = 0
			Explosion.ExplosionType = Enum.ExplosionType.NoCraters
		    Explosion.Position = hitPoint
			Explosion.Parent = Workspace.CurrentCamera
			
			local surfaceCF = CFrame.new(hitPoint, hitPoint + normal)
			
			if ShowEffects and hitPart ~= nil and hitPoint ~= nil and normal ~= nil then 
				if hitData[1][11] and
					hitPart and
					not hitPart.Parent or not findFirstByClass(hitPart.Parent,"Humanoid") then
					local Hole = Instance.new("Part")
					Hole.Name = "ExplosionCrater"
					Hole.Transparency = 1
					Hole.Anchored = true
					Hole.CanCollide = false
					Hole.FormFactor = "Custom"
					Hole.Size = Vector3.new(1, 1, 0.2)
					Hole.TopSurface = 0
					Hole.BottomSurface = 0
					local Mesh = Instance.new("BlockMesh")
					Mesh.Offset = Vector3.new(0, 0, 0)
					Mesh.Scale = Vector3.new(hitData[1][12], hitData[1][12], 0)
					Mesh.Parent = Hole
					local Decal = Instance.new("Decal")
					Decal.Face = Enum.NormalId.Front
					Decal.Texture = "rbxassetid://"..hitData[1][13][math.random(1,#hitData[1][13])]
			    	if hitData[1][14] then
						local hitPartColor = hitPart and hitPart.Color or Color3.fromRGB(255, 255, 255)
						if hitPart and hitPart:IsA("Terrain") then
							hitPartColor = Workspace.Terrain:GetMaterialColor(material or Enum.Material.Sand)
						end
						Decal.Color3 = hitPartColor
					end
					Decal.Parent = Hole
					Hole.Parent = Workspace.CurrentCamera
					Hole.CFrame = surfaceCF * CFrame.Angles(0, 0, math.random(0, 360))
					if (not hitPart.Anchored) then
						-- Weld hitMark to the hitPart
						local weld = Instance.new("WeldConstraint")
						weld.Part0 = Hole
						weld.Part1 = hitPart
						weld.Parent = Hole
						--local Weld = Instance.new("Weld", Hole)
						--Weld.Part0 = HitInfo[1]
						--Weld.Part1 = Hole
				    	--Weld.C0 = HitInfo[1].CFrame:toObjectSpace(surfaceCF * CFrame.Angles(0, 0, math.random(0, 360)))
						Hole.Anchored = false
			    	end
					Thread:Delay(hitData[1][15], function()
						if hitData[1][15] > 0 then
							local t0 = tick()
							while true do
								local Alpha = math.min((tick() - t0) / hitData[1][16], 1)
								Decal.Transparency = numLerp(0, 1, Alpha)
						    	if Alpha == 1 then break end
					      		game:GetService("RunService").Heartbeat:Wait()
							end
					    	Hole:Destroy()
						else
					    	Hole:Destroy()
				    	end
					end)
				end
			end
			
			if hitData[1][8] then
				Explosion.Visible = false
		
				if ShowEffects then
				    local Attachment = Instance.new("Attachment")
				    Attachment.CFrame = surfaceCF
			        Attachment.Parent = Workspace.Terrain
			
				    local function spawner4()
			            local C = hitData[1][9]:GetChildren()
			            for i=1,#C do
				            if C[i].className == "ParticleEmitter" then
					            local count = 1
					            local Particle = C[i]:Clone()
					            Particle.Parent = Attachment
				                if Particle:FindFirstChild("EmitCount") then
					                count = Particle.EmitCount.Value
				                end
					            Thread:Delay(0.01,function()
					                Particle:Emit(count)
					                Debris:AddItem(Particle, Particle.Lifetime.Max)
				                end)
				            end
			            end
				    end
				
			        Thread:Spawn(spawner4)
			        Debris:AddItem(Attachment, 10)
				end
		    end	
			
			Explosion.Hit:connect(function(HitPart, HitDist)
				if HitPart and hitData[6] ~= nil then
					if HitPart.Parent and HitPart.Name == "HumanoidRootPart" or HitPart.Name == "Head" then
						local Distance = (hitPoint - origin).Magnitude
						local TargetHumanoid = findFirstByClass(HitPart.Parent,"Humanoid")
						local TargetTorso = HitPart.Parent:FindFirstChild("HumanoidRootPart") or HitPart.Parent:FindFirstChild("Head")
						local Tagger = game.Players:GetPlayerFromCharacter(hitData[5].Parent)
						if TargetHumanoid then
							if TargetHumanoid.Health > 0 then
								if hitData[1][17] then
									local Multipler = hitData[1][20]
									if TargetHumanoid.Parent.Name == Tagger.Name then Multipler = hitData[1][19] end
									local DistanceFactor = HitDist / hitData[1][2]
									DistanceFactor = 1 - DistanceFactor
									local VelocityMod = (TargetTorso.Position - Explosion.Position).Unit * hitData[1][18] --* DistanceFactor
									local AirVelocity = TargetTorso.Velocity - Vector3.new(0, TargetTorso.Velocity.y, 0) + Vector3.new(VelocityMod.X, 0, VelocityMod.Z)
									local TorsoFly = Instance.new("BodyVelocity")
									TorsoFly.MaxForce = Vector3.new(math.huge,0,math.huge)
									TorsoFly.Velocity = AirVelocity
									TorsoFly.Parent = TargetTorso
									TargetTorso.Velocity = TargetTorso.Velocity + Vector3.new(0, VelocityMod.Y * Multipler, 0)
									Debris:AddItem(TorsoFly, .25)								
								end
								Thread:Spawn(function()
	 					    		RemoteHandler.Invoke("InflictTarget",hitData[7],hitData[5],
						            					Tagger,
						           	 					TargetHumanoid,
								    					TargetTorso,
								    					{hitData[6][1][1],hitData[6][1][2],hitData[6][1][3],Distance,hitData[6][1][4],hitData[6][1][5],hitData[6][1][6]},
								    					{hitData[6][2][1],hitData[6][2][2],hitData[6][2][3],hitData[6][2][4],hitData[6][2][5],hitData[6][2][6],hitData[6][2][7],hitData[6][2][8]},
								    					{hitData[6][3][1],hitData[6][3][2],hitData[6][3][3]},
								    					HitPart,
								    					{hitData[6][4][1], hitData[6][4][2], hitData[6][4][3], hitData[6][4][4], hitData[6][4][5], hitData[6][4][6], hitData[6][4][7]},
														{hitData[1][1], hitData[1][2], HitDist, hitData[1][10]})
								end)
				            	hitData[5].GunScript_Local:FindFirstChild("MarkerEvent"):Fire(HitPart.Name == "Head" and hitData[6][1][3])       	
							end
						end
					elseif HitPart.Name == "_glass" then
						RemoteHandler.Fire("ShatterGlass", HitPart, HitPart.Position, direction)
			    	end
				end
		    end)
		end
	end
end

local function OnRayPenetrated(origin, direction, velocity, hitPart, hitPoint, normal, material, hitData)
	local ShowEffects = ScreenCullingEnabled and (ScreenCulling(hitPoint, ScreenCullingRadius) and (hitPoint - Workspace.CurrentCamera.CFrame.p).Magnitude <= RenderDistance) or (hitPoint - Workspace.CurrentCamera.CFrame.p).Magnitude <= RenderDistance	
	if hitPart ~= nil and hitPart.Parent ~= nil then
		if hitData[6] ~= nil and hitPart.Name == "_glass" then
			RemoteHandler.Fire("ShatterGlass", hitPart, hitPoint, direction)
		else
		   	local Distance = (hitPoint - origin).Magnitude
			local TargetHumanoid = findFirstByClass(hitPart.Parent,"Humanoid")
		   	local TargetTorso = hitPart.Parent:FindFirstChild("HumanoidRootPart") or hitPart.Parent:FindFirstChild("Head")
			local Tagger = game.Players:GetPlayerFromCharacter(hitData[5].Parent)
			if TargetHumanoid and TargetHumanoid.Health > 0 and TargetTorso then
		   		if ShowEffects then MakeBloodFX(hitPart, hitPoint, normal, material, hitData[4]) end
				if hitData[6] ~= nil then
					if TargetHumanoid.Health > 0 then
						Thread:Spawn(function()
		    				RemoteHandler.Invoke("InflictTarget",hitData[7],hitData[5],
		                      					Tagger,
		                      					TargetHumanoid,
				               					TargetTorso,
				               					{hitData[6][1][1],hitData[6][1][2],hitData[6][1][3],Distance,hitData[6][1][4],hitData[6][1][5],hitData[6][1][6]},
				               					{hitData[6][2][1],hitData[6][2][2],hitData[6][2][3],hitData[6][2][4],hitData[6][2][5],hitData[6][2][6],hitData[6][2][7],hitData[6][2][8]},
				               					{hitData[6][3][1],hitData[6][3][2],hitData[6][3][3]},
				               					hitPart,
				               					{hitData[6][4][1], hitData[6][4][2], hitData[6][4][3], hitData[6][4][4], hitData[6][4][5], hitData[6][4][6], hitData[6][4][7]})
						end)
		      	   		hitData[5].GunScript_Local:FindFirstChild("MarkerEvent"):Fire(hitPart.Name == "Head" and hitData[6][1][3]) 	
					end
				end
		  	else
				if ShowEffects then MakeImpactFX(velocity, hitPart, hitPoint, normal, material, hitData[2], hitData[3]) end
		   	end
		end
	end
end

local function OnRayExited(origin, direction, velocity, hitPart, hitPoint, normal, material, hitData)
	local ShowEffects = ScreenCullingEnabled and (ScreenCulling(hitPoint, ScreenCullingRadius) and (hitPoint - Workspace.CurrentCamera.CFrame.p).Magnitude <= RenderDistance) or (hitPoint - Workspace.CurrentCamera.CFrame.p).Magnitude <= RenderDistance	
	if hitPart.Name == "_glass" then
		return
	else
		local TargetHumanoid = findFirstByClass(hitPart.Parent,"Humanoid")
		local TargetTorso = hitPart.Parent:FindFirstChild("HumanoidRootPart") or hitPart.Parent:FindFirstChild("Head")
		if TargetHumanoid and TargetHumanoid.Health > 0 and TargetTorso then
		   	if ShowEffects then MakeBloodFX(hitPart, hitPoint, normal, material, hitData[4]) end
		else
			if ShowEffects then MakeImpactFX(velocity, hitPart, hitPoint, normal, material, hitData[2], hitData[3]) end
		end
	end
end

function ProjectileHandler:SimulateProjectile(Module, Tool, Handle, VMHandle, CLDirections, SVDirections, FirePointObject, HitEffectData, BloodEffectData, BulletHoleData, ExplosiveData, BulletData, WhizData, ClientData)
	if Module and Tool and Handle then
		if ClientData ~= nil then 
			RemoteHandler.Fire("VisualizeBullet", Module, Tool, Handle, nil, nil, SVDirections, FirePointObject, HitEffectData, BloodEffectData, BulletHoleData, ExplosiveData, BulletData, WhizData, nil)
			for _, CLDirection in pairs(CLDirections) do
				local origin, dir = FirePointObject.WorldPosition, CLDirection

				if VMHandle ~= nil then
					origin = VMHandle:FindFirstChild("GunFirePoint").WorldPosition
				end

	            if FirePointObject ~= nil then
	                local tipCFrame = FirePointObject.WorldCFrame
	                local tipPos = tipCFrame.Position
	                local tipDir = tipCFrame.LookVector
	                local amountToCheatBack = math.abs((Tool.Parent:FindFirstChild("HumanoidRootPart").Position - tipPos):Dot(tipDir)) + 1
	                local gunRay = Ray.new(tipPos - tipDir.Unit * amountToCheatBack, tipDir.Unit * amountToCheatBack)
	                local hitPart, hitPoint = Workspace:FindPartOnRayWithIgnoreList(gunRay, {Handle, Tool.Parent, Workspace.CurrentCamera}, false, true)
	                if hitPart and math.abs((tipPos - hitPoint).Magnitude) > 0 then
	                    origin = hitPoint - tipDir.Unit * 0.1
	                    --dir = tipDir.Unit
	                end
	            end

				local vel = dir * BulletData[1]
	
	        	ParticleFramework.new({
	            	position = origin,
	                velocity = vel,
	                acceleration = BulletData[2],
					visible = BulletData[16],
	                color = BulletData[3],
					texture = BulletData[4],
	                size = BulletData[5],
	                bloom = BulletData[6],
	                brightness = BulletData[7],
					life = BulletData[8],
					windspeed = BulletData[21],
					windresistance = BulletData[22],
	                visualorigin = origin,
					visualdirection = dir,
					penetrationtype = BulletData[19],
	                penetrationdepth = BulletData[9],
					penetrationamount = BulletData[20],
					ricochetamount = BulletData[10],
					bounceelasticity = BulletData[17],
					frictionconstant = BulletData[18],
					noexplosionwhilebouncing = BulletData[23],
					stopbouncingonhithumanoid = BulletData[24],
					superricochet = BulletData[25],
					bullettype = BulletData[11],
					canspinpart = BulletData[12],
					spinx = BulletData[13],
					spiny = BulletData[14],
					spinz = BulletData[15],
					toucheventontimeout = BulletData[26], 
					physicsignore = {Handle, Tool.Parent, Workspace.CurrentCamera},
	                ontouch = function(self, part, pos, norm, material)
	            		OnRayHit(origin,
								dir,
			                	self.velocity,
								part,
		                		pos,
		                		norm,
								material,
								{{ExplosiveData[1], ExplosiveData[2], ExplosiveData[3], ExplosiveData[4], ExplosiveData[5], ExplosiveData[6], ExplosiveData[7], ExplosiveData[8], ExplosiveData[9], ExplosiveData[10], ExplosiveData[11], ExplosiveData[12], ExplosiveData[13], ExplosiveData[14], ExplosiveData[15], ExplosiveData[16], ExplosiveData[17], ExplosiveData[18], ExplosiveData[19], ExplosiveData[20]},
	                			{HitEffectData[1], HitEffectData[2], HitEffectData[3], HitEffectData[4], HitEffectData[5], HitEffectData[6], HitEffectData[7], HitEffectData[8]},
	                			{BulletHoleData[1], BulletHoleData[2], BulletHoleData[3], BulletHoleData[4], BulletHoleData[5], BulletHoleData[6]},
	                			{BloodEffectData[1], BloodEffectData[2], BloodEffectData[3], BloodEffectData[4], BloodEffectData[5], BloodEffectData[6], BloodEffectData[7]},
								Tool,
								{{ClientData[1][1], ClientData[1][2], ClientData[1][3], ClientData[1][4], ClientData[1][5], ClientData[1][6]},
	                			{ClientData[2][1], ClientData[2][2], ClientData[2][3], ClientData[2][4], ClientData[2][5], ClientData[2][6], ClientData[2][7], ClientData[2][8]},
	                			{ClientData[3][1], ClientData[3][2], ClientData[3][3]},
	                			{ClientData[4][1], ClientData[4][2], ClientData[4][3], ClientData[4][4], ClientData[4][5], ClientData[4][6], ClientData[4][7]}},
								Module})
	                end,
					onenter = function(self, part, pos, norm, material, exited)
						OnRayPenetrated(origin,
								dir,
								self.velocity,
								part,
								pos,
								norm,
								material,
								{{ExplosiveData[1], ExplosiveData[2], ExplosiveData[3], ExplosiveData[4], ExplosiveData[5], ExplosiveData[6], ExplosiveData[7], ExplosiveData[8], ExplosiveData[9], ExplosiveData[10], ExplosiveData[11], ExplosiveData[12], ExplosiveData[13], ExplosiveData[14], ExplosiveData[15], ExplosiveData[16], ExplosiveData[17], ExplosiveData[18], ExplosiveData[19], ExplosiveData[20]},
	                			{HitEffectData[1], HitEffectData[2], HitEffectData[3], HitEffectData[4], HitEffectData[5], HitEffectData[6], HitEffectData[7], HitEffectData[8]},
	                			{BulletHoleData[1], BulletHoleData[2], BulletHoleData[3], BulletHoleData[4], BulletHoleData[5], BulletHoleData[6]},
	                			{BloodEffectData[1], BloodEffectData[2], BloodEffectData[3], BloodEffectData[4], BloodEffectData[5], BloodEffectData[6], BloodEffectData[7]},
								Tool,
								{{ClientData[1][1], ClientData[1][2], ClientData[1][3], ClientData[1][4], ClientData[1][5], ClientData[1][6]},
	                			{ClientData[2][1], ClientData[2][2], ClientData[2][3], ClientData[2][4], ClientData[2][5], ClientData[2][6], ClientData[2][7], ClientData[2][8]},
	                			{ClientData[3][1], ClientData[3][2], ClientData[3][3]},
	                			{ClientData[4][1], ClientData[4][2], ClientData[4][3], ClientData[4][4], ClientData[4][5], ClientData[4][6], ClientData[4][7]}},
								Module})
					end,
					onexit = function(self, exitpart, exitpos, exitnorm, exitmaterial)
						OnRayExited(origin,
								dir,
								self.velocity,
								exitpart,
								exitpos,
								exitnorm,
								exitmaterial,
								{{ExplosiveData[1], ExplosiveData[2], ExplosiveData[3], ExplosiveData[4], ExplosiveData[5], ExplosiveData[6], ExplosiveData[7], ExplosiveData[8], ExplosiveData[9], ExplosiveData[10], ExplosiveData[11], ExplosiveData[12], ExplosiveData[13], ExplosiveData[14], ExplosiveData[15], ExplosiveData[16], ExplosiveData[17], ExplosiveData[18], ExplosiveData[19], ExplosiveData[20]},
	                			{HitEffectData[1], HitEffectData[2], HitEffectData[3], HitEffectData[4], HitEffectData[5], HitEffectData[6], HitEffectData[7], HitEffectData[8]},
	                			{BulletHoleData[1], BulletHoleData[2], BulletHoleData[3], BulletHoleData[4], BulletHoleData[5], BulletHoleData[6]},
	                			{BloodEffectData[1], BloodEffectData[2], BloodEffectData[3], BloodEffectData[4], BloodEffectData[5], BloodEffectData[6], BloodEffectData[7]},
								Tool,
								{{ClientData[1][1], ClientData[1][2], ClientData[1][3], ClientData[1][4], ClientData[1][5], ClientData[1][6]},
	                			{ClientData[2][1], ClientData[2][2], ClientData[2][3], ClientData[2][4], ClientData[2][5], ClientData[2][6], ClientData[2][7], ClientData[2][8]},
	                			{ClientData[3][1], ClientData[3][2], ClientData[3][3]},
	                			{ClientData[4][1], ClientData[4][2], ClientData[4][3], ClientData[4][4], ClientData[4][5], ClientData[4][6], ClientData[4][7]}},
								Module})
					end,
					onbounce = function(self, part, pos, norm, material, noexplosion)
	            		OnRayBounced(origin,
								dir,
			                	self.velocity,
								part,
		                		pos,
		                		norm,
								material,
								{{ExplosiveData[1], ExplosiveData[2], ExplosiveData[3], ExplosiveData[4], ExplosiveData[5], ExplosiveData[6], ExplosiveData[7], ExplosiveData[8], ExplosiveData[9], ExplosiveData[10], ExplosiveData[11], ExplosiveData[12], ExplosiveData[13], ExplosiveData[14], ExplosiveData[15], ExplosiveData[16], ExplosiveData[17], ExplosiveData[18], ExplosiveData[19], ExplosiveData[20]},
	                			{HitEffectData[1], HitEffectData[2], HitEffectData[3], HitEffectData[4], HitEffectData[5], HitEffectData[6], HitEffectData[7], HitEffectData[8]},
	                			{BulletHoleData[1], BulletHoleData[2], BulletHoleData[3], BulletHoleData[4], BulletHoleData[5], BulletHoleData[6]},
	                			{BloodEffectData[1], BloodEffectData[2], BloodEffectData[3], BloodEffectData[4], BloodEffectData[5], BloodEffectData[6], BloodEffectData[7]},
								Tool,
								{{ClientData[1][1], ClientData[1][2], ClientData[1][3], ClientData[1][4], ClientData[1][5], ClientData[1][6]},
	                			{ClientData[2][1], ClientData[2][2], ClientData[2][3], ClientData[2][4], ClientData[2][5], ClientData[2][6], ClientData[2][7], ClientData[2][8]},
	                			{ClientData[3][1], ClientData[3][2], ClientData[3][3]},
	                			{ClientData[4][1], ClientData[4][2], ClientData[4][3], ClientData[4][4], ClientData[4][5], ClientData[4][6], ClientData[4][7]}},
								Module},
								noexplosion)
					end
	            })
			end
		else
			for _, SVDirection in pairs(SVDirections) do
				local origin, dir = FirePointObject.WorldPosition, SVDirection

	            if FirePointObject ~= nil then
	                local tipCFrame = FirePointObject.WorldCFrame
	                local tipPos = tipCFrame.Position
	                local tipDir = tipCFrame.LookVector
	                local amountToCheatBack = math.abs((Tool.Parent:FindFirstChild("HumanoidRootPart").Position - tipPos):Dot(tipDir)) + 1
	                local gunRay = Ray.new(tipPos - tipDir.Unit * amountToCheatBack, tipDir.Unit * amountToCheatBack)
	                local hitPart, hitPoint = Workspace:FindPartOnRayWithIgnoreList(gunRay, {Handle, Tool.Parent, Workspace.CurrentCamera}, false, true)
	                if hitPart and math.abs((tipPos - hitPoint).Magnitude) > 0 then
	                    origin = hitPoint - tipDir.Unit * 0.1
	                    --dir = tipDir.Unit
	                end
	            end

				local vel = dir * BulletData[1]

				local v3 = Vector3.new
	  			local nv = v3()
	  			local dot = nv.Dot

	        	ParticleFramework.new({
	            	position = origin,
	                velocity = vel,
	                acceleration = BulletData[2],
					visible = BulletData[16],
	                color = BulletData[3],
					texture = BulletData[4],
	                size = BulletData[5],
	                bloom = BulletData[6],
	                brightness = BulletData[7],
					life = BulletData[8],
					windspeed = BulletData[21],
					windresistance = BulletData[22],
	                visualorigin = origin,
					visualdirection = dir,
					penetrationtype = BulletData[19],
	                penetrationdepth = BulletData[9],
					penetrationamount = BulletData[20],
					ricochetamount = BulletData[10],
					bounceelasticity = BulletData[17],
					frictionconstant = BulletData[18],
					noexplosionwhilebouncing = BulletData[23],
					stopbouncingonhithumanoid = BulletData[24],
					superricochet = BulletData[25],
					bullettype = BulletData[11],
					canspinpart = BulletData[12],
					spinx = BulletData[13],
					spiny = BulletData[14],
					spinz = BulletData[15],
					toucheventontimeout = BulletData[26], 
					physicsignore = {Handle, Tool.Parent, Workspace.CurrentCamera},
	                ontouch = function(self, part, pos, norm, material)
	            		OnRayHit(origin,
								dir,
			                	self.velocity,
								part,
		                		pos,
		                		norm,
								material,
								{{ExplosiveData[1], ExplosiveData[2], ExplosiveData[3], ExplosiveData[4], ExplosiveData[5], ExplosiveData[6], ExplosiveData[7], ExplosiveData[8], ExplosiveData[9], ExplosiveData[10], ExplosiveData[11], ExplosiveData[12], ExplosiveData[13], ExplosiveData[14], ExplosiveData[15], ExplosiveData[16], ExplosiveData[17], ExplosiveData[18], ExplosiveData[19], ExplosiveData[20]},
	                			{HitEffectData[1], HitEffectData[2], HitEffectData[3], HitEffectData[4], HitEffectData[5], HitEffectData[6], HitEffectData[7], HitEffectData[8]},
	                			{BulletHoleData[1], BulletHoleData[2], BulletHoleData[3], BulletHoleData[4], BulletHoleData[5], BulletHoleData[6]},
	                			{BloodEffectData[1], BloodEffectData[2], BloodEffectData[3], BloodEffectData[4], BloodEffectData[5], BloodEffectData[6], BloodEffectData[7]},
								Tool, nil, Module})
	                end,
					onenter = function(self, part, pos, norm, material, exited)
						OnRayPenetrated(origin,
								dir,
								self.velocity,
								part,
								pos,
								norm,
								material,
								{{ExplosiveData[1], ExplosiveData[2], ExplosiveData[3], ExplosiveData[4], ExplosiveData[5], ExplosiveData[6], ExplosiveData[7], ExplosiveData[8], ExplosiveData[9], ExplosiveData[10], ExplosiveData[11], ExplosiveData[12], ExplosiveData[13], ExplosiveData[14], ExplosiveData[15], ExplosiveData[16], ExplosiveData[17], ExplosiveData[18], ExplosiveData[19], ExplosiveData[20]},
	                			{HitEffectData[1], HitEffectData[2], HitEffectData[3], HitEffectData[4], HitEffectData[5], HitEffectData[6], HitEffectData[7], HitEffectData[8]},
	                			{BulletHoleData[1], BulletHoleData[2], BulletHoleData[3], BulletHoleData[4], BulletHoleData[5], BulletHoleData[6]},
	                			{BloodEffectData[1], BloodEffectData[2], BloodEffectData[3], BloodEffectData[4], BloodEffectData[5], BloodEffectData[6], BloodEffectData[7]},
								Tool, nil, Module})
					end,
					onexit = function(self, exitpart, exitpos, exitnorm, exitmaterial)
						OnRayExited(origin,
								dir,
								self.velocity,
								exitpart,
								exitpos,
								exitnorm,
								exitmaterial,
								{{ExplosiveData[1], ExplosiveData[2], ExplosiveData[3], ExplosiveData[4], ExplosiveData[5], ExplosiveData[6], ExplosiveData[7], ExplosiveData[8], ExplosiveData[9], ExplosiveData[10], ExplosiveData[11], ExplosiveData[12], ExplosiveData[13], ExplosiveData[14], ExplosiveData[15], ExplosiveData[16], ExplosiveData[17], ExplosiveData[18], ExplosiveData[19], ExplosiveData[20]},
	                			{HitEffectData[1], HitEffectData[2], HitEffectData[3], HitEffectData[4], HitEffectData[5], HitEffectData[6], HitEffectData[7], HitEffectData[8]},
	                			{BulletHoleData[1], BulletHoleData[2], BulletHoleData[3], BulletHoleData[4], BulletHoleData[5], BulletHoleData[6]},
	                			{BloodEffectData[1], BloodEffectData[2], BloodEffectData[3], BloodEffectData[4], BloodEffectData[5], BloodEffectData[6], BloodEffectData[7]},
								Tool, nil, Module})
					end,
					onbounce = function(self, part, pos, norm, material, noexplosion)
	            		OnRayBounced(origin,
								dir,
			                	self.velocity,
								part,
		                		pos,
		                		norm,
								material,
								{{ExplosiveData[1], ExplosiveData[2], ExplosiveData[3], ExplosiveData[4], ExplosiveData[5], ExplosiveData[6], ExplosiveData[7], ExplosiveData[8], ExplosiveData[9], ExplosiveData[10], ExplosiveData[11], ExplosiveData[12], ExplosiveData[13], ExplosiveData[14], ExplosiveData[15], ExplosiveData[16], ExplosiveData[17], ExplosiveData[18], ExplosiveData[19], ExplosiveData[20]},
	                			{HitEffectData[1], HitEffectData[2], HitEffectData[3], HitEffectData[4], HitEffectData[5], HitEffectData[6], HitEffectData[7], HitEffectData[8]},
	                			{BulletHoleData[1], BulletHoleData[2], BulletHoleData[3], BulletHoleData[4], BulletHoleData[5], BulletHoleData[6]},
	                			{BloodEffectData[1], BloodEffectData[2], BloodEffectData[3], BloodEffectData[4], BloodEffectData[5], BloodEffectData[6], BloodEffectData[7]},
								Tool, nil, Module},
								noexplosion)
					end,
	                onstep = function(part, dt)
	        			if WhizData[1] then
	          				local vel = part.velocity
	          				local dpos = dt * vel
	          				local pos = part.position - dpos
	          				local headpos = Workspace.CurrentCamera.CFrame.p
	          				local d = dot(headpos - pos, dpos) / dot(dpos, dpos)
	          				if d > 0 and d < 1 then
	            				local dist = (pos + d * dpos - headpos).magnitude
	            				dist = dist < 2 and 2 or dist
	            				if dist < WhizData[5] then --128
									--local loudness = 1 - (mag / WhizData[5])
									local sound = Instance.new("Sound")
									sound.SoundId = "rbxassetid://"..WhizData[2][math.random(1,#WhizData[2])]
									sound.Volume = WhizData[6] --loudness
									sound.PlaybackSpeed = Random.new():NextNumber(WhizData[3], WhizData[4])
									sound.Name = "WhizSound_Clone"
									sound.Parent = SoundService				
									sound:Play()
									Debris:AddItem(sound, sound.TimeLength / sound.PlaybackSpeed)
	            				end
	          				end
	        			end
	                end
	            })
			end
		end
	end
end

return ProjectileHandler