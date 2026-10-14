local Debris = game:GetService("Debris")
local ReplicatedStrorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = ReplicatedStrorage.Remotes
local Modules = ReplicatedStrorage.Modules

local VisualizeMeleeEffect = Remotes.VisualizeMeleeEffect
local PlayAudio = Remotes.PlayAudio
local ShatterGlass = Remotes.ShatterGlass

local GlassShattering = require(Modules.GlassShattering)
local Utilities = require(Modules.Utilities)
local Math = Utilities.Math

local PhysicEffect = true --For base parts (blocks) only (Glass shattering)

VisualizeMeleeEffect.OnServerEvent:Connect(function(Player, Type, Replicate, Hit, Position, CF, Material, ...)
	local Table = {...}
	if Type == "HarshImpact" then
		for _, plr in next, Players:GetPlayers() do
			if plr ~= Player then
				VisualizeMeleeEffect:FireClient(plr, Type, nil, Hit, Position, CF, Material, Table[1])
			end
		end
	elseif Type == "Hit" then
		for _, plr in next, Players:GetPlayers() do
			if plr ~= Player then
				VisualizeMeleeEffect:FireClient(plr, Type, nil, Hit, Position, CF, Material, Table[1])
			end
		end
	end
end)

PlayAudio.OnServerEvent:Connect(function(Player, Audio, LowAmmoAudio, Replicate)
	for _, plr in next, Players:GetPlayers() do
		if plr ~= Player then
			PlayAudio:FireClient(plr, Audio, LowAmmoAudio, Replicate)
		end
	end
end)

ShatterGlass.OnServerEvent:Connect(function(Player, Hit, Pos, Dir)
	if Hit then
		if Hit.Name == "_glass" then
			if Hit.Transparency ~= 1 then
				if PhysicEffect then
					local Sound = Instance.new("Sound")
					Sound.SoundId = "http://roblox.com/asset/?id=2978605361"
					Sound.TimePosition = .1
					Sound.Volume = 1
					Sound.Parent = Hit
					Sound:Play()
					Sound.Ended:Connect(function()
						Sound:Destroy()
					end)
					GlassShattering:Shatter(Hit, Pos, Dir + Vector3.new(math.random(-25, 25), math.random(-25, 25), math.random(-25, 25)))
					--[[local LifeTime = 5
					local FadeTime = 1
					local SX, SY, SZ = Hit.Size.X, Hit.Size.Y, Hit.Size.Z
					for X = 1, 4 do
						for Y = 1, 4 do
							local Part = Hit:Clone()
							local position = Vector3.new(X - 2.1, Y - 2.1, 0) * Vector3.new(SX / 4, SY / 4, SZ)
							local currentTransparency = Part.Transparency
							Part.Name = "_shatter"
							Part.Size = Vector3.new(SX / 4, SY / 4, SZ)
							Part.CFrame = Hit.CFrame * (CFrame.new(Part.Size / 8) - Hit.Size / 8 + position)			
							Part.Velocity = Vector3.new(math.random(-10, 10), math.random(-10, 10), math.random(-10, 10))
							Part.Parent = workspace
							--Debris:AddItem(Part, 10)
							task.delay(LifeTime, function()
								if Part.Parent ~= nil then
									if LifeTime > 0 then
										local t0 = os.clock()
										while true do
											local Alpha = math.min((os.clock() - t0) / FadeTime, 1)
											Part.Transparency = Math.Lerp(currentTransparency, 1, Alpha)
							    			if Alpha == 1 then break end
						      				task.wait()
										end
										Part:Destroy()
									else
										Part:Destroy()
					    			end
								end
							end)
							Part.Anchored = false
						end
					end]]
				else
					local Sound = Instance.new("Sound")
					Sound.SoundId = "http://roblox.com/asset/?id=2978605361"
					Sound.TimePosition = .1
					Sound.Volume = 1
					Sound.Parent = Hit
					Sound:Play()
					Sound.Ended:Connect(function()
						Sound:Destroy()
					end)
					local Particle = script.Shatter:Clone()
					Particle.Color = ColorSequence.new(Hit.Color)
					Particle.Transparency = NumberSequence.new{
						NumberSequenceKeypoint.new(0, Hit.Transparency), --(time, value)
						NumberSequenceKeypoint.new(1, 1)
					}
					Particle.Parent = Hit
					task.delay(0.01, function()
						Particle:Emit(10 * math.abs(Hit.Size.magnitude))
						Debris:AddItem(Particle, Particle.Lifetime.Max)
					end)
					Hit.CanCollide = false
					Hit.Transparency = 1
				end
			end
		else
			error("Hit part's name must be '_glass'.")
		end
	else
		error("Hit part doesn't exist.")
	end
end)