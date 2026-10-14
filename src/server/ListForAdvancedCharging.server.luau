--[[
	
	This is the list of stats that are available in "ChargeAlterTable"
	To nullify an effect, leave "ChargeAlterTable" blank
		
		ChargeAlterTable = {

			--BASIC

			FireRate = {
				Level1 = NUMBER;
				Level2 = NUMBER;
				Level3 = NUMBER;
			};

			BaseDamage = {
				Level1 = INTEGER;
				Level2 = INTEGER;
				Level3 = INTEGER;
			};

			Spread = {
				Level1 = NUMBER;
				Level2 = NUMBER;
				Level3 = NUMBER;
			};

			Range = {
				Level1 = INTEGER;
				Level2 = INTEGER;
				Level3 = INTEGER;
			};

			HeadshotDamageMultiplier = {
				Level1 = NUMBER;
				Level2 = NUMBER;
				Level3 = NUMBER;
			};

			--DAMAGE DROPOFF

			ZeroDamageDistance = {
				Level1 = INTEGER;
				Level2 = INTEGER;
				Level3 = INTEGER;
			};

			FullDamageDistance = {
				Level1 = INTEGER;
				Level2 = INTEGER;
				Level3 = INTEGER;
			};

			--CRITICAL DAMAGE

	        CriticalBaseChance = {
				Level1 = NUMBER;
				Level2 = NUMBER;
				Level3 = NUMBER;
			};

	        CriticalDamageMultiplier = {
				Level1 = NUMBER;
				Level2 = NUMBER;
				Level3 = NUMBER;			
			};

			--BULLET HOLE VISUALIZER

			BulletHoleSize = {
				Level1 = NUMBER;
				Level2 = NUMBER;
				Level3 = NUMBER;			
			};	

			BulletHoleTexture = {
				Level1 = TABLE;
				Level2 = TABLE;
				Level3 = TABLE;			
			};

			PartColor = {
				Level1 = BOOLEAN;
				Level2 = BOOLEAN;
				Level3 = BOOLEAN;			
			};

			--	HIT VISUALIZER

			HitSoundIDs = {
				Level1 = TABLE;
				Level2 = TABLE;
				Level3 = TABLE;			
			};	

			HitSoundPitchMin = {
				Level1 = NUMBER;
				Level2 = NUMBER;
				Level3 = NUMBER;			
			};

			HitSoundPitchMax = {
				Level1 = NUMBER;
				Level2 = NUMBER;
				Level3 = NUMBER;			
			};

			HitSoundVolume = {
				Level1 = NUMBER;
				Level2 = NUMBER;
				Level3 = NUMBER;			
			};

			CustomHitEffect = {
				Level1 = BOOLEAN;
				Level2 = BOOLEAN;
				Level3 = BOOLEAN;			
			};

			--BLOOD VISUALIZER

			HitCharSndIDs = {
				Level1 = TABLE;
				Level2 = TABLE;
				Level3 = TABLE;			
			};

			HitCharSndPitchMin = {
				Level1 = NUMBER;
				Level2 = NUMBER;
				Level3 = NUMBER;			
			};

			HitCharSndPitchMax = {
				Level1 = NUMBER;
				Level2 = NUMBER;
				Level3 = NUMBER;			
			};

			HitCharSndVolume = {
				Level1 = NUMBER;
				Level2 = NUMBER;
				Level3 = NUMBER;			
			};

			BloodWoundSize = {
				Level1 = NUMBER;
				Level2 = NUMBER;
				Level3 = NUMBER;			
			};	

			BloodWoundTexture = {
				Level1 = TABLE;
				Level2 = TABLE;
				Level3 = TABLE;			
			};

			BloodWoundTextureColor = {
				Level1 = COLOR3;
				Level2 = COLOR3;
				Level3 = COLOR3;			
			};

			BloodWoundPartColor = {
				Level1 = BOOLEAN;
				Level2 = BOOLEAN;
				Level3 = BOOLEAN;			
			};
		
			--CROSSHAIR
			
			CrossExpansion = {
				Level1 = INTEGER;
				Level2 = INTEGER;
				Level3 = INTEGER;	
			};

			--MUZZLE

			LightBrightness = {
				Level1 = INTEGER;
				Level2 = INTEGER;
				Level3 = INTEGER;	
			};

			LightColor = {
				Level1 = COLOR3;
				Level2 = COLOR3;
				Level3 = COLOR3;	
			};

			LightRange = {
				Level1 = INTEGER;
				Level2 = INTEGER;
				Level3 = INTEGER;	
			};

			--SHOTGUN

			BulletPerShot = {
				Level1 = INTEGER;
				Level2 = INTEGER;
				Level3 = INTEGER;			
			};			

			--BURST FIRE

			BulletPerBurst = {
				Level1 = INTEGER;
				Level2 = INTEGER;
				Level3 = INTEGER;			
			};

			BurstRate = {
				Level1 = NUMBER;
				Level2 = NUMBER;
				Level3 = NUMBER;			
			};

			--CAMERA RECOILING
				
			Recoil = {
				Level1 = INTEGER;
				Level2 = INTEGER;
				Level3 = INTEGER;			
			};
		
			--EXPLOSIVE
		
			ExplosiveEnabled = {
				Level1 = BOOLEAN;
				Level2 = BOOLEAN;
				Level3 = BOOLEAN;	
			};
		
			ExplosionRadius = {
				Level1 = INTEGER;
				Level2 = INTEGER;
				Level3 = INTEGER;	
			};
		
			ExplosionKnockbackPower = {
				Level1 = NUMBER;
				Level2 = NUMBER;
				Level3 = NUMBER;			
			};
		
			ExplosionKnockbackMultiplierOnPlayer = {
				Level1 = NUMBER;
				Level2 = NUMBER;
				Level3 = NUMBER;	
			};
		
			ExplosionKnockbackMultiplierOnTarget = {
				Level1 = NUMBER;
				Level2 = NUMBER;
				Level3 = NUMBER;	
			};

			ExplosionSoundIDs = {
				Level1 = TABLE;
				Level2 = TABLE;
				Level3 = TABLE;	
			};

			ExplosionSoundVolume = {
				Level1 = NUMBER;
				Level2 = NUMBER;
				Level3 = NUMBER;	
			};

			ExplosionSoundPitchMin = {
				Level1 = NUMBER;
				Level2 = NUMBER;
				Level3 = NUMBER;	
			};

			ExplosionSoundPitchMax = {
				Level1 = NUMBER;
				Level2 = NUMBER;
				Level3 = NUMBER;	
			};

			ExplosionCraterSize = {
				Level1 = NUMBER;
				Level2 = NUMBER;
				Level3 = NUMBER;	
			};

			ExplosionCraterTexture = {
				Level1 = TABLE;
				Level2 = TABLE;
				Level3 = TABLE;	
			};

			ExplosionCraterPartColor = {
				Level1 = BOOLEAN;
				Level2 = BOOLEAN;
				Level3 = BOOLEAN;	
			};
		
			--PROJECTILE VISUALIZER
		
			BulletSpeed = {
				Level1 = INTEGER;
				Level2 = INTEGER;
				Level3 = INTEGER;	
			};
		
			BulletAcceleration = {
				Level1 = VECTOR3;
				Level2 = VECTOR3;
				Level3 = VECTOR3;	
			};

			BulletColor = {
				Level1 = COLOR3;
				Level2 = COLOR3;
				Level3 = COLOR3;	
			};

			BulletTexture = {
				Level1 = ID;
				Level2 = ID;
				Level3 = ID;	
			};

			BulletSize = {
				Level1 = NUMBER;
				Level2 = NUMBER;
				Level3 = NUMBER;	
			};

			BulletBloom = {
				Level1 = NUMBER;
				Level2 = NUMBER;
				Level3 = NUMBER;	
			};

			BulletBrightness = {
				Level1 = INTEGER;
				Level2 = INTEGER;
				Level3 = INTEGER;	
			};

			BulletLifetime = {
				Level1 = NUMBER;
				Level2 = NUMBER;
				Level3 = NUMBER;	
			};

			WindSpeed = {
				Level1 = INTEGER;
				Level2 = INTEGER;
				Level3 = INTEGER;	
			};

			WindResistance = { --In percent (1 = 100%)
				Level1 = NUMBER;
				Level2 = NUMBER;
				Level3 = NUMBER;	
			};

			VisibleBullet = {
				Level1 = BOOLEAN;
				Level2 = BOOLEAN;
				Level3 = BOOLEAN;	
			};

			BulletType = {
				Level1 = STRING;
				Level2 = STRING;
				Level3 = STRING;	
			};
		
			SpinX = {
				Level1 = NUMBER;
				Level2 = NUMBER;
				Level3 = NUMBER;	
			};
			
			SpinY = {
				Level1 = NUMBER;
				Level2 = NUMBER;
				Level3 = NUMBER;	
			};
			
			SpinZ = {
				Level1 = NUMBER;
				Level2 = NUMBER;
				Level3 = NUMBER;	
			};
		
			--MISCELLANEOUS
		
			Knockback = {
				Level1 = NUMBER;
				Level2 = NUMBER;
				Level3 = NUMBER;	
			};
		
			Lifesteal = {
				Level1 = INTEGER;
				Level2 = INTEGER;
				Level3 = INTEGER;	
			};
		
			IgniteChance = {
				Level1 = NUMBER;
				Level2 = NUMBER;
				Level3 = NUMBER;	
			};
		
			IcifyChance = {
				Level1 = NUMBER;
				Level2 = NUMBER;
				Level3 = NUMBER;	
			};
		
			PenetrationDepth = {
				Level1 = NUMBER;
				Level2 = NUMBER;
				Level3 = NUMBER;	
			};
			
			PenetrationAmount = {
				Level1 = INTEGER;
				Level2 = INTEGER;
				Level3 = INTEGER;	
			};

			RicochetAmount = {
				Level1 = INTEGER;
				Level2 = INTEGER;
				Level3 = INTEGER;	
			};

			BounceElasticity = { --In percent (1 = 100%)
				Level1 = NUMBER;
				Level2 = NUMBER;
				Level3 = NUMBER;	
			};

			FrictionConstant = { --In percent (1 = 100%)
				Level1 = NUMBER;
				Level2 = NUMBER;
				Level3 = NUMBER;	
			};

			NoExplosionWhileBouncing = {
				Level1 = BOOLEAN;
				Level2 = BOOLEAN;
				Level3 = BOOLEAN;	
			};

			StopBouncingOnHitHumanoid = {
				Level1 = BOOLEAN;
				Level2 = BOOLEAN;
				Level3 = BOOLEAN;	
			};

			SuperRicochet = {
				Level1 = BOOLEAN;
				Level2 = BOOLEAN;
				Level3 = BOOLEAN;	
			};
		
			SelfKnockbackPower = {
				Level1 = NUMBER;
				Level2 = NUMBER;
				Level3 = NUMBER;	
			};
			
			SelfKnockbackMultiplier = {
				Level1 = NUMBER;
				Level2 = NUMBER;
				Level3 = NUMBER;	
			};
			
			SelfKnockbackRedution = { --In percent (1 = 100%)
				Level1 = NUMBER;
				Level2 = NUMBER;
				Level3 = NUMBER;	
			};
		
		};

--]]