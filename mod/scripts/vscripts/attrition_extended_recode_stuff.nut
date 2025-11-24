untyped

global function AttritionExtendedRecode_Init
#if SERVER && MP
global function AttritionExtendedRecode_SpawnPilotWithTitan
global function AttritionExtendedRecode_SpawnTitan
#endif
#if SERVER
global function AttritionExtendedRecode_SpawnedPilotedTitans
global function AttritionExtendedRecode_SpawnedUnPilotedTitans
global function AttritionExtendedRecode_TitanHasNpcPilot
global function AttritionExtendedRecode_GetTitanModel
global function Is_AttritionExtendedRecode_Entity
global function AttritionExtendedRecode_CustomTitan

global struct AttritionExtendedRecode_CustomTitanStruct
{
	string Title = "Pilot"
	string TitanSetFile = ""
	string TitanAiSet = ""
	string TitanBehavior = ""
	string EmbarkedTitanAiSet = ""
	string EmbarkedTitanBehavior = ""
	string TitanExecutionRef = ""
	int Camo = -1
	int Skin = -1
	bool AllowedWithPilot = true
	bool AllowedWithoutPilot = true
	string Melee = ""
	array<string> MeleeMods = []
	string Weapon = ""
	array<string> WeaponMods = []
	string Ordnance = ""
	array<string> OrdnanceMods = []
	string Utility = ""
	array<string> UtilityMods = []
	string Tactical = ""
	array<string> TacticalMods = []
	string Core = ""
	array<string> CoreMods = []
	array<int> Passives = []
	int HP = -1
	int UID = -1
}

struct TitanEjectDamage
{
	int damage
	int damageHeavyArmor
	int innerRadius
	int outerRadius
	int explosionFlags
	int explosionForce
	int damageFlags
	int damageSourceId
}

struct TitanNukeDamage
{
	int count
	float duration
	int damage
	int damageHeavyArmor
	int innerRadius
	int outerRadius
	int explosionFlags
	int explosionForce
	int damageFlags
	int damageSourceId
}

struct
{
	table<entity, bool> autoeject
	table<entity, bool> deatheject
	
	table<entity, array<string> > weapons
	table<entity, asset> model
	table<entity, string> grenade
	table<entity, bool> pilotedtitan

	table<entity, int> smokecount

	table<entity, bool> titanstanding
	table<entity, bool> titanisbeingembarked

	table<int, int> spawnedpilotedtitans
	table<int, int> spawnedunpilotedtitans

	table<entity, bool> isattritionextendedrecodeentity

	array<AttritionExtendedRecode_CustomTitanStruct> CustomTitans
	table<entity, int> CustomTitanUID

	array<string> pilotweapons = [
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

	array<string> pilotantititanweapons = [
		"mp_weapon_arc_launcher",
		"mp_weapon_rocket_launcher",
		"mp_weapon_defender"
	]

	array<asset> pilotmodels = [
		$"models/humans/pilots/pilot_medium_geist_m.mdl",
		$"models/humans/pilots/pilot_medium_geist_f.mdl",
		$"models/humans/pilots/pilot_medium_stalker_m.mdl",
		$"models/humans/pilots/pilot_medium_stalker_f.mdl",
		$"models/humans/pilots/pilot_medium_reaper_m.mdl",
		$"models/humans/pilots/pilot_medium_reaper_f.mdl"
	]
	array<string> pilotgrenades = [ 
		"mp_weapon_frag_grenade",
		"mp_weapon_grenade_electric_smoke", 
		"mp_weapon_thermite_grenade",
		"mp_weapon_grenade_emp",
		"mp_weapon_grenade_gravity"
	]
} file
#endif
void function AttritionExtendedRecode_Init()
{
	#if MP
	AddPrivateMatchModeSettingArbitrary( "Attrition Extended Recode", "squad_count", "4", "Squad Count" )
	AddPrivateMatchModeSettingArbitrary( "Attrition Extended Recode", "reaper_count", "2", "Reaper Count" )
	AddPrivateMatchModeSettingArbitrary( "Attrition Extended Recode", "piloted_titan_count", "3", "Piloted Titan Count" )
	AddPrivateMatchModeSettingArbitrary( "Attrition Extended Recode", "unpiloted_titan_count", "0", "Unpiloted Titan Count" )
	AddPrivateMatchModeSettingArbitrary( "Attrition Extended Recode", "spectre_spawn_score", "125", "Spectre Spawn Score" )
	AddPrivateMatchModeSettingArbitrary( "Attrition Extended Recode", "stalker_spawn_score", "380", "Stalker Spawn Score" )
	AddPrivateMatchModeSettingArbitrary( "Attrition Extended Recode", "reaper_spawn_score", "500", "Reaper Spawn Score" )
	AddPrivateMatchModeSettingArbitrary( "Attrition Extended Recode", "titan_spawn_score", "0", "Titan Spawn Score" )
	AddPrivateMatchModeSettingArbitrary( "Attrition Extended Recode", "ct_titan_replace_chance", "0.20", "Custom Titan Replace Chance" )
	#endif
	#if SERVER && MP
	AddDamageByCallback( "npc_titan", PilotTitanExecution )
	AddDamageByCallback( "npc_pilot_elite", PilotExecution )
	AddDamageCallback( "npc_titan", NPCNOPAIN )
	AddDamageCallback( "npc_pilot_elite", NPCNOPAIN )
	AddDamageCallbackSourceID( eDamageSourceId.auto_titan_melee, ApplyNormalMeleeIdToNPCTitan )
	AddDamageCallback( "npc_pilot_elite", PilotDamageAdjustments )
	AddDamageCallback( "npc_titan", PilotTitanAutoOrDeathEjectHandle )
	AddCallback_OnTitanDoomed( EjectWhenDoomed )
	try
	{
		if ( !IsValid( GetConVarInt( "ns_fd_min_numplayers_to_start" ) ) )
			AddCallback_OnNPCKilled( HandleNPCScoreEvent )
	}
	catch( error )
	{
		AddCallback_OnNPCKilled( HandleNPCScoreEvent )
	}
	#endif
}
#if SERVER
int function AttritionExtendedRecode_SpawnedPilotedTitans( int team )
{
	if ( team in file.spawnedpilotedtitans )
		return file.spawnedpilotedtitans[ team ]

	return 0
}

int function AttritionExtendedRecode_SpawnedUnPilotedTitans( int team )
{
	if ( team in file.spawnedunpilotedtitans )
		return file.spawnedunpilotedtitans[ team ]

	return 0
}

asset function AttritionExtendedRecode_GetTitanModel( entity titan )
{
	if ( titan in file.model )
		return file.model[ titan ]

	return file.pilotmodels.getrandom()
}

bool function Is_AttritionExtendedRecode_Entity( entity thing )
{
	if ( thing in file.isattritionextendedrecodeentity && file.isattritionextendedrecodeentity[ thing ] )
		return true
	
	return false
}

void function AttritionExtendedRecode_CustomTitan( AttritionExtendedRecode_CustomTitanStruct CustomTitan )
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

void function AttritionExtendedRecode_GiveTitanAutoEject( entity titan )
{
	file.autoeject[ titan ] <- true
}

void function AttritionExtendedRecode_RemoveTitanAutoEject( entity titan )
{
	file.autoeject[ titan ] <- false
}

void function AttritionExtendedRecode_GiveTitanDeathEject( entity titan )
{
	file.deatheject[ titan ] <- true
}

void function AttritionExtendedRecode_RemoveTitanDeathEject( entity titan )
{
	file.deatheject[ titan ] <- false
}

bool function AttritionExtendedRecode_TitanHasNpcPilot( entity titan )
{
	Assert( titan.IsTitan() )

	if ( !(titan in file.pilotedtitan && file.pilotedtitan[ titan ]) )
		return false

	return true
}
#endif
#if SERVER && MP
void function PilotTitanExecution( entity ent, var damageInfo )
{
	thread PilotTitanExecution_thread( ent, damageInfo )
}

void function PilotTitanExecution_thread( entity ent, var damageInfo )
{
	int damageType = DamageInfo_GetCustomDamageType( damageInfo )
	entity attacker = DamageInfo_GetAttacker( damageInfo )

	if ( !IsAlive( ent ) || !attacker || ent.GetTeam() == attacker.GetTeam() || attacker == ent || !ent.IsTitan() || ent.IsInvulnerable() )
		return

	entity soul = ent.GetTitanSoul()
	if ( attacker.IsNPC() && attacker.IsTitan() )
	{
		if ( IsValid( soul ) && ( damageType & DF_MELEE ) )
		{
			if ( attacker in file.pilotedtitan && file.pilotedtitan[ attacker ] && CodeCallback_IsValidMeleeExecutionTarget( attacker, ent ) )
			{
				if ( GetDoomedState( ent ) && !SoulHasPassive( soul, ePassives.PAS_AUTO_EJECT ) && !ent.IsPhaseShifted() && CanSurviveDamage( ent, damageInfo ) )
				{
					vector attackerStartingAngles = attacker.GetAngles()
					PilotTitanExecution_DamageEnemy( ent, damageInfo )
					DamageInfo_SetDamage( damageInfo, 0 )
					thread PilotTitanExecution_Wait( attacker, attackerStartingAngles )
					waitthread PlayerTriesSyncedMelee( attacker, ent )
				}
			}
		}
	}
}

void function PilotTitanExecution_DamageEnemy( entity ent, var damageInfo )
{
	if ( HasSoul( ent ) && Time() - ent.GetTitanSoul().soul.doomedStartTime < TITAN_DOOMED_INVUL_TIME )
		return

	ent.SetInvulnerable()

	entity soul = ent.GetTitanSoul()
	if ( !IsValid( soul ) )
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
	ent.ClearInvulnerable()
}

void function PilotTitanExecution_Wait( entity attacker, vector attackerStartingAngles )
{
	attacker.EndSignal( "OnDestroy" )
	attacker.EndSignal( "OnDeath" )
	WaitFrame()
	while ( attacker.Anim_IsActive() )
		WaitFrame()
	vector angles = attacker.GetAngles()
	angles.x = attackerStartingAngles.x
	angles.z = attackerStartingAngles.z
	attacker.SetAngles( angles )
}

void function PilotExecution( entity ent, var damageInfo )
{
	thread PilotExecution_thread( ent, damageInfo )
}

void function PilotExecution_thread( entity ent, var damageInfo )
{
	int damageType = DamageInfo_GetCustomDamageType( damageInfo )
	entity attacker = DamageInfo_GetAttacker( damageInfo )

	if ( !IsAlive( ent ) || !attacker || ent.GetTeam() == attacker.GetTeam() || attacker == ent || ent.IsTitan() || ent.IsInvulnerable() )
		return

	if ( attacker.IsNPC() && Is_AttritionExtendedRecode_Entity( attacker ) )
	{
		if ( ( damageType & DF_MELEE ) )
		{
			if ( CodeCallback_IsValidMeleeExecutionTarget( attacker, ent ) && !ent.Anim_IsActive() )
			{
				if ( !(ent.IsPlayer() && PlayerCanSee( ent, attacker, true, 75 ) || ent.IsNPC() && ent.CanSee( attacker )) )
				{
					DamageInfo_SetDamage( damageInfo, 0 )
					waitthread PlayerTriesSyncedMelee( attacker, ent )
				}
			}
		}
	}
}

void function NPCNOPAIN( entity npc, var damageInfo )
{
	if ( npc.GetNPCFlag( NPC_NO_PAIN ) || !npc.GetNPCFlag( NPC_PAIN_IN_SCRIPTED_ANIM ) )
	{
		if ( !npc.IsTitan() )
			DamageInfo_AddDamageFlags( damageInfo, DAMAGEFLAG_NOPAIN )
		if ( npc.IsTitan() )
			if ( npc in file.pilotedtitan && file.pilotedtitan[ npc ] )
				DamageInfo_AddDamageFlags( damageInfo, DAMAGEFLAG_NOPAIN )
	}
}

void function ApplyNormalMeleeIdToNPCTitan( entity victim, var damageInfo )
{
	entity attacker = DamageInfo_GetAttacker( damageInfo )
	int damageSourceID = DamageInfo_GetDamageSourceIdentifier( damageInfo )

	if ( !attacker.IsNPC() )
		return

	if ( !attacker.IsTitan() )
		return

	if ( GetTitanCharacterName( attacker ) == "ronin" && attacker in file.pilotedtitan && file.pilotedtitan[ attacker ] )
	{
		entity meleeWeapon = attacker.GetMeleeWeapon()
		if ( IsValid( meleeWeapon ) )
		{
			if ( meleeWeapon.HasMod( "super_charged" ) )
			{
				DamageInfo_SetDamageSourceIdentifier( damageInfo, eDamageSourceId.mp_titancore_shift_core )
				return
			}
		}
		DamageInfo_SetDamageSourceIdentifier( damageInfo, eDamageSourceId.melee_titan_sword )
		return
	}

	if ( attacker in file.pilotedtitan && file.pilotedtitan[ attacker ])
	{
		DamageInfo_SetDamageSourceIdentifier( damageInfo, eDamageSourceId.melee_titan_punch )
		return
	}
}

void function PilotDamageAdjustments( entity pilot, var damageInfo )
{	
	if ( IsInstantDeath( damageInfo ) || DamageInfo_GetForceKill( damageInfo ) )
		return

	entity attacker = DamageInfo_GetAttacker( damageInfo )

	if ( pilot == attacker )
		DamageInfo_SetDamage( damageInfo, 0 )
}

void function PilotTitanAutoOrDeathEjectHandle( entity titan, var damageInfo )
{
	if ( IsInstantDeath( damageInfo ) || DamageInfo_GetForceKill( damageInfo ) )	
		return

	if ( titan.ContextAction_IsBusy() )
		return

	entity soul = titan.GetTitanSoul()

	if ( !IsValid( soul ) || soul.IsEjecting() )
		return

	if ( titan in file.pilotedtitan && file.pilotedtitan[ titan ] && ( ( titan in file.deatheject && file.deatheject[ titan ] ) || ( titan in file.autoeject && file.autoeject[ titan ] ) ) )
	{
		if ( !CanSurviveDamage( titan, damageInfo ) || ( titan in file.autoeject && file.autoeject[ titan ] && GetDoomedState( titan ) ) )
		{
			if ( ( titan in file.deatheject && file.deatheject[ titan ] ) && !( titan in file.autoeject && file.autoeject[ titan ] ) )
			DamageInfo_SetDamage( damageInfo, 0 )

			thread TitanEjectPlayerForNPCs( titan )

			if ( IsAlive( titan ) && ( titan in file.deatheject && file.deatheject[ titan ] ) && !( titan in file.autoeject && file.autoeject[ titan ] ) )
				titan.SetHealth( 1 )
		}
	}
}

void function EjectWhenDoomed( entity titan, var damageInfo )
{
	thread EjectWhenDoomed_thread( titan )
}

void function EjectWhenDoomed_thread( entity titan )
{
	if ( titan.IsPlayer() || !titan.IsTitan() )
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

	if ( !( titan in file.autoeject && file.autoeject[ titan ] ) )
		wait 2.25
	else
		WaitFrame() 

	while ( soul.IsDoomed() )
	{
		if ( !( titan in file.autoeject && file.autoeject[ titan ] ) )
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

		if ( titan in file.pilotedtitan && file.pilotedtitan[ titan ] && ( shouldEjectTitan || ( titan in file.autoeject && file.autoeject[ titan ] ) ) )
		{
			if ( !titan.IsInvulnerable() || ( titan in file.autoeject && file.autoeject[ titan ] ) )
			{
				thread TitanEjectPlayerForNPCs( titan )
				return
			}
		}
	}
}

void function HandleNPCScoreEvent( entity ent, entity attacker, var damageInfo )
{
	if ( !ent.IsTitan() || !Is_AttritionExtendedRecode_Entity( ent ) )
		return

	int attackerEHandle = ent.GetEncodedEHandle()
	if ( IsValid( attacker ) && ( attacker.IsPlayer() || attacker.IsNPC() ) )
		attackerEHandle = attacker.GetEncodedEHandle()

	int entEHandle = ent.GetEncodedEHandle()
	int scriptDamageType = DamageInfo_GetCustomDamageType( damageInfo )
	int damageSourceId = DamageInfo_GetDamageSourceIdentifier( damageInfo )

	if ( scriptDamageType & DF_VORTEX_REFIRE )
		damageSourceId = eDamageSourceId.mp_titanweapon_vortex_shield

	foreach ( player in GetPlayerArray() )
		Remote_CallFunction_NonReplay( player, "ServerCallback_OnTitanKilled", attackerEHandle, entEHandle, scriptDamageType, damageSourceId )
}

int function GetTitanValidHealthFromDamageInfo( entity titan, var damageInfo )
{
	if ( DamageInfo_GetForceKill( damageInfo ) )
		return 0

	const int INFINITE_HEALTH = 999999

	entity soul = titan.GetTitanSoul()
	int healthShield = titan.GetHealth()
	if ( IsValid( soul ) )
		healthShield += soul.GetShieldHealth()
	if ( IsValid( soul ) && !GetDoomedState( titan ) && !soul.soul.skipDoomState )
		healthShield += 2500

	if ( GetDoomedState( titan ) )
	{
		if ( IsValid( soul ) )
		{
			if ( Time() - soul.soul.doomedStartTime < TITAN_DOOMED_INVUL_TIME )
				return INFINITE_HEALTH
		}
	}
	
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
	Assert( IsValid( titan ) )
	Assert( titan.IsTitan() )

	entity titanSoul = titan.GetTitanSoul()
	if ( !IsValid( titanSoul ) )
		return
	file.pilotedtitan[ titan ] <- false

	array<string> weapon = []
	if ( titan in file.weapons )
		weapon = file.weapons[ titan ]
	asset model = $""
	if ( titan in file.model )
		model = file.model[ titan ]
	string grenade = ""
	if ( titan in file.grenade )
		grenade = file.grenade[ titan ]
	int team = titan.GetTeam()
	vector origin = titan.GetOrigin()
	float angles = titan.GetAngles().z

	entity pilot = CreateEntity( "npc_pilot_elite" )
	pilot.SetOrigin( origin )
	SetTeam( pilot, team )

	DispatchSpawn( pilot )
	file.isattritionextendedrecodeentity[ pilot ] <- true
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
	if ( file.pilotmodels.contains( model ) )
		pilot.SetModel( model )
	else
		pilot.SetModel( file.pilotmodels.getrandom() )
	TakeWeaponsForArray( pilot, pilot.GetMainWeapons() )
	bool gaveweapon = false
	foreach ( string newweapons in weapon )
	{
		pilot.GiveWeapon( newweapons )
		gaveweapon = true
	}
	if ( !gaveweapon )
		RandomPilotWeapon( pilot )
	if ( grenade != "" )
		pilot.kv.grenadeWeaponName = grenade
	else
		pilot.kv.grenadeWeaponName = file.pilotgrenades.getrandom()

	titan.SetOwner( pilot )
	NPCFollowsNPCModded( titan, pilot )

	thread PilotNotInTitanSet( titan )

	UpdateEnemyMemoryFromTeammates( pilot )

	return pilot
}

void function OnFlagChanged( entity npc, array <int> flags, bool disable = false, bool istitan = false, bool isvalidpilot = false )
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
					if ( !( npc in file.pilotedtitan && file.pilotedtitan[ npc ] ) )
						return
				}
				if ( !isvalidpilot )
				{
					if ( npc in file.pilotedtitan && file.pilotedtitan[ npc ] )
						return
				}
			}
		}

		foreach( int flag in flags )
		{
			if ( !disable )
			{
				if ( !npc.GetNPCFlag( flag ) )
				{
					npc.EnableNPCFlag( flag )
				}
			}
			if ( disable )
			{
				if ( npc.GetNPCFlag( flag ) )
				{
					npc.DisableNPCFlag( flag )
				}
			}
		}

		WaitFrame()
	}
}

