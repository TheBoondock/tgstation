//fusion: a terrible idea that was fun but broken. Now reworked to be less broken and more interesting. Again (and again, and again). Again! Again but with machine! Again but with machine assisted open turf!
//Fusion Rework Counter: Please increment this if you make a major overhaul to this system again.
//8 reworks

#define radius_1 8
#define radius_2 20
#define radius_3 30

/obj/machinery/demon_core
	name = "demon core"
	desc = "Fusion reactor core known for its instability and almost alive behaviour."
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
	/// list of payloads
	var/list/payloads

	///Our internal radio
	var/obj/item/radio/radio
	///The key our internal radio uses
	var/radio_key = /obj/item/encryptionkey/headset_eng
	/// The requirements to go to stage 1
	var/list/stage1_req
	/// The requirements to go to stage 2
	var/list/stage2_req
	/// The requirements to go to stage 3
	var/list/stage3_req
	/// The heat capacity of the core
	var/core_heatcap
	/// The temperature of the core
	var/core_temperature

	var/emergency_channel = null // Need null to actually broadcast, lol.

	var/static/message_list = list("Begining kickstart sequence in...", "5", "4", "3", "2", "1")

	var/failed_reason


	STATIC_COOLDOWN_DECLARE(kickstart_cd)
	STATIC_COOLDOWN_DECLARE(update_gas_info)


/obj/machinery/demon_core/Initialize(mapload)
	. = ..()
	radio = new(src)
	radio.keyslot = new radio_key
	radio.set_listening(FALSE)
	radio.recalculateChannels()
	RegisterSignal(src, COMSIG_ATOM_INTERNAL_EXPLOSION, PROC_REF(begin_fusion))
	payloads = list(inserted_ttv, inserted_tank, inserted_grenade)

/obj/machinery/demon_core/Destroy(force)
	. = ..()
	UnregisterSignal(src, COMSIG_ATOM_INTERNAL_EXPLOSION)
	QDEL_NULL(radio)
	payloads = null

/obj/machinery/demon_core/interact(mob/user)
	. = ..()
	if(!check_area())
		say(failed_reason)
		return
	/*else if(!check_atmos())
		say("Atmospheric conditions not met![failed_reason]")
		return*/
	kick_start()

/obj/machinery/demon_core/process_atmos()
	// PART 1: PRELIMINARIES
	var/turf/local_turf = loc
	if(!istype(local_turf))//We are in a crate or somewhere that isn't turf, if we return to turf resume processing but for now.
		return  //Yeah just stop.
	if(isclosedturf(local_turf))
		return
	var/is_spaced = FALSE
	if(isturf(src.loc))
		local_turf = src.loc
		for (var/turf/open/space/turf in ((local_turf.atmos_adjacent_turfs || list()) + local_turf))
			is_spaced = TRUE

	var/datum/gas_mixture/our_mix = local_turf.return_air()
	var/pressure = our_mix.return_pressure()
	if(pressure == 0 || is_spaced)
		vacuum_exposed()
	if(prob(10 * stage))
		fire_nuclear_particle()
	if(check_fusion_req())
		fusion_reaction(our_mix)
	else
		fail_to_sustain()


/obj/machinery/demon_core/attacked_by(obj/item/tool, mob/living/user, list/modifiers, list/attack_modifiers)
	if(isnull(inserted_ttv) && isnull(inserted_tank) && isnull(inserted_grenade))
		if(istype(tool, /obj/item/transfer_valve))
			var/obj/item/transfer_valve/valve = tool
			if(!valve.ready())
				say("[valve] is incomplete.")
				return
			inserted_ttv = tool
		else if(istype(tool, /obj/item/grenade))
			inserted_grenade = tool
		else if(istype(tool, /obj/item/tank))
			var/obj/item/tank/ref_tank = tool
			if(!ref_tank.bomb_status)
				say("Single tank bomb incomplete.")
				return
			inserted_tank = tool
		if(!user.transferItemToLoc(tool, src))
			to_chat(user, span_warning("[tool] is stuck to your hand."))
			return

	to_chat(user, span_notice("You insert [tool] into [src]"))

	return ..()

/obj/machinery/demon_core/crowbar_act(mob/living/user, obj/item/tool)
	. = ..()
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
	var/datum/gas_mixture/past_mix
	var/datum/gas_mixture/present_mix = our_turf.air
	// We check atmos conditions every 2 seconds for conditions that require changes over time
	if(COOLDOWN_FINISHED(src, update_gas_info))
		past_mix = present_mix.copy()
		COOLDOWN_START(src, update_gas_info, 2 SECONDS)
	// The conditions are for advancing into the next stage hence it will be refered to the next stage rather than current
	switch(stage)
		// Temperature prerequisites higher stae = higher temp
		if(0)
			if(present_mix.temperature >= 1000)
				return TRUE
			else
				failed_reason = "Temperature and plasma below 1'000 Kelvin."
				return FALSE
		if(1)
			if(present_mix.temperature >= 10000)
				return TRUE
			else
				failed_reason = "Temperature below 10'000 Kelvin.______qdel_list_wrapper"
				return FALSE
		if(2)
			if(present_mix.temperature >= 1e6)
				return TRUE
			else
				failed_reason = "Temperature below 1e6 Kelvin."
				return FALSE


