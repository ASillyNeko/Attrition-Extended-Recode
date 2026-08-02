untyped

global function AttritionExtendedRecode_Init
global function AttritionExtendedRecode_SpawnPilotWithTitan
global function AttritionExtendedRecode_SpawnTitan
global function AttritionExtendedRecode_SpawnedPilotedTitans
global function AttritionExtendedRecode_SpawnedUnPilotedTitans
global function Is_AttritionExtendedRecode_Entity
global function AttritionExtendedRecode_AddCustomTitan

global struct AttritionExtendedRecode_CustomTitanStruct
{
	string Title = "Pilot"
	string TitanSetFile = ""
	int Camo = -1
	int Skin = -1
	bool AllowedWithPilot = true
	bool AllowedWithoutPilot = true
	int HP = -1
	void functionref( entity ) BeforeSpawn = null
	void functionref( entity ) AfterSpawn = null
	void functionref( entity ) DisembarkTitan = null
	void functionref( entity ) EmbarkTitan = null
	int UID = -1
}

struct
{
	table<entity, bool> autoEject

	table<entity, array<string> > weapons
	table<entity, string> grenade

	table<entity, int> smokeCount

	table<entity, bool> titanIsStanding
	table<entity, bool> titanIsBeingEmbarked

	table<int, array<entity> > spawnedPilotedTitans
	table<int, array<entity> > spawnedUnpilotedTitans

	table<entity, bool> isAttritionExtendedRecodeEntity

	array<AttritionExtendedRecode_CustomTitanStruct> CustomTitans
	table<entity, int> CustomTitanUID

	array<string> pilotWeapons = [
		"mp_weapon_rspn101_og",
		"mp_weapon_r97",
		"mp_weapon_car",
		"mp_weapon_vinson",
		"mp_weapon_epg",
		"mp_weapon_smr",
		"mp_weapon_lmg",
		"mp_weapon_rspn101",
		"mp_weapon_car",
		"mp_weapon_hemlok",
		"mp_weapon_lstar",
		"mp_weapon_hemlok_smg"
	]

	array<string> pilotAntiTitanWeapons = [ "mp_weapon_rocket_launcher", "mp_weapon_defender" ]

	array<asset> pilotModels = [
		$"models/humans/pilots/pilot_medium_geist_m.mdl",
		$"models/humans/pilots/pilot_medium_geist_f.mdl",
		$"models/humans/pilots/pilot_medium_stalker_m.mdl",
		$"models/humans/pilots/pilot_medium_stalker_f.mdl",
		$"models/humans/pilots/pilot_medium_reaper_m.mdl",
		$"models/humans/pilots/pilot_medium_reaper_f.mdl"
	]

	array<string> pilotGrenades = [
		"mp_weapon_frag_grenade",
		"mp_weapon_grenade_electric_smoke",
		"mp_weapon_thermite_grenade",
		"mp_weapon_grenade_emp",
		"mp_weapon_grenade_gravity"
	]
} file

void function AttritionExtendedRecode_Init()
{
	AddDamageByCallback( "npc_titan", PilotTitanExecution )
	AddDamageByCallback( "npc_pilot_elite", PilotExecution )
	AddDamageCallback( "npc_titan", NPCNoPain )
	AddDamageCallback( "npc_pilot_elite", NPCNoPain )
	AddDamageCallbackSourceID( eDamageSourceId.auto_titan_melee, ApplyNormalMeleeIdToNPCTitan )
	AddDamageCallback( "npc_pilot_elite", PilotDamageAdjustments )
	AddDamageCallback( "npc_titan", PilotTitanAutoOrDeathEjectHandle )
	AddCallback_OnTitanDoomed( EjectWhenDoomed )

	if ( GAMETYPE == "aitdm" )
	{
		GM_AddPlayingThinkFunc(
			void function() : ()
			{
				thread DefconHandle()
			}
		)

		AITdm_SetDefcon_1( GetCurrentPlaylistVarInt( "defcon_1_score", 125 ) )
		AITdm_SetDefcon_2( GetCurrentPlaylistVarInt( "defcon_2_score", 250 ) )
		AITdm_SetDefcon_3( GetCurrentPlaylistVarInt( "defcon_3_score", 330 ) )
		AITdm_SetDefcon_4( GetCurrentPlaylistVarInt( "defcon_4_score", 500 ) )
		AITdm_SetDefcon_5( GetCurrentPlaylistVarInt( "defcon_5_score", 575 ) )
		AddCallback_GameStateEnter( eGameState.Playing, OnPlaying )
		AddDeathCallback( "npc_pilot_elite", AddEnemyTeamScore )
		AddDeathCallback( "npc_titan", AddEnemyTeamScore )
	}
}

void function DefconHandle()
{
	foreach ( int team in [ TEAM_IMC, TEAM_MILITIA ] )
	{
		string defcon = team == TEAM_MILITIA ? "IMCdefcon" : "MILdefcon"
		int currentDefCon = GetGlobalNetInt( defcon )

		team = GetOtherTeam( team )

		switch ( currentDefCon )
		{
			case 0:
				level.spectreSpawnChance[ team ] = GetCurrentPlaylistVarInt( "defcon_0_spectre_spawn_chance", 0 )
				level.stalkerSpawnChance[ team ] = GetCurrentPlaylistVarInt( "defcon_0_stalker_spawn_chance", 0 )
				level.reaperSpawnChance[ team ] = GetCurrentPlaylistVarInt( "defcon_0_reaper_spawn_chance", 0 )
				level.maxSpectrePerSide[ team ] = GetCurrentPlaylistVarInt( "defcon_0_spectres", 0 )
				level.maxStalkersPerSide[ team ] = GetCurrentPlaylistVarInt( "defcon_0_stalkers", 0 )
				level.maxReapersPerSide[ team ] = GetCurrentPlaylistVarInt( "defcon_0_reapers", 0 )
				level.modifyAISlots[ team ] = GetCurrentPlaylistVarInt( "defcon_0_additional_ai_slots", 0 )
				break

			case 1:
				level.spectreSpawnChance[ team ] = GetCurrentPlaylistVarInt( "defcon_1_spectre_spawn_chance", 10 )
				level.stalkerSpawnChance[ team ] = GetCurrentPlaylistVarInt( "defcon_1_stalker_spawn_chance", 0 )
				level.reaperSpawnChance[ team ] = GetCurrentPlaylistVarInt( "defcon_1_reaper_spawn_chance", 0 )
				level.maxSpectrePerSide[ team ] = GetCurrentPlaylistVarInt( "defcon_1_spectres", 8 )
				level.maxStalkersPerSide[ team ] = GetCurrentPlaylistVarInt( "defcon_1_stalkers", 0 )
				level.maxReapersPerSide[ team ] = GetCurrentPlaylistVarInt( "defcon_1_reapers", 0 )
				level.modifyAISlots[ team ] = GetCurrentPlaylistVarInt( "defcon_1_additional_ai_slots", 0 )
				break

			case 2:
				level.spectreSpawnChance[ team ] = GetCurrentPlaylistVarInt( "defcon_2_spectre_spawn_chance", 20 )
				level.stalkerSpawnChance[ team ] = GetCurrentPlaylistVarInt( "defcon_2_stalker_spawn_chance", 0 )
				level.reaperSpawnChance[ team ] = GetCurrentPlaylistVarInt( "defcon_2_reaper_spawn_chance", 0 )
				level.maxSpectrePerSide[ team ] = GetCurrentPlaylistVarInt( "defcon_2_spectres", 12 )
				level.maxStalkersPerSide[ team ] = GetCurrentPlaylistVarInt( "defcon_2_stalkers", 0 )
				level.maxReapersPerSide[ team ] = GetCurrentPlaylistVarInt( "defcon_2_reapers", 0 )
				level.modifyAISlots[ team ] = GetCurrentPlaylistVarInt( "defcon_2_additional_ai_slots", 0 )
				break

			case 3:
				level.spectreSpawnChance[ team ] = GetCurrentPlaylistVarInt( "defcon_3_spectre_spawn_chance", 20 )
				level.stalkerSpawnChance[ team ] = GetCurrentPlaylistVarInt( "defcon_3_stalker_spawn_chance", 10 )
				level.reaperSpawnChance[ team ] = GetCurrentPlaylistVarInt( "defcon_3_reaper_spawn_chance", 0 )
				level.maxSpectrePerSide[ team ] = GetCurrentPlaylistVarInt( "defcon_3_spectres", 12 )
				level.maxStalkersPerSide[ team ] = GetCurrentPlaylistVarInt( "defcon_3_stalkers", 8 )
				level.maxReapersPerSide[ team ] = GetCurrentPlaylistVarInt( "defcon_3_reapers", 0 )
				level.modifyAISlots[ team ] = GetCurrentPlaylistVarInt( "defcon_3_additional_ai_slots", 0 )
				break

			case 4:
				level.spectreSpawnChance[ team ] = GetCurrentPlaylistVarInt( "defcon_4_spectre_spawn_chance", 15 )
				level.stalkerSpawnChance[ team ] = GetCurrentPlaylistVarInt( "defcon_4_stalker_spawn_chance", 10 )
				level.reaperSpawnChance[ team ] = GetCurrentPlaylistVarInt( "defcon_4_reaper_spawn_chance", 100 )
				level.maxSpectrePerSide[ team ] = GetCurrentPlaylistVarInt( "defcon_4_spectres", 12 )
				level.maxStalkersPerSide[ team ] = GetCurrentPlaylistVarInt( "defcon_4_stalkers", 4 )
				level.maxReapersPerSide[ team ] = GetCurrentPlaylistVarInt( "defcon_4_reapers", 2 )
				level.modifyAISlots[ team ] = GetCurrentPlaylistVarInt( "defcon_4_additional_ai_slots", 2 )
				break

			case 5:
				level.spectreSpawnChance[ team ] = GetCurrentPlaylistVarInt( "defcon_5_spectre_spawn_chance", 15 )
				level.stalkerSpawnChance[ team ] = GetCurrentPlaylistVarInt( "defcon_5_stalker_spawn_chance", 10 )
				level.reaperSpawnChance[ team ] = GetCurrentPlaylistVarInt( "defcon_5_reaper_spawn_chance", 100 )
				level.maxSpectrePerSide[ team ] = GetCurrentPlaylistVarInt( "defcon_5_spectres", 12 )
				level.maxStalkersPerSide[ team ] = GetCurrentPlaylistVarInt( "defcon_5_stalkers", 4 )
				level.maxReapersPerSide[ team ] = GetCurrentPlaylistVarInt( "defcon_5_reapers", 3 )
				level.modifyAISlots[ team ] = GetCurrentPlaylistVarInt( "defcon_5_additional_ai_slots", 3 )
				break
		}
	}
}

void function OnPlaying()
{
	thread Spawner( TEAM_IMC )
	thread Spawner( TEAM_MILITIA )
}

void function Spawner( int team )
{
	while ( IsAutoPopulateEnabled( team ) )
	{
		int pilotedTitansToSpawn = 0
		int unpilotedTitansToSpawn = 0
		int currentPilotedTitanScore = GameRules_GetTeamScore( GetOtherTeam( team ) )
		int currentUnpilotedTitanScore = GameRules_GetTeamScore( GetOtherTeam( team ) )

		while (
			currentPilotedTitanScore >= GetCurrentPlaylistVarInt( "titan_spawn_score", 650 ) &&
			pilotedTitansToSpawn < GetCurrentPlaylistVarInt( "piloted_titan_count", 3 )
		)
		{
			currentPilotedTitanScore -= GetCurrentPlaylistVarInt( "piloted_titan_ramp_up_score", 150 )
			pilotedTitansToSpawn++
		}

		while (
			currentUnpilotedTitanScore >= GetCurrentPlaylistVarInt( "titan_spawn_score", 650 ) &&
			unpilotedTitansToSpawn < GetCurrentPlaylistVarInt( "unpiloted_titan_count", 0 )
		)
		{
			currentUnpilotedTitanScore -= GetCurrentPlaylistVarInt( "unpiloted_titan_ramp_up_score", 150 )
			unpilotedTitansToSpawn++
		}

		if ( AttritionExtendedRecode_SpawnedPilotedTitans( team ) < pilotedTitansToSpawn )
		{
			AttritionExtendedRecode_SpawnPilotWithTitan( team )

			wait RandomFloatRange( 2.5, 3 )

			if ( Flag( "LevelHasRoof" ) )
				wait WARPFALL_SOUND_DELAY + 2.5 + WARPFALL_FX_DELAY
		}

		if ( AttritionExtendedRecode_SpawnedUnPilotedTitans( team ) < unpilotedTitansToSpawn )
		{
			AttritionExtendedRecode_SpawnTitan( team )

			wait RandomFloatRange( 2.5, 3 )

			if ( Flag( "LevelHasRoof" ) )
				wait WARPFALL_SOUND_DELAY + 2.5 + WARPFALL_FX_DELAY
		}

		WaitFrame()
	}
}

