-- NOTE: was Disabled in Studio
local sp = script.Parent
local t = os.time()-18000 --os.time = GMT. -18000 = -5 hours, GMT-5 = Pacific Stantdard time (US & Canada)
local Clock = sp.ClockRL
local HourArrow = Clock.Hour
local MinArrow = Clock.Min

while true do
	local t=os.time()-18000
	local hour=(((t/60)/60)/12)%1
	local minute=(hour*12)%1
	local mint = math.floor(minute*60)
	local second=math.floor(((minute*60)%1)*60)
	HourArrow.Rotation = 180+(hour*360)
	MinArrow.Rotation = 180+(mint*6)
	wait(1)
end
