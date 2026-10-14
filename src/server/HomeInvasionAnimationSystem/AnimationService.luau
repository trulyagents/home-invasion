local assets = game:GetService("ReplicatedStorage"):WaitForChild("HomeInvasionAnimations")
local caches = {}
local AnimationService = {}

local function cacheFor(character)
    local cache = caches[character]
    if cache then
        return cache
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        return nil
    end
    cache = { tracks = {}, animator = animator }
    caches[character] = cache
    cache.cleanup = character.Destroying:Connect(function()
        for _, track in pairs(cache.tracks) do
            track:Stop(0)
            track:Destroy()
        end
        cache.cleanup:Disconnect()
        caches[character] = nil
    end)
    return cache
end

function AnimationService.play(character, name, looped, speed)
    local cache = cacheFor(character)
    if not cache then
        return nil
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rig = assets:FindFirstChild(humanoid.RigType.Name)
    local animation = rig and rig:FindFirstChild(name)
    if not animation then
        return nil
    end
    local track = cache.tracks[name]
    if not track then
        local success, loaded = pcall(function()
            return cache.animator:LoadAnimation(animation)
        end)
        if not success then
            warn("Could not load " .. name .. ": " .. tostring(loaded))
            return nil
        end
        track = loaded
        track.Priority = looped and Enum.AnimationPriority.Action or Enum.AnimationPriority.Action2
        cache.tracks[name] = track
    end
    track.Looped = looped == true
    track:Play(0.12, 1, speed or 1)
    return track
end

function AnimationService.stop(character, name)
    local cache = caches[character]
    local track = cache and cache.tracks[name]
    if track then
        track:Stop(0.12)
    end
end

function AnimationService.stopActions(character)
    local cache = caches[character]
    if not cache then
        return
    end
    for _, track in pairs(cache.tracks) do
        track:Stop(0.12)
    end
end

return AnimationService