void function AddEnemyTeamScore( entity guy, var damageInfo )
{
	entity attacker = DamageInfo_GetAttacker( damageInfo )

	if ( guy == attacker || !( attacker.IsPlayer() || attacker.IsTitan() ) || GetGameState() != eGameState.Playing )
		return

	if ( attacker.IsNPC() && attacker.IsTitan() && !IsValid( GetPetTitanOwner( attacker ) ) )
		return

	if ( !Is_AttritionExtendedRecode_Entity( guy ) )
		return

	if ( !guy.IsTitan() || ( guy.IsTitan() && TitanHasNpcPilot( guy ) ) )
	{
		AddTeamScore( attacker.GetTeam(), 5 )

		if ( attacker.IsPlayer() )
		{
			attacker.AddToPlayerGameStat( PGS_NPC_KILLS, 1 )
			attacker.AddToPlayerGameStat( PGS_ASSAULT_SCORE, 5 )

			AddPlayerScore( attacker, "KillGrunt" )

			int assaultscore = attacker.GetPlayerGameStat( PGS_ASSAULT_SCORE )
			int assaultscore256 = assaultscore / 256

			attacker.SetPlayerNetInt( "AT_bonusPoints", assaultscore - assaultscore256 * 256 )
			attacker.SetPlayerNetInt( "AT_bonusPoints256", assaultscore256 )
		}
	}
}

int function AttritionExtendedRecode_SpawnedPilotedTitans( int team )
{
	if ( team in file.spawnedPilotedTitans )
	{
		ArrayRemoveDead( file.spawnedPilotedTitans[ team ] )

		return file.spawnedPilotedTitans[ team ].len()
	}

	return 0
}

int function AttritionExtendedRecode_SpawnedUnPilotedTitans( int team )
{
	if ( team in file.spawnedUnpilotedTitans )
	{
		ArrayRemoveDead( file.spawnedUnpilotedTitans[ team ] )

		return file.spawnedUnpilotedTitans[ team ].len()
	}

	return 0
}

bool function Is_AttritionExtendedRecode_Entity( entity guy )
{
	if ( guy in file.isAttritionExtendedRecodeEntity && file.isAttritionExtendedRecodeEntity[ guy ] )
		return true

	return false
}

void function AttritionExtendedRecode_AddCustomTitan( AttritionExtendedRecode_CustomTitanStruct CustomTitan )
{
	CustomTitan.UID = file.CustomTitans.len()

	file.CustomTitans.append( CustomTitan )
}

AttritionExtendedRecode_CustomTitanStruct function AttritionExtendedRecode_CustomTitanEmpty()
{
	AttritionExtendedRecode_CustomTitanStruct CustomTitan

	CustomTitan.AllowedWithPilot = false
	CustomTitan.AllowedWithoutPilot = false

	return CustomTitan
}

// so it always a function for us
#if !NPC_TITAN_PILOT_PROTOTYPE
	bool function TitanHasNpcPilot( entity titan )
	{
		Assert( titan.IsTitan() )

		entity titanSoul = titan.GetTitanSoul()
		if ( !IsValid( titanSoul ) )
			return false

		if ( !titanSoul.soul.seatedNpcPilot.isValid )
			return false

		return true
	}
#endif

void function PilotTitanExecution( entity ent, var damageInfo )
{
	int damageType = DamageInfo_GetCustomDamageType( damageInfo )
	entity attacker = DamageInfo_GetAttacker( damageInfo )

	if ( !IsAlive( ent ) || !IsValid( attacker ) || ent.GetTeam() == attacker.GetTeam() || attacker == ent || !ent.IsTitan() || ent.IsInvulnerable() )
		return

	entity soul = ent.GetTitanSoul()

	if (
		attacker.IsNPC() && attacker.IsTitan() && IsValid( soul ) && damageType & DF_MELEE && TitanHasNpcPilot( attacker ) &&
		Is_AttritionExtendedRecode_Entity( attacker ) && CodeCallback_IsValidMeleeExecutionTarget( attacker, ent ) &&
		!SoulHasPassive( soul, ePassives.PAS_AUTO_EJECT ) && !ent.IsPhaseShifted() && CanSurviveDamage( ent, damageInfo )
	)
	{
		PilotTitanExecution_DamageEnemy( ent, damageInfo )
		DamageInfo_SetDamage( damageInfo, 0 )
		thread PlayerTriesSyncedMelee( attacker, ent )
	}
}

void function PilotTitanExecution_DamageEnemy( entity ent, var damageInfo )
{
	entity soul = ent.GetTitanSoul()

	if ( !IsValid( soul ) || Time() - ent.GetTitanSoul().soul.doomedStartTime < TITAN_DOOMED_INVUL_TIME )
		return

	int damage = int( DamageInfo_GetDamage( damageInfo ) )
	int shieldhealth = soul.GetShieldHealth()
	int titanhealth = ent.GetHealth()
	int shieldhealthdamaged = shieldhealth - damage
	int shieldhealthdamagedunchanged = shieldhealthdamaged

	if ( shieldhealthdamaged < 0 )
		shieldhealthdamaged = 0

	soul.SetShieldHealth( shieldhealthdamaged )

	int newdamage = damage - shieldhealthdamagedunchanged

	if ( newdamage < 0 )
		newdamage = 0

	if ( newdamage > damage )
		newdamage = damage

	int titanhealthdamaged = titanhealth - newdamage

	if ( titanhealthdamaged <= 0 )
		titanhealthdamaged = 1

	ent.SetHealth( titanhealthdamaged )
}

void function PilotExecution( entity ent, var damageInfo )
{
	int damageType = DamageInfo_GetCustomDamageType( damageInfo )
	entity attacker = DamageInfo_GetAttacker( damageInfo )

	if ( !IsAlive( ent ) || !attacker || ent.GetTeam() == attacker.GetTeam() || attacker == ent || ent.IsTitan() || ent.IsInvulnerable() )
		return

	if (
		attacker.IsNPC() && Is_AttritionExtendedRecode_Entity( attacker ) && damageType & DF_MELEE && CodeCallback_IsValidMeleeExecutionTarget( attacker, ent ) &&
		!ent.Anim_IsActive() && !( ( ent.IsPlayer() && PlayerCanSee( ent, attacker, true, 75 ) ) || ( ent.IsNPC() && ent.CanSee( attacker ) ) )
	)
	{
		DamageInfo_SetDamage( damageInfo, 0 )
		thread PlayerTriesSyncedMelee( attacker, ent )
	}
}

void function NPCNoPain( entity npc, var damageInfo )
{
	if ( Is_AttritionExtendedRecode_Entity( npc ) && ( npc.GetNPCFlag( NPC_NO_PAIN ) || !npc.GetNPCFlag( NPC_PAIN_IN_SCRIPTED_ANIM ) ) )
	{
		if ( !npc.IsTitan() )
			DamageInfo_AddDamageFlags( damageInfo, DAMAGEFLAG_NOPAIN )
		else if ( npc.IsTitan() && TitanHasNpcPilot( npc ) )
			DamageInfo_AddDamageFlags( damageInfo, DAMAGEFLAG_NOPAIN )
	}
}

void function ApplyNormalMeleeIdToNPCTitan( entity victim, var damageInfo )
{
	entity attacker = DamageInfo_GetAttacker( damageInfo )
	int damageSourceID = DamageInfo_GetDamageSourceIdentifier( damageInfo )

	if ( !IsValid( attacker ) || !attacker.IsNPC() || !attacker.IsTitan() || !Is_AttritionExtendedRecode_Entity( attacker ) )
		return

	if ( TitanHasNpcPilot( attacker ) )
	{
		if ( GetTitanCharacterName( attacker ) == "ronin" )
		{
			entity meleeWeapon = attacker.GetMeleeWeapon()

			if ( IsValid( meleeWeapon ) && meleeWeapon.HasMod( "super_charged" ) )
				DamageInfo_SetDamageSourceIdentifier( damageInfo, eDamageSourceId.mp_titancore_shift_core )
			else
				DamageInfo_SetDamageSourceIdentifier( damageInfo, eDamageSourceId.melee_titan_sword )
		}
		else
			DamageInfo_SetDamageSourceIdentifier( damageInfo, eDamageSourceId.melee_titan_punch )
	}
}

void function PilotDamageAdjustments( entity pilot, var damageInfo )
{
	if ( IsInstantDeath( damageInfo ) || DamageInfo_GetForceKill( damageInfo ) )
		return

	if ( pilot == DamageInfo_GetAttacker( damageInfo ) )
		DamageInfo_SetDamage( damageInfo, 0 )
}

void function PilotTitanAutoOrDeathEjectHandle( entity titan, var damageInfo )
{
	if ( IsInstantDeath( damageInfo ) || DamageInfo_GetForceKill( damageInfo ) )
		return

	if ( !Is_AttritionExtendedRecode_Entity( titan ) || titan.ContextAction_IsBusy() )
		return

	entity soul = titan.GetTitanSoul()

	if (
		!IsValid( soul ) || soul.IsEjecting() ||
		!( titan in TitanHasNpcPilot( titan ) && titan in file.autoEject && file.autoEject[ titan ] && GetDoomedState( titan ) )
	)
		return

	thread TitanEjectPlayerForNPCs( titan, true )
}

void function EjectWhenDoomed( entity titan, var damageInfo )
{
	if ( !IsNewThread() )
	{
		thread EjectWhenDoomed( titan, damageInfo )
		return
	}

	if ( !Is_AttritionExtendedRecode_Entity( titan ) || !titan.IsTitan() )
		return

	bool shouldEjectTitan = false

	titan.EndSignal( "OnDestroy" )
	titan.EndSignal( "OnDeath" )

	if ( !HasSoul( titan ) )
		return

	entity soul = titan.GetTitanSoul()

	if ( !IsValid( soul ) )
		return

	soul.EndSignal( "OnDestroy" )
	soul.EndSignal( "OnDeath" )

	bool autoEject = ( titan in file.autoEject && file.autoEject[ titan ] )

	if ( !autoEject )
		wait 2.25
	else
		WaitFrame()

	while ( soul.IsDoomed() && !soul.IsEjecting() )
	{
		if ( !autoEject )
			wait 0.2
		else
			WaitFrame()

		float ejectRequiredDoomedHealth = 1250
		int health = titan.GetHealth()
		int shieldHealth = soul.GetShieldHealth()
		int maxHealth = titan.GetMaxHealth()
		int ShieldHealth = health + shieldHealth
		entity enemy = titan.GetEnemy()

		if ( ShieldHealth <= ejectRequiredDoomedHealth )
			shouldEjectTitan = true

		if ( IsAlive( enemy ) && enemy.IsTitan() )
		{
			bool horizontallyClose = Distance2D( titan.GetOrigin(), enemy.GetOrigin() ) < 630
			bool enemyIsEjecting = HasSoul( enemy ) && enemy.GetTitanSoul().IsEjecting()

			if ( !enemyIsEjecting && horizontallyClose && !enemy.ContextAction_IsMeleeExecution() )
				shouldEjectTitan = true
		}

		if ( TitanHasNpcPilot( titan ) && ( ( shouldEjectTitan && !titan.IsInvulnerable() ) || autoEject ) )
			thread TitanEjectPlayerForNPCs( titan, autoEject )
	}
}

int function GetTitanValidHealthFromDamageInfo( entity titan, var damageInfo )
{
	if ( DamageInfo_GetForceKill( damageInfo ) )
		return 0

	entity soul = titan.GetTitanSoul()
	int healthShield = titan.GetHealth()

	if ( GetDoomedState( titan ) && IsValid( soul ) && Time() - soul.soul.doomedStartTime < TITAN_DOOMED_INVUL_TIME )
		return 999999

	if ( IsValid( soul ) )
		healthShield += soul.GetShieldHealth()

	if ( IsValid( soul ) && !GetDoomedState( titan ) && !soul.soul.skipDoomState )
		healthShield += 2500

	return healthShield
}

bool function CanSurviveDamage( entity titan, var damageInfo )
{
	int damage = int( DamageInfo_GetDamage( damageInfo ) )
	int validHealth = GetTitanValidHealthFromDamageInfo( titan, damageInfo )

	return damage < validHealth
}

