/obj/machinery/fan
	name = "fan"
	icon = 'icons/obj/machines/atmospherics/current_generator.dmi'
	icon_state = "fan"
	var/datum/wind_current/fan_blow

/obj/machinery/fan/Initialize(mapload)
	. = ..()
	fan_blow = new /datum/wind_current
	var/iturf = loc
	var/idir = dir
	fan_blow.initiate_vector(iturf, idir, 6, TRUE)

/obj/machinery/fan/process()
	. = ..()
	var/turf/open/ahead = get_step(loc, dir)
	var/turf/open/behind = get_step(loc, turn(dir, 180))
	var/datum/gas_mixture/behind_mix = behind.air
	var/datum/gas_mixture/ahead_mix = ahead.air
