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
	fan_blow.initiate_vector(loc, dir, 6, TRUE)
	SSair.start_processing_machine(src)

/obj/machinery/atmospherics/fan/process_atmos()

	if(!is_operational && on)
		on = FALSE
	if(!on)
		return PROCESS_KILL
	var/turf/open/ahead_tile = get_step(loc, dir)
	var/turf/open/our_tile = loc
	var/datum/gas_mixture/our_mix = our_tile.air
	var/datum/gas_mixture/ahead_tile_mix = ahead_tile.air

	our_mix.force_share(ahead_tile_mix, 0.5)
	SSair.add_to_active(our_tile)
	SSair.add_to_active(ahead_tile)

/obj/machinery/atmospherics/fan/Destroy()
	. = ..()
	qdel(fan_blow)