void function PilotSpeedFlagsHPAndBehavior( entity npc )
{
	npc.SetNPCMoveSpeedScale( 1.25 )
	npc.EnableNPCMoveFlag( NPCMF_PREFER_SPRINT )

	array <int> flags
	flags.extend( [ NPC_NO_PAIN, NPC_NO_GESTURE_PAIN, NPC_ALLOW_PATROL, NPC_ALLOW_INVESTIGATE, NPC_IGNORE_FRIENDLY_SOUND ] )
	thread OnFlagChanged( npc, flags )

	array <int> disableflags
	disableflags.extend( [ NPC_PAIN_IN_SCRIPTED_ANIM, NPC_ALLOW_FLEE ] )
	thread OnFlagChanged( npc, disableflags, true )

	npc.SetMaxHealth( 500 )
	npc.SetHealth( npc.GetMaxHealth() )
	npc.SetBehaviorSelector( "behavior_sp_soldier" )
	npc.SetEnemyChangeCallback( OnNPCPilotEnemyChange )

	Highlight_SetEnemyHighlight( npc, "enemy_player" )
}

void function PilotMiniMap( entity npc )
{
	entity pilotminimap = createpilotminimap( npc )
	thread pilotminimaponpilotdeath( npc, pilotminimap )
}

entity function createpilotminimap( entity npc )
{
	entity pilotminimap = CreateEntity( "npc_spectre" )
	DispatchSpawn( pilotminimap )
	file.isattritionextendedrecodeentity[ pilotminimap ] <- true
	TakeWeaponsForArray( pilotminimap, pilotminimap.GetMainWeapons() )
	pilotminimap.kv.VisibilityFlags = ENTITY_VISIBLE_TO_NOBODY
	pilotminimap.Hide()
	HideName( pilotminimap )
	pilotminimap.SetParent( npc, "HEADFOCUS" )
	pilotminimap.NotSolid()
	pilotminimap.kv.CollisionGroup = 0
	pilotminimap.SetInvulnerable()
	SetTeam( pilotminimap, npc.GetTeam() )
	NPC_NoTarget( pilotminimap )
	pilotminimap.EnableNPCFlag( NPC_IGNORE_ALL )
	pilotminimap.StopPhysics()
	pilotminimap.Freeze()
	pilotminimap.SetModel( $"models/dev/empty_model.mdl" )
	return pilotminimap
}

void function pilotminimaponpilotdeath( entity npc, entity pilotminimap )
{
	while ( true )
	{
		if ( IsValid( npc ) && IsValid( pilotminimap ) )
		{
			if ( npc.GetTeam() != pilotminimap.GetTeam() )
				SetTeam( pilotminimap, npc.GetTeam() )
		}

		if ( IsValid( npc ) && !IsValid( pilotminimap ) )
		{
			pilotminimap = createpilotminimap( npc )
		}

		if ( !IsValid( npc ) && IsValid( pilotminimap ) )
		{
			pilotminimap.Destroy()
			return
		}

		WaitFrame()
	}
}

