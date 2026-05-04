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
