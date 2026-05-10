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
	///internal gas mix of the core
	var/datum/gas_mixture/internal_mix
	///internal volume
	var/volume = CELL_VOLUME

	var/emergency_channel = null // Need null to actually broadcast, lol.

	var/static/message_list = list("Begining kickstart sequence in...", "5", "4", "3", "2", "1")

	var/failed_reason


	STATIC_COOLDOWN_DECLARE(kickstart_cd)


/obj/machinery/demon_core/Initialize(mapload)
	. = ..()
	radio = new(src)
	radio.keyslot = new radio_key
	radio.set_listening(FALSE)
	radio.recalculateChannels()
	RegisterSignal(src, COMSIG_ATOM_INTERNAL_EXPLOSION, PROC_REF(begin_fusion))

	payloads = list(inserted_ttv, inserted_tank, inserted_grenade)
	internal_mix = new(volume)
	internal_mix.set_gas(/datum/gas/plasma, 2000)
	internal_mix.set_gas(/datum/gas/oxygen, 2000)

/obj/machinery/demon_core/Destroy(force)
	. = ..()
	UnregisterSignal(src, COMSIG_ATOM_INTERNAL_EXPLOSION)
	QDEL_NULL(radio)
	payloads = null

/obj/machinery/demon_core/process_atmos()
	// PART 1: PRELIMINARIES
	var/turf/local_turf = loc
	if(!istype(local_turf))//We are in a crate or somewhere that isn't turf, if we return to turf resume processing but for now.
		return
	if(isclosedturf(local_turf))
		return
	var/is_spaced = FALSE
	if(isturf(src.loc))
		local_turf = src.loc
		for (var/turf/open/space/turf in ((local_turf.atmos_adjacent_turfs || list()) + local_turf))
			is_spaced = TRUE

	var/datum/gas_mixture/our_mix = local_turf.return_air()
	for(var/turf/open/target_turf in view(1, loc))
		var/datum/gas_mixture/target_mix = target_turf.return_air()


	if(prob(10 * stage))
		fire_nuclear_particle()
	if(check_fusion_req())
		fusion_reaction(our_mix)
	else
		fail_to_sustain()

/// Check the area surrounding the core to make sure its open and its clear from disturbances
/obj/machinery/demon_core/proc/check_area()
	for(var/turf/ref_turf in view(2, src))
		if(istype(ref_turf, /turf/closed))
			failed_reason = "Reaction area obstructed! Ensured a clear 3 by 3 area to start fusion."
			return FALSE
	return TRUE

/// Check the atmospheric conditions around the core to advance a stage
/obj/machinery/demon_core/proc/check_stage_requirement()
	var/turf/open/our_turf = get_turf(src)
	var/datum/gas_mixture/present_mix = our_turf.air

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
				failed_reason = "Temperature below 10'000 Kelvin."
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
	var/list/cached_gas = tile_mix.gases
	var/conditions_passed = TRUE
	switch(stage)
		if(1)
			fuel_req = list(/datum/gas/plasma = 2000, /datum/gas/carbon_dioxide = 4000)
		if(2)
			fuel_req = list(/datum/gas/tritium = 1500, /datum/gas/hydrogen = 3700)
		if(3)
			fuel_req = list(/datum/gas/pluoxium = 500, /datum/gas/freon = 800)

	for(var/gas_type in fuel_req)
		if(!(gas_type in cached_gas))
			conditions_passed = FALSE
			break
		else if(cached_gas[gas_type][MOLES] < fuel_req[gas_type])// insufficient fuel
			conditions_passed = FALSE

	return conditions_passed

/// Handle the fusion reaction, consuming gas, releasing gas and heat
/// Gas species and mols requirements are already checked in check_fusion_req so we sure they do exist
/obj/machinery/demon_core/proc/fusion_reaction(datum/gas_mixture/tile_mix)
	var/list/cached_gases = tile_mix.gases
	switch(stage)
		// Each stage releases its own more advance gasses as well as more heat
		if(1) //Plasmic fusion, consuming plasma, carbon dioxide: 1 P + 4 CO2 = 3 O2 + 2 BZ
			tile_mix.temperature += 10000
			cached_gases[/datum/gas/plasma][MOLES] -= 10
			cached_gases[/datum/gas/carbon_dioxide][MOLES] -= 40
			tile_mix.assert_gases(/datum/gas/oxygen, /datum/gas/bz)
			cached_gases[/datum/gas/oxygen][MOLES] += 30
			cached_gases[/datum/gas/bz][MOLES] += 20
		if(2)// Hydrogen fusion
			tile_mix.temperature += 1e6
			tile_mix.assert_gases(/datum/gas/proto_nitrate, /datum/gas/healium)
			cached_gases[/datum/gas/tritium][MOLES] -= 7
			cached_gases[/datum/gas/hydrogen][MOLES] -= 8
			cached_gases[/datum/gas/proto_nitrate][MOLES] += 5
			cached_gases[/datum/gas/healium][MOLES] += 10
		if(3)// Heavy gas fusion
			tile_mix.temperature += 1e10
			tile_mix.assert_gases(/datum/gas/zauker, /datum/gas/halon)
			cached_gases[/datum/gas/pluoxium][MOLES] -= 24
			cached_gases[/datum/gas/freon][MOLES] -= 16
			cached_gases[/datum/gas/zauker][MOLES] += 5
			cached_gases[/datum/gas/halon][MOLES] += 36

