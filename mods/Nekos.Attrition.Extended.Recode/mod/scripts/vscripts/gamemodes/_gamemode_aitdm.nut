untyped
global function GamemodeAITdm_Init

struct
{
	table< string, array<string> > weapons
} file

void function GamemodeAITdm_Init()
{
	SetSpawnpointGamemodeOverride( ATTRITION ) // use bounty hunt spawns as vanilla game has no spawns explicitly defined for aitdm

	AddCallback_GameStateEnter( eGameState.Prematch, OnPrematchStart )
	AddCallback_GameStateEnter( eGameState.Playing, OnPlaying )
	
	AddDeathCallback( "npc_soldier", HandleDeathCallbackScoreEvent )
	AddDeathCallback( "npc_spectre", HandleDeathCallbackScoreEvent )
	AddDeathCallback( "npc_stalker", HandleDeathCallbackScoreEvent )
	AddDeathCallback( "npc_super_spectre", HandleDeathCallbackScoreEvent )
	AddDeathCallback( "npc_pilot_elite", HandleDeathCallbackScoreEvent )
	AddDeathCallback( "npc_titan", HandleDeathCallbackScoreEvent )
	AddCallback_OnPlayerKilled( HandleScoreEvent )
		
	AddCallback_OnClientConnected( OnPlayerConnected )
	
	AddCallback_NPCLeeched( OnSpectreLeeched )
	
	if ( GetCurrentPlaylistVarInt( "aitdm_archer_grunts", 0 ) == 0 )
	{
		file.weapons = {
			["npc_soldier"] = [ "mp_weapon_rspn101", "mp_weapon_dmr", "mp_weapon_r97", "mp_weapon_lmg" ],
			["npc_spectre"] = [ "mp_weapon_hemlok_smg", "mp_weapon_doubletake", "mp_weapon_mastiff" ],
			["npc_stalker"] = [ "mp_weapon_hemlok_smg", "mp_weapon_lstar", "mp_weapon_mastiff" ]
		}
	}
	else
	{
		file.weapons = {
			["npc_soldier"] = [ "mp_weapon_rocket_launcher" ],
			["npc_spectre"] = [ "mp_weapon_rocket_launcher" ],
			["npc_stalker"] = [ "mp_weapon_rocket_launcher" ]
		}
	}
	
	ScoreEvent_SetupEarnMeterValuesForMixedModes()
	SetupGenericTDMChallenge()
}

// Starts skyshow, this also requiers AINs but doesn't crash if they're missing
void function OnPrematchStart()
{
	thread StratonHornetDogfightsIntense()
}

void function OnPlaying()
{	
	// don't run spawning code if ains and nms aren't up to date
	if ( GetAINScriptVersion() == AIN_REV && GetNodeCount() != 0 )
	{
		thread SpawnIntroBatch_Threaded( TEAM_MILITIA )
		thread SpawnIntroBatch_Threaded( TEAM_IMC )
	}
}

// Sets up mode specific hud on client
void function OnPlayerConnected( entity player )
{
	Remote_CallFunction_NonReplay( player, "ServerCallback_AITDM_OnPlayerConnected" )
}

void function HandleDeathCallbackScoreEvent( entity victim, var damageInfo )
{
	thread HandleScoreEvent( victim, DamageInfo_GetAttacker( damageInfo ), damageInfo )
}

