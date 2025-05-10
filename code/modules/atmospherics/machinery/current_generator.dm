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
	SSair.add_to_active(iturf)
	SSair.start_processing_machine(src)

/obj/machinery/atmospherics/fan/process_atmos()
	. = ..()
	if(!is_operational && on)
		on = FALSE
	if(!on)
		return PROCESS_KILL
	var/turf/open/ahead = get_step(loc, dir)
	var/turf/open/our_tile = loc
	var/datum/gas_mixture/our_mix = our_tile.air
	var/datum/gas_mixture/ahead_mix = ahead.air

	our_mix.force_share(ahead_mix, 0.5)

/obj/machinery/atmospherics/fan/Destroy()
	. = ..()
	qdel(fan_blow)