/obj/machinery/demon_core/proc/begin_emission()
	//prepare the gases to eject and directions
	var/chosen_dir = pick(GLOB.cardinals)
	var/datum/gas_mixture/removed = internal_mix.remove_ratio(0.8)
	var/list/cached_gas = removed.gases
	var/turf/starting_turf = loc
	var/list/jet_line = list(get_step(starting_turf, chosen_dir))


	//var/turf/destination = get_edge_target_turf(starting_turf, chosen_dir)

	/*var/obj/projectile/plasma_ball/mass_ejected = new /obj/projectile/plasma_ball(starting_turf)
	mass_ejected.aim_projectile(destination, src)
	mass_ejected.gas_to_eject = internal_mix.remove_ratio(0.5) // half of our internal mix goes out
	*/
	for(var/turf/ref in jet_line)
		if(jet_line.len >= 4)
			break
		if(iswallturf(ref))
			SSexplosions.high_mov_atom += ref

		jet_line += ref
		var/turf/open/env_turf = ref
		var/datum/gas_mixture/env_gas = env_turf.return_air()
		env_gas.set_temperature(5000)
		for(var/gas_id in cached_gas)
			env_gas.adjust_gas(gas_id, (cached_gas[gas_id][MOLES] * 0.3))// 30% of the 80% gas moles removed from internal mixed transfered
		jet_line += get_step(ref, chosen_dir)
		env_turf.air_update_turf()
		env_turf.add_atom_colour(COLOR_BLUE, TEMPORARY_COLOUR_PRIORITY)
	emission_effects()

// Impact and visual effects of an emision
/obj/machinery/demon_core/proc/emission_effects()
	for(var/turf/ref_turf in view(4, loc))
		if(prob(30))
			ref_turf.Shake(duration = 1, shake_interval = 0.2)
	//if(stage >= 2)// after level 2 we create shockwave
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
	playsound(src, 'sound/effects/thump.ogg', 100)

/obj/machinery/demon_core/update_appearance(updates)
	. = ..()
	var/internal_temp = internal_mix.return_temperature()
	if(internal_temp <= 1000)
		icon_state = "stage_[1]"
	if(internal_temp <= 5000)
		icon_state = "stage_[2]"
	if(internal_temp <= 10000)
		icon_state = "stage_[3]"
	if(internal_temp <= 25000)
		icon_state = "stage_[4]"
	if(internal_temp <= 50000)
		icon_state = "stage_[5]"
	if(internal_temp <= 1e6)
		icon_state = "stage_[6]"



/obj/machinery/demon_core/proc/suck_gas(datum/gas_mixture/environment)
	var/datum/gas_mixture/incoming = environment.remove_ratio(0.4) //40% of surrounding gas is taken up
	internal_mix.merge(incoming)

//Contain all the player interaction code for the core

/obj/machinery/demon_core/interact(mob/user)
	. = ..()
	if(!check_area())
		say(failed_reason)
		return
	/*else if(!check_stage_requirement())
		say("Atmospheric conditions not met![failed_reason]")
		return*/
	kick_start()

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


/obj/projectile/plasma_ball
	name = "plasma ball"
	desc = "Concentrated plasma matter, will evaporated almost anything."
	icon_state = "solarflare"
	damage_type = BURN
	armor_flag = FIRE //We're operating off of anime remote slash logic here. As such, we can treat this as a hybrid burn/brute this way.
	damage = 100 // Damage amps based on the number of flame_charges it was created off of.
	speed = 2
	light_range = 1
	light_power = 1
	light_color = LIGHT_COLOR_FIRE
	var/datum/gas_mixture/gas_to_eject

/obj/projectile/plasma_ball/Initialize(mapload)
	. = ..()
	RegisterSignal(src, )

/obj/projectile/plasma_ball/on_hit(atom/target, blocked, pierce_hit)
	. = ..()

	if(isatom(target))
		SSexplosions.high_mov_atom += target
