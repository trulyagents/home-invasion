--!strict
return {
    -- phone
    CallSeconds = 4, -- hold to dial
    HelpSeconds = 90, -- police arrive this long after the call
    CutLineSeconds = 3,

    -- car fuel
    FuelSeconds = 3,
    DrainSeconds = 4,
    DrainCooldown = 45,
    GasMinDistance = 40,

    -- safe
    NoteCount = 3,
    SafeGuessCooldown = 1,

    -- hiding
    WardrobeCount = 4,
    SearchSeconds = 1.5,

    -- noise pings shown to invaders
    NoiseCooldown = 1.5,

    -- random events
    EventMinGap = 40,
    EventMaxGap = 70,
    BlackoutSeconds = 8,

    Sounds = {
        PhoneRing = "rbxassetid://9117304268",
        Siren = "rbxassetid://9117810961",
        DogBark = "rbxassetid://8678449977",
        Thunder = "rbxassetid://9120016241",
        Creak = "rbxassetid://9114496277",
    },
}
