GLOBAL_LIST_INIT(fusion_reactions, fusion_reaction_list())

/*
 * Global proc to build the fusion reactions list
 */
/proc/fusion_reaction_list()
	var/list/built_reaction_list = list()
	for(var/reaction_path in subtypesof(/datum/fusion_reaction))
		var/datum/fusion_reaction/reaction = new reaction_path()

/datum/gas_reaction/fusion_reaction
	abstract_type = /datum/gas_reaction/fusion_reaction

/datum/gas_reaction/fusion_reaction/New()
	. = ..()
	factor ||= list()
	factor["Location"] ||= "Can only happen on tiles nearby a fusion core."

/datum/gas_reaction/fusion_reaction/proc/react(datum/gas_mixture/air_mixture)
	return

/**
 * Checks whether the requirements are met for a reaction.
 * Args:
 * * air_mixture: The air mixture to check the requirements for.
 */
/datum/gas_reaction/fusion_reaction/proc/reaction_check(datum/gas_mixture/air_mixture)
	var/temp = air_mixture.temperature
	var/list/cached_moles = air_mixture.moles
	if((requirements["MIN_TEMP"] && temp < requirements["MIN_TEMP"]) || (requirements["MAX_TEMP"] && temp > requirements["MAX_TEMP"]))
		return FALSE
	for(var/id in requirements)
		if (id == "MIN_TEMP" || id == "MAX_TEMP")
			continue
		if(!cached_moles[id] || cached_moles[id] < requirements[id])
			return FALSE
	return TRUE

/datum/gas_reaction/fusion_reaction/plasmic_fusion
	name = "Plasmic fusion"
	id = "plasmic_fusion"
	desc = "Fusion of plasma and hydrogen into heavier compounds"
	requirements = list(
		/datum/gas/plasma = MINIMUM_MOLE_COUNT,
		/datum/gas/hydrogen = MINIMUM_MOLE_COUNT,
		MIN_TEMP = PLASMIC_FUSION_MIN
	)
	factor = list(
			/datum/gas/plasma = "1 mole of plasma get consumed",
			/datum/gas/hydrogen = "1 mole of H gets produced",
			/datum/gas/helium = "2 moles of He get produced",
		)

/datum/gas_reaction/fusion_reaction/plasma_fusion/react(datum/gas_mixture/air_mixture)

	var/old_heat_capacity = air_mixture.heat_capacity()

	air_mixture.adjust_gas(/datum/gas/plasma, -1)
	air_mixture.adjust_gas(/datum/gas/hydrogen, -1)
	air_mixture.adjust_gas(/datum/gas/helium, 2)

	var/new_heat_capacity = air_mixture.heat_capacity()
	var/energy_released = 7.8e6
	if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
		air_mixture.temperature = max(((air_mixture.temperature * old_heat_capacity + energy_released) / new_heat_capacity), TCMB)
