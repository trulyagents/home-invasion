--[[ Edited Version
====================================================================================================
Weapons and Tools Pack 2016's Gun by SuperEvilAzmil and edited by thienbao2109

Features:
- FilteringEnabled support
- Easy to edit with a bunch of settings
- No delays between Mouse Click and Gun Fire
====================================================================================================
]]

local Module = {
--	====================
--	BASIC
--	A basic settings for the gun
--	====================

		Auto = true;
	BaseDamage = 24.5;
		FireRate = 0.07; --In second
	ReloadTime = 2.25; --In second
		AmmoPerMag = 30; --Put "math.huge" to make this gun has infinite ammo and never reload
		Spread = 16; --In degree
		Range = 5000; --The furthest distance the bullet can travel
		HeadshotEnabled = true; --Enable the gun to do extra damage on headshot
		HeadshotDamageMultiplier = 2.2;
		EquipTime = 1; --In 125065766764748
	IdleAnimationID = 75715417072452; --Set to "nil" if you don't want to animate
		IdleAnimationSpeed = 1;
	FireAnimationID = nil; --Set to "nil" if you don't want to animate
		FireAnimationSpeed = 0.6;
	ReloadAnimationID = 75340971663295; --Set to "nil" if you don't want to animate
		ReloadAnimationSpeed = 2;
	EquippedAnimationID = 135611753408764; --Set to "nil" if you don't want to animate
		EquippedAnimationSpeed = 1;
	
		--Viewmodel
	VMIdleAnimationID = 78457076998345; --Set to "nil" if you don't want to animate
		VMIdleAnimationSpeed = 1;
	VMFireAnimationID = 84452043377341; --Set to "nil" if you don't want to animate
		VMFireAnimationSpeed = 1;
	VMReloadAnimationID = 75266873189508; --Set to "nil" if you don't want to animate
		VMReloadAnimationSpeed = 1;
	VMEquippedAnimationID = 119045081299778; --Set to "nil" if you don't want to animate
		VMEquippedAnimationSpeed = 1;
		
		--Enable the user to play second animation. Useful for dual wield 
		SecondaryFireAnimationEnabled = false; --You need an animation ID in order to enable it
		SecondaryFireAnimationID = nil; --Set to "nil" if you don't want to animate
		SecondaryFireAnimationSpeed = 1;
	
		--Viewmodel
		VMSecondaryFireAnimationID = nil; --Set to "nil" if you don't want to animate
		VMSecondaryFireAnimationSpeed = 1;
		
		--Enable the user to play aim animations
		AimAnimationsEnabled = false;
	AimIdleAnimationID = 135611753408764; --Set to "nil" if you don't want to animate
		AimIdleAnimationSpeed = 1;
	AimFireAnimationID = 12750206279; --Set to "nil" if you don't want to animate
		AimFireAnimationSpeed = 1;
		AimSecondaryFireAnimationID = nil; --Set to "nil" if you don't want to animate. NOTE: Make sure "SecondaryFireAnimation" setting is enabled
		AimSecondaryFireAnimationSpeed = 1;
		
		AutoReload = true; --Reload automatically when you run out of mag; disabling it will make you reload manually

-- ====================
-- SMOKE TRAIL
-- Emit smoke trail while firing. NOTE: This setting is only for client
-- ====================

		SmokeTrailEnabled = false;
		SmokeTrailRateIncrement = 1;
		MaximumRate = 4; --Beyond this will return "CurrentRate" to 0 and emit smoke trail. NOTE: Last smoke trail will be terminated after this
		MaximumTime = 1; --Maximum time that smoke trail won't be emitted
		
--  ====================
--  DAMAGE DROPOFF
--	Calculate how the damage of a single shot decreases when the target hit is at a distance away from the gun shot. NOTE: This setting won't apply with "ExplosiveEnabled"
--  ====================

		DamageDropOffEnabled = false;
		ZeroDamageDistance = 10000; --Anything hit at or beyond this distance will receive no damage; default is 10000
		FullDamageDistance = 1000; --Maximum distance that shots will do full damage. Default is 1000 and anything hit beyond this distance will receive less and less damage as the distance nears "ZeroDamageDistance"
		
--	====================
--	GORE VISUALIZER
--	Create gore effect when humanoid died
--	====================

        GoreEffectEnabled = false;
		GoreSoundIDs = {1930359546};
		GoreSoundPitchMin = 1; --Minimum pitch factor you will acquire
	    GoreSoundPitchMax = 1.5; --Maximum pitch factor you will acquire
		GoreSoundVolume = 1;
		FullyGibbedLimbChance = 50; --In percent
		
--	====================
--	CRITICAL DAMAGE
--	Damage critically within its chance
--	====================

        CriticalDamageEnabled = false;
        CriticalBaseChance = 5; --In percent
        CriticalDamageMultiplier = 3;
		
--	====================
--	FIRE SOUND EFFECTS
--	Special effects for fire sound
--	====================
		
		SilenceEffect = false; --Lower volume
		EchoEffect = true; --Create echo effect from distance
		LowAmmo = true; --Play sound when low ammo
		RaisePitch = true; --"LowAmmo" only. The lower ammo is, the higher pitch will play
		
--	====================
--	WALK SPEED REDUTION
--	Nerf chraracter's walk speed when equip the gun
--	====================

        WalkSpeedRedutionEnabled = false;
	    WalkSpeedRedution = 6;
	
--	====================
--	INSPECT ANIMATION
--	Inspect the gun just to see how it looks
--	====================

		InspectAnimationEnabled = true;
	InspectAnimationID = nil; --Set to "nil" if you don't want to animate
		InspectAnimationSpeed = 1;
	
		--Viewmodel
	VMInspectAnimationID = 99066553127826; --Set to "nil" if you don't want to animate
		VMInspectAnimationSpeed = 1;

--	====================
--	TACTICAL RELOAD ANIMATION
--	Reload the gun that has only fired a few rounds out of its magazine
--	====================

		TacticalReloadAnimationEnabled = false;
	TacticalReloadAnimationID = nil; --Set to "nil" if you don't want to animate
		TacticalReloadAnimationSpeed = 1;
	TacticalReloadTime = 2.25;
	
		--Viewmodel
	VMTacticalReloadAnimationID = 12750200350; --Set to "nil" if you don't want to animate
		VMTacticalReloadAnimationSpeed = 1;
	
--	====================
--	HOLD DOWN ANIMATION
--	Character won't fire if hold down the gun
--	====================

        HoldDownEnabled = false;
        HoldDownAnimationID = nil;
	    HoldDownAnimationSpeed = 0.5;
	
		--Viewmodel
		VMHoldDownAnimationID = nil;
        VMHoldDownAnimationSpeed = 0.5;
		
--	====================
--	BULLET HOLE VISUALIZER
--	Create a bullet hole when a bullet hit something but not character
--	====================

        BulletHoleEnabled = true;
        BulletHoleSize = 0.5;
        BulletHoleTexture = {2078626}; --You can insert more IDs
        BulletHoleVisibleTime = 3; --In second
        BulletHoleFadeTime = 1; --In second
        PartColor = true; --Set to hit object color
		
--	====================
--	HIT VISUALIZER
--	Create hit effect when a bullet hit something but not character(And hit sound, too)
--	====================

        HitEffectEnabled = true;
		HitSoundIDs = {186809061, 186809249, 186809250, 186809252};
		HitSoundPitchMin = 1; --Minimum pitch factor you will acquire
	    HitSoundPitchMax = 1.5; --Maximum pitch factor you will acquire
		HitSoundVolume = 1;
        CustomHitEffect = false; --Emits your custom hit effect. NOTE: If you this setting disabled, hit effect will set to default(material tracker included)

--	====================
--	BLOOD VISUALIZER
--	Create blood when a bullet hit character(And hit character sound, too)
--	====================


	BloodEnabled = true;
	HitCharSndIDs = {3802437008, 3802437361, 3802437696, 3802440043, 3802440388, 3802442962};
	HitCharSndPitchMin = 1; --Minimum pitch factor you will acquire
	HitCharSndPitchMax = 1; --Maximum pitch factor you will acquire
	HitCharSndVolume = 1;

	--Blood wound
	BloodWoundEnabled = false;
	BloodWoundSize = 0.5;
	BloodWoundTexture = {2078626}; --You can insert more IDs
	BloodWoundTextureColor = Color3.fromRGB(255, 0, 0);
	BloodWoundVisibleTime = 3; --In second
	BloodWoundFadeTime = 1; --In second
	BloodWoundPartColor = true; --Set to hit object color

		
--	====================
--	TWEEN SETTING
--	Part of ironsight and sniper aim
--	====================

        TweenLength = 0.1; --In second
	EasingStyle = Enum.EasingStyle.Quad; --Linear, Sine, Back, Quad, Quart, Quint, Bounce or Elastic?
        EasingDirection = Enum.EasingDirection.InOut; --In, Out or InOut?

--	====================
--	TWEEN SETTING(NO AIM DOWN)
--	Part of ironsight and sniper aim
--	====================

        TweenLengthNAD = 0.1; --In second
        EasingStyleNAD = Enum.EasingStyle.Quint; --Linear, Sine, Back, Quad, Quart, Quint, Bounce or Elastic?
        EasingDirectionNAD = Enum.EasingDirection.Out; --In, Out or InOut?
		
--	====================
--	BULLET WHIZZING SOUND
--	Create a sound when a bullet travelling through character
--	====================

        WhizSoundEnabled = true;
        WhizSoundID = {3809084884, 3809085250, 3809085650, 3809085996, 3809086455};
		WhizSoundVolume = 1;
		WhizSoundPitchMin = 1; --Minimum pitch factor you will acquire
	    WhizSoundPitchMax = 1; --Maximum pitch factor you will acquire
	    WhizDistance = 25;
	
--		Make sure "CanMovePart" is enabled. Otherwise, it won't work
		
--	====================
--	HITMARKER
--	Mark on somewhere when a bullet hit character
--	====================

        HitmarkerEnabled = true;
	HitmarkerSoundID = {7172056822, 7172056822, 7172056822};
        --Normal
        HitmarkerColor = Color3.fromRGB(255, 255, 255);
        HitmarkerFadeTime = 0.4;
        HitmarkerSoundPitch = 1;
        --Headshot
        HitmarkerColorHS = Color3.fromRGB(255, 0, 0);
        HitmarkerFadeTimeHS = 0.4;
        HitmarkerSoundPitchHS = 1.4;

--	====================
--	CROSSHAIR
--	A gun cursor
--	====================

        CrossSize = 7;
        CrossExpansion = 100;
        CrossSpeed = 15;
        CrossDamper	= 0.8;
		
--	====================
--	MUZZLE
--	Create a muzzle flash when firing
--	====================
        
        MuzzleFlashEnabled = true;
        MuzzleLightEnabled = true;
        LightBrightness = 4;
        LightColor = Color3.new(255/255, 283/255, 0/255);
        LightRange = 15;
        LightShadows = true;
        VisibleTime = 0.01; --In second
		
--	====================
--	BULLET SHELL EJECTION
--	Eject bullet shells when firing
--	====================

		BulletShellEnabled = true;
		BulletShellDelay = 0;
		BulletShellVelocity = 17;
		BulletShellRotVelocity = 40;
		ShellSize = Vector3.new(0.2, 0.2, 0.32); --Scale the part
		AllowCollide = false; --If false, a bullet shell will go through any parts
		ShellScale = Vector3.new(1.5, 1.5, 1.5); --Scale mesh
		ShellMeshID = 95392019;
		ShellTextureID = 95391833;
		DisappearTime = 5; --In second
		
--      You can edit velocity by go to GunScript_Local, and scroll down until you see "function EjectShell(ShootingHandle)"
		
--	====================
--	IRONSIGHT
--	Allow user to ironsighting
--	====================

		IronsightEnabled = true; --NOTE: If "SniperEnabled" is enabled, this setting is not work
	FieldOfViewIS = 40;
		MouseSensitiveIS = 0.5; --In percent
		SpreadRedutionIS = 0.6; --In percent. NOTE: Must be the same value as "SpreadRedutionS"
		CrossScaleIS = 0;
		
--	====================
--	LIMITED AMMO
--	Make a gun has a limit ammo
--	====================

		LimitedAmmoEnabled = false;
		Ammo = 60;
		MaxAmmo = math.huge; --Put "math.huge" to allow user to carry unlimited ammo
		
--	====================
--	SHOTGUN
--	Enable the gun to fire multiple bullet in one shot
--	====================

		ShotgunEnabled = false;
		BulletPerShot = 8;
		
		ShotgunPump = false; --Make user pumping like Shotgun after firing
		ShotgunPumpinAnimationID = nil; --Set to "nil" if you don't want to animate
		ShotgunPumpinAnimationSpeed = 1;
		ShotgunPumpinSpeed = 0.5; --In second
	
		--Viewmodel
		VMShotgunPumpinAnimationID = nil; --Set to "nil" if you don't want to animate
		VMShotgunPumpinAnimationSpeed = 1;
	
		SecondaryShotgunPump = false; --Only for dual wield
		SecondaryShotgunPumpinAnimationID = nil; --Set to "nil" if you don't want to animate
		SecondaryShotgunPumpinAnimationSpeed = 1;
		SecondaryShotgunPumpinSpeed = 0.5; --In second
	
		--Viewmodel
		VMSecondaryShotgunPumpinAnimationID = nil; --Set to "nil" if you don't want to animate
		VMSecondaryShotgunPumpinAnimationSpeed = 1;
		
		ShotgunReload = false; --Make user reloading like Shotgun, which user clipin shell one by one
		ShotgunClipinAnimationID = nil; --Set to "nil" if you don't want to animate
		ShotgunClipinAnimationSpeed = 1;
		ShellClipinSpeed = 0.5; --In second
		PreShotgunReload = false; --Make user pre-reloading before consecutive reload. NOTE: "ShotgunReload" must be enabled
		PreShotgunReloadAnimationID = nil; --Set to "nil" if you don't want to animate
		PreShotgunReloadAnimationSpeed = 1;
		PreShotgunReloadSpeed = 0.5; --In second
	
		--Viewmodel
		VMShotgunClipinAnimationID = nil; --Set to "nil" if you don't want to animate
		VMShotgunClipinAnimationSpeed = 1;
		VMPreShotgunReloadAnimationID = nil; --Set to "nil" if you don't want to animate
		VMPreShotgunReloadAnimationSpeed = 1;
	
		ShotgunPattern = false;
		SpreadPattern = { --{x, y}. This should be the same as "BulletPerShot"
			-- inner 3
			{0, -0.4};
			{-0.35, 0.2};
			{0.35, 0.2};
		
			-- outer five
			{0, 1};
			{0.95, 0.31};
			{0.59, -0.81};
			{-0.59, -0.81};
			{-0.95, 0.31};
		};
		
--		How "ShotgunPump" works [Example 1]:

--      Fire a (shot)gun
--		>>>
--		After "FireRate", user will pump it, creates pumpin delay + "PumpSound"
		
--		How "ShotgunReload" works [Example 2]:

--		Play "ShotgunClipinAnimation" + Play "ShotgunClipin" Audio
--		>>>
--		Wait "ShellClipinSpeed" second(s)
--		>>>
--		Repeat "AmmoPerClip" - "Current Ammo" times
--		>>>
--		Play "ReloadAnimation" + Play "ReloadSound"
--		>>>
--		Wait "ReloadTime"
		
--	====================
--	BURST FIRE
--	Enable the gun to do burst firing like Assault Rifle
--	====================

		BurstFireEnabled = false;
		BulletPerBurst = 3;
		BurstRate = 0.075; --In second

--	====================
--	SELECTIVE FIRE
--	Enable the user to switch firemode. NOTE: The following settings: "Auto", "FireRate", "BurstFireEnabled", "BulletPerBurst", "BurstRate" and "ChargedShotAdvanceEnabled" will be disabled if "SelectiveFireEnabled" is enabled
--	====================

		SelectiveFireEnabled = false;
		FireModes = {1, 2, 3, true}; --"true" is a boolean which uses for autofire, while integer is being used for burst counts
		FireRates = {0.125, 0.5, 0.5, 0.1};
		BurstRates = {0, 0.075, 0.075, 0};
		FireModeTexts = {"SEMI-AUTO", "2-ROUND-BURST", "3-ROUND-BURST", "AUTO"};
		SwitchTime = 0.25; --In second

		SwitchAnimationID = nil; --Set to "nil" if you don't want to animate
		SwitchAnimationSpeed = 1;

		--Viewmodel
		VMSwitchAnimationID = nil; --Set to "nil" if you don't want to animate
		VMSwitchAnimationSpeed = 1;

--		The priority of firemode is from left to right
		
--	====================
--	SNIPER
--	Enable user to use scope
--	====================

		SniperEnabled = false; --NOTE: If "IronsightEnabled" is enabled, this setting is not work
		FieldOfViewS = 12.5;
		MouseSensitiveS = 0.5; --In percent
		SpreadRedutionS = 1; --In percent. NOTE: Must be the same value as "SpreadRedutionOS"
		CrossScaleS = 0;
		ScopeSensitive = 0.2;
		ScopeDelay = 0;
		ScopeKnockbackSpeed = 7;
        ScopeKnockbackDamper = 0.65;
		ScopeSwaySpeed = 10;
        ScopeSwayDamper	= 0.4;

--      You can edit knockback offset by go to GunScript_Local, and scroll down until you reach line 421 and 486
		
--	====================
--	CAMERA RECOILING
--	Make user's camera recoiling when shooting
--	====================

		CameraRecoilingEnabled = true;
		Recoil = 51;
		AngleX_Min = 1; --In degree
		AngleX_Max = 1; --In degree
		AngleY_Min = 0; --In degree
		AngleY_Max = 0; --In degree
		AngleZ_Min = -1; --In degree
		AngleZ_Max = 0; --In degree
        Accuracy = 0.1; --In percent. For example: 0.5 is 50%
        RecoilSpeed = 15; 
        RecoilDamper = 0.65;
		RecoilRedution = 0.5; --In percent.
		
--	====================
--	EXPLOSIVE
--	Make a bullet explosive so user can deal a damage to multiple enemy in single shot. NOTE: Explosion won't break joints
--	====================

		ExplosiveEnabled = false;
		ExplosionSoundEnabled = true;
		ExplosionSoundIDs = {163064102};
		ExplosionSoundVolume = 1;
		ExplosionSoundPitchMin = 1; --Minimum pitch factor you will acquire
	    ExplosionSoundPitchMax = 1.5; --Maximum pitch factor you will acquire
		ExplosionRadius = 8;
		DamageBasedOnDistance = false;
		CustomExplosion = false;
		ExplosionKnockback = false; --Enable the explosion to knockback player. Useful for rocket jumping
		ExplosionKnockbackPower = 50;
		ExplosionKnockbackMultiplierOnPlayer = 2;
		ExplosionKnockbackMultiplierOnTarget = 2;
        ExplosionCraterEnabled = true;
      	ExplosionCraterSize = 3;
        ExplosionCraterTexture = {53875997}; --You can insert more IDs
        ExplosionCraterVisibleTime = 3; --In second
        ExplosionCraterFadeTime = 1; --In second
        ExplosionCraterPartColor = false; --Set to hit object color	
	
--	====================
--	PROJECTILE VISUALIZER
--	Display a travelling projectile
--	====================

		BulletSpeed = 2000; --Studs/second
		BulletAcceleration = Vector3.new(0, 0, 0); --The amount of force applied to the bullet in world space. Useful for wind effects
		BulletColor = Color3.fromRGB(255,170,127);
		BulletTexture = "rbxassetid://2650195052";
		BulletSize = 0.4;
		BulletBloom = 0.005;
		BulletBrightness = 400;
		BulletLifetime = 1;
		WindSpeed = 10;
		WindResistance = 1;
		VisibleBullet = true; --Formerly known as "VisibleBeam"
		BulletType = "None";
		CanSpinPart = false;
		SpinX = 3;
		SpinY = 0;
		SpinZ = 0;
		
--	====================
--	CHARGED SHOT
--	Make a gun charging before firing. Useful for a gun like "Railgun" or "Laser Cannon"
--	====================
		
		ChargedShotEnabled = false;
		ChargingTime = 1;
		
--	====================
--	MINIGUN
--	Make a gun delay before/after firing
--	====================

		MinigunEnabled = false;
		DelayBeforeFiring = 1;
		DelayAfterFiring = 1;
		MinigunRevUpAnimationID = nil;
		MinigunRevUpAnimationSpeed = 1;
		MinigunRevDownAnimationID = nil;
		MinigunRevDownAnimationSpeed = 1;
	
		--Viewmodel
		VMMinigunRevUpAnimationID = nil;
		VMMinigunRevUpAnimationSpeed = 1;
		VMMinigunRevDownAnimationID = nil;
		VMMinigunRevDownAnimationSpeed = 1;
		
--	====================
--	MISCELLANEOUS
--	Etc. settings for the gun
--	====================

		Knockback = 0; --Setting above 0 will enabling the gun to push enemy back.
		Lifesteal = 0; --In percent - Setting above 0 will allow user to steal enemy's health by dealing a damage to them.

		FlamingBullet = false; --Enable the bullet to set enemy on fire. Its DPS and Duration can be edited inside "IgniteScript"
        IgniteChance = 100;

		FreezingBullet = false; --Enable the bullet to freeze enemy. Its Duration can be edited inside "IcifyScript"
        IcifyChance = 100;

		DualEnabled = false; --Enable the user to hold two guns instead one. In order to make this setting work, you must clone its Handle and name it to "Handle2". Enabling this setting will override Idle Animation ID.
	
		PenetrationType = "HumanoidPenetration"; --2 types: "WallPenetration" and "HumanoidPenetration"
		PenetrationDepth = 0; --"WallPenetration" only. This is how many studs a bullet can penetrate into a wall. So if penetration is 0.5 and the wall is 1 studs thick, the bullet won't come out the other side. NOTE: It doesn't work with "ExplosiveEnabled"
		PenetrationAmount = 0; --"HumanoidPenetration" only. Setting above 0 will enabling the gun to penetrate up to XX victim(s). Cannot penetrate wall. NOTE: It doesn't work with "ExplosiveEnabled"
		
		RicochetAmount = 0; --Setting above 0 will enabling the gun to bounce objects in amount of bounces. NOTE: This will disable "PenetrationDepth"	
		BounceElasticity = 1;
		FrictionConstant = 0;
		NoExplosionWhileBouncing = false; --Enable the bullet to be prevented from exploding on bounce. NOTE: "NoExplosionWhileBouncing" will be disabled after reaching 0 bounce
		StopBouncingOnHitHumanoid = false; --Enable the bullet to be forced to stop bouncing after hitting humanoid
		SuperRicochet = false; --Enable the bullet to bounce objects in countless bounces. NOTE: This doesn't affect "RicochetAmount" but won't remove bullet regardless of its limited amount of bounces

		TouchEventOnTimeout = false; --Yield "ontouch" event after timing out (exceed maximum life time). Useful for a TF2 styled grenade launcher
		
		SelfKnockback = false; --Enable the gun to knockback player. Useful for shotgun jumping
		SelfKnockbackPower = 50;
		SelfKnockbackMultiplier = 2;
		SelfKnockbackRedution = 0.8;

		ProjectileMotion = false; --Enable the gun to visible trajectory. Useful for projectile arc weapon

--	====================
--	CHARGED SHOT ADVANCE
--	Unlike "ChargedShot", this advanced version will allow gun to charge by holding down input. NOTE: This setting will disable some features such as "Auto", "ChargedShot", "MinigunEnabled"
--	====================

		ChargedShotAdvanceEnabled = false;
		AdvancedChargingTime = 5; --Known as Level3ChargingTime
		Level1ChargingTime = 1;
		Level2ChargingTime = 2;
		ChargingSoundIncreasePitch = true;
		ChargingSoundPitchRange = {1, 1.5};

		ChargingAnimationEnabled = false; --You need an animation ID in order to enable it
		ChargingAnimationID = nil; --Set to "nil" if you don't want to animate
		ChargingAnimationSpeed = 1;

		AimChargingAnimationID = nil; --Set to "nil" if you don't want to animate
		AimChargingAnimationSpeed = 1;

		ChargeAlterTable = {
		};

--	====================
--	END OF SETTING
--	====================
}

return Module