/datum/antagonist/obsessed
	name = "Obsessed"
	show_in_antagpanel = TRUE
	antagpanel_category = "Other"
	job_rank = ROLE_OBSESSED
	antag_hud_type = ANTAG_HUD_OBSESSED
	antag_hud_name = "obsessed"
	show_name_in_check_antagonists = TRUE
	roundend_category = "obsessed"
	silent = TRUE //not actually silent, because greet will be called by the trauma anyway.
	var/datum/brain_trauma/special/obsessed/trauma
	greentext_reward = 20

/datum/antagonist/obsessed/admin_add(datum/mind/new_owner,mob/admin)
	var/mob/living/carbon/C = new_owner.current
	if(!istype(C))
		to_chat(admin, "[roundend_category] должен быть живым!")
		return
	if(!C.getorgan(/obj/item/organ/brain)) // If only I had a brain
		to_chat(admin, "[roundend_category] НУЖЕН МОЗГ.")
		return
	message_admins("[key_name_admin(admin)] made [key_name_admin(new_owner)] into [name].")
	log_admin("[key_name(admin)] made [key_name(new_owner)] into [name].")
	//PRESTO FUCKIN MAJESTO
	C.gain_trauma(/datum/brain_trauma/special/obsessed)//ZAP

/datum/antagonist/obsessed/greet()
	owner.current.playsound_local(get_turf(owner.current), 'sound/ambience/antag/creepalert.ogg', 100, FALSE, pressure_affected = FALSE, use_reverb = FALSE)
	var/policy = get_policy(ROLE_OBSESSED)
	if(policy)
		to_chat(policy)
	owner.announce_objectives()

/datum/antagonist/obsessed/Destroy()
	if(trauma)
		qdel(trauma)
	. = ..()

/datum/antagonist/obsessed/apply_innate_effects(mob/living/mob_override)
	var/mob/living/M = mob_override || owner.current
	add_antag_hud(antag_hud_type, antag_hud_name, M)

/datum/antagonist/obsessed/remove_innate_effects(mob/living/mob_override)
	var/mob/living/M = mob_override || owner.current
	remove_antag_hud(antag_hud_type, M)

/datum/antagonist/obsessed/proc/forge_objectives(datum/mind/obsessionmind)
	var/list/objectives_left = list("spendtime", "polaroid"/*, "hug"*/) //нахуй, оно сломано
	var/datum/objective/assassinate/obsessed/kill = new
	kill.owner = owner
	kill.target = obsessionmind
	var/datum/quirk/family_heirloom/family_heirloom

	for(var/datum/quirk/quirky in obsessionmind.current.roundstart_quirks)
		if(istype(quirky, /datum/quirk/family_heirloom))
			family_heirloom = quirky
			break
	if(family_heirloom)//oh, they have an heirloom? Well you know we have to steal that.
		objectives_left += "heirloom"

	if(obsessionmind.assigned_role && obsessionmind.assigned_role != "Captain")
		objectives_left += "jealous"//if they have no coworkers, jealousy will pick someone else on the station. this will never be a Развлекаться, nice.

	for(var/i in 1 to 3)
		var/chosen_objective = pick(objectives_left)
		objectives_left.Remove(chosen_objective)
		switch(chosen_objective)
			if("spendtime")
				var/datum/objective/spendtime/spendtime = new
				spendtime.owner = owner
				spendtime.target = obsessionmind
				objectives += spendtime
			if("polaroid")
				var/datum/objective/polaroid/polaroid = new
				polaroid.owner = owner
				polaroid.target = obsessionmind
				objectives += polaroid
			if("hug")
				var/datum/objective/hug/hug = new
				hug.owner = owner
				hug.target = obsessionmind
				objectives += hug
			if("heirloom")
				var/datum/objective/steal/heirloom_thief/heirloom_thief = new
				heirloom_thief.owner = owner
				heirloom_thief.target = obsessionmind//while you usually wouldn't need this for stealing, we need the name of the obsession
				heirloom_thief.steal_target = family_heirloom.heirloom
				objectives += heirloom_thief
			if("jealous")
				var/datum/objective/assassinate/jealous/jealous = new
				jealous.owner = owner
				jealous.target = obsessionmind//will reroll into a coworker on the objective itself
				objectives += jealous

	objectives += kill//finally add the assassinate last, because you'd have to complete it last to greentext.
	for(var/datum/objective/O in objectives)
		O.update_explanation_text()