entity function AttritionExtendedRecode_NpcTitanBecomesPilot( entity titan )
{
	if ( !IsValid( titan ) || !titan.IsTitan() )
		return null

	entity titanSoul = titan.GetTitanSoul()

	if ( !IsValid( titanSoul ) )
		return null

	titanSoul.soul.seatedNpcPilot.isValid = false

	array<string> weapons = []
	asset model = titanSoul.soul.seatedNpcPilot.modelAsset
	string grenade = ""

	if ( titan in file.weapons )
		weapons = file.weapons[ titan ]

	if ( titan in file.grenade )
		grenade = file.grenade[ titan ]

	int team = titan.GetTeam()
	vector origin = titan.GetOrigin()
	float angles = titan.GetAngles().z

	entity pilot = CreateEntity( "npc_pilot_elite" )

	pilot.SetOrigin( origin )

	SetTeam( pilot, team )

	DispatchSpawn( pilot )

	file.isAttritionExtendedRecodeEntity[ pilot ] <- true

	if ( titan in file.CustomTitanUID && file.CustomTitanUID[ titan ] >= 0 )
		pilot.SetTitle( titan.GetTitle() )
	else
		pilot.SetTitle( "Pilot" )

	titan.SetTitle( pilot.GetTitle() + "'s Auto-Titan" )

	thread PilotMiniMap( pilot )
	thread PilotSpeedFlagsHPAndBehavior( pilot )

	pilot.kv.WeaponProficiency = titan.kv.WeaponProficiency
	pilot.kv.AccuracyMultiplier = titan.kv.AccuracyMultiplier
	titan.kv.WeaponProficiency = eWeaponProficiency.AVERAGE
	titan.kv.AccuracyMultiplier = 1.0

	if ( file.pilotModels.contains( model ) )
		pilot.SetModel( model )
	else
		pilot.SetModel( file.pilotModels.getrandom() )

	TakeWeaponsForArray( pilot, pilot.GetMainWeapons() )

	bool gaveweapon = false

	foreach ( string newweapons in weapons )
	{
		pilot.GiveWeapon( newweapons )
		gaveweapon = true
	}

	if ( !gaveweapon )
		RandomPilotWeapons( pilot )

	if ( grenade != "" )
		pilot.kv.grenadeWeaponName = grenade
	else
		pilot.kv.grenadeWeaponName = file.pilotGrenades.getrandom()

	titan.SetOwner( pilot )

	NPCFollowsNPCModded( titan, pilot )
	thread PilotNotInTitanSet( titan )
	UpdateEnemyMemoryFromTeammates( pilot )

	return pilot
}

void function OnFlagChanged( entity npc, array<int> flags, bool disable = false, bool istitan = false, bool isvalidpilot = false )
{
	npc.EndSignal( "OnDestroy" )
	npc.EndSignal( "OnDeath" )

	while ( true )
	{
		if ( istitan )
		{
			entity soul = npc.GetTitanSoul()

			if ( IsValid( soul ) )
			{
				if ( isvalidpilot )
				{
					if ( !( TitanHasNpcPilot( npc ) ) )
						return
				}
				else
				{
					if ( TitanHasNpcPilot( npc ) )
						return
				}
			}
		}

		foreach ( int flag in flags )
			if ( !disable && !npc.GetNPCFlag( flag ) )
				npc.EnableNPCFlag( flag )
			else if ( disable && npc.GetNPCFlag( flag ) )
				npc.DisableNPCFlag( flag )

		WaitFrame()
	}
}

void function PilotSpeedFlagsHPAndBehavior( entity npc )
{
	npc.SetNPCMoveSpeedScale( 1.25 )
	npc.EnableNPCMoveFlag( NPCMF_PREFER_SPRINT )

	thread OnFlagChanged( npc, [ NPC_NO_PAIN, NPC_NO_GESTURE_PAIN, NPC_ALLOW_PATROL, NPC_ALLOW_INVESTIGATE, NPC_IGNORE_FRIENDLY_SOUND ] )
	thread OnFlagChanged( npc, [ NPC_PAIN_IN_SCRIPTED_ANIM, NPC_ALLOW_FLEE ], true )

	npc.SetMaxHealth( 250 ) // 500
	npc.SetHealth( npc.GetMaxHealth() )
	npc.SetBehaviorSelector( "behavior_sp_soldier" )
	npc.SetEnemyChangeCallback( OnNPCPilotEnemyChange )

	Highlight_SetEnemyHighlight( npc, "enemy_player" )
}

void function PilotMiniMap( entity npc )
{
	thread DestroyPilotMiniMapOnPilotDeath( npc, CreatePilotMinimap( npc ) )
}

entity function CreatePilotMinimap( entity npc )
{
	entity pilotMiniMap = CreateEntity( "npc_spectre" )

	DispatchSpawn( pilotMiniMap )

	file.isAttritionExtendedRecodeEntity[ pilotMiniMap ] <- true

	TakeWeaponsForArray( pilotMiniMap, pilotMiniMap.GetMainWeapons() )

	pilotMiniMap.kv.VisibilityFlags = ENTITY_VISIBLE_TO_NOBODY
	pilotMiniMap.Hide()

	HideName( pilotMiniMap )

	pilotMiniMap.SetParent( npc, "HEADFOCUS" )
	pilotMiniMap.NotSolid()
	pilotMiniMap.kv.CollisionGroup = 0
	pilotMiniMap.SetInvulnerable()

	SetTeam( pilotMiniMap, npc.GetTeam() )
	NPC_NoTarget( pilotMiniMap )

	pilotMiniMap.EnableNPCFlag( NPC_IGNORE_ALL )
	pilotMiniMap.StopPhysics()
	pilotMiniMap.Freeze()
	pilotMiniMap.SetModel( $"models/dev/empty_model.mdl" )

	pilotMiniMap.Minimap_AlwaysShow( TEAM_MILITIA, null )
	pilotMiniMap.Minimap_AlwaysShow( TEAM_IMC, null )

	return pilotMiniMap
}

void function DestroyPilotMiniMapOnPilotDeath( entity npc, entity pilotMiniMap )
{
	npc.EndSignal( "OnDestroy" )
	npc.EndSignal( "OnDeath" )

	OnThreadEnd(
		function() : ( pilotMiniMap )
		{
			if ( IsValid( pilotMiniMap ) )
				pilotMiniMap.Destroy()
		}
	)

	while ( true )
	{
		if ( IsValid( pilotMiniMap ) )
		{
			if ( npc.GetTeam() != pilotMiniMap.GetTeam() )
				SetTeam( pilotMiniMap, npc.GetTeam() )
		}
		else
			pilotMiniMap = CreatePilotMinimap( npc )

		WaitFrame()
	}
}

void function RandomPilotWeapons( entity pilot )
{
	TakeWeaponsForArray( pilot, pilot.GetMainWeapons() )

	pilot.GiveWeapon( file.pilotWeapons.getrandom() )
	pilot.GiveWeapon( file.pilotAntiTitanWeapons.getrandom() )
}

void function OnNPCPilotEnemyChange( entity guy )
{
	if ( !IsAlive( guy ) )
		return

	if ( guy.IsFrozen() )
		return

	entity enemy = guy.GetEnemy()

	if ( !IsAlive( enemy ) )
		return

	array<entity> weapons = guy.GetMainWeapons()

	if ( weapons.len() < 2 )
		return

	entity activeWeapon = guy.GetActiveWeapon()

	if ( !IsValid( activeWeapon ) )
		return

	string activeWeaponName = activeWeapon.GetWeaponClassName()
	bool antiTitanActive = activeWeapon != weapons[ 0 ] && !activeWeapon.GetWeaponSettingBool( eWeaponVar.titanarmor_critical_hit_required )
	bool isHeavyArmorTarget = enemy.GetArmorType() == ARMOR_TYPE_HEAVY
	string weaponToChange = ""

	if ( isHeavyArmorTarget )
	{
		if ( antiTitanActive )
			return

		foreach ( entity weapon in weapons )
		{
			string className = weapon.GetWeaponClassName()

			if ( activeWeaponName == className )
				continue

			bool isMainWeapon = weapon == weapons[ 0 ]
			bool isAntiTitan = !weapon.GetWeaponSettingBool( eWeaponVar.titanarmor_critical_hit_required )

			if ( isAntiTitan && !isMainWeapon )
			{
				weaponToChange = className
				break
			}
		}
	}
	else if ( antiTitanActive )
	{
		foreach ( entity weapon in weapons )
		{
			string className = weapon.GetWeaponClassName()

			if ( activeWeaponName == className )
				continue

			bool isMainWeapon = weapon == weapons[ 0 ]
			bool isAntiTitan = !weapon.GetWeaponSettingBool( eWeaponVar.titanarmor_critical_hit_required )

			if ( isMainWeapon || !isAntiTitan )
			{
				weaponToChange = className
				break
			}
		}
	}

	if ( weaponToChange == "" )
		return

	guy.SetActiveWeaponByName( weaponToChange )
}

void function MonitorMonarchShield( entity npc )
{
	entity soul = npc.GetTitanSoul()

	if ( !IsValid( soul ) )
		return

	if ( !TitanHasNpcPilot( npc ) )
		return

	npc.EndSignal( "OnDestroy" )
	npc.EndSignal( "OnDeath" )

	soul.EndSignal( "OnDestroy" )
	soul.EndSignal( "OnDeath" )

	while ( true )
	{
		WaitFrame()

		if ( !TitanHasNpcPilot( npc ) )
			return

		WaitTillTitanCoreCharge( npc )

		if ( !TitanHasNpcPilot( npc ) )
			return

		if ( soul.GetTitanSoulNetInt( "upgradeCount" ) > 2 && soul.GetShieldHealth() > soul.GetShieldHealthMax() * 0.1 )
		{
			thread MonitorMonarchShield( npc )
			return
		}

		if ( npc.ContextAction_IsBusy() || npc.ContextAction_IsMeleeExecution() )
		{
			thread MonitorMonarchShield( npc )
			return
		}

		SoulTitanCore_SetNextAvailableTime( soul, 0.0 )

		entity coreEffect = CreateCoreEffect( npc, $"P_titan_core_atlas_blast" )

		EmitSoundOnEntity( npc, "Titan_Monarch_Smart_Core_Activated_3P" )

		soul.SetShieldHealth( soul.GetShieldHealthMax() )

		entity shake = CreateShake( npc.GetOrigin(), 16.0, 5.0, 2.5, 1500.0 )

		shake.SetParent( npc, "CHESTFOCUS" )

		entity weapon = npc.GetOffhandWeapon( OFFHAND_EQUIPMENT )

		if ( IsValid( weapon ) )
		{
			thread MonarchUpgrade( weapon )

			wait weapon.GetCoreDuration()
		}
		else
			wait 2.5

		shake.Destroy()
		coreEffect.Destroy()
	}
}

void function MonitorTitanCore( entity npc )
{
	entity soul = npc.GetTitanSoul()

	if ( !IsValid( soul ) )
		return

	npc.EndSignal( "OnDestroy" )
	npc.EndSignal( "OnDeath" )

	soul.EndSignal( "OnDestroy" )
	soul.EndSignal( "OnDeath" )

	while ( true )
	{
		SoulTitanCore_SetNextAvailableTime( soul, 0.6 )

		npc.WaitSignal( "CoreBegin" )
		npc.WaitSignal( "CoreEnd" )
	}
}

void function WaitTillTitanCoreCharge( entity titan )
{
	titan.EndSignal( "OnDestroy" )
	titan.EndSignal( "OnDeath" )

	entity soul = titan.GetTitanSoul()

	if ( !IsValid( soul ) )
		return

	soul.EndSignal( "OnDestroy" )
	soul.EndSignal( "OnDeath" )

	while ( TitanCoreInUse( titan ) || SoulTitanCore_GetNextAvailableTime( soul ) != 1.0 )
		WaitFrame()
}

void function MonarchUpgrades( entity titan )
{
	entity soul = titan.GetTitanSoul()

	if ( !IsValid( soul ) )
		return

	GivePassive( soul, ePassives.PAS_VANGUARD_CORE1 )

	if ( RandomInt( 100 ) < 50 )
		GivePassive( soul, ePassives.PAS_VANGUARD_CORE7 )

	if ( !SoulHasPassive( soul, ePassives.PAS_VANGUARD_CORE7 ) )
		GivePassive( soul, ePassives.PAS_VANGUARD_CORE9 )

	GivePassive( soul, ePassives.PAS_VANGUARD_CORE8 )
}