// Used to handle both player and ai events
void function HandleScoreEvent( entity victim, entity attacker, var damageInfo )
{
	// Basic checks
	if ( victim == attacker || GetGameState() != eGameState.Playing )
		return
	// Hacked spectre filter
	if ( victim.GetOwner() == attacker )
		return
	// NPC titans without an owner player will not count towards any team's score
	if ( attacker.IsNPC() && !Is_AttritionExtendedRecode_Entity( attacker ) && !IsValid( GetPetTitanOwner( attacker ) ) )
		return
	
	// Split score so we can check if we are over the score max
	// without showing the wrong value on client
	int teamScore
	int playerScore
	
	// Handle AI, marvins aren't setup so we check for them to prevent crash
	if ( victim.IsNPC() )
	{
		switch ( victim.GetClassName() )
		{
			case "npc_soldier":
			case "npc_spectre":
			case "npc_stalker":
				playerScore = 1
				break
			case "npc_super_spectre":
				playerScore = 3
				break
			case "npc_pilot_elite":
				playerScore = 5
				break
			default:
				playerScore = 0
				break
		}
	}
	
	if ( victim.IsPlayer() )
		playerScore = 5
	
	// Player ejecting triggers this without the extra check
	if ( victim.IsTitan() && victim.GetBossPlayer() != attacker )
		playerScore += 10

	if ( AttritionExtendedRecode_TitanHasNpcPilot( victim ) )
		playerScore += 5
	
	
	teamScore = playerScore
	
	// Check score so we dont go over max
	if ( GameRules_GetTeamScore(attacker.GetTeam()) + teamScore > GetScoreLimit_FromPlaylist() )
		teamScore = GetScoreLimit_FromPlaylist() - GameRules_GetTeamScore(attacker.GetTeam())
	
	// Add score + update network int to trigger the "Score +n" popup
	AddTeamScore( attacker.GetTeam(), teamScore )
	if ( attacker.IsPlayer() )
	{
	    attacker.AddToPlayerGameStat( PGS_ASSAULT_SCORE, playerScore )
	    attacker.SetPlayerNetInt("AT_bonusPoints", attacker.GetPlayerGameStat( PGS_ASSAULT_SCORE ) )
	}
}

// When attrition starts both teams spawn ai on preset nodes, after that
// Spawner_Threaded is used to keep the match populated
void function SpawnIntroBatch_Threaded( int team )
{
    thread AttritionExtendedRecode_Handle( team )
	thread Spawner_Threaded( team )
}

// Populates the match
void function Spawner_Threaded( int team )
{
	svGlobal.levelEnt.EndSignal( "GameStateChanged" )

	// used to index into escalation arrays
	int index = team == TEAM_MILITIA ? 0 : 1
	
	while( true )
	{
		int score = GameRules_GetTeamScore( team )
		// TODO: this should possibly not count scripted npc spawns, probably only the ones spawned by this script
		array<entity> npcs = GetNPCArrayOfTeam( team )
		int count = npcs.len()
		int reaperCount = GetNPCArrayEx( "npc_super_spectre", team, -1, <0,0,0>, -1 ).len()

		// REAPERS
		if ( score >= GetCurrentPlaylistVarInt( "reaper_spawn_score", 500 ) )
		{
			array< entity > points = SpawnPoints_GetTitan()
			if ( reaperCount < GetCurrentPlaylistVarInt( "reaper_count", 2 ) )
			{
				entity node = points[ GetSpawnPointIndex( points, team ) ]
				node.s.lastUsedTime <- Time()
				node.e.spawnTime = Time()
				thread AiGameModes_SpawnReaperModded( node.GetOrigin(), node.GetAngles(), team, "npc_super_spectre_aitdm", ReaperHandler )
				wait 1.0
			}
		}
		
		// NORMAL SPAWNS
		if ( count < GetCurrentPlaylistVarInt( "squad_count", 4 ) * 4 - 2 )
		{
			int squadspawns = 0
			if ( score >= GetCurrentPlaylistVarInt( "spectre_spawn_score", 125 ) )
				squadspawns += 1

			if ( score >= GetCurrentPlaylistVarInt( "stalker_spawn_score", 380 ) )
				squadspawns += 1

			string ent = RandomIntRange( 0, squadspawns + 1 ).tostring()

			if ( ent == "0" )
				ent = "npc_soldier"

			else if ( ent == "1" )
				ent = "npc_spectre"

			else if ( ent == "2" )
				ent = "npc_stalker"
			
			array< entity > points = GetZiplineDropshipSpawns()
			// Prefer dropship when spawning grunts
			if ( ent == "npc_soldier" && points.len() != 0 && CoinFlip() && CoinFlip() )
			{
				if ( RandomInt( points.len() ) )
				{
					entity node = points[ GetSpawnPointIndex( points, team ) ]
					node.s.lastUsedTime <- Time()
					node.e.spawnTime = Time()
					thread Aitdm_SpawnDropShip( node, team )
					wait 2.0
					continue
				}
			}
			
			points = SpawnPoints_GetTitan()
			entity node = points[ GetSpawnPointIndex( points, team ) ]
			node.s.lastUsedTime <- Time()
			node.e.spawnTime = Time()
			thread AiGameModes_SpawnDropPodModded( node.GetOrigin(), node.GetAngles(), team, ent, SquadHandler )
			wait 2.0
		}
		
		WaitFrame()
	}
}

