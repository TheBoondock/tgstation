/obj/machinery/atmospherics/fan
	name = "fan"
	icon = 'icons/obj/machines/atmospherics/current_generator.dmi'
	icon_state = "fan"
	var/datum/wind_current/fan_blow
	var/datum/gas_mixture/our_air
	can_unwrench = TRUE
	on = TRUE
	init_processing = TRUE

/obj/machinery/atmospherics/fan/Initialize(mapload)
	. = ..()
	fan_blow = new /datum/wind_current
	var/iturf = loc
	var/idir = dir
	fan_blow.initiate_vector(iturf, idir, 6, TRUE)
/*
/obj/machinery/atmospherics/fan/process()
	. = ..()
	var/turf/open/ahead = get_step(loc, dir)
	var/turf/open/behind = get_step(loc, turn(dir, 180))
	var/datum/gas_mixture/behind_mix = behind.air
	var/datum/gas_mixture/ahead_mix = ahead.air
	var/list/air_list = behind_mix.gases
	//we suck up 20% of moles in the tiles and spit it out to the tile in front of us
	for(var/gas in air_list)
		var/moles_to_suck = behind_mix[gas][MOLES] * 0.2
		if(moles_to_suck == 0)
			continue
		ahead_mix.assert_gas(gas)
		ahead_mix[gas][MOLES] += moles_to_suck
		behind_mix[gas][MOLES] -= moles_to_suck
*/