/datum/antagonist/obsessed/roundend_report_header()
	return 	"<span class='header'>Кто-то стал одержимым!</span><br>"

/datum/antagonist/obsessed/roundend_report()
	var/list/report = list()

	if(!owner)
		CRASH("antagonist datum without owner")

	report += "<b>[printplayer(owner)]</b>"

	var/objectives_complete = TRUE
	if(objectives.len)
		report += printobjectives(objectives)
		for(var/datum/objective/objective in objectives)
			if(!objective.check_completion())
				objectives_complete = FALSE
				break
	if(trauma)
		if(trauma.total_time_creeping > 0)
			report += span_greentext("Одержимый потратил [DisplayTimeText(trauma.total_time_creeping)] возле [trauma.obsession]!")
		else
			report += span_redtext("Одержимый не ходил рядом с их одержимостью весь раунд! Это очень впечатляет!")
	else
		report += span_redtext("У одержимого не было никакой травмы, приложенной к их путям антагониста! Либо он товарищ администратор неправильно дал эту роль и она сломалась!")

	if(objectives.len == 0 || objectives_complete)
		report += "<span class='greentext big'>Одержимый успешен!</span>"
	else
		report += "<span class='redtext big'>Одержимый провален!</span>"

	return report.Join("<br>")

//////////////////////////////////////////////////
///CREEPY objectives (few chosen per obsession)///
//////////////////////////////////////////////////

/datum/objective/assassinate/obsessed //just a creepy version of assassinate

/datum/objective/assassinate/obsessed/update_explanation_text()
	..()
	if(target?.current)
		explanation_text = "Убить [target.name], на должности [!target_role_type ? target.assigned_role : target.special_role]."
	else
		message_admins("WARNING! [ADMIN_LOOKUPFLW(owner)] obsessed objectives forged without an obsession!")
		explanation_text = "Ничего."

/datum/objective/assassinate/jealous //assassinate, but it changes the target to someone else in the previous target's department. cool, right?
	var/datum/mind/old //the target the coworker was picked from.

/datum/objective/assassinate/jealous/update_explanation_text()
	..()
	old = find_coworker(target)
	if(target?.current && old)
		explanation_text = "Убить старого коллегу моей цели - [target]."
	else
		explanation_text = "Ничего."

/datum/objective/assassinate/jealous/proc/find_coworker(datum/mind/oldmind)//returning null = Развлекаться
	if(!oldmind || !oldmind.assigned_role)
		return
	var/list/viable_coworkers = list()
	var/list/all_coworkers = list()
	var/chosen_department
	var/their_chosen_department
	//note that command and sillycone are gone because borgs can't be obsessions and the heads have their respective department. Sorry cap, your place is more with centcom or something
	if(oldmind.assigned_role in GLOB.security_positions)
		chosen_department = "security"
	if(oldmind.assigned_role in GLOB.engineering_positions)
		chosen_department = "engineering"
	if(oldmind.assigned_role in GLOB.medical_positions)
		chosen_department = "medical"
	if(oldmind.assigned_role in GLOB.science_positions)
		chosen_department = "science"
	if(oldmind.assigned_role in GLOB.supply_positions)
		chosen_department = "supply"
	if(oldmind.assigned_role in GLOB.service_positions)
		chosen_department = "service"
	for(var/mob/living/carbon/human/H in GLOB.alive_mob_list)
		if(!H.mind)
			continue
		if(!SSjob.GetJob(H.mind.assigned_role) || H == oldmind.current || H.mind.has_antag_datum(/datum/antagonist/obsessed))
			continue //the jealousy target has to have a job, and not be the obsession or obsessed.
		all_coworkers += H.mind
		//this won't be called often thankfully.
		if(H.mind.assigned_role in GLOB.security_positions)
			their_chosen_department = "security"
		if(H.mind.assigned_role in GLOB.engineering_positions)
			their_chosen_department = "engineering"
		if(H.mind.assigned_role in GLOB.medical_positions)
			their_chosen_department = "medical"
		if(H.mind.assigned_role in GLOB.science_positions)
			their_chosen_department = "science"
		if(H.mind.assigned_role in GLOB.supply_positions)
			their_chosen_department = "supply"
		if(H.mind.assigned_role in GLOB.service_positions)
			their_chosen_department = "service"
		if(their_chosen_department != chosen_department)
			continue
		viable_coworkers += H.mind

	if(viable_coworkers.len > 0)//find someone in the same department
		target = pick(viable_coworkers)
	else if(all_coworkers.len > 0)//find someone who works on the station
		target = pick(all_coworkers)
	return oldmind