void function AttritionExtendedRecode_Handle( int team )
{
	svGlobal.levelEnt.EndSignal( "GameStateChanged" )
	while ( true )
	{
		if ( GameRules_GetTeamScore( team ) >= GetCurrentPlaylistVarInt( "titan_spawn_score", 0 ) && AttritionExtendedRecode_SpawnedPilotedTitans( team ) < GetCurrentPlaylistVarInt( "piloted_titan_count", 3 ) )
		{
		    AttritionExtendedRecode_SpawnPilotWithTitan( team )
			wait RandomFloatRange( 0.5, 1 )
		}

		if ( GameRules_GetTeamScore( team ) >= GetCurrentPlaylistVarInt( "titan_spawn_score", 0 ) &&AttritionExtendedRecode_SpawnedUnPilotedTitans( team ) < GetCurrentPlaylistVarInt( "unpiloted_titan_count", 0 ) )
		{
		    AttritionExtendedRecode_SpawnTitan( team, false )
			wait RandomFloatRange( 0.5, 1 )
		}
		WaitFrame()
	}
}

void function Aitdm_SpawnDropShip( entity node, int team )
{
	thread AiGameModes_SpawnDropShipModded( node.GetOrigin(), node.GetAngles(), team, 4, SquadHandler )
	wait 20
}


