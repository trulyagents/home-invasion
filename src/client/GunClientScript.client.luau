local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Modules = ReplicatedStorage:WaitForChild("Modules")

local RE = Remotes.VisualizeBullet
local RE_M = Remotes.VisualizeMuzzle
local RE_A = Remotes.PlayAudio

local ProjectileHandler = require(Modules.ProjectileHandler)
local MuzzleHandler = require(Modules.MuzzleHandler)
local AudioHandler = require(Modules.AudioHandler)

function SimulateProjectile(Module, Tool, Handle, VMHandle, CLDirections, SVDirections, FirePointObject, HitEffectData, BloodEffectData, BulletHoleData, ExplosiveData, BulletData, WhizData, ClientData)
	ProjectileHandler:SimulateProjectile(Module, Tool, Handle, VMHandle, CLDirections, SVDirections, FirePointObject, HitEffectData, BloodEffectData, BulletHoleData, ExplosiveData, BulletData, WhizData, ClientData)
end

function VisualizeMuzzle(Handle, VMHandle, MuzzleFlashEnabled, MuzzleLightData, MuzzleEffect, Replicate)
	MuzzleHandler:VisualizeMuzzle(Handle, VMHandle, MuzzleFlashEnabled, MuzzleLightData, MuzzleEffect, Replicate)
end

function PlayAudio(Audio, LowAmmoAudio, Replicate)
	AudioHandler:PlayAudio(Audio, LowAmmoAudio, Replicate)
end

RE.OnClientEvent:connect(SimulateProjectile)
RE_M.OnClientEvent:connect(VisualizeMuzzle)
RE_A.OnClientEvent:connect(PlayAudio)