void function MonarchUpgrade( entity weapon )
{
	entity owner = weapon.GetWeaponOwner()
	entity soul = owner.GetTitanSoul()
	int currentUpgradeCount = soul.GetTitanSoulNetInt( "upgradeCount" )

	if ( !currentUpgradeCount )
	{
		if ( SoulHasPassive( soul, ePassives.PAS_VANGUARD_CORE1 ) )
		{
			array<entity> weapons = GetPrimaryWeapons( owner )

			if ( weapons.len() )
			{
				entity primaryWeapon = weapons[ 0 ]

				if ( IsValid( primaryWeapon ) )
				{
					array<string> mods = primaryWeapon.GetMods()

					mods.append( "arc_rounds" )

					primaryWeapon.SetMods( mods )
					primaryWeapon.SetWeaponPrimaryClipCount( primaryWeapon.GetWeaponPrimaryClipCount() + 10 )
				}
			}
		}
	}
	else if ( currentUpgradeCount == 1 )
	{
		if ( SoulHasPassive( soul, ePassives.PAS_VANGUARD_CORE7 ) )
		{
			entity ordnance = owner.GetOffhandWeapon( OFFHAND_RIGHT )

			owner.TakeWeaponNow( ordnance.GetWeaponClassName() )
			owner.GiveOffhandWeapon( "mp_titanweapon_shoulder_rockets", OFFHAND_RIGHT )
		}
		else if ( SoulHasPassive( soul, ePassives.PAS_VANGUARD_CORE9 ) )
		{
			array<entity> weapons = GetPrimaryWeapons( owner )

			if ( weapons.len() )
			{
				entity primaryWeapon = weapons[ 0 ]

				if ( IsValid( primaryWeapon ) )
				{
					if ( primaryWeapon.HasMod( "arc_rounds" ) )
					{
						primaryWeapon.RemoveMod( "arc_rounds" )

						array<string> mods = primaryWeapon.GetMods()

						mods.append( "arc_rounds_with_battle_rifle" )

						primaryWeapon.SetMods( mods )
					}
					else
					{
						array<string> mods = primaryWeapon.GetMods()

						mods.append( "battle_rifle" )
						mods.append( "battle_rifle_icon" )

						primaryWeapon.SetMods( mods )
					}
				}
			}
		}
	}
	else if ( currentUpgradeCount == 2 )
	{
		if ( SoulHasPassive( soul, ePassives.PAS_VANGUARD_CORE8 ) )
		{
			if ( !GetDoomedState( owner ) )
			{
				owner.SetMaxHealth( min( MAX_HEALTH - 1, owner.GetMaxHealth() + VANGUARD_CORE8_HEALTH_AMOUNT ) )
				owner.SetHealth( min( owner.GetMaxHealth(), owner.GetHealth() + VANGUARD_CORE8_HEALTH_AMOUNT ) )
			}

			soul.SetPreventCrits( true )
		}
	}

	soul.SetTitanSoulNetInt( "upgradeCount", currentUpgradeCount + 1 )
}

void function PilotInTitanSet( entity titan )
{
	if ( IsValid( titan ) )
	{
		thread GiveTitanSmokeEverySixtySeconds( titan )
		thread EmbarkedNPCTitanRodeoCounter( titan )

		if ( titan in file.CustomTitanUID && file.CustomTitanUID[ titan ] >= 0 && file.CustomTitans.len() >= file.CustomTitanUID[ titan ] )
		{
			AttritionExtendedRecode_CustomTitanStruct CustomTitan = clone file.CustomTitans[ file.CustomTitanUID[ titan ] ]

			if ( CustomTitan.EmbarkTitan != null )
				CustomTitan.EmbarkTitan( titan )
		}
		else
		{
			switch ( GetTitanCharacterName( titan ) )
			{
				case "ion":
					titan.SetAISettings( "npc_titan_atlas_stickybomb" )
					titan.SetBehaviorSelector( "behavior_titan_long_range" )
					break

				case "scorch":
					titan.SetAISettings( "npc_titan_ogre_meteor" )
					titan.SetBehaviorSelector( "behavior_titan_ogre_meteor" )
					break

				case "northstar":
					titan.SetAISettings( "npc_titan_stryder_sniper" )
					titan.SetBehaviorSelector( "behavior_titan_sniper" )
					break

				case "ronin":
					titan.SetAISettings( "npc_titan_stryder_leadwall" )
					titan.SetBehaviorSelector( "behavior_titan_shotgun" )
					break

				case "tone":
					titan.SetAISettings( "npc_titan_atlas_tracker" )
					titan.SetBehaviorSelector( "behavior_titan_long_range" )
					break

				case "legion":
					titan.SetAISettings( "npc_titan_ogre_minigun" )
					titan.SetBehaviorSelector( "behavior_titan_ogre_minigun" )
					titan.SetNPCMoveSpeedScale( 1.25 )
					break

				case "vanguard":
					titan.SetAISettings( "npc_titan_atlas_vanguard" )
					titan.SetBehaviorSelector( "behavior_titan_long_range" )

					thread MonitorMonarchShield( titan )
					break
			}
		}

		titan.SetCapabilityFlag( bits_CAP_SYNCED_MELEE_ATTACK, false )
		titan.EnableNPCMoveFlag( NPCMF_PREFER_SPRINT )

		thread OnFlagChanged( titan, [ NPC_NO_PAIN, NPC_NO_GESTURE_PAIN, NPC_ALLOW_PATROL, NPC_ALLOW_INVESTIGATE, NPC_IGNORE_FRIENDLY_SOUND ], false, true, true )
		thread OnFlagChanged( titan, [ NPC_PAIN_IN_SCRIPTED_ANIM, NPC_ALLOW_FLEE ], true, true, true )
	}
}

void function PilotNotInTitanSet( entity titan, bool firstTime = false )
{
	if ( IsValid( titan ) )
	{
		if ( !firstTime )
		{
			if ( titan in file.CustomTitanUID && file.CustomTitanUID[ titan ] >= 0 && file.CustomTitans.len() >= file.CustomTitanUID[ titan ] )
			{
				AttritionExtendedRecode_CustomTitanStruct CustomTitan = clone file.CustomTitans[ file.CustomTitanUID[ titan ] ]

				if ( CustomTitan.DisembarkTitan != null )
					CustomTitan.DisembarkTitan( titan )
			}
			else
			{
				switch ( GetTitanCharacterName( titan ) )
				{
					case "ion":
						titan.SetAISettings( "npc_titan_auto_atlas_stickybomb" )
						break

					case "scorch":
						titan.SetAISettings( "npc_titan_auto_ogre_meteor" )
						break

					case "northstar":
						titan.SetAISettings( "npc_titan_auto_stryder_sniper" )
						break

					case "ronin":
						titan.SetAISettings( "npc_titan_auto_stryder_leadwall" )
						break

					case "tone":
						titan.SetAISettings( "npc_titan_auto_atlas_tracker" )
						break

					case "legion":
						titan.SetAISettings( "npc_titan_auto_ogre_minigun" )
						titan.SetNPCMoveSpeedScale( 1.0 )
						break

					case "vanguard":
						titan.SetAISettings( "npc_titan_auto_atlas_vanguard" )
						break
				}
			}
		}

		titan.DisableNPCMoveFlag( NPCMF_PREFER_SPRINT )
		titan.DisableNPCFlag( NPC_NO_PAIN | NPC_NO_GESTURE_PAIN | NPC_ALLOW_PATROL | NPC_ALLOW_INVESTIGATE | NPC_IGNORE_FRIENDLY_SOUND )
		titan.EnableNPCFlag( NPC_PAIN_IN_SCRIPTED_ANIM | NPC_ALLOW_FLEE )
	}
}

void function NPCFollowsNPCModded( entity npc, entity leader )
{
	thread NPCFollowsNPCModded_thread( npc, leader )
}

void function NPCFollowsNPCModded_thread( entity npc, entity leader )
{
	leader.EndSignal( "OnDeath" )
	leader.EndSignal( "OnDestroy" )

	npc.EndSignal( "OnDeath" )
	npc.EndSignal( "OnDestroy" )

	OnThreadEnd(
		function() : ( npc )
		{
			if ( IsValid( npc ) && IsAlive( npc ) )
				npc.DisableBehavior( "Follow" )
		}
	)

	npc.Signal( "StopHardpointBehavior" )

	int followBehavior = GetDefaultNPCFollowBehavior( npc )

	npc.InitFollowBehavior( leader, followBehavior )
	npc.EnableBehavior( "Follow" )

	WaitForever()
}

void function EmbarkedNPCTitanRodeoCounter( entity titan )
{
	thread EmbarkedNPCTitanRodeoCounter_Threaded( titan )
}

void function EmbarkedNPCTitanRodeoCounter_Threaded( entity titan )
{
	entity soul = titan.GetTitanSoul()

	if ( !IsValid( soul ) )
		return

	titan.EndSignal( "OnDeath" )
	titan.EndSignal( "OnDestroy" )

	soul.EndSignal( "OnDestroy" )

	float beingRodeoedTime = -1
	float lastTickRodeoHitTime = 0
	bool hasusedsmoke = false

	while ( true )
	{
		WaitFrame()

		if ( !TitanHasNpcPilot( titan ) )
			return

		entity rodeoPilot = GetRodeoPilot( titan )
		float rodeoHitTime = soul.GetLastRodeoHitTime()

		if ( rodeoHitTime && !lastTickRodeoHitTime )
		{
			beingRodeoedTime = rodeoHitTime
		}
		else if ( !rodeoHitTime )
		{
			beingRodeoedTime = -1
			hasusedsmoke = false
		}

		lastTickRodeoHitTime = rodeoHitTime

		if ( titan.Anim_IsActive() || IsValid( titan.GetParent() ) )
			continue

		if ( IsAlive( rodeoPilot ) && beingRodeoedTime != -1 )
		{
			if ( !hasusedsmoke )
			{
				if ( rodeoPilot.GetTeam() == titan.GetTeam() )
					continue

				if ( rodeoPilot.IsPlayer() )
				{
					if ( !PlayerHasPassive( rodeoPilot, ePassives.PAS_STEALTH_MOVEMENT ) )
						wait 1
				}

				int smokeCount = 1
				bool shoulddosmoke = true

				if ( titan in file.smokeCount )
					smokeCount = file.smokeCount[ titan ]

				if ( !smokeCount )
				{
					smokeCount = 1
					shoulddosmoke = false
				}

				file.smokeCount[ titan ] <- smokeCount - 1

				if ( shoulddosmoke )
				{
					hasusedsmoke = true

					TitanSmokescreen( titan )
				}
			}
		}
	}
}

void function GiveTitanSmokeEverySixtySeconds( entity npc )
{
	npc.EndSignal( "OnDestroy" )
	npc.EndSignal( "OnDeath" )

	while ( true )
	{
		int smokeCount = 0

		while ( npc in file.smokeCount && file.smokeCount[ npc ] == 6 )
			WaitFrame()

		if ( npc in file.smokeCount )
			smokeCount = file.smokeCount[ npc ]

		file.smokeCount[ npc ] <- smokeCount + 1

		wait 60.0
	}
}

void function TitanSmokescreen( entity ent )
{
	SmokescreenStruct smokescreen

	smokescreen.isElectric = true
	smokescreen.ownerTeam = ent.GetTeam()
	smokescreen.attacker = ent
	smokescreen.inflictor = ent
	smokescreen.damageInnerRadius = 320.0
	smokescreen.damageOuterRadius = 375.0
	smokescreen.dangerousAreaRadius = 1.0
	smokescreen.dpsPilot = 45
	smokescreen.dpsTitan = 450
	smokescreen.damageDelay = 1.0
	smokescreen.blockLOS = false

	vector eyeAngles = < 0.0, ent.EyeAngles().y, 0.0 >
	smokescreen.angles = eyeAngles

	vector forward = AnglesToForward( eyeAngles )
	vector testPos = ent.GetOrigin() + forward * 240.0
	vector basePos = testPos

	float trace = TraceLineSimple( ent.EyePosition(), testPos, ent )

	if ( trace != 1.0 )
		basePos = ent.GetOrigin()

	float fxOffset = 200.0
	float fxHeightOffset = 148.0

	smokescreen.origin = basePos

	smokescreen.fxOffsets =
		[ < -fxOffset, 0.0, 20.0 >, < 0.0, fxOffset, 20.0 >, < 0.0, -fxOffset, 20.0 >, < 0.0, 0.0, fxHeightOffset >, < -fxOffset, 0.0, fxHeightOffset > ]

	Smokescreen( smokescreen )
}

void function AttritionExtendedRecode_SpawnPilotWithTitan( int team )
{
	if ( !IsNewThread() )
	{
		thread AttritionExtendedRecode_SpawnPilotWithTitan( team )
		return
	}

	entity spawnpoint = GetSpawnpoint( team )

	if ( !IsValid( spawnpoint ) )
		return

	spawnpoint.e.spawnTime = Time()

	ToggleSpawnNodeInUse( spawnpoint, true )

	vector pos = spawnpoint.GetOrigin()
	vector angles = spawnpoint.GetAngles()
	entity pod = CreateDropPod( pos, angles )
	entity poddoor = DropPodDoor( pod )

	AttritionExtendedRecode_CustomTitanStruct CustomTitan = AttritionExtendedRecode_CustomTitanEmpty()

	if ( RandomInt( 100 ) < int( GetCurrentPlaylistVarFloat( "ct_titan_replace_chance", 0.2 ) * 100 ) && file.CustomTitans.len() )
		CustomTitan = clone file.CustomTitans.getrandom()

	entity pilot = CreateEntity( "npc_pilot_elite" )

	pilot.SetOrigin( pos )

	DispatchSpawn( pilot )

	file.isAttritionExtendedRecodeEntity[ pilot ] <- true

	SetTeam( pilot, team )
	RandomPilotWeapons( pilot )

	pilot.kv.grenadeWeaponName = file.pilotGrenades.getrandom()
	pilot.kv.AccuracyMultiplier = 1.0 // 2.5
	pilot.kv.WeaponProficiency = eWeaponProficiency.GOOD // eWeaponProficiency.VERYGOOD

	PilotSpeedFlagsHPAndBehavior( pilot )

	pilot.SetModel( file.pilotModels.getrandom() )
	pilot.SetParent( pod, "ATTACH", false )
	pilot.kv.VisibilityFlags = ~ENTITY_VISIBLE_TO_EVERYONE
	pilot.SetInvulnerable()
	pilot.kv.contents = ( int( pilot.kv.contents ) | CONTENTS_NOGRAPPLE )
	pilot.EnableNPCFlag( NPC_IGNORE_ALL )
	pilot.Freeze()

	NPC_NoTarget( pilot )

	if ( CustomTitan.AllowedWithPilot )
		pilot.SetTitle( "[CT] " + CustomTitan.Title )
	else
		pilot.SetTitle( "Pilot" )

	thread AttritionExtendedRecode_NpcPilotCallsInAndEmbarksTitan( pilot, pos, angles, CustomTitan )
	waitthread LaunchAnimDropPod( pod, "pod_testpath", pos, angles )

	if ( IsValid( pilot ) )
	{
		pilot.kv.VisibilityFlags = ENTITY_VISIBLE_TO_EVERYONE
		pilot.Unfreeze()
		pilot.SetOrigin( pod.GetOrigin() )
		pilot.SetAngles( pod.GetAngles() )

		thread PilotMiniMap( pilot )
	}

	DropPodOpenDoorModded( pod, poddoor )
	ActivateFireteamDropPodModded( pod, pilot, poddoor )

	if ( IsValid( spawnpoint ) )
		ToggleSpawnNodeInUse( spawnpoint, false )
}

