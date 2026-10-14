return function()
    assert(not game:GetService("RunService"):IsRunning(), "Stop the playtest first")
    for _, reference in ipairs(script.Parent.AssetStates:GetChildren()) do
        local object = reference.Value
        if object then
            for key, value in pairs(reference:GetAttributes()) do
                object[key] = value
            end
        end
    end
end