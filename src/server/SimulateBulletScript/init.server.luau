local KickPlayer = true
_G.TempBannedPlayers = {} --Local ban list

local Thread = require(game.ReplicatedStorage.Modules.Thread)

local function numLerp(A, B, Alpha)
	return A + (B - A) * Alpha
end

local function compareTables(arr1, arr2)
	for i, v in pairs(arr1) do
		if (typeof(v) == "table") then
			if (compareTables(arr2[i], v) == false) then
				return false
			end
		else
			if (v ~= arr2[i]) then
				return false
			end
		end
	end
	return true
end

--Glenn's Anti-Exploit System (GAE for short). This code is very ugly, but does job done
local function secureSettings(Player,Gun,Module)
    local PreNewModule = Gun:FindFirstChild("Setting")
	if Gun and PreNewModule then
	    local NewModule = require(PreNewModule)
		if (compareTables(Module, NewModule) == false) then
			if KickPlayer then
				Player:Kick("You have been kicked and blocked from rejoining this specific server for exploiting gun stats.")
				warn(Player.Name.." has been kicked for exploiting gun stats.")
				table.insert(_G.TempBannedPlayers, Player)
			else
				warn(Player.Name.." - Potential Exploiter Bypass! Case 2: Changed Gun Stats From Client")	
			end
		end
	else
		if KickPlayer then
			Player:Kick("Gun and Module are not found. Kicked!")
			warn("Gun and Module are missing from "..Player.Name.."'s inventory.")
		else
			warn(Player.Name.." - Potential Exploiter Bypass! Case 1: Missing Gun And Module")	
		end
	end
end

local RE = game.ReplicatedStorage.Remotes.VisualizeBullet
RE.OnServerEvent:connect(function(Player,Module,Tool,Handle,VMHandle,CLDirections,SVDirections,FirePointObject,HitEffectData,BloodEffectData,BulletHoleData,ExplosiveData,BulletData,WhizData,ClientData)
	secureSettings(Player,Tool,Module)	
	for _, plr in next, game.Players:GetPlayers() do
		if plr ~= Player then
			RE:FireClient(plr,Module,Tool,Handle,VMHandle,CLDirections,SVDirections,FirePointObject,HitEffectData,BloodEffectData,BulletHoleData,ExplosiveData,BulletData,WhizData,ClientData)
		end
	end
end)

local RE_M = game.ReplicatedStorage.Remotes.VisualizeMuzzle
RE_M.OnServerEvent:connect(function(Player,Handle,VMHandle,MuzzleFlashEnabled,MuzzleLightData,MuzzleEffect,Replicate)
	for _, plr in next, game.Players:GetPlayers() do
		if plr ~= Player then
			RE_M:FireClient(plr,Handle,VMHandle,MuzzleFlashEnabled,MuzzleLightData,MuzzleEffect,Replicate)
		end
	end
end)

local RE_A = game.ReplicatedStorage.Remotes.PlayAudio
RE_A.OnServerEvent:connect(function(Player,Audio,LowAmmoAudio,Replicate)
	for _, plr in next, game.Players:GetPlayers() do
		if plr ~= Player then
			RE_A:FireClient(plr,Audio,LowAmmoAudio,Replicate)
		end
	end
end)

--For base parts (blocks) only
local physicEffect = true

