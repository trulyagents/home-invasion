-- Task prompts carry a ForTeam attribute. Prompts for the other side are pushed out of
-- reach on this client only. The server checks teams again anyway.
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local tracked = {} -- [prompt] = original distance

local function apply(prompt)
    local forTeam = prompt:GetAttribute("ForTeam")
    if not forTeam then
        return
    end
    if tracked[prompt] == nil then
        tracked[prompt] = prompt.MaxActivationDistance
        prompt.Destroying:Connect(function()
            tracked[prompt] = nil
        end)
    end
    prompt.MaxActivationDistance = player:GetAttribute("RoundRole") == forTeam and tracked[prompt] or 0
end

workspace.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("ProximityPrompt") then
        -- attributes can land a moment after the instance
        task.defer(apply, descendant)
    end
end)
for _, descendant in workspace:GetDescendants() do
    if descendant:IsA("ProximityPrompt") then
        apply(descendant)
    end
end
player:GetAttributeChangedSignal("RoundRole"):Connect(function()
    for prompt in tracked do
        apply(prompt)
    end
end)
