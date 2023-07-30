/datum/computer_file/program/social_rating
	filename = "meowmeowbeanz"
	filedesc = "Social Rating App"
	category = PROGRAM_CATEGORY_CREW
	extended_desc = "A social rating app employed by NT to experiment how crewmates will respond to their social ranking."
	requires_ntnet = TRUE
	tgui_id = "SocialRating"
	program_icon_state = "rating_icon"

/obj/machinery/computer/records/medical/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	if(.)
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if (!ui)
		create_character_preview_view(user)
		ui = new(user, src, "SocialRating")
		ui.set_autoupdate(FALSE)
		ui.open()

/datum/computer_file/program/social_rating/ui_data(mob/user)
	var/list/data = ..()

	var/list/records = list()
	for(var/datum/record/crew/target in GLOB.manifest.general)
		records += list(list(
			age = target.age,
			crew_ref = REF(target),
			gender = target.gender,
			name = target.name,
			rank = target.rank,
			species = target.species,
		))

	data["records"] = records

	return data

