-- Round info that other server systems need but clients must not see.
local RoundShared = {
	roundId = 0,
	traitor = nil, -- Player secretly working with the Invaders
	survivor = nil, -- Protector who can set traps
	escapedRoundId = nil, -- set when a Protector escapes with the keys
	escapedBy = nil,
}

function RoundShared.reset(roundId)
	RoundShared.roundId = roundId
	RoundShared.traitor = nil
	RoundShared.survivor = nil
	RoundShared.escapedRoundId = nil
	RoundShared.escapedBy = nil
end

function RoundShared.isTraitor(player)
	return player ~= nil and RoundShared.traitor == player
end

return RoundShared
