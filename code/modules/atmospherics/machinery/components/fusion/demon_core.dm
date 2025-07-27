// Fusion V8, this core is used to power open turf fusion reaction
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
	/// The TTV inserted in the machine.
	var/obj/item/transfer_valve/inserted_bomb
	///Our internal radio
	var/obj/item/radio/radio
	///The key our internal radio uses
	var/radio_key = /obj/item/encryptionkey/headset_eng

	var/emergency_channel = null // Need null to actually broadcast, lol.

	var/static/message_list = list("Kickstarting reaction in 5...", "4", "3", "2", "1")

	var/failed_reason

/obj/machinery/demon_core/Initialize(mapload)
	. = ..()
	radio = new(src)
	radio.keyslot = new radio_key
	radio.set_listening(FALSE)
	radio.recalculateChannels()
	RegisterSignal(src, COMSIG_ATOM_INTERNAL_EXPLOSION, PROC_REF(begin_fusion))

/obj/machinery/demon_core/Destroy(force)
	. = ..()
	UnregisterSignal(src, COMSIG_ATOM_INTERNAL_EXPLOSION)
	QDEL_NULL(radio)

/obj/machinery/demon_core/process_atmos()
	var/turf/open/our_turf = get_turf(src)

	our_turf.air.temperature += 1e6 * stage

	if(prob(40))
		fire_nuclear_particle()

/obj/machinery/demon_core/proc/kick_start()
	for(var/message_type in message_list)
		radio.talk_into(src, message_type, emergency_channel, list(SPAN_COMMAND))
		sleep(1 SECONDS)

	inserted_bomb.toggle_valve(inserted_bomb.tank_one)

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
	for(var/turf/target_turf in view(4, src))
		if(prob(20))
			target_turf.Shake(duration = 0.1)
	stage = 1
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
	if(istype(tool, /obj/item/transfer_valve))
		if(inserted_bomb)
			to_chat(user, span_warning("There is already a bomb in [src]."))
			return
		var/obj/item/transfer_valve/valve = tool
		if(!valve.ready())
			to_chat(user, span_warning("[valve] is incomplete."))
			return
		if(!user.transferItemToLoc(tool, src))
			to_chat(user, span_warning("[tool] is stuck to your hand."))
			return
		inserted_bomb = tool
		to_chat(user, span_notice("You insert [tool] into [src]"))
		return

	return ..()

/obj/machinery/demon_core/proc/check_area()
	for(var/turf/ref_turf in view(3, src))
		if(istype(ref_turf, /turf/closed))
			failed_reason = "Reaction area obstructed! Ensured a clear 3 by 3 area to start fusion."
			return FALSE
	return TRUE

/obj/machinery/demon_core/proc/check_atmos()
	var/turf/open/our_turf = get_turf(src)

	if(our_turf.air.has_gas(/datum/gas/plasma, 100) && our_turf.air.temperature >= 1000)
		failed_reason = "Need more mols of plasma and temperature exceeding 1000 Kelvin."
		return TRUE
	return FALSE