local GlassShattering = require(game.ReplicatedStorage.Modules.GlassShattering)
local RE_S = game.ReplicatedStorage.Remotes.ShatterGlass
RE_S.OnServerEvent:connect(function(player, hit, pos, dir)
	if hit then
		if hit.Name == "_glass" then
			if hit.Transparency ~= 1 then
				if physicEffect then
					local sound = Instance.new("Sound")
					sound.SoundId = "http://roblox.com/asset/?id=2978605361"
					sound.TimePosition = .1
					sound.Volume = 1
					sound.Parent = hit
					sound:Play()
			        sound.Ended:Connect(function()
			        	sound:Destroy()
			        end)
					GlassShattering:shatter(hit, pos, dir + Vector3.new(math.random(-25, 25), math.random(-25, 25), math.random(-25, 25)))
					--[[local lifeTime = 5
					local fadeTime = 1
					local sx, sy, sz = hit.Size.x, hit.Size.y, hit.Size.z
					for x = 1, 4 do
						for y = 1, 4 do
							local part = hit:Clone()
							local position = Vector3.new(x-2.1, y-2.1, 0) * Vector3.new(sx/4, sy/4, sz)
							local currentTransparency = part.Transparency
							part.Name = "_shatter"
							part.Size = Vector3.new(sx/4, sy/4, sz)
							part.CFrame = hit.CFrame * (CFrame.new(part.Size/8) - hit.Size/8 + position)			
							part.Velocity = Vector3.new(math.random(-10,10), math.random(-10,10), math.random(-10,10))
							part.Parent = workspace
							--game.Debris:AddItem(part, 10)
							Thread:Delay(lifeTime, function()
								if part.Parent ~= nil then
									if lifeTime > 0 then
										local t0 = tick()
										while true do
											local Alpha = math.min((tick() - t0) / fadeTime, 1)
											part.Transparency = numLerp(currentTransparency, 1, Alpha)
							    			if Alpha == 1 then break end
						      				game:GetService("RunService").Heartbeat:wait()
										end
						    			part:Destroy()
									else
						    			part:Destroy()
					    			end
								end
							end)
							part.Anchored = false
						end
					end]]
				else
					local sound = Instance.new("Sound")
					sound.SoundId = "http://roblox.com/asset/?id=2978605361"
					sound.TimePosition = .1
					sound.Volume = 1
					sound.Parent = hit
					sound:Play()
			        sound.Ended:Connect(function()
			        	sound:Destroy()
			        end)
					local Particle = script.Shatter:Clone()
					Particle.Color = ColorSequence.new(hit.Color)
					Particle.Transparency = NumberSequence.new{
			    		NumberSequenceKeypoint.new(0, hit.Transparency), -- (time, value)
						NumberSequenceKeypoint.new(1, 1)
					}
					Particle.Parent = hit
					Thread:Delay(0.01, function()
						Particle:Emit(10*math.abs(hit.Size.magnitude))
						game.Debris:AddItem(Particle, Particle.Lifetime.Max)
					end)
					hit.CanCollide = false
					hit.Transparency = 1
				end
			end
		else
			error("Hit part's name must be '_glass'.")
		end
	else
		error("Hit part doesn't exist.")
	end
end)

local function CalculateDamage(Damage, TravelDistance, ZeroDamageDistance, FullDamageDistance)
	local ZeroDamageDistance = ZeroDamageDistance or 10000
	local FullDamageDistance = FullDamageDistance or 1000
	local DistRange = ZeroDamageDistance - FullDamageDistance
	local FallOff = math.clamp(1 - (math.max(0, TravelDistance - FullDamageDistance) / math.max(1, DistRange)), 0, 1)
	return math.max(Damage * FallOff, 0)
end

