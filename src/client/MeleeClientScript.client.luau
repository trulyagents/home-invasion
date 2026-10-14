local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Modules = ReplicatedStorage:WaitForChild("Modules")

local VisualizeMeleeEffect = Remotes.VisualizeMeleeEffect
local PlayAudio = Remotes.PlayAudio

local MeleeHandler = require(Modules.MeleeHandler)
local AudioHandler = require(Modules.AudioHandler)

local function VisualizeReplicatedMeleeEffect(Module, Tool, Handle, Directions, FirePointObject, HitEffectData, BloodEffectData, BulletHoleData, ExplosiveData, BulletData, WhizData, ClientData)
	MeleeHandler:VisualizeMeleeEffect(Module, Tool, Handle, Directions, FirePointObject, HitEffectData, BloodEffectData, BulletHoleData, ExplosiveData, BulletData, WhizData, ClientData)
end

local function PlayReplicatedAudio(Audio, LowAmmoAudio, Replicate)
	AudioHandler:PlayAudio(Audio, LowAmmoAudio, Replicate)
end

VisualizeMeleeEffect.OnClientEvent:Connect(VisualizeReplicatedMeleeEffect)
PlayAudio.OnClientEvent:Connect(PlayReplicatedAudio)