// Kick start our fusion core by detonating a payload if it succeed we get fusion if it doesnt then womp womp
/obj/machinery/demon_core/proc/kick_start()
	if(!COOLDOWN_FINISHED(src, kickstart_cd))
		say("Core not ready to be kick started again.")
		return
	if(isnull(inserted_ttv) && isnull(inserted_tank) && isnull(inserted_grenade))
		say("No explosive payload detected, canceling kick start.")
		return
	for(var/message_type in message_list)
		radio.talk_into(src, message_type, FREQ_ENGINEERING, list(SPAN_ROBOT))
		sleep(1 SECONDS)

	inserted_ttv?.toggle_valve(inserted_ttv.tank_one, loud_toggle = FALSE)
	inserted_grenade?.detonate()
	inserted_tank?.ignite()

/// Prepare our fusion core to advance to next stage/power level/fusion tier whatever you call it
/obj/machinery/demon_core/proc/ready_to_advance()
	if(src in SSair.atmos_machinery)
		say("Fusion core stabilized, ready for higher fusion reaction. Awaiting kick start...")
		SSair.stop_processing_machine(src)
	return
/// Stop processing since we can no longer sustain a reaction
/obj/machinery/demon_core/proc/fail_to_sustain()
	say("Insufficient heat and fuel to sustain fusion, core reaction halted!")
	SSair.stop_processing_machine(src)
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
	if(stage >= 1)// after level 1 we begin violently shaking the place to create a sense of dread
		for(var/turf/target_turf in view(4, src))
			if(prob(40))
				target_turf.Shake(duration = 1, shake_interval = 0.2)
	if(stage >= 2)// after level 2 we create shockwave
		for(var/atom/movable/thing in view(5, src))
			thing.throw_at()
	stage += 1
	update_appearance()
	for(var/ref_payload in payloads)
		ref_payload = null
	SSair.start_processing_machine(src)
	COOLDOWN_START(src, kickstart_cd, 2 MINUTES)
	addtimer(CALLBACK(src, PROC_REF(ready_to_advance)), 2 MINUTES)
	return

/// Check the gas mix if it can sustain the fusion reaction
/// Return true if it can, false if not
/obj/machinery/demon_core/proc/check_fusion_req(datum/gas_mixture/tile_mix)
	var/list/fuel_req
	var/conditions_passed = TRUE
	switch(stage)
		if(1)
			fuel_req = list(/datum/gas/plasma = 2000, /datum/gas/carbon_dioxide = 4000)
		if(2)
			fuel_req = list(/datum/gas/tritium = 1500, /datum/gas/bz = 3700, /datum/gas/freon)
		if(3)
			fuel_req = list(/datum/gas/proto_nitrate = 500, /datum/gas/pluoxium = 1500)

	for(var/gas_type in fuel_req)
		if(tile_mix.gases[gas_type][MOLES] < fuel_req[gas_type])// insufficient fuel
			conditions_passed = FALSE

	return TRUE

/// Handle the fusion reaction, consuming gas, releasing gas and heat
/obj/machinery/demon_core/proc/fusion_reaction(datum/gas/tile_mix)
	var/list/cached_gases = tile_mix.gasses
	switch(stage)
		// Each stage releases its own more advance gasses as well as more heat
		if(1) //Plasmic fusion, consuming plasma, carbon dioxide: 1 P + 4 CO2 = 3 O2 + 2 BZ
			tile_mix.temperature += 1000
			cached_gases[/datum/gas/plasma][MOLES] -= 10
			cached_gases[/datum/gas/carbon_dioxide][MOLES] -= 40
			tile_mix.assert_gases(/datum/gas/plasma, /datum/gas/bz)
			cached_gases[/datum/gas/oxygen][MOLES] += 30
			cached_gases[/datum/gas/bz][MOLES] += 20
		if(2)
			tile_mix.temperature += 1e6
			tile_mix.assert_gases(/datum/gas/bz, /datum/gas/hydrogen)
			cached_gases.gases[/datum/gas/bz][MOLES] += 50
			cached_gases.gases[/datum/gas/hydrogen][MOLES] += 50
		if(3)
			tile_mix.temperature += 1e10
			tile_mix.assert_gases(/datum/gas/pluoxium, /datum/gas/freon)
			cached_gases.gases[/datum/gas/pluoxium][MOLES] += 50
			cached_gases.gases[/datum/gas/freon][MOLES] += 50

/obj/machinery/demon_core/proc/vacuum_exposed()
	switch(stage)
		if(1)
			core_temperature += 100
		if(2)
			core_temperature += 1000
		if(3)
			core_temperature += 10000
		if(4)
			core_temperature += 100000
		if(5)
			core_temperature += 1e6
		if(6)
			core_temperature += 1e7

/obj/machinery/demon_core/update_appearance(updates)
	. = ..()
	icon_state = "stage_[stage]"

