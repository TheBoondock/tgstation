//fusion: a terrible idea that was fun but broken. Now reworked to be less broken and more interesting. Again (and again, and again). Again! Again but with machine! Again but with machine assisted open turf!
//Fusion Rework Counter: Please increment this if you make a major overhaul to this system again.
//8 reworks

/obj/machinery/demon_core
	name = "Demon core"
	desc = "fusion reactor core known for its instability and almost alive state"
	icon = 'icons/obj/machines/atmospherics/fusion.dmi'
	icon_state = "stage_1"
	use_power = NO_POWER_USE
	anchored = TRUE
	density = TRUE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF | FREEZE_PROOF
	/// What stages are we in, use in determining output gasses and heat as well as other effect.
	var/stage = 0
	/// The TTV inserted in the core.
	var/obj/item/transfer_valve/inserted_ttv
	/// The grenade inserted into the core.
	var/obj/item/grenade/inserted_grenade
	/// The single tank assembly bomb inserted into the core.
	var/obj/item/tank/inserted_tank
	///Our internal radio
	var/obj/item/radio/radio
	///The key our internal radio uses
	var/radio_key = /obj/item/encryptionkey/headset_eng

	var/emergency_channel = null // Need null to actually broadcast, lol.

	var/static/message_list = list("Kickstarting reaction in 5...", "4", "3", "2", "1")

	var/failed_reason

	var/kickstart_cd

/obj/machinery/demon_core/Initialize(mapload)
	. = ..()
	radio = new(src)
	radio.keyslot = new radio_key
	radio.set_listening(FALSE)
	radio.recalculateChannels()
	RegisterSignal(src, COMSIG_ATOM_INTERNAL_EXPLOSION, PROC_REF(begin_fusion))
	COOLDOWN_DECLARE(kickstart_cd)

/obj/machinery/demon_core/Destroy(force)
	. = ..()
	UnregisterSignal(src, COMSIG_ATOM_INTERNAL_EXPLOSION)
	QDEL_NULL(radio)

/obj/machinery/demon_core/process_atmos()
	// PART 1: PRELIMINARIES
	var/turf/local_turf = loc
	if(!istype(local_turf))//We are in a crate or somewhere that isn't turf, if we return to turf resume processing but for now.
		return  //Yeah just stop.
	if(isclosedturf(local_turf))
		return

	var/datum/gas_mixture/our_mix = local_turf.return_air()
	if(prob(40))
		fire_nuclear_particle()
	perform_stage_effect(our_mix)

// Kick start our fusion core by detonating a payload if it succeed we get fusion if it doesnt then womp womp
/obj/machinery/demon_core/proc/kick_start()
	if(!COOLDOWN_FINISHED(src, kickstart_cd))
		say("Core not ready to be kick started again.")
		return
	if(isnull(inserted_ttv) || isnull(inserted_tank) || isnull(inserted_grenade))
		say("No explosive payload detected, canceling kick start.")
		return
	for(var/message_type in message_list)
		radio.talk_into(src, message_type, emergency_channel, list(SPAN_COMMAND))
		sleep(1 SECONDS)

	inserted_ttv?.toggle_valve(inserted_ttv.tank_one)
	inserted_grenade?.detonate()
	inserted_tank?.ignite()
	COOLDOWN_START(src, kickstart_cd, 2 MINUTES)
	addtimer(CALLBACK(src, PROC_REF(ready_to_advance)), 2 MINUTES)

// Prepare our fusion core to advance to next stage/power level/fusion tier whatever you call it
/obj/machinery/demon_core/proc/ready_to_advance()
	say("Fusion core stabilized, ready for higher fusion reaction. Awaiting kick start...")
	SSair.stop_processing_machine(src)
	eject_bomb()
	return

/obj/machinery/demon_core/proc/begin_fusion(atom/source, list/arguments)
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
	SSexplosions.shake_the_room(location, explosion_range, (capped_heavy * 15) + (capped_medium * 20), capped_heavy, capped_medium)

	for(var/i = 1, i <= 20, i++)
		fire_nuclear_particle()
	if(stage == 1)
		for(var/turf/target_turf in view(4, src))
			if(prob(40))
				target_turf.Shake(duration = 0.1)
	stage += 1
	SSair.start_processing_machine(src)
	return