void function AttritionExtendedRecode_SpawnTitan( int team, bool withpilot = false )
{
	if ( !IsNewThread() )
	{
		thread AttritionExtendedRecode_SpawnTitan( team, withpilot )
		return
	}

	entity spawnpoint = GetSpawnpoint( team )

	if ( !IsValid( spawnpoint ) )
		return

	spawnpoint.e.spawnTime = Time()

	ToggleSpawnNodeInUse( spawnpoint, true )

	vector origin = spawnpoint.GetOrigin()
	vector angles = spawnpoint.GetAngles()

	entity pilot = CreateEntity( "npc_pilot_elite" )

	pilot.SetOrigin( origin )

	DispatchSpawn( pilot )

	file.isAttritionExtendedRecodeEntity[ pilot ] <- true

	pilot.SetInvulnerable()

	RandomPilotWeapons( pilot )

	pilot.kv.grenadeWeaponName = file.pilotGrenades.getrandom()
	pilot.kv.AccuracyMultiplier = 1.0 // 2.5
	pilot.kv.WeaponProficiency = eWeaponProficiency.GOOD // eWeaponProficiency.VERYGOOD
	pilot.SetModel( file.pilotModels.getrandom() )
	pilot.EnableNPCFlag( NPC_IGNORE_ALL )
	pilot.kv.VisibilityFlags = ~ENTITY_VISIBLE_TO_EVERYONE

	array<string> settingsArray = GetAllowedTitanAISettings()
	bool usedomeshieldwarpfall = false

	settingsArray.extend(
		[
			"npc_titan_auto_atlas_ion_prime",
			"npc_titan_auto_ogre_scorch_prime",
			"npc_titan_auto_stryder_northstar_prime",
			"npc_titan_auto_stryder_ronin_prime",
			"npc_titan_auto_atlas_tone_prime",
			"npc_titan_auto_ogre_legion_prime"
		]
	)

	string titanSettings = settingsArray.getrandom()

	if ( Flag( "LevelHasRoof" ) )
	{
		usedomeshieldwarpfall = true

		NPCPrespawnWarpfallSequenceModded( titanSettings, origin, angles )
	}

	string setFile = GetRandomTitanSetFile( titanSettings )
	entity titan

	AttritionExtendedRecode_CustomTitanStruct CustomTitan = AttritionExtendedRecode_CustomTitanEmpty()

	if ( RandomInt( 100 ) < int( GetCurrentPlaylistVarFloat( "ct_titan_replace_chance", 0.2 ) * 100 ) && file.CustomTitans.len() )
		CustomTitan = clone file.CustomTitans.getrandom()

	if ( ( !withpilot && CustomTitan.AllowedWithoutPilot ) || ( withpilot && CustomTitan.AllowedWithPilot ) )
	{
		titan = CreateNPCTitan( CustomTitan.TitanSetFile, team, origin, angles )
	}
	else
	{
		titan = CreateNPCTitan( setFile, team, origin, angles )

		SetSpawnOption_AISettings( titan, titanSettings )
	}

	if ( CustomTitan.BeforeSpawn != null )
		CustomTitan.BeforeSpawn( titan )

	DispatchSpawn( titan )

	file.isAttritionExtendedRecodeEntity[ titan ] <- true

	if ( withpilot )
		AttritionExtendedRecode_NpcPilotBecomesTitan( pilot, titan )
	else
		pilot.Destroy()

	titan.Minimap_AlwaysShow( TEAM_MILITIA, null )
	titan.Minimap_AlwaysShow( TEAM_IMC, null )

	if ( ( !withpilot && CustomTitan.AllowedWithoutPilot ) || ( withpilot && CustomTitan.AllowedWithPilot ) )
	{
		titan.SetTitle( "[CT] " + CustomTitan.Title )

		file.CustomTitanUID[ titan ] <- CustomTitan.UID

		if ( CustomTitan.HP > 0 )
		{
			titan.SetMaxHealth( min( MAX_HEALTH - 1, CustomTitan.HP ) )
			titan.SetHealth( titan.GetMaxHealth() )
		}
	}

	if (
		( CustomTitan.Camo != -1 && CustomTitan.Skin != -1 ) && ( ( !withpilot && CustomTitan.AllowedWithoutPilot ) || ( withpilot && CustomTitan.AllowedWithPilot ) )
	)
	{
		titan.SetSkin( CustomTitan.Skin )
		titan.SetCamo( CustomTitan.Camo )
	}
	else
	{
		int randomtitancamo = RandomIntRange( 0, 160 )

		titan.SetSkin( 2 )
		titan.SetCamo( randomtitancamo )
	}

	thread AutoTitanLoadout( titan, CustomTitan )
	thread MonitorTitanCore( titan )

	if ( withpilot )
	{
		if ( !( team in file.spawnedPilotedTitans ) )
			file.spawnedPilotedTitans[ team ] <- []

		file.spawnedPilotedTitans[ team ].append( titan )
	}
	else
	{
		if ( !( team in file.spawnedUnpilotedTitans ) )
			file.spawnedUnpilotedTitans[ team ] <- []

		file.spawnedUnpilotedTitans[ team ].append( titan )
	}

	SetStanceKneel( titan.GetTitanSoul() )
	UpdateEnemyMemoryFromTeammates( titan )

	if ( CustomTitan.AfterSpawn != null )
		CustomTitan.AfterSpawn( titan )

	if ( !usedomeshieldwarpfall )
		NPCTitanHotdrops( titan, true )
	else
		NPCTitanHotdrops( titan, true, "at_hotdrop_drop_2knee_turbo_upgraded" )

	if ( IsValid( spawnpoint ) )
		ToggleSpawnNodeInUse( spawnpoint, false )
}

entity function GetSpawnpoint( int team )
{
	array<entity> spawnPoints = SpawnPoints_GetTitan()

	return GetFrontlineSpawnPoint( spawnPoints, team )
}

void function DropPodOpenDoorModded( entity pod, entity door )
{
	door.ClearParent()
	door.SetVelocity( door.GetForwardVector() * 500 )

	EmitSoundOnEntity( pod, "droppod_door_open" )
}

void function DestroyPod( entity pod, entity door )
{
	pod.Dissolve( ENTITY_DISSOLVE_CORE, Vector( 0, 0, 0 ), 500 )
	door.Dissolve( ENTITY_DISSOLVE_CORE, Vector( 0, 0, 0 ), 500 )
}

entity function DropPodDoor( entity pod )
{
	string attachment = "hatch"
	int attachIndex = pod.LookupAttachment( attachment )
	vector origin = pod.GetAttachmentOrigin( attachIndex )
	vector angles = pod.GetAttachmentAngles( attachIndex )

	entity prop_physics = CreateEntity( "prop_physics" )

	SetTargetName( prop_physics, "door" + UniqueString() )

	prop_physics.SetValueForModelKey( $"models/vehicle/droppod_fireteam/droppod_fireteam_door.mdl" )

	prop_physics.kv.spawnflags = 261
	prop_physics.kv.fadedist = -1
	prop_physics.kv.physdamagescale = 0.1
	prop_physics.kv.inertiaScale = 1.0
	prop_physics.kv.renderamt = 0
	prop_physics.kv.rendercolor = "255 255 255"

	prop_physics.SetOrigin( origin )
	prop_physics.SetAngles( angles )
	prop_physics.SetParent( pod, "HATCH", false )
	prop_physics.MarkAsNonMovingAttachment()

	return prop_physics
}

void function ActivateFireteamDropPodModded( entity pod, entity pilot, entity poddoor )
{
	array<string> exitAnims = [ "pt_dp_exit_a", "pt_dp_exit_b", "pt_dp_exit_c", "pt_dp_exit_d" ]
	array<string> idleAnims = [ "pt_dp_idle_a", "pt_dp_idle_b", "pt_dp_idle_c", "pt_dp_idle_d" ]

	int animIndex = RandomIntRange( 0, exitAnims.len() - 1 )

	SetAnim( pilot, "drop_pod_exit_anim", exitAnims[ animIndex ] )
	SetAnim( pilot, "drop_pod_idle_anim", idleAnims[ animIndex ] )

	if ( IsAlive( pilot ) )
	{
		pilot.MakeVisible()

		entity weapon = pilot.GetActiveWeapon()

		if ( IsValid( weapon ) )
			weapon.MakeVisible()

		thread GuyHangsInPod( pilot, pod, poddoor )
	}
	else
		thread DestroyPod( pod, poddoor )
}

void function GuyHangsInPod( entity guy, entity pod, entity poddoor )
{
	guy.EndSignal( "OnDeath" )
	guy.EndSignal( "OnDestroy" )

	OnThreadEnd(
		function() : ( pod, poddoor )
		{
			thread DestroyPod( pod, poddoor )
		}
	)

	string exitAnim = expect string( GetAnim( guy, "drop_pod_exit_anim" ) )
	bool exitAnimExists = guy.LookupSequence( exitAnim ) != -1

	guy.SetParent( pod, "ATTACH", false )

	if ( exitAnimExists )
		guy.Anim_ScriptedPlay( exitAnim )

	guy.ClearParent()

	if ( exitAnimExists )
		WaittillAnimDone( guy )

	guy.Signal( "npc_deployed" )
}

void function NPCTitanHotdropsWarpfall( entity titan, bool standImmediately, string titanfallAnim = "at_hotdrop_drop_2knee_turbo_upgraded" )
{
	titan.EndSignal( "OnDeath" )
	titan.EndSignal( "OnDestroy" )

	titan.e.isHotDropping = true
	titan.s.bubbleShieldStatus <- 0

	titan.SetEfficientMode( true )
	titan.SetTouchTriggers( false )
	titan.SetAimAssistAllowed( false )

	float impactTime = GetHotDropImpactTime( titan, titanfallAnim )
	vector origin = titan.GetOrigin()
	vector angles = titan.GetAngles()

	#if GRUNTCHATTER_ENABLED
		GruntChatter_TryIncomingSpawn( titan, origin )
	#endif

	TryAnnounceTitanfallWarningToEnemyTeam( titan.GetTeam(), origin )
	waitthread PlayersTitanHotdrops( titan, origin, angles, null, titanfallAnim )

	if ( standImmediately )
	{
		SetStanceStand( titan.GetTitanSoul() )
		waitthread PlayAnimGravity( titan, "at_hotdrop_quickstand" )
	}

	titan.SetEfficientMode( false )
	titan.SetTouchTriggers( true )
	titan.SetAimAssistAllowed( true )

	titan.e.isHotDropping = false

	titan.Signal( "TitanHotDropComplete" )
	titan.SetNoTarget( false )

	while ( titan.s.bubbleShieldStatus == 1 )
		titan.WaitSignal( "BubbleShieldStatusUpdate" )
}

void function NPCPrespawnWarpfallSequenceModded( string aiSettings, vector spawnOrigin, vector spawnAngle )
{
	string animation = "at_hotdrop_drop_2knee_turbo_upgraded"
	string playerSettings = expect string( Dev_GetAISettingByKeyField_Global( aiSettings, "npc_titan_player_settings" ) )
	asset model = GetPlayerSettingsAssetForClassName( playerSettings, "bodymodel" )
	Attachment warpAttach = GetAttachmentAtTimeFromModel( model, animation, "offset", spawnOrigin, spawnAngle, 0 )

	entity fakeTitan = CreatePropDynamic( model )
	float impactTime = GetHotDropImpactTime( fakeTitan, animation )

	fakeTitan.Kill_Deprecated_UseDestroyInstead()

	EmitSoundAtPosition( TEAM_UNASSIGNED, spawnOrigin, "Titan_3P_Warpfall_CallIn" )

	wait WARPFALL_SOUND_DELAY + 2.5

	EmitSoundAtPosition( TEAM_UNASSIGNED, spawnOrigin, "Titan_3P_Warpfall_Start" )

	PlayFX( TURBO_WARP_FX, warpAttach.position + Vector( 0, 0, -104 ), warpAttach.angle )

	wait WARPFALL_FX_DELAY
}

