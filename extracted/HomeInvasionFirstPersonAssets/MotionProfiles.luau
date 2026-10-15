-- Times are normalized to each action's duration. Pose offsets are camera-local.
-- These keyframes move only cosmetic arms/weapons; hitboxes and ammo remain server-owned.
local function pose(x, y, z, pitch, yaw, roll)
    return CFrame.new(x, y, z) * CFrame.Angles(math.rad(pitch or 0), math.rad(yaw or 0), math.rad(roll or 0))
end
local function frame(time, weapon, left)
    return { Time = time, Weapon = weapon or CFrame.identity, Left = left or CFrame.identity }
end
local equip = {
    frame(0, pose(0, -1.2, 0.5, -25, 0, 15)),
    frame(0.65, pose(0, 0.05, -0.03, 2, 0, -2)),
    frame(1),
}
local rangedAttack = {
    frame(0),
    frame(0.2, pose(0, 0.015, 0.13, 5, 0, 0)),
    frame(1),
}
local meleeAttack = {
    frame(0),
    frame(0.22, pose(0.15, 0.25, 0.2, 10, -25, -30), pose(0.1, 0.15, 0)),
    frame(0.52, pose(-0.8, 0.1, -0.15, -15, 35, 70), pose(0.2, 0.25, -0.1)),
    frame(0.75, pose(-0.45, -0.15, 0, -10, 20, 40)),
    frame(1),
}
return {
    EquipSeconds = 0.48,
    Profiles = {
        Unarmed = { Hold = pose(0, 0, 0), FreeHands = true },
        Crossbow = {
            Hold = pose(0.42, -0.5, -1.6, 0, 180, 0),
            Aim = pose(0, -0.1715, -1.8, 0, 180, 0),
            AttackSeconds = 0.28,
            Equip = equip,
            Attack = rangedAttack,
            Reload = {
                frame(0),
                frame(0.07, pose(0, -0.06, 0.1, 0, 0, -8), pose(0, 0.3, -0.58)),
                frame(0.22, pose(0, -0.06, 0.1, 0, 0, -8), pose(0, 0.15, 0.6)),
                frame(0.32, pose(0, -0.08, 0.1, 0, 0, -8), pose(-1, -0.45, 1.1)),
                frame(0.55, pose(0, -0.08, 0.1, 0, 0, -8), pose(-0.35, 0.45, 0.25)),
                frame(0.78, pose(0, -0.05, 0.05, 0, 0, -4), pose(0, 0.36, -0.15)),
                frame(0.9, pose(0, 0, 0.02), pose(0, 0.1, 0)),
                frame(1),
            },
        },
        Rifle = {
            Hold = pose(0.62, -0.48, -1.8, -90, 180, 0),
            Aim = pose(0.195, -0.312, -1.8, -90, 180, 0),
            AttackSeconds = 0.18,
            Equip = equip,
            Attack = rangedAttack,
            Reload = {
                frame(0),
                frame(0.15, pose(0, -0.05, 0.12, 0, 0, -14), pose(0, -0.35, 0.95)),
                frame(0.32, pose(0, -0.05, 0.12, 0, 0, -14), pose(-0.65, -0.7, 1.1)),
                frame(0.5, pose(0, -0.05, 0.12, 0, 0, -14), pose(-0.65, -0.7, 1.1)),
                frame(0.7, pose(0, -0.05, 0.1, 0, 0, -10), pose(0, -0.35, 0.95)),
                frame(0.85, pose(0, 0, 0.08), pose(0.05, 0.32, 0.5)),
                frame(1),
            },
        },
        Machete = {
            Hold = pose(0.72, -0.72, -1.35, -20, -10, -25),
            FreeLeft = true,
            AttackSeconds = 0.48,
            Equip = equip,
            Attack = meleeAttack,
        },
        Crowbar = {
            Hold = pose(0.72, -0.25, -1.5, -15, -10, -25),
            FreeLeft = true,
            AttackSeconds = 0.55,
            Equip = equip,
            Attack = meleeAttack,
        },
        KitchenKnife = {
            Hold = pose(0.62, -0.62, -1.3, -10, -10, -20),
            FreeLeft = true,
            AttackSeconds = 0.4,
            Equip = equip,
            Attack = meleeAttack,
        },
        Screwdriver = {
            Hold = pose(0.6, -0.6, -1.25, -10, -10, -20),
            FreeLeft = true,
            AttackSeconds = 0.32,
            Equip = equip,
            Attack = meleeAttack,
        },
        MeatTenderizer = {
            Hold = pose(0.66, -0.6, -1.35, -15, -10, -25),
            FreeLeft = true,
            AttackSeconds = 0.6,
            Equip = equip,
            Attack = meleeAttack,
        },
        FireplacePoker = {
            Hold = pose(0.72, -0.4, -1.5, -15, -10, -25),
            FreeLeft = true,
            AttackSeconds = 0.6,
            Equip = equip,
            Attack = meleeAttack,
        },
    },
}