// Decides where to spawn ai
// Each team has their "zone" where they and their ai spawns
// These zones should swap based on which team is dominating where
int function GetSpawnPointIndex( array< entity > points, int team )
{
	entity zone = DecideSpawnZone_Generic( points, team )
	
	if ( IsValid( zone ) )
		for ( int i = 0; i < points.len(); i++ )
			if ( Distance2D( points[i].GetOrigin(), zone.GetOrigin() ) < 6000 && IsSpawnpointValid( points[i], team ) )
				return i

	array < entity > spawnpoints
	foreach ( entity spawnpoint in points )
		if ( IsSpawnpointValid( spawnpoint, team ) )
			spawnpoints.append( spawnpoint )

	entity point
	if ( spawnpoints.len() )
		if ( IsValid( zone ) )
			point = GetClosest2D( spawnpoints, zone.GetOrigin() )
		else
			point = spawnpoints.getrandom()

	for ( int i = 0; i < points.len(); i++ )
		if ( points[i] == point )
			return i
	
	return RandomInt( points.len() )
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

    if ( spawnpoint.IsOccupied() || ( "inuse" in spawnpoint.s && spawnpoint.s.inuse ) || ( "lastUsedTime" in spawnpoint.s && Time() - spawnpoint.s.lastUsedTime <= 10.0 ) || ( "spawnTime" in spawnpoint.e && Time() - spawnpoint.e.spawnTime <= 10.0 )  )
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

// tells infantry where to go
// In vanilla there seem to be preset paths ai follow to get to the other teams vone and capture it
// AI can also flee deeper into their zone suggesting someone spent way too much time on this
void function SquadHandler( array<entity> guys )
{
	int team = guys[0].GetTeam()
	// show the squad enemy radar
	array<entity> players = GetPlayerArrayOfEnemies( team )
	foreach ( entity guy in guys )
	{
		if ( IsAlive( guy ) )
		{
			foreach ( player in players )
				guy.Minimap_AlwaysShow( 0, player )
		}
	}

	// Not all maps have assaultpoints / have weird assault points ( looking at you ac )
	// So we use enemies with a large radius
	while ( GetNPCArrayOfEnemies( team ).len() == 0 ) // if we can't find any enemy npcs, keep waiting
		WaitFrame()

	// our waiting is end, check if any soldiers left
	bool squadAlive = false
	foreach ( entity guy in guys )
	{
		if ( IsAlive( guy ) )
			squadAlive = true
		else
			guys.removebyvalue( guy )
	}
	if ( !squadAlive )
		return

	array<entity> points = GetNPCArrayOfEnemies( team )
	
	vector point
	point = points[ RandomInt( points.len() ) ].GetOrigin()
	
	// Setup AI, first assault point
	foreach ( guy in guys )
	{
		if ( IsAlive( guy ) )
		{
			guy.EnableNPCFlag( NPC_ALLOW_PATROL | NPC_ALLOW_INVESTIGATE | NPC_ALLOW_HAND_SIGNALS | NPC_ALLOW_FLEE )
			guy.AssaultPoint( point )
			guy.AssaultSetGoalRadius( 1600 ) // 1600 is minimum for npc_stalker, works fine for others
		}

		//thread AITdm_CleanupBoredNPCThread( guy )
	}
	
	// Every 5 - 15 secs change AssaultPoint
	while ( true )
	{	
		foreach ( guy in guys )
		{
			// Check if alive
			if ( !IsAlive( guy ) )
			{
				guys.removebyvalue( guy )
				continue
			}
			// Stop func if our squad has been killed off
			if ( guys.len() == 0 )
				return
		}

		// Get point and send our whole squad to it
		points = GetNPCArrayOfEnemies( team )
		if ( points.len() == 0 ) // can't find any points here
		{
			// Have to wait some amount of time before continuing
			// because if we don't the server will continue checking this
			// forever, aren't loops fun?
			// This definitely didn't waste ~8 hours of my time reverting various
			// launcher PRs before finding this mods PR that caused servers to
			// freeze forever before having their process killed by the dedi watchdog
			// without any logging. If anyone reads this, PLEASE add logging to your scripts
			// for when weird edge cases happen, it can literally only help debugging. -Spoon
			WaitFrame()
			continue
		}
			
		point = points[ RandomInt( points.len() ) ].GetOrigin()
		
		foreach ( guy in guys )
		{
			if ( IsAlive( guy ) )
				guy.AssaultPoint( point )
		}

		wait RandomFloatRange(5.0,15.0)
	}
}

// Award for hacking
void function OnSpectreLeeched( entity spectre, entity player )
{
	// Set Owner so we can filter in HandleScore
	spectre.SetOwner( player )
	// Add score + update network int to trigger the "Score +n" popup
	AddTeamScore( player.GetTeam(), 1 )
	player.AddToPlayerGameStat( PGS_ASSAULT_SCORE, 1 )
	player.SetPlayerNetInt("AT_bonusPoints", player.GetPlayerGameStat( PGS_ASSAULT_SCORE ) )
}

// Same as SquadHandler, just for reapers
void function ReaperHandler( entity reaper )
{
	array<entity> players = GetPlayerArrayOfEnemies( reaper.GetTeam() )
	foreach ( player in players )
		reaper.Minimap_AlwaysShow( 0, player )
	
	reaper.AssaultSetGoalRadius( 500 )
	
	// Every 10 - 20 secs get a player and go to him
	// Definetly not annoying or anything :)
	while( IsAlive( reaper ) )
	{
		players = GetPlayerArrayOfEnemies( reaper.GetTeam() )
		if ( players.len() != 0 )
		{
			entity player = GetClosest2D( players, reaper.GetOrigin() )
			reaper.AssaultPoint( player.GetOrigin() )
		}
		wait RandomFloatRange(10.0,20.0)
	}
	// thread AITdm_CleanupBoredNPCThread( reaper )
}

// Currently unused as this is handled by SquadHandler
// May need to use this if my implementation falls apart
void function AITdm_CleanupBoredNPCThread( entity guy )
{
	// track all ai that we spawn, ensure that they're never "bored" (i.e. stuck by themselves doing fuckall with nobody to see them) for too long
	// if they are, kill them so we can free up slots for more ai to spawn
	// we shouldn't ever kill ai if players would notice them die
	
	// NOTE: this partially covers up for the fact that we script ai alot less than vanilla probably does
	// vanilla probably messes more with making ai assaultpoint to fights when inactive and stuff like that, we don't do this so much

	guy.EndSignal( "OnDestroy" )
	wait 15.0 // cover spawning time from dropship/pod + before we start cleaning up
	
	int cleanupFailures = 0 // when this hits 2, cleanup the npc
	while ( cleanupFailures < 2 )
	{
		wait 10.0
	
		if ( guy.GetParent() != null )
			continue // never cleanup while spawning
	
		array<entity> otherGuys = GetPlayerArray()
		otherGuys.extend( GetNPCArrayOfTeam( GetOtherTeam( guy.GetTeam() ) ) )
		
		bool failedChecks = false
		
		foreach ( entity otherGuy in otherGuys )
		{	
			// skip dead people
			if ( !IsAlive( otherGuy ) )
				continue
		
			failedChecks = false
		
			// don't kill if too close to anything
			if ( Distance( otherGuy.GetOrigin(), guy.GetOrigin() ) < 2000.0 )
				break
			
			// don't kill if ai or players can see them
			if ( otherGuy.IsPlayer() )
			{
				if ( PlayerCanSee( otherGuy, guy, true, 135 ) )
					break
			}
			else
			{
				if ( otherGuy.CanSee( guy ) )
					break
			}
			
			// don't kill if they can see any ai
			if ( guy.CanSee( otherGuy ) )
				break
				
			failedChecks = true
		}
		
		if ( failedChecks )
			cleanupFailures++
		else
			cleanupFailures--
	}
	
	print( "cleaning up bored npc: " + guy + " from team " + guy.GetTeam() )
	guy.Destroy()
}

// Modded Stuff So It Supports Zanieon's Frontier Defense
void function SetUpNPCWeapons( entity guy )
{
	string className = guy.GetClassName()
	
	array<string> mainWeapons
	if ( className in file.weapons )
		mainWeapons = file.weapons[ className ]
	
	if ( mainWeapons.len() == 0 ) // no valid weapons
		return

	// take off existing main weapons, or sometimes they'll have a archer by default
	foreach ( entity weapon in guy.GetMainWeapons() )
		guy.TakeWeapon( weapon.GetWeaponClassName() )

	if ( mainWeapons.len() > 0 )
	{
		string weaponName = mainWeapons[ RandomInt( mainWeapons.len() ) ]
		guy.GiveWeapon( weaponName )
		guy.SetActiveWeaponByName( weaponName )
	}
}

void function AiGameModes_SpawnDropShipModded( vector pos, vector rot, int team, int count, void functionref( array<entity> guys ) squadHandler = null )
{  
	string squadName = MakeSquadName( team, UniqueString( "" ) )

	CallinData drop
	drop.origin 		= pos
	drop.yaw 			  = rot.y
	drop.dist 			= 768
	drop.team 			= team
	drop.squadname 	= squadName
	SetDropTableSpawnFuncs( drop, CreateSoldier, count )
	SetCallinStyle( drop, eDropStyle.ZIPLINE_NPC )
  
	thread RunDropshipDropoff( drop )
	
	WaitSignal( drop, "OnDropoff" )
	
	array< entity > guys = GetNPCArrayBySquad( squadName )
	
	foreach ( guy in guys )
	{
		SetUpNPCWeapons( guy )
		guy.EnableNPCFlag( NPC_ALLOW_PATROL | NPC_ALLOW_INVESTIGATE | NPC_ALLOW_HAND_SIGNALS | NPC_ALLOW_FLEE )
	}
	
	if ( squadHandler != null )
		thread squadHandler( guys )
}


void function AiGameModes_SpawnDropPodModded( vector pos, vector rot, int team, string content /*( ͡° ͜ʖ ͡°)*/, void functionref( array<entity> guys ) squadHandler = null, int flags = 0 )
{
	entity pod = CreateDropPod( pos, <0,0,0> )
	
	InitFireteamDropPod( pod, flags )
		
	waitthread LaunchAnimDropPod( pod, "pod_testpath", pos, rot )

	string squadName = MakeSquadName( team, UniqueString( "" ) )
	array<entity> guys
	for ( int i = 0; i < 4 ;i++ )
	{
		entity npc = CreateNPC( content, team, pos,<0,0,0> )
		DispatchSpawn( npc )
		SetSquad( npc, squadName )

        SetUpNPCWeapons( npc )

		npc.SetParent( pod, "ATTACH", true )
		
		npc.EnableNPCFlag( NPC_ALLOW_PATROL | NPC_ALLOW_INVESTIGATE | NPC_ALLOW_HAND_SIGNALS | NPC_ALLOW_FLEE )
		guys.append( npc )
	}
	
	ActivateFireteamDropPod( pod, guys )

	// start searching for enemies
	if ( squadHandler != null )
		thread squadHandler( guys )
}

const float REAPER_WARPFALL_DELAY = 4.7 // same as fd does
void function AiGameModes_SpawnReaperModded( vector pos, vector rot, int team, string aiSettings = "", void functionref( entity reaper ) reaperHandler = null )
{
	float reaperLandTime = REAPER_WARPFALL_DELAY + 1.2 // reaper takes ~1.2s to warpfall
	thread HotDrop_Spawnpoint( pos, team, reaperLandTime, false, damagedef_reaper_fall )

	wait REAPER_WARPFALL_DELAY
	entity reaper = CreateSuperSpectre( team, pos, rot )
	reaper.EndSignal( "OnDestroy" )
	// reaper highlight
	Highlight_SetFriendlyHighlight( reaper, "sp_enemy_pilot" )
	reaper.Highlight_SetParam( 1, 0, < 1,1,1 > )
	SetDefaultMPEnemyHighlight( reaper )
	Highlight_SetEnemyHighlight( reaper, "enemy_titan" )

	SetSpawnOption_Titanfall( reaper )
	SetSpawnOption_Warpfall( reaper )
	
	if ( aiSettings != "" )
		SetSpawnOption_AISettings( reaper, aiSettings )
	
	HideName( reaper ) // prevent flash a name onto it
	DispatchSpawn( reaper )

	reaper.WaitSignal( "WarpfallComplete" )
	ShowName( reaper ) // show name again after drop
	
	if ( reaperHandler != null )
		thread reaperHandler( reaper )
}

// copied from cl_replacement_titan_hud.gnut
void function HotDrop_Spawnpoint( vector origin, int team, float impactTime, bool hasFriendlyWarning = false, int damageDef = -1 )
{
	array<entity> targetEffects = []
	vector surfaceNormal = < 0, 0, 1 >

	int index = GetParticleSystemIndex( $"P_ar_titan_droppoint" )

	if( hasFriendlyWarning )
	{
		entity effectFriendly = StartParticleEffectInWorld_ReturnEntity( index, origin, surfaceNormal )
		SetTeam( effectFriendly, team )
		EffectSetControlPointVector( effectFriendly, 1, FRIENDLY_COLOR_FX )
		effectFriendly.kv.VisibilityFlags = ENTITY_VISIBLE_TO_FRIENDLY
		effectFriendly.DisableHibernation() // prevent it from fading out
		targetEffects.append( effectFriendly )
	}

	entity effectEnemy = StartParticleEffectInWorld_ReturnEntity( index, origin, surfaceNormal )
	SetTeam( effectEnemy, team )
	EffectSetControlPointVector( effectEnemy, 1, ENEMY_COLOR_FX )
	effectEnemy.kv.VisibilityFlags = ENTITY_VISIBLE_TO_ENEMY
	effectEnemy.DisableHibernation() // prevent it from fading out
	targetEffects.append( effectEnemy )

	// so enemy npcs will mostly avoid them
	entity damageAreaInfo
	if ( damageDef > -1 )
	{
		damageAreaInfo = CreateEntity( "info_target" )
		DispatchSpawn( damageAreaInfo )
		AI_CreateDangerousArea_DamageDef( damageDef, damageAreaInfo, team, true, true )
	}

	wait impactTime

	// clean up
	foreach( entity targetEffect in targetEffects )
	{
		if ( IsValid( targetEffect ) )
			EffectStop( targetEffect )
	}
	if ( IsValid( damageAreaInfo ) )
		damageAreaInfo.Destroy()
}