void function RandomPilotWeapon( entity pilot )
{
	TakeWeaponsForArray( pilot, pilot.GetMainWeapons() )
	pilot.GiveWeapon( file.pilotweapons.getrandom() )
	pilot.GiveWeapon( file.pilotantititanweapons.getrandom() )
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
	bool antiTitanActive = activeWeapon != weapons[0] && !activeWeapon.GetWeaponSettingBool( eWeaponVar.titanarmor_critical_hit_required )

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
			bool isMainWeapon = weapon == weapons[0]
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
			bool isMainWeapon = weapon == weapons[0]
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

void function core( entity titan )
{
	while( true )
	{
		titan.WaitSignal( "CoreBegin" )
		if ( IsValid( titan ) )
		{
			ronincore( titan )
		}
		if ( !IsValid( titan ) )
			return
	}
}


void function ronincore( entity titan )
{
	entity meleeWeapon = titan.GetMeleeWeapon()
	if ( meleeWeapon.HasMod( "super_charged" ) )
	{
		titan.SetAISettings( "npc_titan_stryder_leadwall_shift_core" )
		titan.SetBehaviorSelector( "behavior_titan_melee_core" )
	}

	titan.WaitSignal( "CoreEnd" )

	if ( IsValid( titan ) )
	{
		titan.SetAISettings( "npc_titan_stryder_leadwall" )
		titan.SetBehaviorSelector( "behavior_titan_shotgun" )
	}
}


void function MonitorMonarchShield( entity npc )
{
	entity soul = npc.GetTitanSoul()
	if ( !IsValid( soul ) )
		return

	if ( !(npc in file.pilotedtitan && file.pilotedtitan[ npc ]) )
		return
	
	npc.EndSignal( "OnDestroy" )
	npc.EndSignal( "OnDeath" )
	soul.EndSignal( "OnDestroy" )
	soul.EndSignal( "OnDeath" )
	
	while( true )
	{
		WaitFrame()
		entity soul = npc.GetTitanSoul()
		if ( !IsValid( soul ) )
			return

		if ( !(npc in file.pilotedtitan && file.pilotedtitan[ npc ]) )
			return

		WaitTillTitanCoreCharge( npc )

		if ( !IsValid( npc ) )
			return

		if ( !IsValid( soul ) )
			return

		if ( !(npc in file.pilotedtitan && file.pilotedtitan[ npc ]) )
			return

		if ( soul.GetTitanSoulNetInt( "upgradeCount" ) > 2 )
		{
			if ( soul.GetShieldHealth() > soul.GetShieldHealthMax() * 0.1 )
			{
				thread MonitorMonarchShield( npc )
				return
			}
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
		if ( !IsValid( weapon ) )
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
	
	soul.EndSignal( "OnDestroy" )
	soul.EndSignal( "OnDeath" )
	npc.EndSignal( "OnDestroy" )
	npc.EndSignal( "OnDeath" )
	
	while( true )
	{
		SoulTitanCore_SetNextAvailableTime( soul, 0.6 )
		npc.WaitSignal( "CoreBegin" )
		npc.WaitSignal( "CoreEnd" )
	}
}


void function WaitTillTitanCoreCharge( entity titan )
{
	entity soul = titan.GetTitanSoul()
	if ( !IsValid( soul ) )
		return

	soul.EndSignal( "OnDestroy" )

	while ( IsAlive( titan ) )
	{
		if ( !TitanCoreInUse( titan ) )
			break

		WaitFrame()
	}

	while ( IsAlive( titan ) )
	{
		if ( SoulTitanCore_GetNextAvailableTime( soul ) == 1.0 )
			break

		WaitFrame()
	}
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
	if ( currentUpgradeCount == 0 )
	{
		if ( SoulHasPassive( soul, ePassives.PAS_VANGUARD_CORE1 ) )  // Arc Rounds
		{
			array<entity> weapons = GetPrimaryWeapons( owner )
			if ( weapons.len() )
			{
				entity primaryWeapon = weapons[0]
				if ( IsValid( primaryWeapon ) )
				{
					array<string> mods = primaryWeapon.GetMods()
					mods.append( "arc_rounds" )
					primaryWeapon.SetMods( mods )
					primaryWeapon.SetWeaponPrimaryClipCount( primaryWeapon.GetWeaponPrimaryClipCount() + 10 )
				}
			}
			if ( owner.IsPlayer() )
			{
				int conversationID = GetConversationIndex( "upgradeTo1" )
				Remote_CallFunction_Replay( owner, "ServerCallback_PlayTitanConversation", conversationID )
				Remote_CallFunction_NonReplay( owner, "ServerCallback_VanguardUpgradeMessage", 1 )
			}
		}
	}
	else if ( currentUpgradeCount == 1 )
	{
		if ( SoulHasPassive( soul, ePassives.PAS_VANGUARD_CORE7 ) )  // Multi-Target Missiles
		{
			if ( owner.IsPlayer() )
			{
				array<string> conversations = [ "upgradeTo3", "upgradeToFin" ]
				int conversationID = GetConversationIndex( conversations.getrandom() )
				Remote_CallFunction_Replay( owner, "ServerCallback_PlayTitanConversation", conversationID )
				Remote_CallFunction_NonReplay( owner, "ServerCallback_VanguardUpgradeMessage", 7 )
			}

			entity ordnance = owner.GetOffhandWeapon( OFFHAND_RIGHT )

			owner.TakeWeaponNow( ordnance.GetWeaponClassName() )
			owner.GiveOffhandWeapon( "mp_titanweapon_shoulder_rockets", OFFHAND_RIGHT )
		}
		else if ( SoulHasPassive( soul, ePassives.PAS_VANGUARD_CORE9 ) ) //XO-16 Battle Rifle
		{
			array<entity> weapons = GetPrimaryWeapons( owner )
			if ( weapons.len() )
			{
				entity primaryWeapon = weapons[0]
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

			if ( owner.IsPlayer() )
			{
				array<string> conversations = [ "upgradeTo3", "upgradeToFin" ]
				int conversationID = GetConversationIndex( conversations.getrandom() )
				Remote_CallFunction_Replay( owner, "ServerCallback_PlayTitanConversation", conversationID )
				Remote_CallFunction_NonReplay( owner, "ServerCallback_VanguardUpgradeMessage", 9 )
			}
		}
	}
	else if ( currentUpgradeCount == 2 )
	{
		if ( SoulHasPassive( soul, ePassives.PAS_VANGUARD_CORE8 ) ) //Superior Chassis
		{
			if ( owner.IsPlayer() )
			{
				array<string> conversations = [ "upgradeTo3", "upgradeToFin" ]
				int conversationID = GetConversationIndex( conversations.getrandom() )
				Remote_CallFunction_Replay( owner, "ServerCallback_PlayTitanConversation", conversationID )
				Remote_CallFunction_NonReplay( owner, "ServerCallback_VanguardUpgradeMessage", 8 )

				if ( !GetDoomedState( owner ) )
				{
					int missingHealth = owner.GetMaxHealth() - owner.GetHealth()
					array<string> settingMods = owner.GetPlayerSettingsMods()
					settingMods.append( "core_health_upgrade" )
					owner.SetPlayerSettingsWithMods( owner.GetPlayerSettings(), settingMods )
					owner.SetHealth( max( owner.GetMaxHealth() - missingHealth, VANGUARD_CORE8_HEALTH_AMOUNT ) )

					//Hacky Hack - Append core_health_upgrade to setFileMods so that we have a way to check that this upgrade is active.
					soul.soul.titanLoadout.setFileMods.append( "core_health_upgrade" )
				}
				else
				{
					owner.SetHealth( owner.GetMaxHealth() )
				}
			}
			else
			{
			  if ( !GetDoomedState( owner ) )
			  {
				  owner.SetMaxHealth( owner.GetMaxHealth() + VANGUARD_CORE8_HEALTH_AMOUNT )
				  owner.SetHealth( owner.GetHealth() + VANGUARD_CORE8_HEALTH_AMOUNT )
			  }
			}
			entity soul = owner.GetTitanSoul()
			soul.SetPreventCrits( true )
		}
	}
	else
	{
		if ( owner.IsPlayer() )
		{
			int conversationID = GetConversationIndex( "upgradeShieldReplenish" )
			Remote_CallFunction_Replay( owner, "ServerCallback_PlayTitanConversation", conversationID )
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
			if ( CustomTitan.EmbarkedTitanAiSet != "" )
				titan.SetAISettings( CustomTitan.EmbarkedTitanAiSet )
			if ( CustomTitan.EmbarkedTitanBehavior != "" )
				titan.SetBehaviorSelector( CustomTitan.EmbarkedTitanBehavior )
			if ( CustomTitan.Melee == "melee_titan_sword" && !CustomTitan.MeleeMods.contains( "super_charged" ) )
				thread core( titan )
			if ( CustomTitan.Weapon == "mp_titanweapon_predator_cannon" )
				titan.SetNPCMoveSpeedScale( 1.25 )
			if ( CustomTitan.Core == "mp_titancore_upgrade" )
				thread MonitorMonarchShield( titan )
		}
		else
		{
			string attackerType = GetTitanCharacterName( titan )
			switch ( attackerType )
			{
				case "ronin":
					titan.SetAISettings( "npc_titan_stryder_leadwall" )
					titan.SetBehaviorSelector( "behavior_titan_shotgun" )
					thread core( titan )
					break
				case "scorch":
					titan.SetAISettings( "npc_titan_ogre_meteor" )
					titan.SetBehaviorSelector( "behavior_titan_ogre_meteor" )
					break
				case "legion":
					titan.SetAISettings( "npc_titan_ogre_minigun" )
					titan.SetBehaviorSelector( "behavior_titan_ogre_minigun" )
					titan.SetNPCMoveSpeedScale( 1.25 )
					break
				case "ion":
					titan.SetAISettings( "npc_titan_atlas_stickybomb" )
					titan.SetBehaviorSelector( "behavior_titan_long_range" )
					break
				case "tone":
					titan.SetAISettings( "npc_titan_atlas_tracker" )
					titan.SetBehaviorSelector( "behavior_titan_long_range" )
					break
				case "vanguard":
					titan.SetAISettings( "npc_titan_atlas_vanguard" )
					titan.SetBehaviorSelector( "behavior_titan_long_range" )
					thread MonitorMonarchShield( titan )
					break
				case "northstar":
					titan.SetAISettings( "npc_titan_stryder_sniper" )
					titan.SetBehaviorSelector( "behavior_titan_sniper" )
					break
			}
		}
		titan.SetCapabilityFlag( bits_CAP_SYNCED_MELEE_ATTACK, false )
		titan.EnableNPCMoveFlag( NPCMF_PREFER_SPRINT )
		array <int> flags
		flags.extend([ NPC_NO_PAIN, NPC_NO_GESTURE_PAIN, NPC_ALLOW_PATROL, NPC_ALLOW_INVESTIGATE, NPC_IGNORE_FRIENDLY_SOUND ])
		thread OnFlagChanged( titan, flags, false, true, true )
		array <int> disableflags
		disableflags.extend([ NPC_PAIN_IN_SCRIPTED_ANIM, NPC_ALLOW_FLEE ])
		thread OnFlagChanged( titan, disableflags, true, true, true )
	}
}

void function PilotNotInTitanSet( entity titan, bool firsttime = false )
{
	if ( IsValid( titan ) )
	{
		if ( !firsttime )
		{
			if ( titan in file.CustomTitanUID && file.CustomTitanUID[ titan ] >= 0 && file.CustomTitans.len() >= file.CustomTitanUID[ titan ] )
			{
				AttritionExtendedRecode_CustomTitanStruct CustomTitan = clone file.CustomTitans[ file.CustomTitanUID[ titan ] ]
				if ( CustomTitan.TitanAiSet != "" )
					titan.SetAISettings( CustomTitan.TitanAiSet )
				if ( CustomTitan.TitanBehavior != "" )
					titan.SetBehaviorSelector( CustomTitan.TitanBehavior )
				if ( CustomTitan.Weapon == "mp_titanweapon_predator_cannon" )
					titan.SetNPCMoveSpeedScale( 1.0 )
			}
			else
			{
				string attackerType = GetTitanCharacterName( titan )
				switch ( attackerType )
				{
					case "ronin":
						titan.SetAISettings( "npc_titan_auto_stryder_leadwall" )
						break
					case "scorch":
						titan.SetAISettings( "npc_titan_auto_ogre_meteor" )
						break
					case "legion":
						titan.SetAISettings( "npc_titan_auto_ogre_minigun" )
						titan.SetNPCMoveSpeedScale( 1.0 )
						break
					case "ion":
						titan.SetAISettings( "npc_titan_auto_atlas_stickybomb" )
						break
					case "tone":
						titan.SetAISettings( "npc_titan_auto_atlas_tracker" )
						break
					case "vanguard":
						titan.SetAISettings( "npc_titan_auto_atlas_vanguard" )
						break
					case "northstar":
						titan.SetAISettings( "npc_titan_auto_stryder_sniper" )
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

		titan = soul.GetTitan()
		if ( !( titan in file.pilotedtitan && file.pilotedtitan[ titan ] ) )
			return

		entity rodeoPilot = GetRodeoPilot( titan )
		float rodeoHitTime = soul.GetLastRodeoHitTime()
		if ( rodeoHitTime != 0 && lastTickRodeoHitTime == 0 )
			beingRodeoedTime = rodeoHitTime
		else if ( rodeoHitTime == 0 )
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
				if ( titan in file.smokecount )
					smokeCount = file.smokecount[ titan ]
				
				if ( smokeCount == 0 )
				{
					smokeCount = 1
					shoulddosmoke = false
				}

				if ( !( titan in file.smokecount ) )
					file.smokecount[ titan ] <- smokeCount - 1
				else
					file.smokecount[ titan ] = smokeCount - 1

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

	while( true )
	{
		int smokeCount = 0
		if ( npc in file.smokecount )
		{
			while( file.smokecount[ npc ] == 6 )
				WaitFrame()
		}

		if ( npc in file.smokecount )
			smokeCount = file.smokecount[ npc ]

		if ( !( npc in file.smokecount ) )
			file.smokecount[ npc ] <- smokeCount + 1
		else
			file.smokecount[ npc ] = smokeCount + 1

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

	vector eyeAngles = <0.0, ent.EyeAngles().y, 0.0>
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

	smokescreen.fxOffsets = [ < -fxOffset, 0.0, 20.0>,
							  <0.0, fxOffset, 20.0>,
							  <0.0, -fxOffset, 20.0>,
							  <0.0, 0.0, fxHeightOffset>,
							  < -fxOffset, 0.0, fxHeightOffset> ]

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
	spawnpoint.s.lastUsedTime <- Time()
	spawnpoint.e.spawnTime = Time()
	ToggleSpawnpointUse( spawnpoint, true )
	vector pos = spawnpoint.GetOrigin()
	vector angles = spawnpoint.GetAngles()
	entity pod = CreateDropPod( pos, angles )
	entity poddoor = DropPodDoor( pod )
	AttritionExtendedRecode_CustomTitanStruct CustomTitan = AttritionExtendedRecode_CustomTitanEmpty()
	if ( RandomInt( 100 ) < int( GetCurrentPlaylistVarFloat( "ct_titan_replace_chance", 0.20 ) * 100 ) && file.CustomTitans.len() )
		CustomTitan = clone file.CustomTitans.getrandom()
	array<entity> npcs
	for ( int i = 0; i < 1; i++ )
	{
		entity entitynpc = CreateEntity( "npc_pilot_elite" )
		entitynpc.SetOrigin( pos )
		DispatchSpawn( entitynpc )
		file.isattritionextendedrecodeentity[ entitynpc ] <- true
		SetTeam( entitynpc, team )
		thread RandomPilotWeapon( entitynpc )
		entitynpc.kv.grenadeWeaponName = file.pilotgrenades.getrandom()
		entitynpc.kv.AccuracyMultiplier = 2.5
		entitynpc.kv.WeaponProficiency = eWeaponProficiency.VERYGOOD
		thread PilotSpeedFlagsHPAndBehavior( entitynpc )
		thread entitynpc.SetModel( file.pilotmodels.getrandom() )

		entitynpc.SetParent( pod, "ATTACH", true )
		entitynpc.kv.VisibilityFlags = ~ENTITY_VISIBLE_TO_EVERYONE
		entitynpc.SetInvulnerable()
		entitynpc.EnableNPCFlag( NPC_IGNORE_ALL )
		NPC_NoTarget( entitynpc )
		if ( CustomTitan.AllowedWithPilot )
			entitynpc.SetTitle( "[CT] " + CustomTitan.Title )
		else
			entitynpc.SetTitle( "Pilot" )
		npcs.append( entitynpc )
	}

	thread AttritionExtendedRecode_NpcPilotCallsInAndEmbarksTitan( npcs.getrandom(), pos, angles, CustomTitan )
	if ( team in file.spawnedpilotedtitans )
		file.spawnedpilotedtitans[ team ] <- file.spawnedpilotedtitans[ team ] + 1
	else
		file.spawnedpilotedtitans[ team ] <- 1
	waitthread LaunchAnimDropPod( pod, "pod_testpath", pos, angles )

	string squadName = MakeSquadName( team, UniqueString( "" ) )

	foreach ( entity pilot in npcs )
		pilot.kv.VisibilityFlags = ENTITY_VISIBLE_TO_EVERYONE
	foreach ( entity pilot in npcs )
		thread PilotMiniMap( pilot )
	DropPodOpenDoorModded( pod, poddoor )
	thread ActivateFireteamDropPodModded( pod, npcs, poddoor )
	if ( IsValid( spawnpoint ) )
		ToggleSpawnpointUse( spawnpoint, false )
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
	spawnpoint.s.lastUsedTime <- Time()
	spawnpoint.e.spawnTime = Time()
	ToggleSpawnpointUse( spawnpoint, true )
	vector origin = spawnpoint.GetOrigin()
	vector angles = spawnpoint.GetAngles()
	entity pilot = CreateEntity( "npc_pilot_elite" )
	pilot.SetOrigin( origin )
	DispatchSpawn( pilot )
	file.isattritionextendedrecodeentity[ pilot ] <- true
	pilot.SetInvulnerable()
	thread RandomPilotWeapon( pilot )
	pilot.kv.grenadeWeaponName = file.pilotgrenades.getrandom()
	pilot.kv.AccuracyMultiplier = 2.5
	pilot.kv.WeaponProficiency = eWeaponProficiency.VERYGOOD
	pilot.SetModel( file.pilotmodels.getrandom() )
	pilot.EnableNPCFlag( NPC_IGNORE_ALL )
	pilot.kv.VisibilityFlags = ~ENTITY_VISIBLE_TO_EVERYONE
	array<string> settingsArray = GetAllowedTitanAISettings()
	bool usedomeshieldwarpfall = false

	settingsArray.extend( [ "npc_titan_auto_atlas_ion_prime", "npc_titan_auto_ogre_scorch_prime", "npc_titan_auto_stryder_northstar_prime", "npc_titan_auto_stryder_ronin_prime", "npc_titan_auto_atlas_tone_prime", "npc_titan_auto_ogre_legion_prime" ] )
	string titanSettings = settingsArray.getrandom()
	if ( GetMapName().find( "mp_lf_" ) != null || GetMapName() == "mp_grave" )
	{
		usedomeshieldwarpfall = true
		NPCPrespawnWarpfallSequenceModded( titanSettings, origin, angles )
	}
	string setFile = GetRandomTitanSetFile( titanSettings )
	entity titan
	AttritionExtendedRecode_CustomTitanStruct CustomTitan = AttritionExtendedRecode_CustomTitanEmpty()
	if ( RandomInt( 100 ) < int( GetCurrentPlaylistVarFloat( "ct_titan_replace_chance", 0.20 ) * 100 ) && file.CustomTitans.len() )
		CustomTitan = clone file.CustomTitans.getrandom()
	if ( ( !withpilot && CustomTitan.AllowedWithoutPilot ) || ( withpilot && CustomTitan.AllowedWithPilot ) )
	{
		titan = CreateNPCTitan( CustomTitan.TitanSetFile, team, origin, angles )
		SetSpawnOption_AISettings( titan, CustomTitan.EmbarkedTitanAiSet )
	}
	else
	{
		titan = CreateNPCTitan( setFile, team, origin, angles )
		SetSpawnOption_AISettings( titan, titanSettings )
	}
	DispatchSpawn( titan )

	file.isattritionextendedrecodeentity[ titan ] <- true
	if ( withpilot )
		AttritionExtendedRecode_NpcPilotBecomesTitan( pilot, titan )
	else
		pilot.Destroy()

	if ( ( !withpilot && CustomTitan.AllowedWithoutPilot ) || ( withpilot && CustomTitan.AllowedWithPilot ) )
	{
		titan.SetTitle( "[CT] " + CustomTitan.Title )
		file.CustomTitanUID[ titan ] <- CustomTitan.UID
		if ( CustomTitan.HP > 0 )
		{
			titan.SetMaxHealth( CustomTitan.HP )
			titan.SetHealth( titan.GetMaxHealth() )
		}
	}

	if ( ( CustomTitan.Camo != -1 && CustomTitan.Skin != -1 ) && ( ( !withpilot && CustomTitan.AllowedWithoutPilot ) || ( withpilot && CustomTitan.AllowedWithPilot ) ) )
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
	if ( team in file.spawnedunpilotedtitans )
		file.spawnedunpilotedtitans[ team ] <- file.spawnedunpilotedtitans[ team ] + 1
	else
		file.spawnedunpilotedtitans[ team ] <- 1
	thread TillDeath( titan, false )

	SetStanceKneel( titan.GetTitanSoul() )
	UpdateEnemyMemoryFromTeammates( titan )
	if ( !usedomeshieldwarpfall )
	{
		NPCTitanHotdrops( titan, true )
	}
	else
	{
		NPCTitanHotdrops( titan, true, "at_hotdrop_drop_2knee_turbo_upgraded" )
	}
	if ( IsValid( spawnpoint ) )
		ToggleSpawnpointUse( spawnpoint, false )
}

void function TillDeath( entity titan, bool withpilot )
{
	int team = titan.GetTeam()
	while ( true )
	{
		if ( !IsValid( titan ) )
		{
			if ( withpilot && team in file.spawnedpilotedtitans )
				file.spawnedpilotedtitans[ team ] <- file.spawnedpilotedtitans[ team ] - 1
			else if ( !withpilot && team in file.spawnedunpilotedtitans )
				file.spawnedunpilotedtitans[ team ] <- file.spawnedunpilotedtitans[ team ] - 1

			return
		}
		else if ( team != titan.GetTeam() )
		{
			if ( withpilot && team in file.spawnedpilotedtitans )
				file.spawnedpilotedtitans[ team ] <- file.spawnedpilotedtitans[ team ] - 1
			else if ( !withpilot && team in file.spawnedunpilotedtitans )
				file.spawnedunpilotedtitans[ team ] <- file.spawnedunpilotedtitans[ team ] - 1

			team = titan.GetTeam()
			if ( withpilot && team in file.spawnedpilotedtitans )
				file.spawnedpilotedtitans[ team ] <- file.spawnedpilotedtitans[ team ] + 1
			else if ( withpilot )
				file.spawnedpilotedtitans[ team ] <- 1
			else if ( !withpilot && team in file.spawnedunpilotedtitans )
				file.spawnedunpilotedtitans[ team ] <- file.spawnedunpilotedtitans[ team ] + 1
			else if ( !withpilot )
				file.spawnedunpilotedtitans[ team ] <- 1
		}
		WaitFrame()
	}
}

entity function GetSpawnpoint( int team )
{
	array<entity> spawns = SpawnPoints_GetTitan()
	array<entity> betterspawns
	if ( !spawns.len() )
		return null

	foreach ( entity spawnpoint in spawns )
		if ( IsSpawnpointValid( spawnpoint, team ) )
			betterspawns.append( spawnpoint )

	if ( !betterspawns.len() )
		return null
	else
		return betterspawns.getrandom()
}

bool function IsSpawnpointValid( entity spawnpoint, int team )
{
	if ( !spawnpoint.HasKey( "ignoreGamemode" ) || spawnpoint.HasKey( "ignoreGamemode" ) && spawnpoint.kv.ignoreGamemode == "0" )
	{
		if ( GetSpawnpointGamemodeOverride() != "" )
		{
			string gamemodeKey = "gamemode_" + GetSpawnpointGamemodeOverride()
			if ( spawnpoint.HasKey( gamemodeKey ) && ( spawnpoint.kv[ gamemodeKey ] == "0" || spawnpoint.kv[ gamemodeKey ] == "" ) )
				return false
		}
		else if ( GameModeRemove( spawnpoint ) )
			return false
	}

	if ( spawnpoint.IsOccupied() || ( "inuse" in spawnpoint.s && spawnpoint.s.inuse ) || ( "lastUsedTime" in spawnpoint.s && Time() - spawnpoint.s.lastUsedTime <= 10.0 ) || ( spawnpoint.e.spawnTime != 0 && Time() - spawnpoint.e.spawnTime <= 10.0 ) || spawnpoint.e.spawnPointInUse )
		return false

	if ( SpawnPointInNoSpawnArea( spawnpoint.GetOrigin(), team ) )
		return false

	array< entity > enemyTitans = GetTitanArrayOfEnemies( team )
	if ( GetConVarBool( "spawnpoint_avoid_npc_titan_sight" ) )
	{
		foreach ( titan in enemyTitans )
		{
			if ( IsAlive( titan ) && titan.IsNPC() && titan.CanSee( spawnpoint ) )
				return false
		}
	}

	return !spawnpoint.IsVisibleToEnemies( team )
}

void function ToggleSpawnpointUse( entity spawnpoint, bool value )
{
	spawnpoint.s.inuse <- value
	spawnpoint.e.spawnPointInUse = value
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

void function ActivateFireteamDropPodModded( entity pod, array<entity> guys, entity poddoor )
{
	if ( guys.len() >= 1 )
	{
		SetAnim( guys[0], "drop_pod_exit_anim", "pt_dp_exit_a" )
		SetAnim( guys[0], "drop_pod_idle_anim", "pt_dp_idle_a" )
	}

	if ( guys.len() >= 2 )
	{
		SetAnim( guys[1], "drop_pod_exit_anim", "pt_dp_exit_b" )
		SetAnim( guys[1], "drop_pod_idle_anim", "pt_dp_idle_b" )
	}

	if ( guys.len() >= 3 )
	{
		SetAnim( guys[2], "drop_pod_exit_anim", "pt_dp_exit_c" )
		SetAnim( guys[2], "drop_pod_idle_anim", "pt_dp_idle_c" )
	}

	if ( guys.len() >= 4 )
	{
		SetAnim( guys[3], "drop_pod_exit_anim", "pt_dp_exit_d" )
		SetAnim( guys[3], "drop_pod_idle_anim", "pt_dp_idle_d" )
	}

	foreach ( guy in guys )
	{
		if ( IsAlive( guy ) )
		{
			guy.MakeVisible()
			entity weapon = guy.GetActiveWeapon()
			if ( IsValid( weapon ) )
				weapon.MakeVisible()

			thread GuyHangsInPod( guy, pod, poddoor )
		}
	}
}

void function GuyHangsInPod( entity guy, entity pod, entity poddoor )
{
	guy.EndSignal( "OnDeath" )
	guy.EndSignal( "OnDestroy" )

	OnThreadEnd(
		function () : ( pod, poddoor )
		{
			thread DestroyPod( pod, poddoor )
		}
	)

	string exitAnim

	guy.SetParent( pod, "ATTACH", false )

	exitAnim = expect string ( GetAnim( guy, "drop_pod_exit_anim" ) )
	bool exitAnimExists = guy.LookupSequence( exitAnim ) != -1
	if ( exitAnimExists )
		guy.Anim_ScriptedPlay( exitAnim )

	guy.ClearParent()

	if ( exitAnimExists )
		WaittillAnimDone( guy )
	guy.Signal( "npc_deployed" )
}

function NPCTitanHotdropsWarpfall( entity titan, bool standImmediately, string titanfallAnim = "at_hotdrop_drop_2knee_turbo_upgraded" )
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

	#if MP
	TryAnnounceTitanfallWarningToEnemyTeam( titan.GetTeam(), origin )
	#endif

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

	while( titan.s.bubbleShieldStatus == 1 )
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

	#if SP
		thread TemporarilyDisableTitanfallAroundRadius( spawnOrigin, 72, WARPFALL_SOUND_DELAY + WARPFALL_FX_DELAY )
	#endif

	fakeTitan.Kill_Deprecated_UseDestroyInstead()

	EmitSoundAtPosition( TEAM_UNASSIGNED, spawnOrigin, "Titan_3P_Warpfall_CallIn" )

	wait WARPFALL_SOUND_DELAY + 2.5

	EmitSoundAtPosition( TEAM_UNASSIGNED, spawnOrigin, "Titan_3P_Warpfall_Start" )

	PlayFX( TURBO_WARP_FX, warpAttach.position + Vector(0,0,-104), warpAttach.angle )

	wait WARPFALL_FX_DELAY
}

entity function AttritionExtendedRecode_NpcPilotCallsInTitan( entity pilot, vector origin, vector angles, AttritionExtendedRecode_CustomTitanStruct CustomTitan )
{
	Assert( !pilot.IsTitan() )
	Assert( IsAlive( pilot ) )

	array<string> settingsArray = GetAllowedTitanAISettings()
	bool usedomeshieldwarpfall = false

	settingsArray.extend([ "npc_titan_auto_atlas_ion_prime", "npc_titan_auto_ogre_scorch_prime", "npc_titan_auto_stryder_northstar_prime", "npc_titan_auto_stryder_ronin_prime", "npc_titan_auto_atlas_tone_prime", "npc_titan_auto_ogre_legion_prime" ])
	string titanSettings = settingsArray.getrandom()
	int team = pilot.GetTeam()
	string pilottitle = pilot.GetTitle()
	if ( GetMapName().find( "mp_lf_") != null || GetMapName() == "mp_grave" )
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
	{
		titan = CreateNPCTitan( CustomTitan.TitanSetFile, team, origin, angles )
		SetSpawnOption_AISettings( titan, CustomTitan.TitanAiSet )
	}
	DispatchSpawn( titan )
	if ( CustomTitan.AllowedWithPilot )
	{
		file.CustomTitanUID[ titan ] <- CustomTitan.UID
		if ( CustomTitan.HP > 0 )
		{
			titan.SetMaxHealth( CustomTitan.HP )
			titan.SetHealth( titan.GetMaxHealth() )
		}
	}
	if ( IsValid( pilot ) && IsAlive( pilot ) )
		titan.SetTitle( pilot.GetTitle() + "'s Auto-Titan" )
	else
		titan.SetTitle( pilottitle + "'s Auto-Titan" )
	file.isattritionextendedrecodeentity[ titan ] <- true
	if ( !usedomeshieldwarpfall )
		thread NPCTitanHotdrops( titan, false )
	else
		thread NPCTitanHotdrops( titan, false, "at_hotdrop_drop_2knee_turbo_upgraded" )
	if ( (CustomTitan.Camo == -1 && CustomTitan.Skin == -1) || !CustomTitan.AllowedWithPilot )
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
	thread ShouldTitanStandOrKneel( titan, pilot )
	thread TitanStandAfterDropIn( titan, pilot )

	SetStanceKneel( titan.GetTitanSoul() )
	thread TillDeath( titan, true )
	UpdateEnemyMemoryFromTeammates( titan )

	return titan
}

string function GetRandomTitanSetFile( string titanSettings )
{
	string SetFile = ""
	if ( titanSettings == "npc_titan_auto_atlas_stickybomb" )
	{
		SetFile = "titan_atlas_stickybomb"
	}
	if ( titanSettings == "npc_titan_auto_atlas_ion_prime" )
	{
		SetFile = "titan_atlas_ion_prime"
	}
	if ( titanSettings == "npc_titan_auto_ogre_meteor" )
	{
		SetFile = "titan_ogre_meteor"
	}
	if ( titanSettings == "npc_titan_auto_ogre_scorch_prime" )
	{
		SetFile = "titan_ogre_scorch_prime"
	}
	if ( titanSettings == "titan_stryder_sniper" )
	{
		SetFile = "npc_titan_auto_stryder_sniper"
	}
	if ( titanSettings == "npc_titan_auto_stryder_northstar_prime" )
	{
		SetFile = "titan_stryder_northstar_prime"
	}
	if ( titanSettings == "npc_titan_auto_stryder_leadwall" )
	{
		SetFile = "titan_stryder_leadwall"
	}
	if ( titanSettings == "npc_titan_auto_stryder_ronin_prime" )
	{
		SetFile = "titan_stryder_ronin_prime"
	}
	if ( titanSettings == "npc_titan_auto_atlas_tracker" )
	{
		SetFile = "titan_atlas_tracker"
	}
	if ( titanSettings == "npc_titan_auto_atlas_tone_prime" )
	{
		SetFile = "titan_atlas_tone_prime"
	}
	if ( titanSettings == "npc_titan_auto_ogre_minigun" )
	{
		SetFile = "titan_ogre_minigun"
	}
	if ( titanSettings == "npc_titan_auto_ogre_legion_prime" )
	{
		SetFile = "titan_ogre_legion_prime"
	}
	if ( titanSettings == "npc_titan_auto_atlas_vanguard" )
	{
		SetFile = "titan_atlas_vanguard"
	}
	return SetFile
}

void function AttritionExtendedRecode_NpcPilotBecomesTitan( entity pilot, entity titan )
{
	Assert( IsAlive( pilot ) )
	Assert( IsAlive( titan ) )
	Assert( IsGrunt( pilot ) || IsPilotElite( pilot ) )
	Assert( titan.IsTitan() )

	array <entity> weapons = pilot.GetMainWeapons()
	array <string> weaponNames
	foreach( entity weapon in weapons )
	{
		weaponNames.append( weapon.GetWeaponClassName() )
	}
	entity titanSoul = titan.GetTitanSoul()

	file.pilotedtitan[ titan ] <- true
	file.weapons[ titan ] <- weaponNames
	file.model[ titan ] <- pilot.GetModelName()
	file.grenade[ titan ] <- expect string( pilot.kv.grenadeWeaponName )

	if ( titan in file.CustomTitanUID && file.CustomTitanUID[ titan ] >= 0 )
		titan.SetTitle( pilot.GetTitle() )
	else
	{
		string attackerType = GetTitanCharacterName( titan )
		switch ( attackerType )
		{
			case "ronin":
				titan.SetTitle( "Ronin" )
				break
			case "scorch":
				titan.SetTitle( "Scorch" )
				break
			case "legion":
				titan.SetTitle( "Legion" )
				break
			case "ion":
				titan.SetTitle( "Ion" )
				break
			case "tone":
				titan.SetTitle( "Tone" )
				break
			case "vanguard":
				titan.SetTitle( "Monarch" )
				break
			case "northstar":
				titan.SetTitle( "Northstar" )
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

		if ( titan in file.CustomTitanUID && CustomTitans.UID == file.CustomTitanUID[ titan ] )
		{
			if ( CustomTitans.Weapon != "" )
				titan.GiveWeapon( CustomTitans.Weapon )
			if ( CustomTitans.Weapon != "" && CustomTitans.WeaponMods.len() )
			{
				entity weapon = titan.GetActiveWeapon()
				if ( IsValid( weapon ) )
				{
					array<string> mods = weapon.GetMods()
					mods.extend( CustomTitans.WeaponMods )
					weapon.SetMods( mods )
				}
			}

			if ( CustomTitans.Ordnance != "" )
				titan.GiveOffhandWeapon( CustomTitans.Ordnance, OFFHAND_ORDNANCE )
			if ( CustomTitans.Ordnance != "" && CustomTitans.OrdnanceMods.len() )
			{
				entity weapon = titan.GetOffhandWeapon( OFFHAND_ORDNANCE )
				if ( IsValid( weapon ) )
				{
					array<string> mods = weapon.GetMods()
					mods.extend( CustomTitans.OrdnanceMods )
					weapon.SetMods( mods )
				}
			}

			if ( CustomTitans.Utility != "" )
				titan.GiveOffhandWeapon( CustomTitans.Utility, OFFHAND_EQUIPMENT )
			if ( CustomTitans.Utility != "" && CustomTitans.UtilityMods.len() )
			{
				entity weapon = titan.GetOffhandWeapon( OFFHAND_EQUIPMENT )
				if ( IsValid( weapon ) )
				{
					array<string> mods = weapon.GetMods()
					mods.extend( CustomTitans.UtilityMods )
					weapon.SetMods( mods )
				}
			}

			if ( CustomTitans.Tactical != "" )
				titan.GiveOffhandWeapon( CustomTitans.Tactical, OFFHAND_ANTIRODEO )
			if ( CustomTitans.Tactical != "" && CustomTitans.TacticalMods.len() )
			{
				entity weapon = titan.GetOffhandWeapon( OFFHAND_ANTIRODEO )
				if ( IsValid( weapon ) )
				{
					array<string> mods = weapon.GetMods()
					mods.extend( CustomTitans.TacticalMods )
					weapon.SetMods( mods )
				}
			}

			if ( CustomTitans.Core != "" )
			{
				titan.GiveOffhandWeapon( CustomTitans.Core, OFFHAND_SPECIAL )
				if ( CustomTitans.Core == "mp_titancore_upgrade" )
					thread MonarchUpgrades( titan )
			}
			if ( CustomTitans.Core != "" && CustomTitans.CoreMods.len() )
			{
				entity weapon = titan.GetOffhandWeapon( OFFHAND_SPECIAL )
				if ( IsValid( weapon ) )
				{
					array<string> mods = weapon.GetMods()
					mods.extend( CustomTitans.CoreMods )
					weapon.SetMods( mods )
				}
			}

			if ( CustomTitans.Melee != "" )
				titan.GiveOffhandWeapon( CustomTitans.Melee, OFFHAND_MELEE )
			if ( CustomTitans.Melee != "" && CustomTitans.MeleeMods.len() )
			{
				entity weapon = titan.GetOffhandWeapon( OFFHAND_MELEE )
				if ( IsValid( weapon ) )
				{
					array<string> mods = weapon.GetMods()
					mods.extend( CustomTitans.MeleeMods )
					weapon.SetMods( mods )
				}
			}

			entity soul = titan.GetTitanSoul()
			if ( IsValid( soul ) )
			{
				if ( CustomTitans.TitanExecutionRef != "" )
					soul.soul.titanLoadout.titanExecution = CustomTitans.TitanExecutionRef
				if ( CustomTitans.Passives.len() )
					foreach( int passive in CustomTitans.Passives )
						GivePassive( soul, passive )
			}
		}
		else
		{
			string attackerType = GetTitanCharacterName( titan )
			switch ( attackerType )
			{
				case "ronin":
					titan.GiveWeapon( "mp_titanweapon_leadwall" )
					titan.GiveOffhandWeapon( "mp_titanweapon_arc_wave", OFFHAND_ORDNANCE )
					titan.GiveOffhandWeapon( "mp_titancore_shift_core", OFFHAND_EQUIPMENT )
					titan.GiveOffhandWeapon( "mp_titanability_phase_dash", OFFHAND_ANTIRODEO )
					titan.GiveOffhandWeapon( "mp_ability_swordblock", OFFHAND_SPECIAL )
					titan.GiveOffhandWeapon( "melee_titan_sword", OFFHAND_MELEE )
					entity soul = titan.GetTitanSoul()
					if ( IsValid( soul ) )
					{
						soul.soul.titanLoadout.titanExecution = "execution_random_3"
					}
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
					{
						soul.soul.titanLoadout.titanExecution = "execution_random_1"
					}
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
					{
						soul.soul.titanLoadout.titanExecution = "execution_random_5"
					}
					break

				case "ion":
					titan.GiveWeapon( "mp_titanweapon_particle_accelerator" )
					titan.GiveOffhandWeapon( "mp_titanweapon_laser_lite", OFFHAND_ORDNANCE )
					titan.GiveOffhandWeapon( "mp_titancore_laser_cannon", OFFHAND_EQUIPMENT )
					titan.GiveOffhandWeapon( "mp_titanability_laser_trip", OFFHAND_ANTIRODEO )
					titan.GiveOffhandWeapon( "mp_titanweapon_vortex_shield", OFFHAND_SPECIAL )
					titan.GiveOffhandWeapon( "melee_titan_punch", OFFHAND_MELEE )
					entity soul = titan.GetTitanSoul()
					if ( IsValid( soul ) )
					{
						soul.soul.titanLoadout.titanExecution = "execution_ion"
					}
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
					{
						soul.soul.titanLoadout.titanExecution = "execution_random_4"
					}
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
						if ( RandomInt( 100 ) < 50 )
						{
							GivePassive( soul, ePassives.PAS_VANGUARD_COREMETER )
							soul.soul.titanLoadout.titanExecution = "execution_vanguard_kit"
						}
						if ( !SoulHasPassive( soul, ePassives.PAS_VANGUARD_COREMETER ) && RandomInt( 100 ) < 50 )
							GivePassive( soul, ePassives.PAS_VANGUARD_DOOM )
					}
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
					{
						soul.soul.titanLoadout.titanExecution = "execution_random_2"
					}
					break
			}
		}

		if ( GetCurrentPlaylistVarInt( "aegis_upgrades", 0 ) == 1 )
		{
			titan.SetMaxHealth( titan.GetMaxHealth() + 2500 )
			titan.SetHealth( titan.GetMaxHealth() )
		}

		bool hasnucleareject = false
		if ( RandomInt( 100 ) < 25 )
		{
			hasnucleareject = true
			NPC_SetNuclearPayload( titan )
		}

		if ( !hasnucleareject && RandomInt( 100 ) < 15 )
			AttritionExtendedRecode_GiveTitanAutoEject( titan )
	}
}

entity function AttritionExtendedRecode_NpcPilotCallsInAndEmbarksTitan( entity pilot, vector origin, vector angles, AttritionExtendedRecode_CustomTitanStruct CustomTitan )
{
	pilot.EndSignal( "OnDestroy" )
	pilot.EndSignal( "OnDeath" )
	wait 2.5
	entity titan = AttritionExtendedRecode_NpcPilotCallsInTitan( pilot, origin, angles, CustomTitan )
	thread AttritionExtendedRecode_NpcPilotRunsToAndEmbarksFallingTitan( pilot, titan )

	return titan
}

function AttritionExtendedRecode_NpcPilotRunsToAndEmbarksFallingTitan( entity pilot, entity titan )
{
	waitthread WaitTillHotDropComplete( titan )

	if( !IsValid( titan ) )
		return

	if ( !IsAlive( titan ) )
		return

	if( !IsValid( pilot ) )
		return

	if( !IsAlive( pilot ) )
		return

	pilot.EndSignal( "OnDestroy" )
	pilot.EndSignal( "OnDeath" )

	NPCFollowsNPCModded( pilot, titan )

	waitthread AttritionExtendedRecode_NpcPilotEmbarksTitan( pilot, titan )
}

void function ShouldTitanStandOrKneel( entity titan, entity pilot )
{
	titan.EndSignal( "OnDestroy" )
	titan.EndSignal( "OnDeath" )
	titan.WaitSignal( "TitanHotDropComplete" )
	if ( !IsValid( pilot ) )
		thread TitanStandUp( titan )
	if ( !IsAlive( pilot ) )
		thread TitanStandUp( titan )
	pilot.EndSignal( "OnDestroy" )
	pilot.EndSignal( "OnDeath" )
	OnThreadEnd(
		function () : ( titan )
		{
			if ( IsValid( titan ) )
			{
				if ( IsAlive( titan ) )
				{
					if ( !( titan in file.pilotedtitan && file.pilotedtitan[ titan ]) && !(titan in file.titanstanding && file.titanstanding[titan]) )
						thread TitanStandUp( titan )
				}
			}
		}
	)
	WaitForever()
}

void function TitanStandAfterDropIn( entity titan, entity pilot )
{
	wait 23
	if ( IsValid( titan ) && IsValid( pilot ) )
	{
		if ( IsAlive( titan ) && IsAlive( pilot ) && ( !( titan in file.titanisbeingembarked ) || file.titanisbeingembarked[titan] == false ) )
		{
			file.titanstanding[titan] <- true
			thread TitanStandUp( titan )
		}
	}
}

function AttritionExtendedRecode_NpcPilotEmbarksTitan( entity pilot, entity titan )
{
	Assert( IsAlive( pilot ) )
	Assert( IsAlive( titan ) )
	Assert( !pilot.IsTitan() )
	Assert( titan.IsTitan() )

	titan.EndSignal( "OnDestroy" )
	titan.EndSignal( "OnDeath" )
	pilot.EndSignal( "OnDestroy" )
	pilot.EndSignal( "OnDeath" )

	string titanSubClass = GetSoulTitanSubClass( titan.GetTitanSoul() )

	while ( FindBestEmbark( pilot, titan ) == null )
		WaitFrame()

	table embarkSet = expect table ( FindBestEmbark( pilot, titan ) )

	FirstPersonSequenceStruct sequence
	sequence.attachment = "hijack"
	sequence.useAnimatedRefAttachment = expect bool ( embarkSet.action.useAnimatedRefAttachment )
	sequence.blendTime = 0.5
	sequence.thirdPersonAnim = GetAnimFromAlias( titanSubClass, embarkSet.animSet.thirdPersonKneelingAlias )
	string titanAnim = expect string ( embarkSet.animSet.titanKneelingAnim )
	if ( titan.GetTitanSoul().GetStance() > STANCE_STANDING )
	{
		sequence.thirdPersonAnim = GetAnimFromAlias( titanSubClass, embarkSet.animSet.thirdPersonStandingAlias )
		titanAnim = expect string ( embarkSet.animSet.titanStandingAnim )
	}

	if ( IsCloaked( pilot ) )
		pilot.SetCloakDuration( 0, 0, 1.5 )

	pilot.SetInvulnerable()
	pilot.Anim_Stop()
	thread FirstPersonSequence( sequence, pilot, titan )
	array <int> nopain
	nopain.append( NPC_NO_PAIN )
	thread OnFlagChanged( titan, nopain, false, true, false )
	pilot.EnableNPCFlag( NPC_IGNORE_ALL )
	file.titanisbeingembarked[ titan ] <- true
	waitthread PlayAnimGravity( titan, titanAnim )
	SetStanceStand( titan.GetTitanSoul() )
	AttritionExtendedRecode_NpcPilotBecomesTitan( pilot, titan )
}

void function NPCPilotEjectingAnimation( entity pilot )
{
	pilot.EndSignal( "OnDestroy" )
	pilot.EndSignal( "OnDeath" )
	
	if ( !pilot.ContextAction_IsBusy() )
		pilot.ContextAction_SetBusy()

	pilot.Anim_ScriptedPlayActivityByName( "ACT_FALL", true, 0.2 )
	pilot.SetNPCPriorityOverride( 10 )

	OnThreadEnd
	(
		function(): ( pilot )
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
	float failSafeTime = Time() + 6.0
	while( Time() < failSafeTime )
	{
		if ( pilot.IsOnGround() && pilot.GetVelocity().z <= 0 )
			break
		
		WaitFrame()
	}
}

const TITAN_PLAYEREJECT_DELAY = 0.4
const TITAN_PLAYEREJECT_DURATION = 0.8
const MAX_EJECT_LATENCY_COMPENSATION = 0.4

bool function ShouldCalloutEjection( entity player, vector titanOrigin, entity titan )
{
	if ( DistanceSqr( titanOrigin, titan.GetOrigin() ) < 2000 * 2000 )
		return true

	// have they hit each other recently? To catch LTS sniper war ejections
	if ( WasRecentlyHitByEntity( player, titan, 6.0 ) )
		return true

	if ( WasRecentlyHitByEntity( titan, player, 6.0 ) )
		return true

	return false
}

void function TitanEjectVO( entity player, vector titanOrigin )
{
	array<entity> titans = GetTitanArray()
	int team = player.GetTeam()
	int voEnum

	foreach ( titan in titans )
	{
		if ( !titan.IsPlayer() )
			continue
		if ( titan == player )
			continue

		if ( team == titan.GetTeam() )
		{
			if ( DistanceSqr( titanOrigin, titan.GetOrigin() ) > 2000 * 2000 )
				return

			voEnum = eTitanVO.FRIENDLY_EJECTED
		}
		else
		{
			if ( !ShouldCalloutEjection( player, titanOrigin, titan ) )
				return

			voEnum = eTitanVO.ENEMY_EJECTED
		}

		Remote_CallFunction_Replay( titan, "SCB_TitanDialogue", voEnum )
	}
}

TitanEjectDamage function GetSoulEjectDamageOverride( entity soul )
{
	TitanEjectDamage defaultStruct
		return defaultStruct
}

void function ClearEjectInvulnerability( entity player )
{
	if ( !IsValid( player ) )
		return

	player.EndSignal( "OnDeath" )

	OnThreadEnd(
		function () : (player)
		{
			if ( IsValid( player ) )
				player.ClearInvulnerable()
		}
	)

	wait 0.35
}

void function LookAtEachOther( entity rider, entity player )
{
	rider.EndSignal( "OnDeath" )
	player.EndSignal( "OnDeath" )

	float endTime = Time() + 0.45

	for ( ;; )
	{
		vector org1 = rider.GetOrigin()
		vector org2 = player.GetOrigin()
		vector vec1 = org2 - org1
		vector angles1 = VectorToAngles( vec1 )
		vector vec2 = org1 - org2
		vector angles2 = VectorToAngles( vec2 )

		angles1.x = 0
		angles2.x = 0
		if ( rider.GetParent() == null )
			rider.SetAngles( angles1 )
		if ( player.GetParent() == null )
			player.SetAngles( angles2 )

		if ( Time() >= endTime )
			return

		WaitFrame()
	}
}

void function EjectFlightTracker( entity player )
{
	player.EndSignal( "OnDeath" )
	player.EndSignal( "EjectLand" )
	player.EndSignal( "RodeoStarted" )

	OnThreadEnd(
		function () : (player)
		{
			player.p.pilotEjecting = false
			player.p.pilotEjectEndTime = Time()
		}
	)

	player.p.pilotEjecting = true
	player.p.pilotEjectStartTime = Time()

	wait 0.1
	for ( ;; )
	{
		if ( player.IsOnGround() )
			player.Signal("EjectLand")

		wait 0.1
	}
}

void function TitanNonSolidTemp( entity titan )
{
	if ( !EntityInSolid( titan ) )
		return

	string collisionGroup = expect string ( titan.kv.CollisionGroup )

	// Blocks bullets, projectiles but not players and not AI
	titan.kv.CollisionGroup = TRACE_COLLISION_GROUP_BLOCK_WEAPONS

	titan.EndSignal( "OnDeath" )

	while( EntityInSolid( titan ) )
	{
		wait 0.1
	}

	titan.kv.collisionGroup = collisionGroup
}

TitanNukeDamage function GetSoulNukeDamageOverride( entity soul )
{
	TitanNukeDamage defaultStruct
		return defaultStruct
}

void function ClearNuclearBlueSunEffect( e )
{
	foreach ( fx in e.nukeFX )
	{
		if ( IsValid( fx ) )
			fx.Kill_Deprecated_UseDestroyInstead()
	}
	e.nukeFX.clear()
	e.needToClearNukeFX = false
}

void function DelayedCleanUpNukeFX( entity titan, array<entity> nukeFXToCleanUp )
{
	titan.WaitSignal( "OnDestroy" )
	foreach ( entity nukeFX in nukeFXToCleanUp )
	{
		if ( IsValid( nukeFX ) )
			EffectStop( nukeFX )
	}
}

void function NuclearCoreExplosionChainReaction( vector origin, e )
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
			// npc nuke: the idea is to be the same as the regular nuke - but with less explosion calls
			explosions = 3
			innerRadius = 350
			time = 1.5 //1 is the regular nuke time - but we won't be adding an extra explosion and we want 3 explosions over 1s. This will mathematically give us that.
			IsNPC = true

			float fraction = 10.0 / explosions //10 is the regular nuke number
			heavyArmorDamage = heavyArmorDamage * fraction
			normalDamage = normalDamage * fraction
			break

		case 3:
			// super nuke: PAS_NUCLEAR_CORE + PAS_BUILD_UP_NUCLEAR_CORE
			explosions = 20
			innerRadius = 350
			time = 1.7
			IsNPC = false
			break

		case 2:
			// super nuke: PAS_NUCLEAR_CORE
			explosions = 15
			innerRadius = 350
			time = 1.4
			IsNPC = false
			break

		case 1:
			// regular nuke: PAS_BUILD_UP_NUCLEAR_CORE
			explosions = 10
			innerRadius = 350
			time = 1.0
			IsNPC = false
			break

		default:
			Assert( 0, "e.nuclearPayload value: " + e.nuclearPayload + " not accounted for." )
			break
	}

	float waitPerExplosion = time / explosions

	ClearNuclearBlueSunEffect( e )

	if ( IsValid( e.player ) )
	{
		thread __CreateFxInternal( TITAN_NUCLEAR_CORE_FX_1P, null, "", origin, Vector(0,RandomInt(360),0), C_PLAYFX_SINGLE, null, 1, expect entity( e.player ) )
		thread __CreateFxInternal( TITAN_NUCLEAR_CORE_FX_3P, null, "", origin + Vector( 0, 0, -100 ), Vector(0,RandomInt(360),0), C_PLAYFX_SINGLE, null, 6, expect entity( e.player ) )
	}
	else
	{
		PlayFX( TITAN_NUCLEAR_CORE_FX_3P, origin + Vector( 0, 0, -100 ), Vector(0,RandomInt(360),0) )
	}

	// one extra explosion that does damage to physics entities at smaller radius
	if ( !IsNPC )
		explosions += 1

	int outerRadius

	float baseNormalDamage 		= normalDamage
	float baseHeavyArmorDamage 	= heavyArmorDamage
	int baseInnerRadius 		= innerRadius
	int baseOuterRadius 		= outerRadius

	// all damage must have an inflictor currently
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
		float normalDamage 		= baseNormalDamage
		float heavyArmorDamage 	= baseHeavyArmorDamage
		int innerRadius 		= baseInnerRadius
		int outerRadius 		= baseOuterRadius

		if ( i == 0 && !IsNPC )
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

		RadiusDamage_DamageDef( damagedef_nuclear_core,
			origin,								// origin
			explosionOwner,						// owner
			inflictor,							// inflictor
			normalDamage,						// normal damage
			heavyArmorDamage,					// heavy armor damage
			innerRadius,						// inner radius
			outerRadius,						// outer radius
			0 )									// dist from attacker

		wait waitPerExplosion
	}
}

void function NuclearCoreExplosion( vector origin, e )
{
	entity titan = expect entity( e.titan )

	titan.EndSignal( "OnDeath" )

	e.needToClearNukeFX = false //This thread and NuclearCoreExplosionChainReaction now take responsibility for clearing the FX

	OnThreadEnd(
		function() : ( e )
		{
			ClearNuclearBlueSunEffect( e )
		}
	)

	wait 1.3
	Assert( IsValid( titan ) )
	titan.s.silentDeath <- true  //Don't play normal titan_death_explode in _deathpackage since we're playing titan_nuclear_death_explode

	EmitSoundAtPosition( titan.GetTeam(), origin, "titan_nuclear_death_explode" )

	titan.s.noLongerCountsForLTS <- true

	thread NuclearCoreExplosionChainReaction( origin, e )

	if ( IsAlive( titan ) )
		titan.Die( e.attacker, e.inflictor, { scriptType = DF_EXPLOSION, damageType = DMG_REMOVENORAGDOLL, damageSourceId = e.damageSourceId } )
}

void function TitanEjectPlayerForNPCs( entity ejectTitan, bool instant = false ) //TODO: This needs a refactor badly. Way too long and unwieldy. I think it was a mistake to handle both player Titan eject and NPC titan eject in the same function
{
	ejectTitan.Signal( "EjectAttempt" )

	Assert( ejectTitan.IsTitan() )
	Assert( IsAlive( ejectTitan ), "Ejecting titan expected to be alive. IsPlayer? " + ejectTitan.IsPlayer() + " ent: " + ejectTitan )

	if ( ejectTitan.ContextAction_IsActive() )
		return

	entity soul = ejectTitan.GetTitanSoul()

	if ( soul.IsEjecting() )
		return

	if ( ejectTitan.IsPlayer() )
	{
		if ( IsPlayerDisembarking( ejectTitan ) )
			return
	}

	table e = {}
	e.titan <- ejectTitan
	e.team <- ejectTitan.GetTeam()

	e.player <- null
	e.npcPilot <- null
	bool ejectTitanHasNpcPilot = false
	if ( ejectTitan.IsPlayer() )
		e.player = ejectTitan

	if ( AttritionExtendedRecode_TitanHasNpcPilot( ejectTitan ) )
	{
		ejectTitanHasNpcPilot = true
		ejectTitan.kv.allowShoot = 0
		ForceTitanSustainedDischargeEnd( ejectTitan )
	}

	e.nukeFX <- []
	e.attacker <- ( "attacker" in soul.lastAttackInfo ) ? soul.lastAttackInfo.attacker : null
	e.inflictor <- ( "inflictor" in soul.lastAttackInfo ) ? soul.lastAttackInfo.inflictor : null
	e.damageSourceId <- ( "damageSourceId" in soul.lastAttackInfo ) ? soul.lastAttackInfo.damageSourceId : -1
	e.damageTypes <- soul.lastAttackInfo.scriptType
	e.overrideAttacker <- soul.soul.nukeAttacker

	int nuclearPayload = 0
	if ( IsValid( e.player ) )
		nuclearPayload = GetNuclearPayload( ejectTitan )
	else
		nuclearPayload = NPC_GetNuclearPayload( ejectTitan )

	e.nuclearPayload <- nuclearPayload

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
		function() : ( e, ejectTitan )
		{
			if ( IsAlive( ejectTitan ) )
			{
				thread ClearEjectInvulnerability( ejectTitan )
				if ( IsValid( ejectTitan.GetOwner() ) && IsAlive( ejectTitan.GetOwner() ) )
				thread ClearEjectInvulnerability( ejectTitan.GetOwner() )
			}
			else if ( IsValid( ejectTitan ) )
			{
				ejectTitan.ClearInvulnerable()
			}

			if ( IsValid( e.player ) )
			{
				e.player.UnfreezeControlsOnServer()
			}

			entity titan = expect entity( e.titan )

			if ( e.nuclearPayload )
			{
				if ( e.needToClearNukeFX )
				{
					if ( IsAlive( titan ) )
					{
						//Nuclear eject sequence got interrupted early, probably because Pilot died
						Assert( titan.IsTitan() )
						thread NuclearCoreExplosion( titan.GetOrigin(), e )
					}
					else
					{
						//Nuclear eject fired, needs to be cleaned up
						ClearNuclearBlueSunEffect( e )
					}
				}
				//Nuclear core handles cleaning up the left over titan by itself, so just return out early
				return
			}

			if ( !IsAlive( titan ) )
				return

			entity soul = titan.GetTitanSoul()
			if ( !soul.soul.diesOnEject )
				return

			Assert( titan.IsTitan() )
			Assert( soul.IsEjecting() )
			titan.Die( e.attacker, e.inflictor, { scriptType = damageTypes.titanEjectExplosion | e.damageTypes, damageSourceId = e.damageSourceId } )
		}
	)

	soul.SetEjecting( true )
	ejectTitan.SetInvulnerable()  //Give both player and ejectTitan temporary invulnerability in the course of ejecting. Player invulnerability gets cleared in ClearEjectInvulnerability

	#if SERVER
		StatusEffect_StopAll( expect entity( e.titan ), eStatusEffect.lockon_detected_titan )
	#endif

	#if HAS_STATS
	if ( IsValid( e.player ) )
	{
		UpdatePlayerStat( expect entity( e.player ), "misc_stats", "timesEjected" )
		if ( nuclearPayload )
			UpdatePlayerStat( expect entity( e.player ), "misc_stats", "timesEjectedNuclear" )
	}
	#endif
	#if SERVER && MP
		PIN_AddToPlayerCountStat( expect entity( e.player ), "ejects" )
	#endif

	if ( !ejectTitan.ContextAction_IsBusy() )
		ejectTitan.ContextAction_SetBusy()

	bool standing = true
	if ( IsValid( e.player ) )
		standing = expect bool ( e.player.IsStanding() )
	else
		standing = soul.GetStance() == STANCE_STAND

	string titanEjectAnimPlayer, titanEjectAnimTitan
	if ( standing )
	{
		if ( nuclearPayload )
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

	float ejectDuration // = TITAN_PLAYEREJECT_DURATION
	if ( nuclearPayload )
		ejectDuration = TITAN_PLAYEREJECT_DURATION * 2.0
	else
		ejectDuration = TITAN_PLAYEREJECT_DURATION

//	ejectDuration = ejectTitan.GetSequenceDuration( titanEjectAnimPlayer )

	if ( nuclearPayload )
	{
		array<entity> players = GetPlayerArray()
		int frequency = 40
		float duration = 8.5
		vector origin = ejectTitan.GetOrigin()

		foreach ( guy in players )
		{
			if ( guy == e.player )
				continue

			if ( !IsAlive( guy ) )
				continue

			float dist = Distance( guy.GetOrigin(), origin )
			float result = Graph( dist, 750, 1500, 5.0, 0.0 )
			Remote_CallFunction_Replay( guy, "ServerCallback_ScreenShake", result, frequency, duration )
		}

		e.needToClearNukeFX = true
		e.nukeFXInfoTarget.SetParent( ejectTitan, "CHESTFOCUS" ) //Play FX and sound on entity since we need something that lasts across the player titan -> pilot transition
		e.nukeFX.append( PlayFXOnEntity( TITAN_NUCLEAR_CORE_NUKE_FX, expect entity( e.nukeFXInfoTarget ) ) )
		e.nukeFX.append( e.nukeFXInfoTarget )
		//ejectDuration += 0.5

		EmitSoundOnEntity( e.nukeFXInfoTarget, "titan_nuclear_death_charge" )
	}

	entity rodeoPlayer = GetRodeoPilot( ejectTitan )
	if ( IsValid( rodeoPlayer ) && rodeoPlayer.IsPlayer() )
		Remote_CallFunction_Replay( rodeoPlayer, "ServerCallback_RodeoerEjectWarning", ejectTitan.GetTitanSoul().GetEncodedEHandle(), TITAN_PLAYEREJECT_DELAY + ejectDuration )

	if ( IsValid( e.player ) )
		e.player.CockpitStartEject()

	float blendDelay = 0.15
	vector origin = ejectTitan.GetOrigin()

	if ( !instant )
	{
		if ( IsValid( e.player ) )
		{
			Remote_CallFunction_Replay( e.player, "ServerCallback_EjectConfirmed" )
			EmitSoundAtPositionExceptToPlayer( e.team, ejectTitan.GetOrigin(), e.player, "Titan_Eject_Servos_3P" )
			e.player.FreezeControlsOnServer()
		}
		else
		{
			EmitSoundAtPosition( e.team, ejectTitan.GetOrigin(), "Titan_Eject_Servos_3P" )
		}

		if ( !ejectTitan.IsTitan() )
		{
			// must be a titan, something bad has happened
			KillStuckPlayer( ejectTitan )
			return
		}

		ejectTitan.Anim_Play( titanEjectAnimPlayer )

		wait blendDelay  // wait for ejectTitan to blend into disembark pose

		Assert( ejectDuration > MAX_EJECT_LATENCY_COMPENSATION )
		wait ejectDuration - MAX_EJECT_LATENCY_COMPENSATION

		if ( IsValid( e.player ) )
		{
			// subtract player latency so that the client gets the eject at the same time they finish the animation
			float latency = expect entity( e.player ).GetLatency()
			float waitduration = MAX_EJECT_LATENCY_COMPENSATION - min( latency, MAX_EJECT_LATENCY_COMPENSATION )
			//printt( "Eject: compensating for " + latency + " seconds of latency; wait " + waitduration )
			wait waitduration
		}
	}

	// Defensive fix for if player becomes a spectator between initiating eject and now
	if ( IsValid( e.player ) && e.player.GetPlayerSettings() == "spectator" )
		return

	if ( ejectTitan.GetTitanSoul() == null )
		return

	if ( IsValid( e.player ) )
		EmitSoundAtPositionExceptToPlayer( e.team, ejectTitan.GetOrigin(), e.player, "Titan_Eject_PilotLaunch_3P" )
	else
		EmitSoundAtPosition( e.team, ejectTitan.GetOrigin(), "Titan_Eject_PilotLaunch_3P" )

	entity titan
	if ( IsValid( e.player ) )
	{
		entity player = expect entity( e.player )
		titan = CreateAutoTitanForPlayer_ForTitanBecomesPilot( player )
		DispatchSpawn( titan )
		player.p.lastEjectTime = Time()
		HolsterAndDisableWeapons( player ) //Primarily done to not play the holster animation, then deploy animation of weapon if we happened to switch the active weapon in GiveWeaponsFromStoredArray()
		TitanBecomesPilot( ejectTitan, titan )
		DeployAndEnableWeapons( player )//Undo Holster
		player.UnfreezeControlsOnServer()
	}
	else
	{
		// the titan is an AI
		titan = ejectTitan
	}

	if ( ejectTitanHasNpcPilot )
	{
		entity npcPilot = AttritionExtendedRecode_NpcTitanBecomesPilot( ejectTitan )
		e.npcPilot = npcPilot
		if ( IsAlive( npcPilot ) )
		{
			npcPilot.SetInvulnerable()
			thread NPCPilotEjectingAnimation( npcPilot )
		}
	}

	vector titanOrigin = titan.GetOrigin()

	// HACKY, surprised there isn't a wrapper for this yet
	if ( !( "disableAutoTitanConversation" in titan.s ) )
		titan.s.disableAutoTitanConversation <- true // no auto titan chatter

	titan.SetInvulnerable() //Titan dies at the end of eject sequence by script
	titan.SetNPCPriorityOverride_NoThreat()	// AI shouldn't consider this ejecting titan as an enemy and shoot it, etc

	if ( e.nuclearPayload )
	{
		e.nukeFXInfoTarget.SetParent( titan, "CHESTFOCUS" )
	}

	bool isInDeepWater = expect bool ( "isInDeepWater" in ejectTitan.s && ejectTitan.s.isInDeepWater )

	if ( e.nuclearPayload || isInDeepWater )
	{
		thread TitanNonSolidTemp( titan )
	}

	ejectTitan.Anim_Stop()
	e.titan = titan

	if ( ejectTitan.ContextAction_IsBusy() )
		ejectTitan.ContextAction_ClearBusy()

	FirstPersonSequenceStruct sequence
	sequence.thirdPersonAnim = titanEjectAnimTitan
	sequence.teleport = true
	thread FirstPersonSequence( sequence, titan )

	if ( IsValid( e.player ) )
	{
		entity player = expect entity( e.player )
		thread TempAirControl( player )

		PutEntityInSafeSpot( player, titan, null, origin + <0,0,60>, player.GetOrigin() + <0,0,60> )
	}

	vector ejectAngles = titan.GetAngles()
	ejectAngles.x = 270
	//ejectAngles.x = RandomIntRange( 263, 277 ) //5 degrees back of straight up was 245

	float speed = RandomFloatRange( 1500, 1700 ) //was 1000
	if ( nuclearPayload )
		speed += 400

	if ( isInDeepWater )
		speed += 1000

	e.singleRodeoPilot <- null //HACKY. Need to store it off because after time passes we don't have a handle to the rider anymore. Terribly hacky

	entity rider = GetRodeoPilot( titan )
	if ( rider && rider.GetParent() == titan )
	{
		e.singleRodeoPilot = rider //Need to store it off because after time passes we don't have a handle to the rider anymore. Terribly hacky
		if ( IsValid( e.player ) )
			thread TemporarilyNonSolidPlayer( expect entity( e.player ) )

		thread TemporarilyNonSolidPlayer( rider )

		vector riderEjectAngles = AnglesCompose( ejectAngles, < 5, 0, 0 > )

		float gravityScale = 1.0

		if ( rider.IsPlayer() )
			gravityScale = expect float ( rider.GetPlayerSettingsField( "gravityscale" ) )

		vector riderVelocity = AnglesToForward( riderEjectAngles ) * (speed * gravityScale) * 0.95

		if ( rider.IsPlayer() )
			ThrowRiderOff( rider, titan, riderVelocity )
		else
			rider.Die( titan, titan, { force = Vector( 0.4, 0.2, 0.3 ), scriptType = DF_GIB, damageSourceId = eDamageSourceId.titan_explosion } )

		wait 0.05
	}

	if ( IsAlive( expect entity( e.player ) ) )
	{
		if ( PlayerHasPassive( expect entity( e.player ), ePassives.PAS_PHASE_EJECT ) )
		{
			PhaseShift( expect entity( e.player ), 0.0, 3.0 )
			ejectAngles.x = 315
			speed *= 0.5
		}
		ejectAngles = AnglesCompose( ejectAngles, < -5, 0, 0 > )

		float gravityScale = expect float ( e.player.GetPlayerSettingsField( "gravityscale" ) )
		vector velocity = AnglesToForward( ejectAngles ) * speed * sqrt( gravityScale )
		e.player.SetOrigin( e.player.GetOrigin() )
		e.player.SetVelocity( velocity )
		vector player_look_angles = titan.GetAngles()
		player_look_angles.x = 80  //was 35
		e.player.SetAngles( player_look_angles )

		thread EjectFlightTracker( expect entity( e.player ) )

		entity rider = expect entity( e.singleRodeoPilot )
		if ( IsAlive( rider ) && e.player.GetTeam() != rider.GetTeam() )
			thread LookAtEachOther( rider, expect entity( e.player ) )
	}
	else if ( ejectTitanHasNpcPilot && IsAlive( expect entity( e.npcPilot ) ) )
	{
		vector velocity = < 0, 0, speed > //straight up
		e.npcPilot.SetOrigin( titan.GetOrigin() + Vector(0,0,100) )
		e.npcPilot.SetAngles( titan.GetAngles() )
		e.npcPilot.SetVelocity( velocity )
		e.overrideAttacker = e.npcPilot
	}

	if ( IsValid( e.player ) )
		TitanEjectVO( expect entity( e.player ), titanOrigin )

	wait 0.15

	vector explosionOrigin = titanOrigin + Vector( 0, 0, 200 )

	if ( nuclearPayload )
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
			explosionOrigin,				// origin
			explosionOwner,					// owner
			inflictor,		 				// inflictor
			1,								// normal damage
			1800,							// heavy armor damage
			100,							// inner radius
			300,							// outer radius
			SF_ENVEXPLOSION_NO_DAMAGEOWNER,	// explosion flags
			0, 								// distanceFromAttacker
			0, 								// explosionForce
			damageTypes.explosive,			// damage flags
			eDamageSourceId.titan_explosion	// damage source id
		)

		entity shake = CreateEntity( "env_shake" )
		shake.SetOrigin( titanOrigin )
		shake.kv.amplitude = 12  //1-16
		shake.kv.duration = 1
		shake.kv.frequency = 100 //.001 - 255
		shake.kv.radius = 1000
		shake.kv.spawnflags = 4 //in air
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

entity function GetExplosionOwner( e )
{
	if ( IsValid( expect entity( e.overrideAttacker ) ) )
		return expect entity( e.overrideAttacker )

	if ( IsValid( expect entity( e.player ) ) )
		return expect entity( e.player )

	if ( IsValid( expect entity( e.titan ) ) )
		return expect entity( e.titan )

	return GetTeamEnt( expect int( e.team ) )
}
#endif