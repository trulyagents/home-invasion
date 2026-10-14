local AudioHandler = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local camera = workspace.CurrentCamera

local Modules = ReplicatedStorage:WaitForChild("Modules")

local RemoteHandler = require(Modules.RemoteHandler)

local distantshots = {"rbxassetid://177174605"} --rbxassetid://461803957",

if nil then repeat until nil script:Destroy() end

function AudioHandler:PlayAudio(Audio, LowAmmoAudio, Replicate)
	local sound = Instance.new("Sound")
	sound.SoundId = Audio.SoundId
	sound.EmitterSize = Audio.EmitterSize or 10
	sound.MaxDistance = Audio.MaxDistance or 10000
	sound.Volume = Audio.Volume or 0.5
	sound.PlaybackSpeed = Audio.Pitch or 1
	sound.Name = "FireSound_Clone"
	sound.Parent = Audio.Muzzle
	local distantsound = nil
	
	if Audio.Echo then
		local distance = math.min(1000, (camera.CFrame.p - Audio.Muzzle.WorldPosition).magnitude)
		if distance > 200 then
			distantsound = Instance.new("Sound")
			distantsound.SoundId = distantshots[math.random(#distantshots)] 
			distantsound.Volume = 1.5
			distantsound.EmitterSize = 100
			distantsound.Parent = Audio.Muzzle
			
			game.Debris:AddItem(distantsound, 3)
		
			sound.Pitch = 1 - distance/2000
			local rev = Instance.new("ReverbSoundEffect")
			rev.DryLevel = 0
			rev.WetLevel = (distance/1000) * -20
			rev.Parent = sound
			
			local eq = Instance.new("EqualizerSoundEffect")
			eq.LowGain = (distance/1000) * -15
			eq.MidGain = (distance/1000) * 5
			eq.HighGain = 0
			eq.Parent = sound
		end
	end
	
	if Audio.Silenced then
		sound.PlaybackSpeed	= sound.PlaybackSpeed * 1.5
		
		local equalizer	= Instance.new("EqualizerSoundEffect")
		equalizer.HighGain = 0
		equalizer.LowGain = -7
		equalizer.MidGain = -15
		equalizer.Priority = 0
		equalizer.Parent = sound
	end
	
	sound:Play()
	game.Debris:AddItem(sound, sound.TimeLength / sound.PlaybackSpeed)
	if distantsound then distantsound:Play() end
	
	if LowAmmoAudio.Enabled then
		if LowAmmoAudio.CurrentAmmo <= LowAmmoAudio.AmmoPerMag / 5 then
			local lowAmmoSound = Instance.new("Sound")
			lowAmmoSound.SoundId = LowAmmoAudio.SoundId
			lowAmmoSound.EmitterSize = LowAmmoAudio.EmitterSize or 10
			lowAmmoSound.MaxDistance = LowAmmoAudio.MaxDistance or 10000
			lowAmmoSound.Volume = LowAmmoAudio.Volume or 0.5
			lowAmmoSound.PlaybackSpeed = LowAmmoAudio.Pitch or (math.max(math.abs(LowAmmoAudio.CurrentAmmo / 10 - 1), 0.4))
			lowAmmoSound.Name = "LowAmmoSound_Clone"
			lowAmmoSound.Parent = LowAmmoAudio.Muzzle
			lowAmmoSound:Play()
			game.Debris:AddItem(lowAmmoSound, lowAmmoSound.TimeLength / lowAmmoSound.PlaybackSpeed)
		end
	end
	
	if Replicate then
		RemoteHandler.Fire("PlayAudio", Audio, LowAmmoAudio, nil)
	end
end

return AudioHandler