/obj/machinery/atmospherics/fan
	name = "fan"
	icon = 'icons/obj/machines/atmospherics/current_generator.dmi'
	icon_state = "fan"
	var/datum/wind_current/fan_blow
	can_unwrench = TRUE
	on = FALSE


/obj/machinery/atmospherics/fan/click_alt(mob/user)
	on = !on
	if(on)
		fan_blow = new /datum/wind_current
		var/turf/open/starting_current_tile = get_step(loc, dir)
		fan_blow.initiate_vector(starting_current_tile, dir, 6)
		SSair.start_processing_machine(src)

	else
		if(fan_blow)
			qdel(fan_blow)
		SSair.remove_from_active(src)
	balloon_alert(user, "turned [on ? "on" : "off"]")
	return CLICK_ACTION_SUCCESS

/obj/machinery/atmospherics/fan/process_atmos()

	if(!is_operational && on)
		on = FALSE
	if(!on)
		return PROCESS_KILL
	var/turf/open/ahead_tile = get_step(loc, dir)
	var/turf/open/our_tile = loc
	var/datum/gas_mixture/our_mix = our_tile.air
	var/datum/gas_mixture/ahead_tile_mix = ahead_tile.air
	var/pressure_diff = our_mix.force_share(ahead_tile_mix, 0.5)
	our_tile.consider_pressure_difference(ahead_tile, pressure_diff)
	SSair.add_to_active(our_tile)
	SSair.add_to_active(ahead_tile)

/obj/machinery/atmospherics/fan/Destroy()
	. = ..()
	qdel(fan_blow)


