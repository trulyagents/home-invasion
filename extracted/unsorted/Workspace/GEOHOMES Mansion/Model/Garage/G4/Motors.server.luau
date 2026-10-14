-- NOTE: was Disabled in Studio
local m1 = Instance.new("Motor", script.Parent.P1.SS) --doors
local m2 = Instance.new("Motor", script.Parent.P2.SS)

m1.MaxVelocity = 0.01
m1.Part0 = script.Parent.M
m1.Part1 = m1.Parent

m2.MaxVelocity = 0.02
m2.Part0 = script.Parent.P1.M2
m2.Part1 = m2.Parent