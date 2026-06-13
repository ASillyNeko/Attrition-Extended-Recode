# Attrition Extended Recode

[Discord server](https://ds.asillyneko.dev)

Use this to make sure the server doesn't crash by too many props

- `sv_max_props_multiplayer 500000`
- `sv_max_prop_data_dwords_multiplayer 800000`

## Playlistvars

`squad_count` Squads per team * 4. Default 4

`spectre_count` Spectres per team. Default 12

`reaper_count` Reapers per team. Default 2

`piloted_titan_count` Max piloted titan count. Default 3

`piloted_titan_ramp_up_score` Piloted titan ramp up, score `500` score = `1` titan `650` score = `2` titans and so on. Default 150

`unpiloted_titan_count` Max unpiloted titan count. Default 0

`unpiloted_titan_ramp_up_score` unpiloted titan ramp up, score `500` score = `1` titan `650` score = `2` titans and so on. Default 150

`spectre_spawn_score` Spectre spawn score. Default 125

`stalker_spawn_score` Stalker spawn score. Defualt 380

`reaper_spawn_score` Reaper spawn score. Default 500

`titan_spawn_score` Titan spawn score. Default 500

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
	CustomTitan.TitanAiSet = "npc_titan_auto_atlas_vanguard"
	CustomTitan.TitanBehavior = ""
	CustomTitan.EmbarkedTitanAiSet = "npc_titan_atlas_vanguard"
	CustomTitan.EmbarkedTitanBehavior = "behavior_titan_long_range"
	CustomTitan.TitanExecutionRef = "execution_vanguard_kit"
	CustomTitan.Camo = 138
	CustomTitan.Skin = 2
	CustomTitan.AllowedWithPilot = true
	CustomTitan.AllowedWithoutPilot = false
	CustomTitan.Melee = "melee_titan_punch"
	CustomTitan.MeleeMods = []
	CustomTitan.Weapon = "mp_titanweapon_xo16_vanguard"
	CustomTitan.WeaponMods = []
	CustomTitan.Ordnance = "mp_titanweapon_salvo_rockets"
	CustomTitan.OrdnanceMods = []
	CustomTitan.Utility = "mp_titanability_rearm"
	CustomTitan.UtilityMods = []
	CustomTitan.Tactical = "mp_titanweapon_stun_laser"
	CustomTitan.TacticalMods = []
	CustomTitan.Core = "mp_titancore_upgrade"
	CustomTitan.CoreMods = []
	CustomTitan.Passives = [ ePassives.PAS_VANGUARD_COREMETER ]
	CustomTitan.HP = -1 // Max is MAX_HEALTH( 524287 ) and min is 1

	AttritionExtendedRecode_AddCustomTitan( CustomTitan )
}
```

Ones that are `[]` should be like `[ "1", "2", "3" ]` and the passives one should be like `[ 1, 2, 3 ]`/`[ ePassives.PAS_VANGUARD_COREMETER, ePassives.PAS_VANGUARD_DOOM ]`
