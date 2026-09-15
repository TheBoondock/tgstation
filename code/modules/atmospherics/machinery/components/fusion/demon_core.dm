//fusion: a terrible idea that was fun but broken. Now reworked to be less broken and more interesting. Again (and again, and again). Again! Again but with machine! Again but with machine assisted open turf!
//Fusion Rework Counter: Please increment this if you make a major overhaul to this system again.
//8 reworks

#define radius_1 8
#define radius_2 20
#define radius_3 30

/obj/machinery/demon_core
	name = "demon core"
	desc = "Fusion reactor core known for its instability and almost magical behaviour."
	icon = 'icons/obj/machines/atmospherics/fusion.dmi'
	icon_state = "pedestal_empty"
	use_power = NO_POWER_USE
	anchored = TRUE
	density = TRUE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF | FREEZE_PROOF
	/// What stages are we in, use in determining output gasses and heat as well as other effect.
	var/stage = 0
	/// The TTV inserted in the core.
	var/obj/item/transfer_valve/inserted_ttv
	/// The single tank assembly bomb inserted into the core.
	var/obj/item/tank/inserted_tank
	///Our internal radio
	var/obj/item/radio/radio
	///The key our internal radio uses
	var/radio_key = /obj/item/encryptionkey/headset_eng
	///The inserted core
	var/obj/item/fusion_core/our_core
	///Our internal energy in MeV, uses 1MeV per reaction catalyzed
	var/internal_energy = 0
	///Active state of fusion
	var/fusing = FALSE
	///Stability status of the core
	var/destabilizing = FALSE


	var/emergency_channel = null // Need null to actually broadcast, lol.

	var/static/message_list = list("Begining kickstart sequence in...", "5", "4", "3", "2", "1")

	var/failed_reason

	STATIC_COOLDOWN_DECLARE(emission_effects)
	STATIC_COOLDOWN_DECLARE(implosion_attempt)


/obj/machinery/demon_core/Initialize(mapload)
	. = ..()
	radio = new(src)
	radio.keyslot = new radio_key
	radio.set_listening(FALSE)
	radio.recalculateChannels()

	RegisterSignal(src, COMSIG_ATOM_INTERNAL_EXPLOSION, PROC_REF(check_explosion))



/obj/machinery/demon_core/Destroy(force)
	. = ..()
	UnregisterSignal(src, COMSIG_ATOM_INTERNAL_EXPLOSION)
	QDEL_NULL(radio)

/obj/machinery/demon_core/process_atmos()
	//Preliminary checks
	var/turf/local_turf = loc
	if(!istype(local_turf))
		return
	if(isclosedturf(local_turf))
		return

	var/datum/gas_mixture/local_env = loc.return_air()
	var/list/area_of_effect = list(loc)
	var/our_temp = local_env.return_temperature()
	area_of_effect += local_turf.atmos_adjacent_turfs
	if(isnull(our_core))
		return

	var/minimum_temp = our_core.min_temperature
	var/instability_temp = our_core.instability_threshold
	var/maximum_temp = our_core.max_temperature

	if(our_temp >= minimum_temp && our_temp <= instability_temp)
		if(!fusing && COOLDOWN_FINISHED(src, implosion_attempt))
			say("Temperature threshold reached! Initiating implosion.")
			//radio.talk_into(src, "Temperature threshold reached! Initiating implosion.", RADIO_CHANNEL_ENGINEERING, list(SPAN_ROBOT))
			COOLDOWN_START(src, implosion_attempt, 10 SECONDS)
			sleep(1 SECONDS)
			attempts_implosion()
			return
		else if(fusing)
			destabilizing = FALSE
			catalyze_area(area_of_effect)
	else if(our_temp >= instability_temp && our_temp <= maximum_temp)
		if(!destabilizing)
			radio.talk_into(src, "Caution! Core stability decreasing.", RADIO_CHANNEL_ENGINEERING, list(SPAN_ROBOT))
		destabilizing = TRUE
		if(COOLDOWN_FINISHED(src, emission_effects))
			emission()
	else if(our_temp >= maximum_temp)
		melt_down()

//Contain all the player interaction code for the core
/obj/machinery/demon_core/interact(mob/user)
	. = ..()
	if(!check_area())
		say(failed_reason)
		return

/obj/machinery/demon_core/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	. = ..()
	if(!inserted_ttv || !inserted_tank)
		if(istype(tool, /obj/item/transfer_valve))
			var/obj/item/transfer_valve/valve = tool
			if(!valve.ready())
				say("[valve] is incomplete.")
				return ITEM_INTERACT_BLOCKING
			inserted_ttv = tool
		else if(istype(tool, /obj/item/tank))
			var/obj/item/tank/ref_tank = tool
			if(!ref_tank.bomb_status)
				say("Single tank bomb incomplete.")
				return ITEM_INTERACT_BLOCKING
			inserted_tank = tool

	if(istype(tool, /obj/item/fusion_core/plasma))
		our_core = tool
		icon_state ="pedestal_plasma"
		SSair.start_processing_machine(src)

	if(!user.transferItemToLoc(tool, src))
		to_chat(user, span_warning("[tool] is stuck to your hand."))
		return ITEM_INTERACT_BLOCKING
	to_chat(user, span_notice("You insert [tool] into [src]"))

	return ITEM_INTERACT_SUCCESS

