local RoundRules = {}

-- `protectorsAlive` should not include the traitor.
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

function RoundRules.escapeResult(player)
    return {
        winner = "Protectors",
        reason = "Escaped",
        message = player.DisplayName .. " escaped with the car keys",
    }
end

function RoundRules.timeExpiredResult(studioSolo, timeoutWinner)
    if studioSolo then
        return { winner = "StudioSolo", reason = "TimeExpired", message = "Solo test complete: time expired" }
    end
    return {
        winner = timeoutWinner,
        reason = "TimeExpired",
        message = timeoutWinner == "Invaders" and "Nobody escaped before dawn" or "The protectors held out until dawn",
    }
end

return RoundRules
