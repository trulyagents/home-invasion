return {
    -- Solo testing only works in Studio (checked with RunService:IsStudio()).
    StudioSoloEnabled = true,
    StudioSoloIntermissionSeconds = 10,
    StudioSoloRoundSeconds = 120,

    -- Team sizes scale with the server: 1 Invader for every PlayersPerInvader players.
    MinimumPlayers = 4,
    PlayersPerInvader = 4,
    MaxInvaders = 3,
    MaxProtectors = 8,

    -- A secret traitor is picked when there are at least this many Protectors.
    TraitorMinimumProtectors = 4,

    -- Who wins if nobody escapes and nobody is wiped out.
    TimeoutWinner = "Invaders",

    IntermissionSeconds = 15,
    PreparationSeconds = 45,
    RoundSeconds = 300,
    ResultsSeconds = 8,
    RespawnSeconds = 3,
    SpawnTimeoutSeconds = 25,

    Masks = { "Lamb", "Fox", "Tiger" },
}