local DamageModule = require(script.DamageModule)
local VisualizeGore = game.ReplicatedStorage.Remotes.VisualizeGore
local InflictTarget = game.ReplicatedStorage.Remotes.InflictTarget
InflictTarget.OnServerInvoke = function(Player,Module,Tool,Tagger,TargetHumanoid,TargetTorso,Damage,Misc,Critical,hit,GoreData,ExplosiveData)
	local PreModule = Tool:FindFirstChild("Setting")
	if Tool and PreModule then
		--[[local Module = require(PreModule)
		if (Damage[1] ~= Module.BaseDamage
			or Damage[2] ~= Module.HeadshotDamageMultiplier
			or Damage[3] ~= Module.HeadshotEnabled
			or Misc[1] ~= Module.Knockback
			or Misc[2] ~= Module.Lifesteal
			or Misc[3] ~= Module.FlamingBullet
			or Misc[4] ~= Module.FreezingBullet
			or Misc[7] ~= Module.IgniteChance
			or Misc[8] ~= Module.IcifyChance
			or Critical[1] ~= Module.CriticalDamageEnabled
			or Critical[2] ~= Module.CriticalBaseChance
			or Critical[3] ~= Module.CriticalDamageMultiplier) then
			if KickPlayer then
		    	Player:Kick("You have been kicked and blocked from rejoining this specific server for exploiting damage registrer.")
				warn(Player.Name.." has been kicked for exploiting damage registrer.")
		    	table.insert(_G.TempBannedPlayers, Player)
			else
				warn(Player.Name.." - Potential Exploiter Bypass! Case 3: Exploited Damage Registrer From Client")	
			end
		--else
			--return
		end]]
	else
		if KickPlayer then
			Player:Kick("Gun and Module are not found. Kicked!")
			warn("Gun and Module are missing from "..Player.Name.."'s inventory.")
		else
			warn(Player.Name.." - Potential Exploiter Bypass! Case 1: Missing Gun And Module")	
		end
	end
	secureSettings(Player,Tool,Module) --Second layer
	local TrueDamage
	if ExplosiveData and ExplosiveData[1] then
		local damageMultiplier = (1 - math.clamp((ExplosiveData[3] / ExplosiveData[2]), 0, 1))		
		TrueDamage = ExplosiveData[4] and ((hit and hit.Name == "Head" and Damage[3]) and Damage[1] * Damage[2] or Damage[1]) * damageMultiplier or (hit and hit.Name == "Head" and Damage[3]) and Damage[1] * Damage[2] or Damage[1]
	else
		TrueDamage = Damage[5] and CalculateDamage((hit and hit.Name == "Head" and Damage[3]) and Damage[1] * Damage[2] or Damage[1], Damage[4], Damage[6], Damage[7]) or (hit and hit.Name == "Head" and Damage[3]) and Damage[1] * Damage[2] or Damage[1]
	end
	--GORE
	if TargetHumanoid.Health - TrueDamage <= 0 and not TargetHumanoid.Parent:FindFirstChild("gibbed") then
		if hit then
			if hit.Name == "Head" or hit.Name == "Torso" or hit.Name == "Left Arm" or hit.Name == "Right Arm" or hit.Name == "Right Leg" or hit.Name == "Left Leg" or hit.Name == "UpperTorso" or hit.Name == "LowerTorso" or hit.Name == "LeftUpperArm" or hit.Name == "LeftLowerArm" or hit.Name == "LeftHand" or hit.Name == "RightUpperArm" or hit.Name == "RightLowerArm" or hit.Name == "RightHand" or hit.Name == "RightUpperLeg" or hit.Name == "RightLowerLeg" or hit.Name == "RightFoot" or hit.Name == "LeftUpperLeg" or hit.Name == "LeftLowerLeg" or hit.Name == "LeftFoot" then
				VisualizeGore:FireAllClients(hit, TargetHumanoid.Parent, GoreData)
			end
		end
	end
	if Tagger and TargetHumanoid and TargetHumanoid.Health ~= 0 and TargetTorso and DamageModule.CanDamage(TargetHumanoid.Parent, Tagger) then
		while TargetHumanoid:FindFirstChild("creator") do
			TargetHumanoid.creator:Destroy()
		end
		local creator = Instance.new("ObjectValue",TargetHumanoid)
		creator.Name = "creator"
		creator.Value = Tagger
		game.Debris:AddItem(creator,5)
		if Critical[1] then
			local CriticalChanceRandom = Random.new():NextInteger(0, 100)
		    if CriticalChanceRandom <= Critical[2] then
			    TargetHumanoid:TakeDamage(math.abs(TrueDamage * Critical[3]))
		    else
			    TargetHumanoid:TakeDamage(math.abs(TrueDamage))
		    end			
		else
			TargetHumanoid:TakeDamage(math.abs(TrueDamage))
		end
	    if Misc[1] > 0 then --knockback
		    local shover = Tagger.Character.HumanoidRootPart or Tagger.Character.Head
		    local duration = 0.1
		    local speed = Misc[1]/duration
		    local velocity = (TargetTorso.Position - shover.Position).unit * speed
		    local shoveForce = Instance.new("BodyVelocity")
		    shoveForce.maxForce = Vector3.new(1e9, 1e9, 1e9)
		    shoveForce.velocity = velocity
		    shoveForce.Parent = TargetTorso
		    game:GetService("Debris"):AddItem(shoveForce, duration)
		end
		if Misc[2] > 0 and Tagger.Character.Humanoid and Tagger.Character.Humanoid.Health ~= 0 then --lifesteal
			Tagger.Character.Humanoid.Health = Tagger.Character.Humanoid.Health + (TrueDamage*Misc[2])
		end
		if Misc[3] then --flame		
		    local igniteroll = math.random(1, 100)
		    if igniteroll <= Misc[7] then
			    local Debuff = TargetHumanoid.Parent:FindFirstChild("IgniteScript") or Misc[5]:Clone()
			    Debuff.creator.Value = Tagger
			    Debuff.Disabled = false
			    Debuff.Parent = TargetHumanoid.Parent
		    end
		end
		if Misc[4] then --freeze
		    local icifyroll = math.random(1, 100)
		    if icifyroll <= Misc[8] then
			    local Debuff = TargetHumanoid.Parent:FindFirstChild("IcifyScript") or Misc[6]:Clone()
			    Debuff.Disabled = false
			    Debuff.Parent = TargetHumanoid.Parent
		    end
		end
	end
end

game.Players.PlayerAdded:connect(function(player)
	for i, v in pairs(_G.TempBannedPlayers) do
		if v == player.Name then
			player:Kick("You cannot rejoin a server the you were kicked from.")
			warn(player.Name.." tried to rejoin a server the he/she was kicked from.")
			break
		end
	end
end)