/obj/machinery/demon_core/interact(mob/user)
	. = ..()
	if(!check_area())
		say(failed_reason)
		return
	else if(!check_atmos())
		say("Atmospheric conditions not met!")
		say(failed_reason)
		return
	kick_start()

/obj/machinery/demon_core/attacked_by(obj/item/tool, mob/living/user, list/modifiers, list/attack_modifiers)
	if(inserted_ttv || inserted_tank || inserted_grenade)
		say("Payload already occupied.")
		return
	if(istype(tool, /obj/item/transfer_valve))
		var/obj/item/transfer_valve/valve = tool
		if(!valve.ready())
			say("[valve] is incomplete.")
			return
		if(!user.transferItemToLoc(tool, src))
			to_chat(user, span_warning("[tool] is stuck to your hand."))
			return
		inserted_ttv = tool
	else if(istype(tool, /obj/item/grenade))
		if(!user.transferItemToLoc(tool, src))
			to_chat(user, span_warning("[tool] is stuck to your hand."))
			return
		inserted_grenade = tool
	else if(istype(tool, /obj/item/tank))
		var/obj/item/tank/ref_tank = tool
		if(!ref_tank.bomb_status)
			say("Single tank bomb incomplete.")
			return
		if(!user.transferItemToLoc(tool, src))
			to_chat(user, span_warning("[tool] is stuck to your hand."))
			return
		inserted_tank = tool

	to_chat(user, span_notice("You insert [tool] into [src]"))

	return ..()

/obj/machinery/demon_core/wrench_act(mob/living/user, obj/item/tool)
	. = ..()
	if(inserted_ttv)
		inserted_ttv.forceMove(drop_location())
	else if(inserted_grenade)
		inserted_grenade.forceMove(drop_location())
	else if(inserted_tank)
		inserted_tank.forceMove(drop_location())

/// We dont allow incomplete valves to go in but do code in checks for incomplete valves. Just in case.
/obj/machinery/demon_core/proc/eject_bomb()
	if(inserted_ttv)
		inserted_ttv.forceMove(drop_location())
	else if(inserted_grenade)
		inserted_grenade.forceMove(drop_location())
	else if(inserted_tank)
		inserted_tank.forceMove(drop_location())

/// Check the area surrounding the core to make sure its open and its clear from disturbances
/obj/machinery/demon_core/proc/check_area()
	for(var/turf/ref_turf in view(3, src))
		if(istype(ref_turf, /turf/closed))
			failed_reason = "Reaction area obstructed! Ensured a clear 3 by 3 area to start fusion."
			return FALSE
	return TRUE

/// Check the atmospheric conditions around the core
/obj/machinery/demon_core/proc/check_atmos()
	var/turf/open/our_turf = get_turf(src)

	if(our_turf.air.has_gas(/datum/gas/plasma, 100) && our_turf.air.temperature >= 1000)
		failed_reason = "Need more mols of plasma and temperature exceeding 1000 Kelvin."
		return TRUE
	return FALSE

/obj/machinery/demon_core/proc/perform_stage_effect(datum/gas_mixture/turf_mixture)
	switch(stage)
		// stage 1 we simply heat up the gasses by 100 degrees and output oxygen + plasma
		if(1)
			turf_mixture.temperature += 100
			turf_mixture.assert_gases(list(/datum/gas/oxygen, /datum/gas/plasma))
			turf_mixture.gases[/datum/gas/oxygen][MOLES] += 50
			turf_mixture.gases[/datum/gas/plasma][MOLES] += 50
		if(2)
			turf_mixture.temperature += 1000
			turf_mixture.assert_gases(list(/datum/gas/bz, /datum/gas/tritium))
			turf_mixture.gases[/datum/gas/bz][MOLES] += 50
			turf_mixture.gases[/datum/gas/tritium][MOLES] += 50

