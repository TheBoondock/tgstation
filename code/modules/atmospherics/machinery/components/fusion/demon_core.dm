// Fusion V8, this core is used to power open turf fusion reaction
/obj/machinery/demon_core
	name = "Demon core"
	desc = "fusion reactor core known for its instability and almost alive state"
	icon = 'icons/obj/machines/atmospherics/fusion.dmi'
	icon_state = "stage_1"
	use_power = NO_POWER_USE
	anchored = TRUE
	/// What stages are we in, use in determining output gasses and heat as well as other effect.
	var/stage = 0
	/// The TTV inserted in the machine.
	var/obj/item/transfer_valve/inserted_bomb
	/// The gas mix currently submerging the core.
	var/datum/gas_mixture/tile_mix
	///Our internal radio
	var/obj/item/radio/radio
	///The key our internal radio uses
	var/radio_key = /obj/item/encryptionkey/headset_eng

	var/emergency_channel = null // Need null to actually broadcast, lol.

	var/static/message_list = list("Beginning kick start reaction in 5...", "4", "3", "2", "1")

/obj/machinery/demon_core/Initialize(mapload)
	. = ..()
	SSair.start_processing_machine(src)
	radio = new(src)
	radio.keyslot = new radio_key
	radio.set_listening(FALSE)
	radio.recalculateChannels()

/obj/machinery/demon_core/process_atmos()
	var/turf/open/our_turf = get_turf(src)
	tile_mix = our_turf.air

	tile_mix.temperature += 1e6 * stage

/obj/machinery/demon_core/proc/kick_start()
	for(var/message_type in message_list)
		radio.talk_into(src, message_type, emergency_channel, list(SPAN_COMMAND))
		sleep(1 SECONDS)

	inserted_bomb.toggle_valve(inserted_bomb.tank_one)
	for(var/i = 1, i <= 20, i++)
		fire_nuclear_particle()
	stage = 1

/obj/machinery/demon_core/interact(mob/user)
	. = ..()
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