entity function AttritionExtendedRecode_NpcPilotCallsInTitan( entity pilot, vector origin, vector angles, AttritionExtendedRecode_CustomTitanStruct CustomTitan )
{
	if ( !IsAlive( pilot ) || pilot.IsTitan() )
		return null

	array<string> settingsArray = GetAllowedTitanAISettings()
	bool usedomeshieldwarpfall = false

	settingsArray.extend(
		[
			"npc_titan_auto_atlas_ion_prime",
			"npc_titan_auto_ogre_scorch_prime",
			"npc_titan_auto_stryder_northstar_prime",
			"npc_titan_auto_stryder_ronin_prime",
			"npc_titan_auto_atlas_tone_prime",
			"npc_titan_auto_ogre_legion_prime"
		]
	)

	string titanSettings = settingsArray.getrandom()
	int team = pilot.GetTeam()
	string pilottitle = pilot.GetTitle()

	if ( Flag( "LevelHasRoof" ) )
	{
		usedomeshieldwarpfall = true

		NPCPrespawnWarpfallSequenceModded( titanSettings, origin, angles )
	}

	string setFile = GetRandomTitanSetFile( titanSettings )
	entity titan

	if ( !CustomTitan.AllowedWithPilot )
	{
		titan = CreateNPCTitan( setFile, team, origin, angles )

		SetSpawnOption_AISettings( titan, titanSettings )
	}
	else
		titan = CreateNPCTitan( CustomTitan.TitanSetFile, team, origin, angles )

	if ( CustomTitan.BeforeSpawn != null )
		CustomTitan.BeforeSpawn( titan )

	DispatchSpawn( titan )

	if ( CustomTitan.AllowedWithPilot )
	{
		file.CustomTitanUID[ titan ] <- CustomTitan.UID

		if ( CustomTitan.HP > 0 )
		{
			titan.SetMaxHealth( min( MAX_HEALTH - 1, CustomTitan.HP ) )
			titan.SetHealth( titan.GetMaxHealth() )
		}
	}

	if ( IsValid( pilot ) && IsAlive( pilot ) )
		titan.SetTitle( pilot.GetTitle() + "'s Auto-Titan" )
	else
		titan.SetTitle( pilottitle + "'s Auto-Titan" )

	file.isAttritionExtendedRecodeEntity[ titan ] <- true

	titan.Minimap_AlwaysShow( TEAM_MILITIA, null )
	titan.Minimap_AlwaysShow( TEAM_IMC, null )

	if ( !usedomeshieldwarpfall )
		thread NPCTitanHotdrops( titan, false )
	else
		thread NPCTitanHotdrops( titan, false, "at_hotdrop_drop_2knee_turbo_upgraded" )

	if ( ( CustomTitan.Camo == -1 && CustomTitan.Skin == -1 ) || !CustomTitan.AllowedWithPilot )
	{
		int randomtitancamo = RandomIntRange( 0, 160 )

		titan.SetSkin( 2 )
		titan.SetCamo( randomtitancamo )
	}
	else
	{
		titan.SetSkin( CustomTitan.Skin )
		titan.SetCamo( CustomTitan.Camo )
	}

	PilotNotInTitanSet( titan, true )
	thread AutoTitanLoadout( titan, CustomTitan )
	thread MonitorTitanCore( titan )
	thread TitanStandAfterDropIn( titan, pilot )
	SetStanceKneel( titan.GetTitanSoul() )
	UpdateEnemyMemoryFromTeammates( titan )
	NPCFollowsNPCModded( titan, pilot )

	if ( CustomTitan.AfterSpawn != null )
		CustomTitan.AfterSpawn( titan )

	return titan
}

string function GetRandomTitanSetFile( string titanSettings )
{
	string SetFile

	if ( titanSettings == "npc_titan_auto_atlas_stickybomb" )
		SetFile = "titan_atlas_stickybomb"
	else if ( titanSettings == "npc_titan_auto_atlas_ion_prime" )
		SetFile = "titan_atlas_ion_prime"
	else if ( titanSettings == "npc_titan_auto_ogre_meteor" )
		SetFile = "titan_ogre_meteor"
	else if ( titanSettings == "npc_titan_auto_ogre_scorch_prime" )
		SetFile = "titan_ogre_scorch_prime"
	else if ( titanSettings == "titan_stryder_sniper" )
		SetFile = "npc_titan_auto_stryder_sniper"
	else if ( titanSettings == "npc_titan_auto_stryder_northstar_prime" )
		SetFile = "titan_stryder_northstar_prime"
	else if ( titanSettings == "npc_titan_auto_stryder_leadwall" )
		SetFile = "titan_stryder_leadwall"
	else if ( titanSettings == "npc_titan_auto_stryder_ronin_prime" )
		SetFile = "titan_stryder_ronin_prime"
	else if ( titanSettings == "npc_titan_auto_atlas_tracker" )
		SetFile = "titan_atlas_tracker"
	else if ( titanSettings == "npc_titan_auto_atlas_tone_prime" )
		SetFile = "titan_atlas_tone_prime"
	else if ( titanSettings == "npc_titan_auto_ogre_minigun" )
		SetFile = "titan_ogre_minigun"
	else if ( titanSettings == "npc_titan_auto_ogre_legion_prime" )
		SetFile = "titan_ogre_legion_prime"
	else if ( titanSettings == "npc_titan_auto_atlas_vanguard" )
		SetFile = "titan_atlas_vanguard"

	return SetFile
}

void function AttritionExtendedRecode_NpcPilotBecomesTitan( entity pilot, entity titan )
{
	if ( !IsAlive( pilot ) || !IsAlive( titan ) || ( !IsGrunt( pilot ) && !IsPilotElite( pilot ) ) || !titan.IsTitan() )
		return

	array<entity> weapons = pilot.GetMainWeapons()
	array<string> weaponNames

	foreach ( entity weapon in weapons )
		weaponNames.append( weapon.GetWeaponClassName() )

	entity titanSoul = titan.GetTitanSoul()

	if ( !IsValid( titanSoul ) )
		return

	titanSoul.soul.seatedNpcPilot.isValid = true
	titanSoul.soul.seatedNpcPilot.modelAsset = pilot.GetModelName()
	file.weapons[ titan ] <- weaponNames
	file.grenade[ titan ] <- expect string( pilot.kv.grenadeWeaponName )

	if ( titan in file.CustomTitanUID && file.CustomTitanUID[ titan ] >= 0 )
	{
		titan.SetTitle( pilot.GetTitle() )
	}
	else
	{
		switch ( GetTitanCharacterName( titan ) )
		{
			case "ion":
				titan.SetTitle( "Ion" )
				break

			case "scorch":
				titan.SetTitle( "Scorch" )
				break

			case "northstar":
				titan.SetTitle( "Northstar" )
				break

			case "ronin":
				titan.SetTitle( "Ronin" )
				break

			case "tone":
				titan.SetTitle( "Tone" )
				break

			case "legion":
				titan.SetTitle( "Legion" )
				break

			case "vanguard":
				titan.SetTitle( "Monarch" )
				break
		}
	}

	thread PilotInTitanSet( titan )

	titan.kv.WeaponProficiency = pilot.kv.WeaponProficiency
	titan.kv.AccuracyMultiplier = pilot.kv.AccuracyMultiplier

	pilot.Destroy()
}

void function AutoTitanLoadout( entity titan, AttritionExtendedRecode_CustomTitanStruct CustomTitans )
{
	if ( IsValid( titan ) )
	{
		TakeWeaponsForArray( titan, titan.GetMainWeapons() )

		titan.TakeOffhandWeapon( OFFHAND_ORDNANCE )
		titan.TakeOffhandWeapon( OFFHAND_SPECIAL )
		titan.TakeOffhandWeapon( OFFHAND_ANTIRODEO )
		titan.TakeOffhandWeapon( OFFHAND_EQUIPMENT )
		titan.TakeOffhandWeapon( OFFHAND_MELEE )

		if ( !( titan in file.CustomTitanUID && CustomTitans.UID == file.CustomTitanUID[ titan ] ) )
		{
			switch ( GetTitanCharacterName( titan ) )
			{
				case "ion":
					titan.GiveWeapon( "mp_titanweapon_particle_accelerator" )
					titan.GiveOffhandWeapon( "mp_titanweapon_laser_lite", OFFHAND_ORDNANCE )
					titan.GiveOffhandWeapon( "mp_titancore_laser_cannon", OFFHAND_EQUIPMENT )
					titan.GiveOffhandWeapon( "mp_titanability_laser_trip", OFFHAND_ANTIRODEO )
					titan.GiveOffhandWeapon( "mp_titanweapon_vortex_shield", OFFHAND_SPECIAL )
					titan.GiveOffhandWeapon( "melee_titan_punch", OFFHAND_MELEE )

					entity soul = titan.GetTitanSoul()

					if ( IsValid( soul ) )
						soul.soul.titanLoadout.titanExecution = "execution_ion"
					break

				case "scorch":
					titan.GiveWeapon( "mp_titanweapon_meteor" )
					titan.GiveOffhandWeapon( "mp_titanweapon_flame_wall", OFFHAND_ORDNANCE )
					titan.GiveOffhandWeapon( "mp_titancore_flame_wave", OFFHAND_EQUIPMENT )
					titan.GiveOffhandWeapon( "mp_titanability_slow_trap", OFFHAND_ANTIRODEO )
					titan.GiveOffhandWeapon( "mp_titanweapon_heat_shield", OFFHAND_SPECIAL )
					titan.GiveOffhandWeapon( "melee_titan_punch", OFFHAND_MELEE )

					entity soul = titan.GetTitanSoul()

					if ( IsValid( soul ) )
						soul.soul.titanLoadout.titanExecution = "execution_random_1"
					break

				case "northstar":
					titan.GiveWeapon( "mp_titanweapon_sniper" )
					titan.GiveOffhandWeapon( "mp_titanweapon_dumbfire_rockets", OFFHAND_ORDNANCE )
					titan.GiveOffhandWeapon( "mp_titancore_flight_core", OFFHAND_EQUIPMENT )
					titan.GiveOffhandWeapon( "mp_titanability_hover", OFFHAND_ANTIRODEO )
					titan.GiveOffhandWeapon( "mp_titanability_tether_trap", OFFHAND_SPECIAL )
					titan.GiveOffhandWeapon( "melee_titan_punch", OFFHAND_MELEE )

					entity soul = titan.GetTitanSoul()

					if ( IsValid( soul ) )
						soul.soul.titanLoadout.titanExecution = "execution_random_2"
					break

				case "ronin":
					titan.GiveWeapon( "mp_titanweapon_leadwall" )
					titan.GiveOffhandWeapon( "mp_titanweapon_arc_wave", OFFHAND_ORDNANCE )
					titan.GiveOffhandWeapon( "mp_titancore_shift_core", OFFHAND_EQUIPMENT )
					titan.GiveOffhandWeapon( "mp_titanability_phase_dash", OFFHAND_ANTIRODEO )
					titan.GiveOffhandWeapon( "mp_ability_swordblock", OFFHAND_SPECIAL )
					titan.GiveOffhandWeapon( "melee_titan_sword", OFFHAND_MELEE )

					entity soul = titan.GetTitanSoul()

					if ( IsValid( soul ) )
						soul.soul.titanLoadout.titanExecution = "execution_random_3"
					break

				case "tone":
					titan.GiveWeapon( "mp_titanweapon_sticky_40mm" )
					titan.GiveOffhandWeapon( "mp_titanweapon_tracker_rockets", OFFHAND_ORDNANCE )
					titan.GiveOffhandWeapon( "mp_titancore_salvo_core", OFFHAND_EQUIPMENT )
					titan.GiveOffhandWeapon( "mp_titanability_sonar_pulse", OFFHAND_ANTIRODEO )
					titan.GiveOffhandWeapon( "mp_titanability_particle_wall", OFFHAND_SPECIAL )
					titan.GiveOffhandWeapon( "melee_titan_punch", OFFHAND_MELEE )

					entity soul = titan.GetTitanSoul()

					if ( IsValid( soul ) )
						soul.soul.titanLoadout.titanExecution = "execution_random_4"
					break

				case "legion":
					titan.GiveWeapon( "mp_titanweapon_predator_cannon" )
					titan.GiveOffhandWeapon( "mp_titanability_power_shot", OFFHAND_ORDNANCE )
					titan.GiveOffhandWeapon( "mp_titancore_siege_mode", OFFHAND_EQUIPMENT )
					titan.GiveOffhandWeapon( "mp_titanability_ammo_swap", OFFHAND_ANTIRODEO )
					titan.GiveOffhandWeapon( "mp_titanability_gun_shield", OFFHAND_SPECIAL )
					titan.GiveOffhandWeapon( "melee_titan_punch", OFFHAND_MELEE )

					entity soul = titan.GetTitanSoul()

					if ( IsValid( soul ) )
						soul.soul.titanLoadout.titanExecution = "execution_random_5"
					break

				case "vanguard":
					titan.GiveWeapon( "mp_titanweapon_xo16_vanguard" )
					titan.GiveOffhandWeapon( "mp_titanweapon_salvo_rockets", OFFHAND_ORDNANCE )
					titan.GiveOffhandWeapon( "mp_titancore_upgrade", OFFHAND_EQUIPMENT )
					titan.GiveOffhandWeapon( "mp_titanability_rearm", OFFHAND_ANTIRODEO )
					titan.GiveOffhandWeapon( "mp_titanweapon_stun_laser", OFFHAND_SPECIAL )
					titan.GiveOffhandWeapon( "melee_titan_punch", OFFHAND_MELEE )

					thread MonarchUpgrades( titan )

					entity soul = titan.GetTitanSoul()

					if ( IsValid( soul ) )
					{
						soul.soul.titanLoadout.titanExecution = "execution_vanguard"

						if ( CoinFlip() )
							GivePassive( soul, ePassives.PAS_VANGUARD_COREMETER )

						if ( !SoulHasPassive( soul, ePassives.PAS_VANGUARD_COREMETER ) && CoinFlip() )
							GivePassive( soul, ePassives.PAS_VANGUARD_DOOM )
					}
					break
			}

			if ( GetCurrentPlaylistVarInt( "aegis_upgrades", 0 ) == 1 )
			{
				titan.SetMaxHealth( min( MAX_HEALTH - 1, titan.GetMaxHealth() + 2500 ) )
				titan.SetHealth( titan.GetMaxHealth() )
			}
		}

		bool hasNuclearEeject = false

		if ( RandomInt( 100 ) < 25 )
		{
			hasNuclearEeject = true

			NPC_SetNuclearPayload( titan )
		}

		if ( !hasNuclearEeject && RandomInt( 100 ) < 15 )
			file.autoEject[ titan ] <- true
	}
}