/datum/objective/spendtime //spend some time around someone, handled by the obsessed trauma since that ticks
	name = "spendtime"
	var/timer = 1800 //5 minutes

/datum/objective/spendtime/update_explanation_text()
	if(timer == initial(timer))//just so admins can mess with it
		timer += pick(-600, 0)
	var/datum/antagonist/obsessed/creeper = owner.has_antag_datum(/datum/antagonist/obsessed)
	if(target?.current && creeper)
		creeper.trauma.attachedobsessedobj = src
		explanation_text = "Находиться возле [target.name] [DisplayTimeText(timer)]ы пока цель жива."
	else
		explanation_text = "Ничего."

/datum/objective/spendtime/check_completion()
	return timer <= 0 || explanation_text == "Ничего."


/datum/objective/hug//this objective isn't perfect. hugging the correct amount of times, then switching bodies, might fail the objective anyway. maybe i'll come back and fix this sometime.
	name = "hugs"
	var/hugs_needed

/datum/objective/hug/update_explanation_text()
	..()
	if(!hugs_needed)//just so admins can mess with it
		hugs_needed = rand(4,6)
	if(!owner)
		return
	var/datum/antagonist/obsessed/creeper = owner.has_antag_datum(/datum/antagonist/obsessed)
	if(target?.current && creeper)
		explanation_text = "Обнять [target.name] [hugs_needed] раз пока цель жива."
	else
		explanation_text = "Ничего."

/datum/objective/hug/check_completion()
	var/datum/antagonist/obsessed/creeper = owner.has_antag_datum(/datum/antagonist/obsessed)
	if(!creeper || !creeper.trauma || !hugs_needed)
		return TRUE//Развлекаться
	return creeper.trauma.obsession_hug_count >= hugs_needed

/datum/objective/polaroid //take a picture of the target with you in it.
	name = "polaroid"

/datum/objective/polaroid/update_explanation_text()
	..()
	if(target?.current)
		explanation_text = "Сделать фото с [target.name] пока цель жива."
	else
		explanation_text = "Ничего."

/datum/objective/polaroid/check_completion()
	var/list/datum/mind/owners = get_owners()
	for(var/datum/mind/M in owners)
		if(!isliving(M.current))
			continue
		var/list/all_items = M.current.GetAllContents()	//this should get things in cheesewheels, books, etc.
		for(var/obj/I in all_items) //Check for wanted items
			if(istype(I, /obj/item/photo))
				var/obj/item/photo/P = I
				if(P.picture && (target.current in P.picture.mobs_seen) && !(target.current in P.picture.dead_seen)) //Does the picture exist and is the target in it and is the target not dead
					return TRUE
	return FALSE


/datum/objective/steal/heirloom_thief //exactly what it sounds like, steal someone's heirloom.
	name = "heirloomthief"

/datum/objective/steal/heirloom_thief/update_explanation_text()
	..()
	if(steal_target)
		explanation_text = "Украсть семейную реликвию [steal_target] у [target.name]."
	else
		explanation_text = "Ничего."
