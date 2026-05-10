GLOBAL_LIST_INIT(demon_core_reactions, electrolyzer_reactions_list())

/*
 * Global proc to build the electrolyzer reactions list
 */
/proc/demon_core_reactions_list()
	var/list/built_reaction_list = list()
	for(var/reaction_path in subtypesof(/datum/electrolyzer_reaction))
		var/datum/electrolyzer_reaction/reaction = new reaction_path()

/datum/demon_core_reaction
	var/list/requirements
	var/name = "reaction"
	var/id = "r"
	var/desc = ""
	var/list/factor

/datum/electrolyzer_reaction/proc/react(datum/gas_mixture/air_mixture)
	return

/**
 * Checks whether the requirements are met for a reaction.
 * Args:
 * * air_mixture: The air mixture to check the requirements for.
 */
/datum/demon_core_reaction/proc/reaction_check(datum/gas_mixture/air_mixture)
	var/temp = air_mixture.temperature
	var/list/cached_gases = air_mixture.gases
	if((requirements["MIN_TEMP"] && temp < requirements["MIN_TEMP"]) || (requirements["MAX_TEMP"] && temp > requirements["MAX_TEMP"]))
		return FALSE
	for(var/id in requirements)
		if (id == "MIN_TEMP" || id == "MAX_TEMP")
			continue
		if(!cached_gases[id] || cached_gases[id][MOLES] < requirements[id])
			return FALSE
	return TRUE

/datum/demon_core_reaction/plasmic_fusion
	name = "Plasmic fusion"
	id = "plasmic_fusion"
	desc = "Fusion of plasma, hydrogen and CO2 into heavier compounds"
	requirements = list(
		/datum/gas/plasma = MINIMUM_MOLE_COUNT,
		/datum/gas/hydrogen = MINIMUM_MOLE_COUNT,
		/datum/gas/carbon_dioxide = MINIMUM_MOLE_COUNT,
	)
factor = list(
		/datum/gas/water_vapor = "2 moles of H2O get consumed",
		/datum/gas/oxygen = "1 mole of O2 gets produced",
		/datum/gas/hydrogen = "2 moles of H2 get produced",
		"Location" = "Can only happen on turfs with an active Electrolyzer.",
	)
