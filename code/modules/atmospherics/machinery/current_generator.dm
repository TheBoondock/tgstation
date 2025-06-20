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

		SSair.start_processing_machine(src)

	else

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
	our_mix.force_share(ahead_tile_mix, 0.5)
	ahead_tile.applied_wind[dir] = 6


	SSair.add_to_active(our_tile)
	SSair.add_to_active(ahead_tile)



