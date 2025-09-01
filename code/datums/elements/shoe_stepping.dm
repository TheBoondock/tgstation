/datum/element/shoe_stepping

/datum/element/shoe_stepping/Attach(datum/target)
	. = ..()
	RegisterSignal(target, COMSIG_LIVING_MOB_SWAPPED, PROC_REF(step_on_shoe))

/datum/element/shoe_stepping/Detach(datum/source, ...)
	. = ..()
	UnregisterSignal(source, COMSIG_LIVING_MOB_SWAPPED)

/datum/element/shoe_stepping/proc/step_on_shoe(mob/living/agressor, mob/living/victim)
	SIGNAL_HANDLER

	if(prob(100))
		//agressor handling
		agressor.face_atom(victim)
		agressor.do_alert_animation()
		to_chat(agressor, span_boldwarning("You stepped on [victim]'s shoes! Will you apologize or escalate more."))
		to_chat(agressor, span_alertwarning("The conflict ends once you apologize or one of you is in crit."))
		//victim handling
		victim.face_atom(agressor)
		victim.do_alert_animation()
		to_chat(victim, span_boldwarning("[agressor] stepped on your shoes! Will you let them get away with that?"))
		to_chat(victim, span_alertwarning("The conflict ends once [agressor] apologize or one of you is in crit."))

