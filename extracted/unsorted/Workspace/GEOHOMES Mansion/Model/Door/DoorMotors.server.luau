-- NOTE: was Disabled in Studio
local d = Instance.new("Motor", script.Parent.Door.SS2)

d.MaxVelocity = 0.05
d.Part0 = script.Parent.LD
d.Part1 = d.Parent

script:Destroy()