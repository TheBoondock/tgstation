/obj/machinery/computer/core_monitor
	name = "fusion core monitor"
	desc = "A computer to remotely cmonitor fusion core"
	icon_state = MAP_SWITCH("computer", "/obj/machinery/computer/core_monitor")
	icon_screen = "generic"
	icon_keyboard = "generic_key"
	circuit = /obj/item/circuitboard/computer/demon_core
	///Weakref of the connected machine to this computer
	var/datum/weakref/demon_core
	///Easy way to connect a computer and a turbine roundstart by setting an id on both this and the core_rotor
	var/mapping_id

/obj/machinery/computer/core_monitor/post_machine_initialize()
	. = ..()

	if(!mapping_id)
		return
	for(var/obj/machinery/demon_core/main as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/demon_core))
		register_machine(main)
		break

/obj/machinery/computer/core_monitor/multitool_act(mob/living/user, obj/item/multitool/multitool)
	. = ITEM_INTERACT_FAILURE
	if(!istype(multitool.buffer, /obj/machinery/demon_core))
		to_chat(user, span_notice("Wrong machine type in [multitool] buffer..."))
		return
	if(demon_core)
		to_chat(user, span_notice("Changing [src] bluespace network..."))
	if(!do_after(user, 0.2 SECONDS, src))
		return

	playsound(get_turf(user), 'sound/machines/click.ogg', 10, TRUE)
	register_machine(multitool.buffer)
	to_chat(user, span_notice("You link [src] to the console in [multitool]'s buffer."))
	return ITEM_INTERACT_SUCCESS

/**
 * Links the rotor with this computer
 * Arguments
 *
 * * obj/machinery/power/turbine/core_rotor/machine - the machine to link
 */
/obj/machinery/computer/core_monitor/proc/register_machine(obj/machinery/power/turbine/core_rotor/machine)
	PRIVATE_PROC(TRUE)

	demon_core = WEAKREF(machine)

/obj/machinery/computer/core_monitor/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CoreMonitor", name)
		ui.open()

/obj/machinery/computer/core_monitor/ui_data(mob/user)
	. = list()
	var/obj/machinery/demon_core/our_core = demon_core?.resolve()
	if(!our_core.catalyst_core)
		.["core_present"] = FALSE
		return
	else
		.["core_present"] = TRUE
	//operation status
	if(our_core?.catalyst_core)
		.["min_temperature"] = our_core?.catalyst_core.min_temperature
		.["max_temperature"] = our_core?.catalyst_core.max_temperature
		.["stability"] = our_core.destabilizing ? "Unstable" : "Stable"
	.["bomb_size"] = our_core.bomb_size
	.["internal_energy"] = our_core.internal_energy
	.["environment_temperature"] = our_core.env_temp

	//explosive parameters
	.["payload"] = our_core?.inserted_ttv?.name || our_core??.inserted_tank.name

/obj/machinery/computer/core_monitor/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("begin_implosion")
			var/obj/machinery/demon_core/our_core = demon_core?.resolve()
			if(!our_core)
				return FALSE
			our_core.attempts_implosion()
			return TRUE