/obj/machinery/demon_core/crowbar_act(mob/living/user, obj/item/tool)
	. = ..()
	inserted_ttv?.forceMove(drop_location())
	inserted_tank?.forceMove(drop_location())

/// Check the area surrounding the core to make sure its open and its clear from disturbances
/obj/machinery/demon_core/proc/check_area()
	for(var/turf/ref_turf in view(2, src))
		if(istype(ref_turf, /turf/closed))
			failed_reason = "Reaction area obstructed! Ensured a clear 3 by 3 area to start fusion."
			return FALSE
	return TRUE

/obj/machinery/demon_core/hitby(atom/movable/hit_by, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum)
	. = ..()
	if(istype(hit_by, /obj/projectile/energy/nuclear_particle))
		// Half of the energy is recovered
		internal_energy += 1 / 2

/// Itereate through given turfs and catalyze the reaction
/obj/machinery/demon_core/proc/catalyze_area(list/list_of_turfs)
	//Handle catalyzing adjacent air mixes
	for(var/turf/adjacent_turf in list_of_turfs)
		if(!istype(adjacent_turf))//We are in a crate or somewhere that isn't turf, if we return to turf resume processing but for now.
			return
		if(isclosedturf(adjacent_turf))
			return

		var/datum/gas_mixture/environment = adjacent_turf.return_air()

		if(!environment)
			return
		if(internal_energy <= 0)
			stop_fusing()
			return
		catalyze_reaction(environment, adjacent_turf)
		internal_energy --
		air_update_turf(FALSE, FALSE)

/obj/machinery/demon_core/proc/catalyze_reaction(datum/gas_mixture/target_mix, turf/open/target_turf)

	target_mix.fuse(target_turf)

// Kick start our fusion core by detonating a payload if it succeed we get fusion if it doesnt then womp womp
/obj/machinery/demon_core/proc/attempts_implosion()
	if(!inserted_ttv && !inserted_tank)
		say("No explosive payload detected, canceling kick start.")
		return
	for(var/message_type in message_list)
		radio.talk_into(src, message_type, RADIO_CHANNEL_ENGINEERING, list(SPAN_ROBOT))
		sleep(1 SECONDS)

	inserted_ttv?.toggle_valve(inserted_ttv.tank_one, loud_toggle = FALSE)
	inserted_tank?.ignite()


/obj/machinery/demon_core/proc/check_explosion(atom/source, list/arguments)
	SIGNAL_HANDLER

	. = COMSIG_CANCEL_EXPLOSION

	var/heavy = arguments[EXARG_KEY_DEV_RANGE]
	var/medium = arguments[EXARG_KEY_HEAVY_RANGE]
	var/light = arguments[EXARG_KEY_LIGHT_RANGE]
	var/explosion_range = max(heavy, medium, light, 0)
	var/turf/location = get_turf(src)

	var/cap_multiplier = SSmapping.level_trait(location.z, ZTRAIT_BOMBCAP_MULTIPLIER)
	if(isnull(cap_multiplier))
		cap_multiplier = 1
	var/capped_heavy = min(GLOB.MAX_EX_DEVESTATION_RANGE * cap_multiplier, heavy)
	var/capped_medium = min(GLOB.MAX_EX_HEAVY_RANGE * cap_multiplier, medium)
	SSexplosions.shake_the_room(location, explosion_range, (capped_heavy * 15) + (capped_medium * 20), capped_heavy / 2, capped_medium)
	if(our_core.explosion_req <= explosion_range)
		fusing = TRUE
		internal_energy = explosion_range * our_core.energy_multiplier
	inserted_tank?.forceMove(drop_location())
	inserted_ttv?.forceMove(drop_location())

	return

// Create special effects when instability threshold is passed
/obj/machinery/demon_core/proc/emission()
	for(var/turf/ref_turf in view(5, loc))
		if(prob(30))
			ref_turf.Shake(duration = 0.3)



	playsound(src, 'sound/effects/thump.ogg', 100)

	COOLDOWN_START(src, emission_effects, 10 SECONDS)

/obj/machinery/demon_core/proc/melt_down()
	for(var/obj/thing in oview(4, loc))
		if(thing.anchored)
			continue
		var/src_target_dir = get_dir(src, thing)
		var/turf/target_turf = get_ranged_target_turf(thing, src_target_dir, 2)
		thing.throw_at(target_turf, 2, 2)
	for(var/mob/too_close in oview(4, loc))
		if(!too_close.mob_negates_gravity())
			var/mob_dir = get_dir(src, too_close)
			var/turf/target_turf = get_ranged_target_turf(too_close, mob_dir, 2)
			too_close.throw_at(target_turf, 2, 2)
	QDEL_NULL(our_core)
	stop_fusing()

/obj/machinery/demon_core/proc/stop_fusing()
	destabilizing = FALSE
	fusing = FALSE
	SSair.stop_processing_machine(src)
	our_core.forceMove(drop_location())