entity function AttritionExtendedRecode_NpcPilotCallsInAndEmbarksTitan( entity pilot, vector origin, vector angles, AttritionExtendedRecode_CustomTitanStruct CustomTitan )
{
	pilot.EndSignal( "OnDestroy" )
	pilot.EndSignal( "OnDeath" )

	wait 2.5

	entity titan = AttritionExtendedRecode_NpcPilotCallsInTitan( pilot, origin, angles, CustomTitan )

	int team = titan.GetTeam()

	if ( !( team in file.spawnedPilotedTitans ) )
		file.spawnedPilotedTitans[ team ] <- []

	file.spawnedPilotedTitans[ team ].append( titan )

	thread AttritionExtendedRecode_NpcPilotRunsToAndEmbarksFallingTitan( pilot, titan )

	return titan
}

function AttritionExtendedRecode_NpcPilotRunsToAndEmbarksFallingTitan( entity pilot, entity titan )
{
	waitthread WaitTillHotDropComplete( titan )

	if ( !IsValid( titan ) || !IsAlive( titan ) )
	{
		if ( IsValid( pilot ) && IsAlive( pilot ) )
		{
			pilot.Dissolve( ENTITY_DISSOLVE_CHAR, < 0, 0, 0 >, 500 )
			return
		}
	}

	if ( !IsValid( pilot ) || !IsAlive( pilot ) )
	{
		if ( IsValid( titan ) && IsAlive( titan ) )
		{
			titan.Dissolve( ENTITY_DISSOLVE_CHAR, < 0, 0, 0 >, 500 )
			return
		}
	}

	pilot.EndSignal( "OnDestroy" )
	pilot.EndSignal( "OnDeath" )

	NPCFollowsNPCModded( pilot, titan )
	waitthread AttritionExtendedRecode_NpcPilotEmbarksTitan( pilot, titan )
}

void function TitanStandAfterDropIn( entity titan, entity pilot )
{
	titan.EndSignal( "OnDestroy" )
	titan.EndSignal( "OnDeath" )
	titan.WaitSignal( "TitanHotDropComplete" )

	OnThreadEnd(
		function() : ( titan, pilot )
		{
			if ( IsValid( titan ) && IsAlive( titan ) && !TitanHasNpcPilot( titan ) && ( !IsValid( pilot ) || !IsAlive( pilot ) ) )
				titan.Dissolve( ENTITY_DISSOLVE_CHAR, < 0, 0, 0 >, 500 )
		}
	)

	if ( IsValid( pilot ) && IsAlive( pilot ) )
	{
		pilot.EndSignal( "OnDestroy" )
		pilot.EndSignal( "OnDeath" )
	}
	else
		return

	wait EMBARK_TIMEOUT

	if ( ( !( titan in file.titanIsBeingEmbarked ) || !file.titanIsBeingEmbarked[ titan ] ) )
	{
		file.titanIsStanding[ titan ] <- true

		thread TitanStandUp( titan )
	}
}

void function AttritionExtendedRecode_NpcPilotEmbarksTitan( entity pilot, entity titan )
{
	if ( !IsValid( pilot ) || !IsValid( titan ) || !IsAlive( pilot ) || !IsAlive( titan ) || pilot.IsTitan() || !titan.IsTitan() || !HasSoul( titan ) )
		return

	titan.EndSignal( "OnDestroy" )
	titan.EndSignal( "OnDeath" )
	pilot.EndSignal( "OnDestroy" )
	pilot.EndSignal( "OnDeath" )

	OnThreadEnd(
		function() : ( pilot, titan )
		{
			if ( IsValid( pilot ) && IsAlive( pilot ) )
				pilot.Dissolve( ENTITY_DISSOLVE_CHAR, < 0, 0, 0 >, 500 )

			if ( IsValid( titan ) && !TitanHasNpcPilot( titan ) )
				titan.Dissolve( ENTITY_DISSOLVE_CHAR, < 0, 0, 0 >, 500 )
		}
	)

	string titanSubClass = GetSoulTitanSubClass( titan.GetTitanSoul() )

	while ( !FindBestEmbark( pilot, titan ) )
		WaitFrame()

	table embarkSet = expect table( FindBestEmbark( pilot, titan ) )

	FirstPersonSequenceStruct sequence
	sequence.attachment = "hijack"
	sequence.useAnimatedRefAttachment = expect bool( embarkSet.action.useAnimatedRefAttachment )
	sequence.blendTime = 0.5
	sequence.thirdPersonAnim = GetAnimFromAlias( titanSubClass, embarkSet.animSet.thirdPersonKneelingAlias )

	string titanAnim = expect string( embarkSet.animSet.titanKneelingAnim )

	if ( titan.GetTitanSoul().GetStance() > STANCE_STANDING )
	{
		sequence.thirdPersonAnim = GetAnimFromAlias( titanSubClass, embarkSet.animSet.thirdPersonStandingAlias )

		titanAnim = expect string( embarkSet.animSet.titanStandingAnim )
	}

	if ( IsCloaked( pilot ) )
		pilot.SetCloakDuration( 0, 0, 1.5 )

	pilot.SetInvulnerable()
	pilot.Anim_Stop()

	thread FirstPersonSequence( sequence, pilot, titan )
	thread OnFlagChanged( titan, [ NPC_NO_PAIN ], false, true, false )

	pilot.EnableNPCFlag( NPC_IGNORE_ALL )

	file.titanIsBeingEmbarked[ titan ] <- true

	waitthread PlayAnimGravity( titan, titanAnim )
	SetStanceStand( titan.GetTitanSoul() )
	AttritionExtendedRecode_NpcPilotBecomesTitan( pilot, titan )
}

void function TrackNPCPilotCloakSound( entity pilot, float duration )
{
	pilot.EndSignal( "OnDestroy" )
	pilot.EndSignal( "OnDeath" )

	wait duration

	StopSoundOnEntity( pilot, "cloak_sustain_loop_3P" )

	if ( pilot.IsCloaked( CLOAK_INCLUDE_FADE_IN_TIME ) )
		EmitSoundOnEntity( pilot, "cloak_interruptend_3P" )
}

void function NPCPilotEjectingAnimation( entity pilot )
{
	pilot.EndSignal( "OnDestroy" )
	pilot.EndSignal( "OnDeath" )

	if ( !pilot.ContextAction_IsBusy() )
		pilot.ContextAction_SetBusy()

	pilot.Anim_ScriptedPlayActivityByName( "ACT_FALL", true, 0.2 )
	pilot.SetNPCPriorityOverride( 10 )

	OnThreadEnd(
		function() : ( pilot )
		{
			if ( IsValid( pilot ) )
			{
				if ( pilot.ContextAction_IsBusy() )
					pilot.ContextAction_ClearBusy()

				pilot.Anim_Stop()

				if ( IsAlive( pilot ) )
					pilot.ClearNPCPriorityOverride()
			}
		}
	)

	float lastAnimPlayedTime = -1
	float failSafeTime = Time() + 5.9

	wait 0.1

	while ( Time() < failSafeTime && !( pilot.IsOnGround() && pilot.GetVelocity().z <= 0 ) )
		WaitFrame()
}

const TITAN_PLAYEREJECT_DELAY = 0.4
const TITAN_PLAYEREJECT_DURATION = 0.8
const MAX_EJECT_LATENCY_COMPENSATION = 0.4

void function ClearEjectInvulnerability( entity player )
{
	if ( !IsValid( player ) )
		return

	player.EndSignal( "OnDeath" )

	OnThreadEnd(
		function() : ( player )
		{
			if ( IsValid( player ) )
				player.ClearInvulnerable()
		}
	)

	wait 0.35
}

void function TitanNonSolidTemp( entity titan )
{
	if ( !EntityInSolid( titan ) )
		return

	string collisionGroup = expect string( titan.kv.CollisionGroup )

	titan.kv.CollisionGroup = TRACE_COLLISION_GROUP_BLOCK_WEAPONS

	titan.EndSignal( "OnDeath" )

	while ( EntityInSolid( titan ) )
		wait 0.1

	titan.kv.collisionGroup = collisionGroup
}

void function ClearNuclearBlueSunEffect( e )
{
	foreach ( fx in e.nukeFX )
		if ( IsValid( fx ) )
			fx.Kill_Deprecated_UseDestroyInstead()

	e.nukeFX.clear()
	e.needToClearNukeFX = false
}

void function NuclearCoreExplosionChainReaction( vector origin, table e )
{
	int explosions
	int innerRadius
	float time
	bool IsNPC

	float heavyArmorDamage = 2500
	float normalDamage = 75

	switch ( e.nuclearPayload )
	{
		case 4:
			explosions = 3
			innerRadius = 350
			time = 1.5
			IsNPC = true

			float fraction = 10.0 / explosions

			heavyArmorDamage = heavyArmorDamage * fraction
			normalDamage = normalDamage * fraction
			break

		case 3:
			explosions = 20
			innerRadius = 350
			time = 1.7
			IsNPC = false
			break

		case 2:
			explosions = 15
			innerRadius = 350
			time = 1.4
			IsNPC = false
			break

		case 1:
			explosions = 10
			innerRadius = 350
			time = 1.0
			IsNPC = false
			break

		default:
			return
			break
	}

	float waitPerExplosion = time / explosions

	ClearNuclearBlueSunEffect( e )
	PlayFX( TITAN_NUCLEAR_CORE_FX_3P, origin + Vector( 0, 0, -100 ), Vector( 0, RandomInt( 360 ), 0 ) )

	if ( !IsNPC )
		explosions += 1

	int outerRadius

	float baseNormalDamage = normalDamage
	float baseHeavyArmorDamage = heavyArmorDamage
	int baseInnerRadius = innerRadius
	int baseOuterRadius = outerRadius

	entity inflictor = CreateEntity( "script_ref" )

	inflictor.SetOrigin( origin )
	inflictor.kv.spawnflags = SF_INFOTARGET_ALWAYS_TRANSMIT_TO_CLIENT

	DispatchSpawn( inflictor )

	OnThreadEnd(
		function() : ( inflictor )
		{
			if ( IsValid( inflictor ) )
				inflictor.Destroy()
		}
	)

	for ( int i = 0; i < explosions; i++ )
	{
		float normalDamage = baseNormalDamage
		float heavyArmorDamage = baseHeavyArmorDamage
		int innerRadius = baseInnerRadius
		int outerRadius = baseOuterRadius

		if ( !i && !IsNPC )
		{
			normalDamage = 75
			heavyArmorDamage = 0
			outerRadius = 600
		}
		else
		{
			outerRadius = 750
		}

		entity explosionOwner = GetExplosionOwner( e )

		if ( outerRadius < innerRadius )
			outerRadius = innerRadius

		RadiusDamage_DamageDef( damagedef_nuclear_core, origin, explosionOwner, inflictor, normalDamage, heavyArmorDamage, innerRadius, outerRadius, 0 )

		wait waitPerExplosion
	}
}

