# Attrition Extended Recode

[Discord Server](https://ds.nekouwugamerfnf.dev)

Use This To Make Sure The Server Doesn't Crash As Much :)

- `sv_max_props_multiplayer 500000` 
- `sv_max_prop_data_dwords_multiplayer 800000` 

Playlistvars 

`piloted_titan_count` Default 3

`unpiloted_titan_count` Default 0

`titan_spawn_score` Default 0

Custom Titan's

Titans That Are Custom Will Have [CT] In Their Names

To Make A Custom Titan You Can Do

`    AttritionExtendedRecode_CustomTitanCommand( "ASillyNeko", "titan_atlas_vanguard", "npc_titan_auto_atlas_vanguard", "", "npc_titan_atlas_vanguard", "behavior_titan_long_range", "execution_vanguard_kit", 138, 2, true, true, "melee_titan_punch", [], "mp_titanweapon_xo16_vanguard", [], "mp_titanweapon_salvo_rockets", [], "mp_titanability_rearm", [], "mp_titanweapon_stun_laser", [], "mp_titancore_upgrade", [], [ePassives.PAS_VANGUARD_COREMETER] )`

Or

`    AttritionExtendedRecode_CustomTitanStruct CustomTitan
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
    CustomTitan.AllowedWithoutPilot = true
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
    CustomTitan.Passives = [ePassives.PAS_VANGUARD_COREMETER]
    CustomTitan.HP = -1`

The Ones That Are [] Should Be Like ["1","2","3"] And The Passives One Should Be Like [1,2,3]

Also Title TitanSetFile TitanAiSet TitanBehavior EmbarkedTitanAiSet EmbarkedTitanBehavior and TitanExecutionRef Must Be Set
