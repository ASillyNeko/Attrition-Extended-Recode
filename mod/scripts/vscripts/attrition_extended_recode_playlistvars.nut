global function AttritionExtendedRecodePlaylistvars_Init

void function AttritionExtendedRecodePlaylistvars_Init()
{
	AddPrivateMatchModeSettingArbitrary( "Attrition Extended Recode", "squad_count", "4", "Squad Count" )
	AddPrivateMatchModeSettingArbitrary( "Attrition Extended Recode", "reaper_count", "2", "Reaper Count" )
	AddPrivateMatchModeSettingArbitrary( "Attrition Extended Recode", "piloted_titan_count", "3", "Piloted Titan Count" )
	AddPrivateMatchModeSettingArbitrary( "Attrition Extended Recode", "unpiloted_titan_count", "0", "Unpiloted Titan Count" )
	AddPrivateMatchModeSettingArbitrary( "Attrition Extended Recode", "spectre_spawn_score", "125", "Spectre Spawn Score" )
	AddPrivateMatchModeSettingArbitrary( "Attrition Extended Recode", "stalker_spawn_score", "380", "Stalker Spawn Score" )
	AddPrivateMatchModeSettingArbitrary( "Attrition Extended Recode", "reaper_spawn_score", "500", "Reaper Spawn Score" )
	AddPrivateMatchModeSettingArbitrary( "Attrition Extended Recode", "titan_spawn_score", "500", "Titan Spawn Score" )
	AddPrivateMatchModeSettingArbitrary( "Attrition Extended Recode", "ct_titan_replace_chance", "0.20", "Custom Titan Replace Chance" )
}