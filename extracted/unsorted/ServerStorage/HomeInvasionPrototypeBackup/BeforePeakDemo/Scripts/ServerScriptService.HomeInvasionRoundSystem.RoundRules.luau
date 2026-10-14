local RoundRules = {}

function RoundRules.eliminationResult(invadersAlive, protectorsAlive, studioSolo)
    if invadersAlive == 0 and protectorsAlive == 0 then
        return {
            winner = studioSolo and "StudioSolo" or "Draw",
            reason = "NoSurvivors",
            message = studioSolo and "Solo test ended: player eliminated"
                or "Round ended: no players remaining",
        }
    elseif not studioSolo and invadersAlive == 0 then
        return { winner = "Protectors", reason = "Elimination", message = "Protectors win" }
    elseif not studioSolo and protectorsAlive == 0 then
        return { winner = "Invaders", reason = "Elimination", message = "Invaders win" }
    end
    return nil
end

function RoundRules.timeExpiredResult(studioSolo)
    return {
        winner = studioSolo and "StudioSolo" or "Protectors",
        reason = "TimeExpired",
        message = studioSolo and "Solo test complete: time expired"
            or "Protectors win: time expired",
    }
end

return RoundRules
