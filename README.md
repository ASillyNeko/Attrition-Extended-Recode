# Attrition Extended Recode

[Discord server](https://ds.asillyneko.dev)

## Playlistvars

[Playlistvars](mod/scripts/vscripts/attrition_extended_recode_playlistvars.nut)

## Custom Titans

Titans that are custom will have `[CT]` in their names

To make a custom titan you do this, make sure to change the `Example` to something unique

```txt
global function AttritionExtendedRecode_CustomTitanExample_Init

void function AttritionExtendedRecode_CustomTitanExample_Init()
{
	AttritionExtendedRecode_CustomTitanStruct CustomTitan

	CustomTitan.Title = "ASillyNeko"
	CustomTitan.TitanSetFile = "titan_atlas_vanguard"
	CustomTitan.Camo = 138
	CustomTitan.Skin = 2
	CustomTitan.AllowedWithPilot = true
	CustomTitan.AllowedWithoutPilot = false
	CustomTitan.BeforeSpawn = AttrritionExtendedRecode_CustomTitanExample_BeforeSpawn
	CustomTitan.AfterSpawn = AttrritionExtendedRecode_CustomTitanExample_AfterSpawn
	CustomTitan.DisembarkTitan = AttrritionExtendedRecode_CustomTitanExample_DisembarkTitan
	CustomTitan.EmbarkTitan = AttrritionExtendedRecode_CustomTitanExample_EmbarkTitan
	CustomTitan.HP = -1 // Max is MAX_HEALTH( 524287 ) and min is 1

	AttritionExtendedRecode_AddCustomTitan( CustomTitan )
}

void function AttrritionExtendedRecode_CustomTitanExample_BeforeSpawn( entity titan )
{
	SetSpawnOption_AISettings( titan, "npc_titan_auto_atlas_vanguard" )
}

void function AttrritionExtendedRecode_CustomTitanExample_AfterSpawn( entity titan )
{
	titan.GiveWeapon( "mp_titanweapon_xo16_vanguard" )
	titan.GiveOffhandWeapon( "mp_titanweapon_salvo_rockets", OFFHAND_ORDNANCE )
	titan.GiveOffhandWeapon( "mp_titancore_upgrade", OFFHAND_EQUIPMENT )
	titan.GiveOffhandWeapon( "mp_titanability_rearm", OFFHAND_ANTIRODEO )
	titan.GiveOffhandWeapon( "mp_titanweapon_stun_laser", OFFHAND_SPECIAL )
	titan.GiveOffhandWeapon( "melee_titan_punch", OFFHAND_MELEE )

	entity soul = titan.GetTitanSoul()

	if ( IsValid( soul ) )
	{
		soul.soul.titanLoadout.titanExecution = "execution_vanguard"

		GivePassive( soul, ePassives.PAS_VANGUARD_COREMETER )
	}
}

void function AttrritionExtendedRecode_CustomTitanExample_DisembarkTitan( entity titan )
{
}

void function AttrritionExtendedRecode_CustomTitanExample_EmbarkTitan( entity titan )
{
	titan.SetAISettings( "npc_titan_atlas_vanguard" )
	titan.SetBehaviorSelector( "behavior_titan_long_range" )
}
```

Ones that are `[]` should be like `[ "1", "2", "3" ]` and the passives one should be like `[ 1, 2, 3 ]`/`[ ePassives.PAS_VANGUARD_COREMETER, ePassives.PAS_VANGUARD_DOOM ]`
