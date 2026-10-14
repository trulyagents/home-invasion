return function()
    assert(not game:GetService("RunService"):IsRunning(), "Stop Play before restoring.")
    local backup = script.Parent
    for _, reference in backup.Roots:GetChildren() do
        local target = reference.Value
        if target then target:PivotTo(reference:GetAttribute("OriginalPivot")) end
    end
    for _, reference in backup.PartStates:GetChildren() do
        if reference.Value then reference.Value.CFrame = reference:GetAttribute("OriginalCFrame") end
    end
    for _, reference in backup.AttributeStates:GetChildren() do
        if reference.Value then
            for name, value in reference:GetAttributes() do reference.Value:SetAttribute(name, value) end
        end
    end
    local forest = backup:FindFirstChild("Bosque")
    if forest then forest.Parent = workspace end
    local ground = backup.GroundReference.Value
    if ground then ground:Destroy() end
    return "Forest and house placement restored."
end