void function NuclearCoreExplosion( vector origin, table e )
{
	entity titan = expect entity( e.titan )

	titan.EndSignal( "OnDestroy" )
	titan.EndSignal( "OnDeath" )

	e.needToClearNukeFX = false

	OnThreadEnd(
		function() : ( e )
		{
			ClearNuclearBlueSunEffect( e )
		}
	)

	wait 1.3

	titan.s.silentDeath <- true

	EmitSoundAtPosition( titan.GetTeam(), origin, "titan_nuclear_death_explode" )

	titan.s.noLongerCountsForLTS <- true

	thread NuclearCoreExplosionChainReaction( origin, e )

	titan.Die( e.attacker, e.inflictor, { scriptType = DF_EXPLOSION, damageType = DMG_REMOVENORAGDOLL, damageSourceId = e.damageSourceId } )
}

void function TitanEjectPlayerForNPCs( entity ejectTitan, bool autoEject = false )
{
	ejectTitan.Signal( "EjectAttempt" )

	if ( !IsValid( ejectTitan ) || !IsAlive( ejectTitan ) || !ejectTitan.IsTitan() || ejectTitan.ContextAction_IsActive() )
		return

	entity soul = ejectTitan.GetTitanSoul()

	if ( soul.IsEjecting() )
		return

	table e = {}

	e.titan <- ejectTitan
	e.team <- ejectTitan.GetTeam()
	e.npcPilot <- null

	bool ejectTitanHasNpcPilot = false

	if ( TitanHasNpcPilot( ejectTitan ) )
	{
		ejectTitanHasNpcPilot = true
		ejectTitan.kv.allowShoot = 0
	}

	e.nukeFX <- []
	e.attacker <- ( "attacker" in soul.lastAttackInfo ) ? soul.lastAttackInfo.attacker : null
	e.inflictor <- ( "inflictor" in soul.lastAttackInfo ) ? soul.lastAttackInfo.inflictor : null
	e.damageSourceId <- ( "damageSourceId" in soul.lastAttackInfo ) ? soul.lastAttackInfo.damageSourceId : -1
	e.damageTypes <- soul.lastAttackInfo.scriptType
	e.overrideAttacker <- soul.soul.nukeAttacker

	e.nuclearPayload <- NPC_GetNuclearPayload( ejectTitan )

	if ( e.nuclearPayload )
	{
		e.needToClearNukeFX <- false
		e.nukeFXInfoTarget <- CreateEntity( "info_target" )
		e.nukeFXInfoTarget.kv.spawnflags = SF_INFOTARGET_ALWAYS_TRANSMIT_TO_CLIENT

		DispatchSpawn( e.nukeFXInfoTarget )

		AI_CreateDangerousArea_DamageDef( damagedef_nuclear_core, e.nukeFXInfoTarget, ejectTitan.GetTeam(), true, true )
	}

	entity rodeoPilot = GetRodeoPilot( ejectTitan )

	if ( rodeoPilot && rodeoPilot == e.attacker )
		e.damageSourceId = eDamageSourceId.rodeo_forced_titan_eject

	ejectTitan.Signal( "TitanEjectionStarted" )
	ejectTitan.EndSignal( "OnDeath" )

	OnThreadEnd(
		function() : ( e, ejectTitan, soul )
		{
			if ( IsAlive( ejectTitan ) )
			{
				thread ClearEjectInvulnerability( ejectTitan )

				if ( IsValid( ejectTitan.GetOwner() ) && IsAlive( ejectTitan.GetOwner() ) )
					thread ClearEjectInvulnerability( ejectTitan.GetOwner() )
			}
			else if ( IsValid( ejectTitan ) )
				ejectTitan.ClearInvulnerable()

			entity titan = expect entity( e.titan )

			if ( e.nuclearPayload )
			{
				if ( e.needToClearNukeFX )
				{
					if ( IsAlive( titan ) )
					{
						if ( !titan.IsTitan() )
							return

						thread NuclearCoreExplosion( titan.GetOrigin(), e )
					}
					else
						ClearNuclearBlueSunEffect( e )
				}

				return
			}

			if ( !IsAlive( titan ) || !IsValid( soul ) || !soul.soul.diesOnEject )
				return

			if ( titan.IsTitan() && soul.IsEjecting() )
				titan.Die( e.attacker, e.inflictor, { scriptType = damageTypes.titanEjectExplosion | e.damageTypes, damageSourceId = e.damageSourceId } )
		}
	)

	soul.SetEjecting( true )

	ejectTitan.SetInvulnerable()

	if ( !ejectTitan.ContextAction_IsBusy() )
		ejectTitan.ContextAction_SetBusy()

	bool standing = soul.GetStance() == STANCE_STAND
	string titanEjectAnimPlayer, titanEjectAnimTitan

	if ( standing )
	{
		if ( e.nuclearPayload )
		{
			titanEjectAnimPlayer = "at_nuclear_eject_standing"
			titanEjectAnimTitan = "at_nuclear_eject_standing_idle"
		}
		else
		{
			titanEjectAnimPlayer = "at_MP_eject_stand_start"
			titanEjectAnimTitan = "at_MP_eject_stand_end"
		}
	}
	else
	{
		titanEjectAnimPlayer = "at_MP_eject_crouch_idle"
		titanEjectAnimTitan = "at_MP_eject_crouch_start"
	}

	float ejectDuration

	if ( e.nuclearPayload )
		ejectDuration = TITAN_PLAYEREJECT_DURATION * 2.0
	else
		ejectDuration = TITAN_PLAYEREJECT_DURATION

	if ( e.nuclearPayload )
	{
		array<entity> players = GetPlayerArray()
		int frequency = 40
		float duration = 8.5
		vector origin = ejectTitan.GetOrigin()

		foreach ( guy in players )
		{
			if ( !IsAlive( guy ) )
				continue

			float dist = Distance( guy.GetOrigin(), origin )
			float result = Graph( dist, 750, 1500, 5.0, 0.0 )

			Remote_CallFunction_Replay( guy, "ServerCallback_ScreenShake", result, frequency, duration )
		}

		e.needToClearNukeFX = true
		e.nukeFXInfoTarget.SetParent( ejectTitan, "CHESTFOCUS" )
		e.nukeFX.append( PlayFXOnEntity( TITAN_NUCLEAR_CORE_NUKE_FX, expect entity( e.nukeFXInfoTarget ) ) )
		e.nukeFX.append( e.nukeFXInfoTarget )

		EmitSoundOnEntity( e.nukeFXInfoTarget, "titan_nuclear_death_charge" )
	}

	entity rodeoPlayer = GetRodeoPilot( ejectTitan )

	if ( IsValid( rodeoPlayer ) && rodeoPlayer.IsPlayer() )
		Remote_CallFunction_Replay(
			rodeoPlayer,
			"ServerCallback_RodeoerEjectWarning",
			ejectTitan.GetTitanSoul().GetEncodedEHandle(),
			TITAN_PLAYEREJECT_DELAY + ejectDuration
		)

	float blendDelay = 0.15
	vector origin = ejectTitan.GetOrigin()

	EmitSoundAtPosition( e.team, ejectTitan.GetOrigin(), "Titan_Eject_Servos_3P" )

	if ( !ejectTitan.IsTitan() )
	{
		KillStuckPlayer( ejectTitan )
		return
	}

	ejectTitan.Anim_Play( titanEjectAnimPlayer )

	wait blendDelay

	if ( ejectDuration <= MAX_EJECT_LATENCY_COMPENSATION )
		return

	wait ejectDuration - MAX_EJECT_LATENCY_COMPENSATION

	if ( !IsValid( ejectTitan.GetTitanSoul() ) )
		return

	EmitSoundAtPosition( e.team, ejectTitan.GetOrigin(), "Titan_Eject_PilotLaunch_3P" )

	entity titan = ejectTitan

	if ( ejectTitanHasNpcPilot )
	{
		ForceTitanSustainedDischargeEnd( ejectTitan )

		entity npcPilot = AttritionExtendedRecode_NpcTitanBecomesPilot( ejectTitan )

		e.npcPilot = npcPilot

		if ( IsAlive( npcPilot ) )
		{
			npcPilot.SetInvulnerable()

			if ( autoEject )
			{
				EmitSoundOnEntity( npcPilot, "cloak_on_3P" )
				EmitSoundOnEntity( npcPilot, "cloak_sustain_loop_3P" )

				npcPilot.SetCanCloak( true )
				npcPilot.SetCloakDuration( 1.0, 6.0, 1.0 )

				thread TrackNPCPilotCloakSound( npcPilot, 7.0 )
			}

			thread NPCPilotEjectingAnimation( npcPilot )
		}
	}

	vector titanOrigin = titan.GetOrigin()

	if ( !( "disableAutoTitanConversation" in titan.s ) )
		titan.s.disableAutoTitanConversation <- true

	titan.SetInvulnerable()
	titan.SetNPCPriorityOverride_NoThreat()

	if ( e.nuclearPayload )
		e.nukeFXInfoTarget.SetParent( titan, "CHESTFOCUS" )

	bool isInDeepWater = expect bool( "isInDeepWater" in ejectTitan.s && ejectTitan.s.isInDeepWater )

	if ( e.nuclearPayload || isInDeepWater )
		thread TitanNonSolidTemp( titan )

	ejectTitan.Anim_Stop()
	e.titan = titan

	if ( ejectTitan.ContextAction_IsBusy() )
		ejectTitan.ContextAction_ClearBusy()

	FirstPersonSequenceStruct sequence
	sequence.thirdPersonAnim = titanEjectAnimTitan
	sequence.teleport = true

	thread FirstPersonSequence( sequence, titan )

	vector ejectAngles = titan.GetAngles()

	ejectAngles.x = 270

	float speed = RandomFloatRange( 1500, 1700 )

	if ( e.nuclearPayload )
		speed += 400

	if ( isInDeepWater )
		speed += 1000

	e.singleRodeoPilot <- null

	entity rider = GetRodeoPilot( titan )

	if ( IsValid( rider ) && rider.GetParent() == titan )
	{
		e.singleRodeoPilot = rider

		thread TemporarilyNonSolidPlayer( rider )

		vector riderEjectAngles = AnglesCompose( ejectAngles, < 5, 0, 0 > )
		float gravityScale = 1.0

		if ( rider.IsPlayer() )
			gravityScale = expect float( rider.GetPlayerSettingsField( "gravityscale" ) )

		vector riderVelocity = AnglesToForward( riderEjectAngles ) * ( speed * gravityScale ) * 0.95

		if ( rider.IsPlayer() )
			ThrowRiderOff( rider, titan, riderVelocity )
		else
			rider.Die( titan, titan, { force = Vector( 0.4, 0.2, 0.3 ), scriptType = DF_GIB, damageSourceId = eDamageSourceId.titan_explosion } )

		wait 0.05
	}

	if ( ejectTitanHasNpcPilot && IsAlive( expect entity( e.npcPilot ) ) )
	{
		vector velocity = < 0, 0, speed >

		e.npcPilot.SetOrigin( titan.GetOrigin() + Vector( 0, 0, 100 ) )
		e.npcPilot.SetAngles( titan.GetAngles() )
		e.npcPilot.SetVelocity( velocity )
		e.overrideAttacker = e.npcPilot
	}

	wait 0.15

	vector explosionOrigin = titanOrigin + Vector( 0, 0, 200 )

	if ( e.nuclearPayload )
	{
		thread NuclearCoreExplosion( explosionOrigin, e )
	}
	else
	{
		entity explosionOwner = GetExplosionOwner( e )
		entity inflictor

		if ( IsValid( titan ) )
			inflictor = titan
		else
			inflictor = explosionOwner

		RadiusDamage(
			explosionOrigin,
			explosionOwner,
			inflictor,
			1,
			1800,
			100,
			300,
			SF_ENVEXPLOSION_NO_DAMAGEOWNER,
			0,
			0,
			damageTypes.explosive,
			eDamageSourceId.titan_explosion
		)

		entity shake = CreateEntity( "env_shake" )

		shake.SetOrigin( titanOrigin )
		shake.kv.amplitude = 12
		shake.kv.duration = 1
		shake.kv.frequency = 100
		shake.kv.radius = 1000
		shake.kv.spawnflags = 4

		DispatchSpawn( shake )

		shake.Fire( "StartShake" )
		shake.Kill_Deprecated_UseDestroyInstead( 1 )
	}

	if ( IsValid( titan ) )
	{
		if ( titan.ContextAction_IsBusy() )
			titan.ContextAction_ClearBusy()
	}
}

void function KillStuckPlayer( entity player )
{
	if ( IsAlive( player ) )
		player.Die( svGlobal.worldspawn, svGlobal.worldspawn, { scriptType = DF_DISSOLVE, damageSourceId = damagedef_crush } )
}

entity function GetExplosionOwner( table e )
{
	if ( IsValid( expect entity( e.overrideAttacker ) ) )
		return expect entity( e.overrideAttacker )

	if ( IsValid( expect entity( e.titan ) ) )
		return expect entity( e.titan )

	return GetTeamEnt( expect int( e.team ) )
}
