local root = script.Parent.Parent:WaitForChild("HumanoidRootPart")
local function muteDefault(child)
    if child.Name == "Running" and child:IsA("Sound") then child.Volume = 0 end
end
for _,child in root:GetChildren() do muteDefault(child) end
root.ChildAdded:Connect(muteDefault)