-- NOTE: was Disabled in Studio
wait(0.1)
local m = script.Parent.Parent.Parent.SS2.Motor

script.Parent.MouseClick:connect(function(p)
if m.DesiredAngle == 0 then
	m.DesiredAngle = 1.5
elseif m.DesiredAngle == 1.5 then
	m.DesiredAngle = 0
end
end)