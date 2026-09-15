GLOBAL_LIST_INIT(fusion_reactions, fusion_reaction_list())

/*
 * Global proc to build the fusion reactions list
 */
/proc/fusion_reaction_list()
	var/list/built_reaction_list = list()
	for(var/reaction_path in subtypesof(/datum/gas_reaction/fusion_reaction))
		var/datum/gas_reaction/fusion_reaction/reaction = new reaction_path()
		built_reaction_list[reaction.id] = reaction

	return built_reaction_list

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
		/datum/gas/plasma = PLASMIC_FUSION_MIN_PLASMA,
		/datum/gas/hydrogen = PLASMIC_FUSION_MIN_HYDROGEN,
		MIN_TEMP = PLASMIC_FUSION_MIN
	)
	factor = list(
			/datum/gas/plasma = "1 mole of plasma get consumed",
			/datum/gas/hydrogen = "1 mole of H gets produced",
			/datum/gas/helium = "2 moles of He get produced",
			/datum/gas/bz = "1 moles of bz gets produced at high energy",
		)

/* Plasmic fusion
	Consumes 1:1 moles of plasma and hydrogen as a base rate
	At higher temperature the reaction change to a 2:1 plasma to hydrogen consumption rate
	High energy reaction produce bz as byproduct
*/
/datum/gas_reaction/fusion_reaction/plasmic_fusion/react(datum/gas_mixture/air_mixture)
	var/list/cached_moles = air_mixture.moles
	var/old_heat_capacity = air_mixture.heat_capacity()
	var/moles_ratio = log(min(cached_moles[/datum/gas/plasma], cached_moles[/datum/gas/hydrogen]) / PLASMIC_FUSION_MIN_HYDROGEN + 1)
	var/fusion_burn_rate
	var/energy_dense = FALSE
	if(air_mixture.temperature >= PLASMIC_FUSION_HIGH_THRESHOLD)
		energy_dense = TRUE
		fusion_burn_rate = PLASMIC_FUSION_HIGH_RATE
	else
		fusion_burn_rate = PLASMIC_FUSION_BASE_RATE

	var/moles_consumed =  fusion_burn_rate * moles_ratio
	air_mixture.adjust_gas(/datum/gas/plasma, -1 * moles_consumed)
	air_mixture.adjust_gas(/datum/gas/hydrogen, -1 * moles_consumed)

	if(energy_dense)
		// 100% of product is He
		air_mixture.adjust_gas(/datum/gas/helium, moles_consumed * 2)
	else
		// 2/3 of product become Bz the rest become He
		air_mixture.adjust_gas(/datum/gas/helium, moles_consumed / 2)
		air_mixture.adjust_gas(/datum/gas/bz, moles_consumed / 3)

	var/new_heat_capacity = air_mixture.heat_capacity()
	var/energy_released = PLASMIC_FUSION_ENERGY_RELEASE * consumed_amount
	if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
		air_mixture.temperature = max(((air_mixture.temperature * old_heat_capacity + energy_released) / new_heat_capacity), TCMB)

/datum/gas_reaction/fusion_reaction/plasmic_fusion/reaction_check(datum/gas_mixture/air_mixture)
	return ..()

/datum/gas_reaction/fusion_reaction/hydrogen_fusion
	name = "Hydrogen fusion"
	id = "hydrogen_fusion"
	desc = "Fusion of plasma and hydrogen into heavier compounds"
	requirements = list(
		/datum/gas/tritium = HYDROGEN_FUSION_MIN_TRITIUM,
		/datum/gas/hydrogen = HYDROGEN_FUSION_MIN_HYDROGEN,
		MIN_TEMP = HYDROGEN_FUSION_MIN
	)
	factor = list(
			/datum/gas/tritium = "1 mole of Tritium get consumed",
			/datum/gas/hydrogen = "1 mole of H gets produced",
			/datum/gas/proto_nitrate = "2 moles of He get produced",
			/datum/gas/healium = "1 moles of bz gets produced at high energy",
		)
/datum/gas_reaction/fusion_reaction/hydrogen_fusion/react(datum/gas_mixture/air_mixture)
	var/list/cached_moles = air_mixture.moles
	var/old_heat_capacity = air_mixture.heat_capacity()
	//Higher tritium:hydrogen ratio lead to more burn rate
	var/moles_ratio = cached_moles[/datum/gas/tritium] / cached_moles[/datum/gas/hydrogen]
	var/fusion_burn_rate = moles_ratio * HYDROGEN_FUSION_BASE_RATE

	air_mixture.adjust_gas(/datum/gas/tritium, -1 * fusion_burn_rate)
	air_mixture.adjust_gas(/datum/gas/hydrogen, -1 * fusion_burn_rate)
	air_mixture.adjust_gas(/datum/gas/halon, fusion_burn_rate / 2)
	air_mixture.adjust_gas(/datum/gas/healium, fusion_burn_rate / 2)

	var/new_heat_capacity = air_mixture.heat_capacity()
	var/energy_released = HYDROGEN_FUSION_ENERGY_RELEASE * fusion_burn_rate
	if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
		air_mixture.temperature = max(((air_mixture.temperature * old_heat_capacity + energy_released) / new_heat_capacity), TCMB)
